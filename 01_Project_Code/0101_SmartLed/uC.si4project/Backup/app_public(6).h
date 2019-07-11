/*
************************************************************************************************************************
* file : E:\KeilWorkspace\M3\uCOS_III_mdk5\ApplicationLayer\inc\app_public.h
* Description : 
* Owner : Lews Hammond
* Time : 2019-6-4
************************************************************************************************************************
*/


#ifndef _APP_PUBLIC_H
#define _APP_PUBLIC_H


#include "hal_public.h"
#include "osal.h"
#include "srv_comm.h"






void Sys_LedInit(void);

void Wifi_TaskInit(void);

#if (D_UC_OS_III_ENABLE != D_STD_ON)

#define D_SYS_MS_COUNT				(1000ul)

void Wifi_TaskHandle(void);
void Sys_LedFlash(void);
void Shk_PeriodHandle(void);


#endif

#endif

