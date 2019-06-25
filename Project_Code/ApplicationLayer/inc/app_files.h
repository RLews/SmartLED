/*
************************************************************************************************************************
* file : app_files.h
* Description : 
* Author : Lews Hammond
* Time : 2019-6-12
************************************************************************************************************************
*/


#ifndef _APP_FILES_H
#define _APP_FILES_H

#include "app_public.h"

#define D_APP_SD_CARD_INIT_MAX_TIME		3

#define D_FILE_SYSTEM_NOT_ERROR			0

#define D_FILE_SYS_DELAY_MOUNT			0
#define D_FILE_SYS_IMMEDIATELY_MOUNT	1

#define D_FILE_SYS_RUN_LOG_DIR			"0:/uC_Terminal/System_Log"
#define D_FILE_SYS_RUN_LOG_PATH			"0:/uC_Terminal/System_Log/Log.txt"

#define D_FILE_SYS_FAULT_LOG_DIR		"0:/uC_Terminal/Fault_Log"
#define D_FILE_SYS_FAULT_LOG_PATH		"0:/uC_Terminal/Fault_Log/Fault_Record.txt"

typedef enum _APP_PHY_DEVICE_T
{
	EN_SD_CARD_DEVICE = 0,
	EN_ALL_DEVICE_TYPE
}appPhyDevice_t;

typedef enum _FILE_SYSTEM_RUN_STA_T
{
	EN_SD_CARD_UNINITIAL = 0,
	EN_SD_CARD_INITIAL,
	EN_FILE_SYS_UNMOUNTED,
	EN_FILE_SYS_MOUNTED,
	EN_FILE_SYS_RUNNING,
	EN_USB_NOT_CONNECTED,
	EN_USB_CONNECTED,
	EN_FILE_SYSTEM_ALL_STATE
}fileSystemSta_t;

typedef struct _FILE_SYSTEM_RUN_INFO_T
{
	fileSystemSta_t fileSta;
	uint8_t fileErrCode;
}fileSysRunInfo_t;

#endif

