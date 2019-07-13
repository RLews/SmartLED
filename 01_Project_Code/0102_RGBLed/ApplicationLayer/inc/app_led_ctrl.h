/*
************************************************************************************************************************
* file : app_led_ctrl.h
* Description : 
* Author : Lews Hammond
* Time : 2019-7-11
************************************************************************************************************************
*/

#ifndef _APP_LED_CTRL_H
#define _APP_LED_CTRL_H

#include "app_public.h"

#define D_LED_MIN_BRIGHTNESS			3

#define D_LED_GRADIENT_DEFAULT_FREQ		500

#define D_LED_BRIGHTNESS_MAX			D_DRV_PWM_LEVEL_MAX

typedef enum _LED_MODE_T
{
	EN_LED_SLEEP = 0,
	EN_LED_MODE0,
	EN_LED_MODE1,
	EN_LED_MODE2,
	EN_LED_WIFI_MODE/* set wifi link */
}ledMode_t;

typedef struct _LED_DATA_T
{
	uint16_t warmLedDuty;
	uint16_t redLedDuty;
	uint16_t greenLedDuty;
	uint16_t blueLedDuty;
}ledData_t;


void Led_SetWarmDat(uint16_t duty);

void Led_SetRGBDat(uint16_t rDuty, uint16_t gDuty, uint16_t bDuty);

void Led_WarmOff(void);

void Led_WarmOn(void);

void Led_ModeCycling(void);

void Led_AllOff(void);

void Led_ModeCycling(void);

void Led_PeriodProc(void);

void Led_CtrlInit(void);

void Led_PeriodProc(void);

void Led_SetFlash(void);

void Led_EnterWifiSet(void);

void Led_ExitWifiSet(void);

uint16_t Led_GetWarmDuty(void);

uint16_t Led_GetRedDuty(void);

uint16_t Led_GetGreenDuty(void);

uint16_t Led_GetBlueDuty(void);

#endif

