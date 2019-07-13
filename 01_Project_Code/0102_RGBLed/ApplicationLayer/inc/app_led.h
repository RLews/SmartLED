/*
************************************************************************************************************************
* file : E:\KeilWorkspace\M3\uCOS_III_mdk5\ApplicationLayer\inc\app_led.h
* Description : 
* Owner : Lews Hammond
* Time : 2019-6-4
************************************************************************************************************************
*/


#ifndef __APP_LED_H
#define __APP_LED_H

#include "app_public.h"

#define D_SYS_LED_STACK_DEBUG		D_STD_OFF

#define D_SYS_LED_FLASH_TIME		500//unit: ms


void Sys_LedInit(void);
void Sys_LedFlash(void);




#endif
