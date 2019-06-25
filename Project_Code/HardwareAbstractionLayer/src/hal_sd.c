/*
************************************************************************************************************************
* file : hal_sd.c
* Description : 
* Author : Lews Hammond
* Time : 2019-6-12
************************************************************************************************************************
*/

#include "hal_sd.h"

#if (D_PLATFORMS_SD_ENABLE == D_SYS_STD_ON)

static uint8_t sdCardType = D_SD_TYPE_ERR;

static void Hal_SDCardInitPulse(void);
static uint8_t Hal_SDCardIntoIDLE(void);
static sdCardErr_t Hal_SDCardReadOCR(uint8_t *pBuf);


/*
************************************************************************************************************************
* Function Name    : Hal_SDCardGetCID
* Description      : read cid
* Input Arguments  : 
* Output Arguments : uint8_t *pCID
* Returns          : sdCardErr_t
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-12
************************************************************************************************************************
*/

sdCardErr_t Hal_SDCardGetCID(uint8_t *pCID)
{
	uint8_t revDat = 0;
	sdCardErr_t optRes = EN_SD_OPT_OK;

	revDat = Drv_SDCardSendCmd(D_SD_CMD10_READ_CID, 0, 0x01);
	if (revDat == D_SD_MSD_RESPONSE_NORMAL)
	{
		optRes = Drv_SDCardRevDat(pCID, D_SD_CARD_CID_SIZE);
	}
	Drv_SDCardCanelSelect();

	return optRes;
}


/*
************************************************************************************************************************
* Function Name    : Hal_SDCardGetCSD
* Description      : read csd
* Input Arguments  : 
* Output Arguments : uint8_t *pCSD
* Returns          : sdCardErr_t
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-12
************************************************************************************************************************
*/

sdCardErr_t Hal_SDCardGetCSD(uint8_t *pCSD)
{
	uint8_t revDat = 0;
	sdCardErr_t optRes = EN_SD_OPT_OK;

	revDat = Drv_SDCardSendCmd(D_SD_CMD9_READ_CSD, 0, 0x01);
	if (revDat == D_SD_MSD_RESPONSE_NORMAL)
	{
		optRes = Drv_SDCardRevDat(pCSD, D_SD_CARD_CSD_SIZE);
	}
	else
	{
		optRes = EN_SD_ERR_RESPONSE_FAIL;
	}
	Drv_SDCardCanelSelect();

	return optRes;
}


/*
************************************************************************************************************************
* Function Name    : Hal_SDCardGetSectorNum
* Description      : read sector number
* Input Arguments  : 
* Output Arguments : uint32_t *pSectorNum
* Returns          : sdCardErr_t
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-12
************************************************************************************************************************
*/

sdCardErr_t Hal_SDCardGetSectorNum(uint32_t *pSectorNum)
{
	uint8_t csd[D_SD_CARD_CSD_SIZE] = {0};
	uint8_t n = 0;
	uint16_t cSize = 0;
	sdCardErr_t optErr = EN_SD_OPT_OK;

	optErr = Hal_SDCardGetCSD(csd);
	if (optErr != EN_SD_OPT_OK)
	{
		return optErr;
	}

	if ( (csd[0] & 0xC0) == 0x40 )//SDHC V2.x
	{
		cSize = csd[9] + ((uint16_t)csd[8] << 8) + 1;
		*pSectorNum = (uint32_t)cSize << 10;
	}
	else //V1.xx
	{
		n = (csd[5] & 0x0F) + ((csd[10] & 0x80) >> 7) + ((csd[9] & 0x03) << 1) + 2;
		cSize = (csd[8] >> 6) + ((uint16_t)csd[7] << 2) + ((uint16_t)(csd[6] & 0x03) << 10) + 1;
		*pSectorNum = (uint32_t)cSize << (n - 9);
	}

	return optErr;
}



/*
************************************************************************************************************************
* Function Name    : Hal_SDCardReadDisk
* Description      : read disk
* Input Arguments  : uint32_t sector, uint8_t cnt
* Output Arguments : uint8_t *pBuf
* Returns          : sdCardErr_t
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-12
************************************************************************************************************************
*/

sdCardErr_t Hal_SDCardReadDisk(uint8_t *pBuf, uint32_t sector, uint8_t cnt)
{
	sdCardErr_t optRes = EN_SD_OPT_OK;

	if (sdCardType != D_SD_TYPE_V2HC)
	{
		sector <<= 9;//convert byte address
	}

	if (cnt == 1)
	{
		optRes = (sdCardErr_t)Drv_SDCardSendCmd(D_SD_CMD17_READ_SECTOR, sector, 0x01);
		if (optRes == EN_SD_OPT_OK)
		{
			optRes = Drv_SDCardRevDat(pBuf, D_SD_CARD_SECTOR_SIZE);
		}
	}
	else
	{
		optRes = (sdCardErr_t)Drv_SDCardSendCmd(D_SD_CMD18_READ_MULT_SECTOR, sector, 0x01);
		do {
			optRes = Drv_SDCardRevDat(pBuf, D_SD_CARD_SECTOR_SIZE);
			pBuf += D_SD_CARD_SECTOR_SIZE;
			cnt--;
		}while ( (cnt != 0) && (optRes == EN_SD_OPT_OK) );
		(void)Drv_SDCardSendCmd(D_SD_CMD12_STOP_TRANS, 0, 0x01);
	}

	Drv_SDCardCanelSelect();

	return optRes;
}



/*
************************************************************************************************************************
* Function Name    : Hal_SDCardWriteDisk
* Description      : write disk
* Input Arguments  : const uint8_t *pBuf, uint32_t sector, uint8_t cnt
* Output Arguments : 
* Returns          : sdCardErr_t
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-12
************************************************************************************************************************
*/

sdCardErr_t Hal_SDCardWriteDisk(const uint8_t *pBuf, uint32_t sector, uint8_t cnt)
{
	sdCardErr_t optRes = EN_SD_OPT_OK;
	uint8_t i = 0;

	if (sdCardType != D_SD_TYPE_V2HC)
	{
		sector <<= 9;//convert byte address
	}

	if (cnt == 1)
	{
		optRes = (sdCardErr_t)Drv_SDCardSendCmd(D_SD_CMD24_WRITE_SECTOR, sector, 0x01);
		if (optRes == EN_SD_OPT_OK)
		{
			optRes = Drv_SDCardSendBlock(pBuf, 0xFE);
		}
	}
	else
	{
		if (sdCardType != D_SD_TYPE_MMC)
		{
			optRes = (sdCardErr_t)Drv_SDCardSendCmd(D_SD_CMD55, 0, 0x01);
			optRes = (sdCardErr_t)Drv_SDCardSendCmd(D_SD_CMD23_ERASE_BLOCK, cnt, 0x01);
		}
		optRes = (sdCardErr_t)Drv_SDCardSendCmd(D_SD_CMD25_WRITE_MULT_SECTOR, sector, 0x01);
		if (optRes == EN_SD_OPT_OK)
		{
			for (i = 0; i < cnt; i++)
			{
				optRes = Drv_SDCardSendBlock(pBuf, 0xFC);
				pBuf += D_SD_CARD_SECTOR_SIZE;
				if (optRes != EN_SD_OPT_OK)
				{
					break;
				}
			}

			optRes = Drv_SDCardSendBlock(0, 0xFD);
		}
	}
	Drv_SDCardCanelSelect();

	return optRes;
}


/*
************************************************************************************************************************
* Function Name    : Hal_SDCardInitPulse
* Description      : transmit 74 pulse
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-12
************************************************************************************************************************
*/

static void Hal_SDCardInitPulse(void)
{
	uint8_t i = 0;
	uint8_t rev = 0;
	
	for (i = 0; i < 10; i++)
	{/* transmit 74 pulse */
		(void)D_SD_CARD_WR_BYTE_FUNC(0xFF, &rev);
	}
}


/*
************************************************************************************************************************
* Function Name    : Hal_SDCardIntoIDLE
* Description      : goto idle mode
* Input Arguments  : 
* Output Arguments : 
* Returns          : uint8_t
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-12
************************************************************************************************************************
*/

static uint8_t Hal_SDCardIntoIDLE(void)
{
	uint8_t timeCnt = 20;
	uint8_t rev = 0;

	do {
		rev = Drv_SDCardSendCmd(D_SD_CMD0_RESET, 0, 0x95);
		timeCnt--;
	}while ( (timeCnt != 0) && (rev != D_SD_MSD_IN_IDLE_STATUS) );

	return rev;
}


/*
************************************************************************************************************************
* Function Name    : Hal_SDCardReadOCR
* Description      : read ocr
* Input Arguments  : 
* Output Arguments : uint8_t *pBuf
* Returns          : sdCardErr_t
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-12
************************************************************************************************************************
*/

static sdCardErr_t Hal_SDCardReadOCR(uint8_t *pBuf)
{
	uint8_t i = 0;
	
	if (Drv_SDCardSendCmd(D_SD_CMD58_READ_OCR, 0, 0x01) == D_SD_MSD_RESPONSE_NORMAL)
	{
		for (i = 0; i < 4; i++)
		{
			(void)D_SD_CARD_WR_BYTE_FUNC(0xFF, pBuf);
			pBuf++;
		}

		return EN_SD_OPT_OK;
	}
	else
	{
		return EN_SD_ERR_RESPONSE_FAIL;
	}
}


/*
************************************************************************************************************************
* Function Name    : Hal_SDCardInit
* Description      : sd card initial
* Input Arguments  : 
* Output Arguments : 
* Returns          : sdCardErr_t
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-12
************************************************************************************************************************
*/

sdCardErr_t Hal_SDCardInit(void) 
{
	uint8_t rev = 0;
	uint16_t timeCnt = 0;
	uint8_t buf[4] = {0};
	uint8_t i = 0;
	
	Drv_SDCardSpiInit();
	D_SET_SD_CARD_LOW_SPD_MODE();
	Hal_SDCardInitPulse();
	
	if (Hal_SDCardIntoIDLE() == D_SD_MSD_IN_IDLE_STATUS)
	{
		if (Drv_SDCardSendCmd(D_SD_CMD8_TX_IF_COND, 0x1AA, 0x87) == 1)//SD v2.0
		{
			for (i = 0; i < 4; i++)
			{
				(void)D_SD_CARD_WR_BYTE_FUNC(0xFF, &buf[i]);//Get trailing return value of R7 resp
			}
			if ( (buf[2] == 0x01) && (buf[3] == 0xAA) )/* 2.7 - 3.6v */
			{
				timeCnt = 0xFFFE;
				do {
					rev = Drv_SDCardSendCmd(D_SD_CMD55, 0, 0x01);
					rev = Drv_SDCardSendCmd(D_SD_CMD41, 0x40000000, 0x01);
					timeCnt--;
				}while ( (rev != 0) && (timeCnt != 0) );

				if ( (timeCnt != 0) && (Hal_SDCardReadOCR(buf) == EN_SD_OPT_OK) )
				{
					if (0 != (buf[0] & 0x40))
					{
						sdCardType = D_SD_TYPE_V2HC;
					}
					else
					{
						sdCardType = D_SD_TYPE_V2;
					}
				}
			}
		}
		else/* SD v1.x / MMC */
		{
			rev = Drv_SDCardSendCmd(D_SD_CMD55, 0, 0x01);
			rev = Drv_SDCardSendCmd(D_SD_CMD41, 0, 0x01);
			if (rev <= 1)
			{
				sdCardType = D_SD_TYPE_V1;
				timeCnt = 0xFFFE;
				do {
					rev = Drv_SDCardSendCmd(D_SD_CMD55, 0, 0x01);
					rev = Drv_SDCardSendCmd(D_SD_CMD41, 0, 0x01);
					timeCnt--;
				}while ( (timeCnt != 0) && (rev != D_SD_MSD_RESPONSE_NORMAL) );
			}
			else
			{
				sdCardType = D_SD_TYPE_MMC;
				timeCnt = 0xFFFE;
				do {
					rev = Drv_SDCardSendCmd(D_SD_CMD1, 0, 0x01);
				}while ( (timeCnt != 0) && (rev != D_SD_MSD_RESPONSE_NORMAL) );
			}
			if ((timeCnt == 0) || (Drv_SDCardSendCmd(D_SD_CMD16_SECTOR_SIZE, D_SD_CARD_SECTOR_SIZE, 0x01) != 0))
			{
				sdCardType = D_SD_TYPE_ERR;
			}
		}
	}

	Drv_SDCardCanelSelect();
	D_SET_SD_CARD_HIGH_SPD_MODE();

	if (sdCardType != D_SD_TYPE_ERR)
	{
		return EN_SD_OPT_OK;
	}
	else if (rev != 0)
	{
		return (sdCardErr_t)rev;
	}
	else
	{
		return EN_SD_ERR_OTHER;
	}
}

#endif

