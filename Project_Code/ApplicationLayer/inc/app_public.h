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


#define D_SYS_COMM_ENABLE		D_SYS_STD_OFF

#if (D_SYS_COMM_ENABLE == D_SYS_STD_ON)
void SysCommInit(void);
#endif


#if (D_FILE_SYSTEM_ENABLE == D_SYS_STD_ON)
void FilesTaskInit(void);
#endif

void SystemLedInit(void);

void WifiTaskInit(void);

#if (D_UC_OS_III_ENABLE != D_SYS_STD_ON)

void WifiTaskHandle(void);
void SystemLedFlash(void);


#endif

#endif

