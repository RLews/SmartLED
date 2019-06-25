/*
************************************************************************************************************************
* file : E:\KeilWorkspace\M3\uCOS_III_mdk5\HardwareDriverLayer\inc\drv_wdg.h
* Description : 
* Owner : Lews Hammond
* Time : 2019-6-4
************************************************************************************************************************
*/


#ifndef __DRV_WATCHDOG_H
#define __DRV_WATCHDOG_H

#include "drv_public.h"


/* Toverflow = ((4 * (2 ^ PerscalerFactor)) * ReloadVal) / 40 */
#define D_DRV_WDG_RELOAD_VAL			(187u)//300ms overflow

#define D_DRV_WDG_PERSCALER_FACTOR		(4u)


#endif

