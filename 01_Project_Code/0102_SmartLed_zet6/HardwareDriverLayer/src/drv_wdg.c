/*
************************************************************************************************************************
* file : E:\KeilWorkspace\M3\uCOS_III_mdk5\HardwareDriverLayer\src\drv_wdg.c
* Description : 
* Owner : Lews Hammond
* Time : 2019-6-4
************************************************************************************************************************
*/


#include "drv_wdg.h"


#if (D_SYS_WDG_ENABLE == D_STD_ON)

static stdBoolean_t wdgInitFinished = EN_STD_FALSE;

/*
************************************************************************************************************************
* Function Name    : Drv_WdgInit
* Description      : watchdog initial
* Input Arguments  : void
* Output Arguments : void
* Returns          : void
* Notes            : 
* Owner            : Lews
* Time             : 2019-6-4
************************************************************************************************************************
*/

void Drv_WdgInit(void)
{
	IWDG_WriteAccessCmd(IWDG_WriteAccess_Enable);
	
	IWDG_SetPrescaler(D_DRV_WDG_PERSCALER_FACTOR);
	
	IWDG_SetReload(D_DRV_WDG_RELOAD_VAL);
	
	IWDG_ReloadCounter();
	
	IWDG_Enable();

	wdgInitFinished = EN_STD_TRUE;
}

/*
************************************************************************************************************************
* Function Name    : Drv_GetWdgInitSta
* Description      : get watchdog initial status
* Input Arguments  : void
* Output Arguments : void
* Returns          : stdBoolean_t : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-10
************************************************************************************************************************
*/

stdBoolean_t Drv_GetWdgInitSta(void)
{
	return wdgInitFinished;
}


/*
************************************************************************************************************************
* Function Name    : Drv_WdgFeed
* Description      : feed watchdog
* Input Arguments  : void
* Output Arguments : void
* Returns          : void
* Notes            : 
* Owner            : Lews
* Time             : 2019-6-4
************************************************************************************************************************
*/

void Drv_WdgFeed(void)
{
	IWDG_ReloadCounter();
}
#endif


