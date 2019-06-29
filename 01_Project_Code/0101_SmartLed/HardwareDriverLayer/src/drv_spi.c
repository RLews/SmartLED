/*
************************************************************************************************************************
* file : E:\KeilWorkspace\M3\uCOS_III_mdk5\HardwareDriverLayer\src\drv_spi.c
* Description : 
* Author : Lews Hammond
* Time : 2019-6-5
************************************************************************************************************************
*/


#include "drv_spi.h"

#if (D_PLATFORMS_SPI_ENABLE == D_SYS_STD_ON)

static const spiConfig_t spiConfigArr[EN_ALL_SPI_NUM] = {
	D_SPI_CONFIG_ARRAY
};

static stdBoolean_t spiInitFinished = EN_STD_FALSE;

static spiError_t Drv_Spi2IsBusy(void);

/*
************************************************************************************************************************
* Function Name    : Drv_SpiInit
* Description      : Spi Initial
* Input Arguments  : void
* Output Arguments : void
* Returns          : void
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-5
************************************************************************************************************************
*/

void Drv_SpiInit(void)
{
	uint8_t i = 0;
	SPI_InitTypeDef SPI_InitStructure = {0};
	const spiConfig_t *pConfig = spiConfigArr;

	for (i = 0; i < EN_ALL_SPI_NUM; i++)
	{
		RCC_APB1PeriphClockCmd(pConfig[i].spiRcc,ENABLE);
		SPI_InitStructure.SPI_Direction = pConfig[i].spiDir;
		SPI_InitStructure.SPI_Mode = pConfig[i].spiMode;
		SPI_InitStructure.SPI_DataSize = pConfig[i].spiDataSize;
		SPI_InitStructure.SPI_CPOL = pConfig[i].spiCpol;
		SPI_InitStructure.SPI_CPHA = pConfig[i].spiCpha;
		SPI_InitStructure.SPI_NSS = pConfig[i].spiNss;
		SPI_InitStructure.SPI_BaudRatePrescaler = pConfig[i].spiBaudRatePer;
		SPI_InitStructure.SPI_FirstBit = pConfig[i].spiFirstBits;
		SPI_InitStructure.SPI_CRCPolynomial = pConfig[i].spiCrc;
		SPI_Init(pConfig[i].spiDef, &SPI_InitStructure);
		SPI_Cmd(pConfig[i].spiDef, ENABLE);
	}

	spiInitFinished = EN_STD_TRUE;
}

/*
************************************************************************************************************************
* Function Name    : Drv_GetSpiInitSta
* Description      : Get spi initial status
* Input Arguments  : void
* Output Arguments : void
* Returns          : stdBoolean_t: spi driver initial status
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-10
************************************************************************************************************************
*/

stdBoolean_t Drv_GetSpiInitSta(void)
{
	return spiInitFinished;
}


/*
************************************************************************************************************************
* Function Name    : Drv_Spi2SetSpeed
* Description      : set spi2 baudrate prescaler
* Input Arguments  : uint8_t baudRatePer : spi perscaler
* Output Arguments : void
* Returns          : void
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-5
************************************************************************************************************************
*/

void Drv_Spi2SetSpeed(uint8_t baudRatePre)
{
	SPI2->CR1 &= 0xFFC7;
	SPI2->CR1 |= baudRatePre;
	SPI_Cmd(SPI2,ENABLE);
}

/*
************************************************************************************************************************
* Function Name    : Drv_Spi2IsBusy
* Description      : judge spi2 busy?
* Input Arguments  : void
* Output Arguments : void
* Returns          : spiError_t
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-5
************************************************************************************************************************
*/

static spiError_t Drv_Spi2IsBusy(void)
{
	uint16_t timeCount = 0;
	
	do {
		timeCount++;
		if (timeCount >= D_SPI2_TIMEOUT_LIMIT_VAL)
		{
			return EN_OPERATION_SPI_BUSY;
		}
	}while (SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_TXE) == RESET);

	return EN_OPERATION_SPI_OK;
}

/*
************************************************************************************************************************
* Function Name    : Drv_Spi2RWByte
* Description      : spi2 write and read byte
* Input Arguments  : const uint8_t txDat : transmit data
* Output Arguments : uint8_t * rxDat : receiver data
* Returns          : spiError_t
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-5
************************************************************************************************************************
*/

spiError_t Drv_Spi2RWByte(const uint8_t txDat, uint8_t * rxDat)
{
	uint16_t timeCount = 0;

	if (Drv_Spi2IsBusy() == EN_OPERATION_SPI_BUSY)
	{
		return EN_OPERATION_SPI_BUSY;
	}

	SPI_I2S_SendData(SPI2, txDat);

	do {
		timeCount++;
		if (timeCount >= D_SPI2_TIMEOUT_LIMIT_VAL)
		{
			return EN_OPERATION_SPI_TIMEOUT;
		}
	}while (SPI_I2S_GetFlagStatus(SPI2, SPI_I2S_FLAG_RXNE) == RESET);
	
	*rxDat = SPI_I2S_ReceiveData(SPI2);

	return EN_OPERATION_SPI_OK;
}
#endif

