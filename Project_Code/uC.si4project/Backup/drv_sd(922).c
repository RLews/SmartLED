/*
************************************************************************************************************************
* file : E:\KeilWorkspace\M3\uCOS_III_mdk5\HardwareDriverLayer\src\drv_sd.c
* Description : 
* Author : Lews Hammond
* Time : 2019-6-5
************************************************************************************************************************
*/


#include "drv_sd.h"




/*
************************************************************************************************************************
* Function Name    : Drv_SDCardSpiInit
* Description      : SD Card spi initial
* Input Arguments  : void
* Output Arguments : void
* Returns          : void
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-10
************************************************************************************************************************
*/

void Drv_SDCardSpiInit(void)
{
	uint8_t initTx = 0xFF;
	uint8_t initRx = 0;
	
	if (EN_STD_FALSE == Drv_GetGpioInitSta())
	{
		Drv_GpioInit();
	}

	if (EN_STD_FALSE == Drv_GetSpiInitSta())
	{
		Drv_SpiInit();
	}
	
	(void)D_SD_CARD_WR_BYTE_FUNC(initTx, &initRx);
	D_SD_CARD_SPI_CS_CANCEL();
}

/*
************************************************************************************************************************
* Function Name    : Drv_SDCardCanelSelect
* Description      : sd card canel chip select
* Input Arguments  : void
* Output Arguments : void
* Returns          : void
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-10
************************************************************************************************************************
*/

void Drv_SDCardCanelSelect(void)
{
	uint8_t data = 0;
	
	D_SD_CARD_SPI_CS_CANCEL();
	(void)D_SD_CARD_WR_BYTE_FUNC(0xFF, &data);
}

/*
************************************************************************************************************************
* Function Name    : Drv_SDCardWaitReady
* Description      : wait sd card
* Input Arguments  : void
* Output Arguments : void
* Returns          : sdCardErr_t
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-10
************************************************************************************************************************
*/

sdCardErr_t Drv_SDCardWaitReady(void)
{
	uint32_t timeOutCnt = 0;
	uint8_t rxDat = 0;

	do {
		(void)D_SD_CARD_WR_BYTE_FUNC(0xFF, &rxDat);
		if (rxDat == 0xFF)
		{
			return EN_SD_OPT_OK;
		}
	}while (timeOutCnt < 0xFFFFFF);

	return EN_SD_ERR_TIMEOUT;
}

/*
************************************************************************************************************************
* Function Name    : Drv_SDCardSelect
* Description      : select sd card
* Input Arguments  : void
* Output Arguments : void
* Returns          : sdCardErr_t
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-10
************************************************************************************************************************
*/

sdCardErr_t Drv_SDCardSelect(void)
{
	D_SD_CARD_SPI_CS_SELECT();
	if (Drv_SDCardWaitReady() == EN_SD_OPT_OK)
	{
		return EN_SD_OPT_OK;
	}
	else
	{
		D_SD_CARD_SPI_CS_CANCEL();
		return EN_SD_ERR_TIMEOUT;
	}
}

/*
************************************************************************************************************************
* Function Name    : Drv_SDCardResponseIsCorrect
* Description      : judge response correct
* Input Arguments  : uint8_t resp
* Output Arguments : void
* Returns          : uint8_t
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-10
************************************************************************************************************************
*/

uint8_t Drv_SDCardResponseIsCorrect(uint8_t resp)
{
	uint16_t waitCnt = 0xFFFFu;
	uint8_t rxDat = 0;

	do {
		(void)D_SD_CARD_WR_BYTE_FUNC(0xFF, &rxDat);
		waitCnt--;
	}while ((rxDat != resp) && (waitCnt != 0));

	if (waitCnt == 0)
	{
		return D_SD_MSD_RESPONSE_FAIL;
	}
	else
	{
		return D_SD_MSD_RESPONSE_NORMAL;
	}
}

/*
************************************************************************************************************************
* Function Name    : Drv_SDCardRevDat
* Description      : receiver sd card data package
* Input Arguments  : uint16_t len
* Output Arguments : uint8_t *pBuf
* Returns          : sdCardErr_t
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-10
************************************************************************************************************************
*/

sdCardErr_t Drv_SDCardRevDat(uint8_t *pBuf, uint16_t len)
{
	uint16_t i = 0;
	uint8_t tmp = 0;
	
	if (Drv_SDCardResponseIsCorrect(D_SD_CARD_DATA_START_TOKEN) != D_SD_MSD_RESPONSE_NORMAL)
	{
		return EN_SD_ERR_RESPONSE_FAIL;
	}

	for (i = 0; i < len; i++)
	{
		(void)D_SD_CARD_WR_BYTE_FUNC(0xFF, pBuf);
		pBuf++;
	}

	/* Dummy CRC */
	(void)D_SD_CARD_WR_BYTE_FUNC(0xFF, &tmp);
	(void)D_SD_CARD_WR_BYTE_FUNC(0xFF, &tmp);

	return EN_SD_OPT_OK;
}

/*
************************************************************************************************************************
* Function Name    : Drv_SDCardSendBlock
* Description      : sd card send block data
* Input Arguments  : const uint8_t pBuf[]: data , uint8_t cmd: command
* Output Arguments : void
* Returns          : sdCardErr_t
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-10
************************************************************************************************************************
*/

sdCardErr_t Drv_SDCardSendBlock(const uint8_t pBuf[], uint8_t cmd)
{
	uint16_t i = 0;
	uint8_t tmp = 0;

	if (Drv_SDCardWaitReady() != EN_SD_OPT_OK)
	{
		return EN_SD_ERR_TIMEOUT;
	}

	(void)D_SD_CARD_WR_BYTE_FUNC(cmd, &tmp);
	if (cmd != D_SD_CARD_DATA_END_CMD)
	{
		for (i = 0; i < D_SD_CARD_BLOCK_SIZE; i++)
		{
			(void)D_SD_CARD_WR_BYTE_FUNC(pBuf[i], &tmp);
		}
		/* Dummy CRC */
		(void)D_SD_CARD_WR_BYTE_FUNC(0xFF, &tmp);
		(void)D_SD_CARD_WR_BYTE_FUNC(0xFF, &tmp);
		/* receiver response */
		(void)D_SD_CARD_WR_BYTE_FUNC(0xFF, &tmp);
		if ((tmp & 0x1F) != D_SD_MSD_DATA_OK)
		{
			return EN_SD_ERR_RESPONSE_FAIL;
		}
	}

	return EN_SD_OPT_OK;
}

/*
************************************************************************************************************************
* Function Name    : Drv_SDCardSendCmd
* Description      : sd card send cmd
* Input Arguments  : uint8_t cmd : , uint32_t arg : , uint8_t crc : 
* Output Arguments : void
* Returns          : uint8_t
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-10
************************************************************************************************************************
*/

uint8_t Drv_SDCardSendCmd(uint8_t cmd, uint32_t arg, uint8_t crc)
{
	uint8_t reg = 0;
	uint8_t waitCnt = 0;

	Drv_SDCardCanelSelect();
	if (Drv_SDCardSelect() != EN_SD_OPT_OK)
	{
		return EN_SD_ERR_TIMEOUT;
	}

	(void)D_SD_CARD_WR_BYTE_FUNC((cmd | 0x40), &reg);
	(void)D_SD_CARD_WR_BYTE_FUNC((uint8_t)(arg >> 24), &reg);
	(void)D_SD_CARD_WR_BYTE_FUNC((uint8_t)(arg >> 16), &reg);
	(void)D_SD_CARD_WR_BYTE_FUNC((uint8_t)(arg >> 8), &reg);
	(void)D_SD_CARD_WR_BYTE_FUNC((uint8_t)(arg), &reg);
	(void)D_SD_CARD_WR_BYTE_FUNC(crc, &reg);
	if (cmd == D_SD_CMD12_STOP_TRANS)
	{
		(void)D_SD_CARD_WR_BYTE_FUNC(0xFF, &reg);//Skip a stuff byte when stop reading
	}

	waitCnt = 0x1F;
	do {
		(void)D_SD_CARD_WR_BYTE_FUNC(0xFF, &reg);
		waitCnt--;
	}while ( (reg & 0x80) && (waitCnt != 0) );

	return reg;
}




