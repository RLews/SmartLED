/*
************************************************************************************************************************
* file : hal_rtc.h
* Description : 
* Author : Lews Hammond
* Time : 2019-6-11
************************************************************************************************************************
*/

#ifndef _HAL_RTC_H
#define _HAL_RTC_H

#include "hal_public.h"

#define D_DEFAULT_SYS_TIME_YEAR		2019
#define D_DEFAULT_SYS_TIME_MON		6
#define D_DEFAULT_SYS_TIME_DAY		6
#define D_DEFAULT_SYS_TIME_HOUR		16
#define D_DEFAULT_SYS_TIME_MIN		30
#define D_DEFAULT_SYS_TIME_SEC		30
#define D_DEFAULT_SYS_TIME_WEEK		4

#define D_HAL_LEAP_YEAR				(366)
#define D_HAL_NOR_YEAR				(365)
#define D_HAL_TIME_HOUR_IN_A_DAY	(24)
#define D_HAL_TIME_MIN_IN_A_HOUR	(60)
#define D_HAL_TIME_SEC_IN_A_MIN		(60)

#define D_HAL_SEC_IN_A_DAY			( (uint32_t)((D_HAL_TIME_HOUR_IN_A_DAY * D_HAL_TIME_MIN_IN_A_HOUR) * D_HAL_TIME_SEC_IN_A_MIN) )
#define D_HAL_SEC_IN_A_HOUR			( (uint32_t)(D_HAL_TIME_MIN_IN_A_HOUR * D_HAL_TIME_SEC_IN_A_MIN) )

#define D_HAL_SEC_IN_LEAP_YEAR		( (uint32_t)((uint32_t)D_HAL_LEAP_YEAR * D_HAL_SEC_IN_A_DAY) )
#define D_HAL_SEC_IN_NOR_YEAR		( (uint32_t)((uint32_t)D_HAL_NOR_YEAR * D_HAL_SEC_IN_A_DAY) )


#endif

