/*
************************************************************************************************************************
* file : E:\KeilWorkspace\M3\uCOS_III_mdk5\HardwareAbstractionLayer\src\hal.c
* Description : 
* Owner : Lews Hammond
* Time : 2019-6-4
************************************************************************************************************************
*/


#include "hal.h"


static halInitSta_t halInitSta = EN_HAL_UNINIT;

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
	halInitSta_t *pInitSta = &halInitSta;
#if (D_SYS_WDG_ENABLE == D_SYS_STD_ON)
	D_HAL_WDG_INIT();
	*pInitSta = EN_HAL_WDG_INIT_FINISH;
#endif	
	Hal_SysIntInit();
	*pInitSta = EN_HAL_INT_INIT_FINISH;
	
	Hal_IoInit();
	*pInitSta = EN_HAL_IO_INIT_FINISH;
	
	Hal_SysUartInit();
	*pInitSta = EN_HAL_UART_INIT_FINISH;

	Hal_RtcInit();
	*pInitSta = EN_HAL_ALL_INIT_FINISH;
}

/*
************************************************************************************************************************
*                                            get hardware abstraction layer inital status
*
* Description : get hardware abstraction layer inital status.
*
* Arguments   : void.
*
* Returns     : halInitSta_t. initial status.
************************************************************************************************************************
*/
halInitSta_t Hal_GetInitStatus(void)
{
	return halInitSta;
}



