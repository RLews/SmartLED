/*
************************************************************************************************************************
* file : E:\KeilWorkspace\M3\uCOS_III_mdk5\HardwareAbstractionLayer\src\hal_led.c
* Description : 
* Owner : Lews Hammond
* Time : 2019-6-4
************************************************************************************************************************
*/


#include "hal_led.h"

static uint8_t wifiLedSta = D_STD_OFF;

/*
************************************************************************************************************************
*                                               hal gpio initial
*
* Description : hal gpio initial.
*
* Arguments   : void.
*
* Returns     : void.
************************************************************************************************************************
*/
void Hal_IoInit(void)
{
	Drv_GpioInit();
}

/*
************************************************************************************************************************
*                                               hal system run led on
*
* Description : control run led on.
*
* Arguments   : void.
*
* Returns     : void.
************************************************************************************************************************
*/
void Hal_RunLedOn(void)
{
	Drv_GpioNameOut(EN_SYSTEM_RUN_LED, EN_GPIO_LOW);
}

/*
************************************************************************************************************************
*                                               hal system run led off
*
* Description : control run led off.
*
* Arguments   : void.
*
* Returns     : void.
************************************************************************************************************************
*/
void Hal_RunLedOff(void)
{
	Drv_GpioNameOut(EN_SYSTEM_RUN_LED, EN_GPIO_HIGH);
}

/*
************************************************************************************************************************
*                                               hal wifi led on
*
* Description : control wifi led on.
*
* Arguments   : void.
*
* Returns     : void.
************************************************************************************************************************
*/
void Hal_WifiLedOn(void)
{
	Drv_GpioNameOut(EN_WIFI_LED_GPIO, EN_GPIO_LOW);
	
	wifiLedSta = D_SYS_STD_ON;
}

/*
************************************************************************************************************************
*                                               hal wifi led off
*
* Description : control wifi led off.
*
* Arguments   : void.
*
* Returns     : void.
************************************************************************************************************************
*/
void Hal_WifiLedOff(void)
{
	Drv_GpioNameOut(EN_WIFI_LED_GPIO, EN_GPIO_HIGH);
	
	wifiLedSta = D_STD_OFF;
}


/*
************************************************************************************************************************
* Function Name    : Hal_GetWifiLedSta
* Description      : get wifi led state
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-17
************************************************************************************************************************
*/

uint8_t Hal_GetWifiLedSta(void)
{
	return wifiLedSta;
}

