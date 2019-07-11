/*
************************************************************************************************************************
* file : E:\KeilWorkspace\M3\uCOS_III_mdk5\HardwareAbstractionLayer\inc\hal_public.h
* Description : 
* Owner : Lews Hammond
* Time : 2019-6-4
************************************************************************************************************************
*/


#ifndef _HAL_PUBLIC_H
#define _HAL_PUBLIC_H

#include "drv_public.h"
#include "srv_queue.h"

typedef void (*SysISRFunc)(void);
typedef void (*FaultRecordFunc)(void);
typedef void (*UartRxSemPost)(void);

#define D_HAL_INT_NULL		((void *)0)


/*
************************************************************************************************************************
* Hardware Abstraction Layer initial Interface
************************************************************************************************************************
*/
void Hal_SysInit(void);


/*
************************************************************************************************************************
* Key Hardware Abstraction Layer Interface
************************************************************************************************************************
*/
typedef enum _KEY_NAME_T
{
	EN_KEY_WIFI = 0,
	EN_KEY_ALL_TYPE
}keyName_t;

typedef enum _KEY_STATE_T
{
	EN_KEY_NONE = 0,
	EN_KEY_PRESS_DOWN,
	EN_KEY_WAIT_PRESS_UP,
	EN_KEY_PRESS_UP,
	EN_KEY_REPEAT,	//hold press
	EN_KEY_DOUBLE_PRESS,
	EN_KEY_DOUBLE_PRESS_UP,
	EN_KEY_ALL_STATE
}keyState_t;

typedef struct _KEY_MANAGE_T
{
	stdBoolean_t newKeyFlg;
	keyState_t keySta;
}keyManage_t;

void Hal_KeyScan(void);
stdBoolean_t Hal_CheckNewKey(uint8_t id);
void Hal_ClearNewKeyFlg(uint8_t id);
keyState_t Hal_GetKeySta(uint8_t id);


/*
************************************************************************************************************************
* Interrupt  Interface
************************************************************************************************************************
*/
typedef enum _SYS_INT_ISR_T
{
	EN_NMI_ISR = 0,
	EN_HARD_FAULT_ISR,
	EN_MEM_MANAGE_ISR,
	EN_BUS_FAULT_ISR,
	EN_SUAGE_FAULT_ISR,
	EN_SVC_ISR,
	EN_DEBUG_MON_ISR,
	/*EN_PENDSV_ISR, //this uC/OS manage */
	EN_SYS_TICK_ISR,
	EN_WWDG_ISR,
	EN_PVD_ISR,
	EN_TAMPER_ISR,
	EN_RTC_ISR,
	EN_FLASH_ISR,
	EN_RCC_ISR,
	EN_EXTI0_ISR,
	EN_EXTI1_ISR,
	EN_EXTI2_ISR,
	EN_EXTI3_ISR,
	EN_EXTI4_ISR,
	EN_DMA1_CH1_ISR,
	EN_DMA1_CH2_ISR,
	EN_DMA1_CH3_ISR,
	EN_DMA1_CH4_ISR,
	EN_DMA1_CH5_ISR,
	EN_DMA1_CH6_ISR,
	EN_DMA1_CH7_ISR,
	EN_ADC1_2_ISR,
	EN_USB_HP_CAN1_TX_ISR,
	EN_USB_LP_CAN1_RX0_ISR,
	EN_CAN1_RX1_ISR,
	EN_CAN1_SCE_ISR,
	EN_EXTI9_5_ISR,
	EN_TIM1_BRK_ISR,
	EN_TIM1_UP_ISR,
	EN_TIM1_TRG_COM_ISR,
	EN_TIM1_CC_ISR,
	EN_TIM2_ISR,
	EN_TIM3_ISR,
	EN_TIM4_ISR,
	EN_I2C1_EV_ISR,
	EN_I2C1_ER_ISR,
	EN_I2C2_EV_ISR,
	EN_I2C2_ER_ISR,
	EN_SPI1_ISR,
	EN_SPI2_ISR,
	EN_USART1_ISR,
	EN_USART2_ISR,
	EN_USART3_ISR,
	EN_EXTI15_10_ISR,
	EN_RTCAlarm_ISR,
	EN_USBWakeUp_ISR,
	EN_TIM8_BRK_ISR,
	EN_TIM8_UP_ISR,
	EN_TIM8_TRG_COM_ISR,
	EN_TIM8_CC_ISR,
	EN_ADC3_ISR,
	EN_FSMC_ISR,
	EN_SDIO_ISR,
	EN_TIM5_ISR,
	EN_SPI3_ISR,
	EN_UART4_ISR,
	EN_UART5_ISR,
	EN_TIM6_ISR,
	EN_TIM7_ISR,
	EN_DMA2_CH1_ISR,
	EN_DMA2_CH2_ISR,
	EN_DMA2_CH3_ISR,
	EN_DMA2_CH4_5_ISR,
	EN_ALL_SYS_ISR_NUM
}sysIntIsr_t;

void Hal_SysIntInit(void);
void Hal_SysISRSet(sysIntIsr_t isrTyp, SysISRFunc isrFunc);
uint8_t Hal_GetCurIntID(void);
void Hal_SetFaultFunc(FaultRecordFunc pFunc);
void Hal_DisableAllInt(void);
void Hal_EnableAllInt(void);


/*
************************************************************************************************************************
* Watchdog  Interface
************************************************************************************************************************
*/
#if (D_SYS_WDG_ENABLE == D_STD_ON)
#define D_HAL_WDG_INIT()			Drv_WdgInit()
#define D_HAL_WDG_FEED()			Drv_WdgFeed()
#endif


/*
************************************************************************************************************************
* Adc  Interface
************************************************************************************************************************
*/

void Hal_AdcInit(void);
uint16_t Hal_ScanShock(void);


/*
************************************************************************************************************************
* Timer  Interface
************************************************************************************************************************
*/
void Hal_SysTickInit(uint16_t tim);

/*
************************************************************************************************************************
* Led  Interface
************************************************************************************************************************
*/
#define D_HAL_SET_WARM_LED(duty)		Drv_PwmSetDuty(EN_WARM_PWM, duty)
#define D_HAL_SET_RED_LED(duty)			Drv_PwmSetDuty(EN_RED_PWM, duty)
#define D_HAL_SET_GREEN_LED(duty)		Drv_PwmSetDuty(EN_GREEN_PWM, duty)
#define D_HAL_SET_BLUE_LED(duty)		Drv_PwmSetDuty(EN_BLUE_PWM, duty)


void Hal_IoInit(void);
void Hal_RunLedOn(void);
void Hal_RunLedOff(void);
void Hal_WifiLedOn(void);
void Hal_WifiLedOff(void);
uint8_t Hal_GetWifiLedSta(void);


/*
************************************************************************************************************************
* Uart  Interface
************************************************************************************************************************
*/
void Hal_SysUartInit(void);
void Hal_SetSysRxSemPostFunc(UartRxSemPost pFunc);
void Hal_SetWifiRxSemPostFunc(UartRxSemPost pFunc);

srvQueueError_t Hal_UartWrite(uartName_t name, const uint8_t dat[], uint8_t len);
srvQueueError_t Hal_UartReadByte(uartName_t name, uint8_t *dat);


/*
************************************************************************************************************************
* RTC  Interface
************************************************************************************************************************
*/
typedef struct _RTC_TIME_T
{
	uint16_t rtcYear;
	uint8_t rtcMon;
	uint8_t rtcDay;
	uint8_t rtcHour;
	uint8_t rtcMin;
	uint8_t rtcSec;
	uint8_t rtcWeek;
}rtcTime_t;

void Hal_RtcInit(void);
void Hal_RtcGetTime(rtcTime_t *pTime);
void Hal_RtcSetTime(rtcTime_t times);


/*
************************************************************************************************************************
* SD Card  Interface
************************************************************************************************************************
*/
#if (D_PLATFORMS_SD_ENABLE == D_STD_ON)

sdCardErr_t Hal_SDCardGetCID(uint8_t *pCID);
sdCardErr_t Hal_SDCardGetCSD(uint8_t *pCSD);
sdCardErr_t Hal_SDCardGetSectorNum(uint32_t *pSectorNum);
sdCardErr_t Hal_SDCardReadDisk(uint8_t *pBuf, uint32_t sector, uint8_t cnt);
sdCardErr_t Hal_SDCardWriteDisk(const uint8_t *pBuf, uint32_t sector, uint8_t cnt);
sdCardErr_t Hal_SDCardInit(void);

#endif


#endif

