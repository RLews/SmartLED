/*
************************************************************************************************************************
* file : app_wifi.h
* Description : 
* Author : Lews Hammond
* Time : 2019-6-17
************************************************************************************************************************
*/

#ifndef _APP_WIFI_H
#define _APP_WIFI_H

#include "app_public.h"
#include "gizwits_product.h"
#include "srv_wifi_comm.h"
#include "app_shock.h"
#include "app_led_ctrl.h"

#if (D_UC_OS_III_ENABLE == D_STD_ON)

#include "os_cfg_app.h"

#define D_WIFI_TMR_MS			(OS_CFG_TICK_RATE_HZ/OS_CFG_TMR_TASK_RATE_HZ)

#else

#define D_WIFI_TMR_MS			5

#endif

#define D_WIFI_UPDATE_PERIOD	(200 * 1000ul)

#define D_WIFI_REQUEST_TIME		(10000ul * 1000ul) //10s

#define D_WIFI_LED_PERIOD_TICK	D_WIFI_TMR_MS


typedef enum _WIFI_SET_MODE_T
{
	EN_WIFI_MODE_RUN = 0,
	EN_WIFI_MODE_AIR_LINK,
	EN_WIFI_MODE_SOFT_AP,
	EN_WIFI_MODE_SLEEP,
	EN_WIFI_MODE_RESET
}wifiSetMode_t;

typedef struct _WIFI_SET_INFO_T
{
	uint32_t setTs;
	wifiSetMode_t setMode;
}wifiSetInfo_t;



void Wifi_TaskInit(void);
void Wifi_TaskHandle(void);

#endif


