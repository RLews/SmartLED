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

#if (D_UC_OS_III_ENABLE == D_SYS_STD_ON)

#include "os_cfg_app.h"

#define D_WIFI_TMR_MS			(OS_CFG_TICK_RATE_HZ/OS_CFG_TMR_TASK_RATE_HZ)

#else

#define D_WIFI_TMR_MS			5

#endif

#define D_WIFI_UPDATE_PERIOD	(100 * 1000ul)

#define D_WIFI_REQUEST_TIME		(30000ul * 1000ul) //30s

#endif


