/*
************************************************************************************************************************
* file : E:\KeilWorkspace\M3\uCOS_III_mdk5\HardwareDriverLayer\inc\drv_public.h
* Description : 
* Owner : Lews Hammond
* Time : 2019-6-4
************************************************************************************************************************
*/


#ifndef _DRV_PUBLIC_H
#define _DRV_PUBLIC_H

#include "platforms.h"

#define D_PLATFORMS_SPI_ENABLE				D_SYS_STD_OFF
#define D_PLATFORMS_SD_ENABLE				D_SYS_STD_OFF

/*
************************************************************************************************************************
* GPIO Interface
************************************************************************************************************************
*/
typedef enum _GPIO_NAME_T
{
	EN_SYSTEM_RUN_LED = 0,
	EN_WIFI_LED_GPIO,
	EN_WIFI_KEY_IO,
	EN_SYSTEM_UART_TX,
	EN_SYSTEM_UART_RX,
/*
	EN_W25Q63_CS,
	EN_NRFxx_CS,
	EN_SD_CARD_CS,
	EN_SPI2_SCK,
	EN_SPI2_MISO,
	EN_SPI2_MOSI,
*/
	EN_WIFI_UART_TX,
	EN_WIFI_UART_RX,
	EN_ALL_GPIO_NUM
}gpioName_t;

typedef enum _GPIO_STATE_T
{
	EN_GPIO_LOW = 0,
	EN_GPIO_HIGH,
	EN_GPIO_INPUT,
	EN_GPIO_NONE,
	EN_GPIO_ERR
}gpioState_t;

void Drv_GpioInit(void);
stdBoolean_t Drv_GetGpioInitSta(void);
void Drv_GpioNameOut(gpioName_t name, gpioState_t sta);
gpioState_t Drv_GpioNameIn(gpioName_t name);


/*
************************************************************************************************************************
* UART Interface
************************************************************************************************************************
*/
typedef enum _UART_NAME_T
{
	EN_SYS_COM = 0,
	EN_WIFI_COM,
	EN_ALL_UART_NUM
}uartName_t;

void Drv_SysUartInit(void);
stdBoolean_t Drv_GetUartInitSta(void);
void Drv_UartTxByte(uartName_t name, const uint8_t dat);
void Drv_UartITRxEnable(uartName_t name);
void Drv_UartITRxDisable(uartName_t name);
void Drv_UartITTxEnable(uartName_t name);
void Drv_UartITTxDisable(uartName_t name);
stdBoolean_t Drv_IsUartTxInt(uartName_t name);
stdBoolean_t Drv_IsUartRxInt(uartName_t name);
uint8_t Drv_UartGetRevData(uartName_t name);


/*
************************************************************************************************************************
* SPI Interface
************************************************************************************************************************
*/
#if (D_PLATFORMS_SPI_ENABLE == D_SYS_STD_ON)

typedef enum _SPI_NAME_T
{
	EN_SD_CARD_CH = 0,
	EN_ALL_SPI_NUM
}spiName_t;

typedef enum _SPI_ERROR_T
{
	EN_OPERATION_SPI_OK = 0,
	EN_OPERATION_SPI_BUSY,
	EN_OPERATION_SPI_TIMEOUT,
	EN_OPERATION_SPI_ALL_STA
}spiError_t;

void Drv_SpiInit(void);
stdBoolean_t Drv_GetSpiInitSta(void);
spiError_t Drv_Spi2RWByte(const uint8_t txDat, uint8_t * rxDat);
void Drv_Spi2SetSpeed(uint8_t baudRatePre);

#endif

/*
************************************************************************************************************************
* SD Card Interface
************************************************************************************************************************
*/
#if (D_PLATFORMS_SD_ENABLE == D_SYS_STD_ON)
typedef enum _SD_CARD_ERR_T

{
	EN_SD_OPT_OK = 0,
	EN_SD_ERR_TIMEOUT,
	EN_SD_ERR_RESPONSE_FAIL,
	EN_SD_ERR_OTHER,
	EN_SD_OPT_ERR_ALL_TYPE
}sdCardErr_t;

/* sd card command */
#define D_SD_CMD0_RESET					0
#define D_SD_CMD1						1
#define D_SD_CMD8_TX_IF_COND			8
#define D_SD_CMD9_READ_CSD				9
#define D_SD_CMD10_READ_CID				10
#define D_SD_CMD12_STOP_TRANS			12
#define D_SD_CMD16_SECTOR_SIZE			16
#define D_SD_CMD17_READ_SECTOR			17
#define D_SD_CMD18_READ_MULT_SECTOR		18
#define D_SD_CMD23_ERASE_BLOCK			23
#define D_SD_CMD24_WRITE_SECTOR			24
#define D_SD_CMD25_WRITE_MULT_SECTOR	25
#define D_SD_CMD41						41
#define D_SD_CMD55						55
#define D_SD_CMD58_READ_OCR				58
#define D_SD_CMD59_CRC_CTRL				59

/* sd card response identifer define */
#define D_SD_MSD_RESPONSE_NORMAL		0x00
#define D_SD_MSD_IN_IDLE_STATUS			0x01
#define D_SD_MSD_ERASE_RESET			0x02
#define D_SD_MSD_ILLEGAL_COMMAND		0x04
#define D_SD_MSD_CRC_ERR				0x08
#define D_SD_MSD_ERASE_SEQUENCE_ERR		0x10
#define D_SD_MSD_ADDRESS_ERR			0x20
#define D_SD_MSD_PARAMETER_ERR			0x40
#define D_SD_MSD_RESPONSE_FAIL			0xFF

#define D_SD_CARD_HIGH_SPEED			SPI_BaudRatePrescaler_2
#define D_SD_CARD_LOW_SPEED				SPI_BaudRatePrescaler_256

#define D_SET_SD_CARD_HIGH_SPD_MODE()	Drv_Spi2SetSpeed(D_SD_CARD_HIGH_SPEED)
#define D_SET_SD_CARD_LOW_SPD_MODE()	Drv_Spi2SetSpeed(D_SD_CARD_LOW_SPEED)
#define D_SD_CARD_WR_BYTE_FUNC(tx, rx)	Drv_Spi2RWByte(tx, rx)

#define D_SD_CARD_SPI_CS_SELECT()		Drv_GpioNameOut(EN_SD_CARD_CS, EN_GPIO_LOW)
#define D_SD_CARD_SPI_CS_CANCEL()		Drv_GpioNameOut(EN_SD_CARD_CS, EN_GPIO_HIGH)

void Drv_SDCardSpiInit(void);
void Drv_SDCardCanelSelect(void);
sdCardErr_t Drv_SDCardSelect(void);
uint8_t Drv_SDCardResponseIsCorrect(uint8_t resp);
sdCardErr_t Drv_SDCardRevDat(uint8_t *pBuf, uint16_t len);
sdCardErr_t Drv_SDCardSendBlock(const uint8_t pBuf[], uint8_t cmd);
uint8_t Drv_SDCardSendCmd(uint8_t cmd, uint32_t arg, uint8_t crc);
sdCardErr_t Drv_SDCardWaitReady(void);
#endif


/*
************************************************************************************************************************
* Interrupt Interface
************************************************************************************************************************
*/
#define D_ENABLE_ALL_INTERRUPT()	__enable_irq()
#define D_DISABLE_ALL_INTERRUPT()	__disable_irq()


/*
************************************************************************************************************************
* DWT Interface
************************************************************************************************************************
*/
void Drv_DwtInit(void);
stdBoolean_t Drv_GetDwtInitSta(void);
uint32_t Drv_GetDwtCnt(void);
uint32_t Drv_GetCpuFreq(void);


/*
************************************************************************************************************************
* Timer Interface
************************************************************************************************************************
*/
void Drv_SysTickIntEnable(void);
void Drv_SysTickIntDisable(void);
void Drv_SysTickOpen(void);
void Drv_SysTickClose(void);
void Drv_SysTickSetReload(uint32_t val);


/*
************************************************************************************************************************
* RTC Interface
************************************************************************************************************************
*/
typedef enum _DRV_RTC_ERR_T
{
	EN_RTC_OPT_OK = 0,
	EN_RTC_OPT_ERR_TIMROUT,
	EN_RTC_OPT_ERR_PARAMETER,
	EN_RTC_OPT_ERR_ALL_TYPE
}drvRtcErr_t;

#define D_DRV_ENABLE_RTC_SEC_INT()		RTC_ITConfig(RTC_IT_SEC, ENABLE)
#define D_DRV_DISABLE_RTC_SEC_INT()		RTC_ITConfig(RTC_IT_SEC, DISABLE)

void Drv_RtcInit(void);
void Drv_RtcSetCount(uint32_t secCnt);
uint32_t Drv_RtcGetCount(void);
stdBoolean_t Drv_RtcIsSecInt(void);
void Drv_RtcIsrHandle(void);



/*
************************************************************************************************************************
* Watchdog Interface
************************************************************************************************************************
*/
#define D_SYS_WDG_ENABLE			D_SYS_STD_OFF

#if (D_SYS_WDG_ENABLE == D_SYS_STD_ON)
void Drv_WdgInit(void);
void Drv_WdgFeed(void);
stdBoolean_t Drv_GetWdgInitSta(void);
#endif


#endif

