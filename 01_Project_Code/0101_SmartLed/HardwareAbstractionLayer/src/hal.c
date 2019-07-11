/*
************************************************************************************************************************
* file : E:\KeilWorkspace\M3\uCOS_III_mdk5\HardwareAbstractionLayer\src\hal.c
* Description : 
* Owner : Lews Hammond
* Time : 2019-6-4
************************************************************************************************************************
*/


#include "hal.h"



/*
************************************************************************************************************************
*                                               hardware abstraction layer inital
*
* Description : All hardware abstraction layer inital.
*
* Arguments   : void.
*
* Returns     : void.
************************************************************************************************************************
*/
void Hal_SysInit(void)
{
#if (D_SYS_WDG_ENABLE == D_STD_ON)
	D_HAL_WDG_INIT();
#endif	
	Hal_SysIntInit();
	
	Hal_IoInit();

	Hal_AdcInit();
	
	Hal_SysUartInit();

	Hal_RtcInit();
	
#if (D_UC_OS_III_ENABLE != D_STD_ON)
	Drv_DwtInit();//dwt initial
#endif
}



