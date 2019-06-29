/*
************************************************************************************************************************
* file : E:\KeilWorkspace\M3\uCOS_III_mdk5\HardwareDriverLayer\src\drv_timer.c
* Description : 
* Owner : Lews Hammond
* Time : 2019-6-4
************************************************************************************************************************
*/


#include "drv_timer.h"

/*
************************************************************************************************************************
*                                               SysTick interrupt enable
*
* Description : SysTick interrupt enable.
*
* Arguments   : void
*
* Returns     : void
************************************************************************************************************************
*/
void Drv_SysTickIntEnable(void)
{
	SysTick->CTRL |= SysTick_CTRL_TICKINT_Msk;   	//¿ªÆôSYSTICKÖÐ¶Ï
}

/*
************************************************************************************************************************
*                                               SysTick interrupt disable
*
* Description : SysTick interrupt disable.
*
* Arguments   : void
*
* Returns     : void
************************************************************************************************************************
*/
void Drv_SysTickIntDisable(void)
{
	SysTick->CTRL &= (uint32_t)(~SysTick_CTRL_TICKINT_Msk);
}

/*
************************************************************************************************************************
*                                               SysTick Start
*
* Description : SysTick start.
*
* Arguments   : void
*
* Returns     : void
************************************************************************************************************************
*/
void Drv_SysTickOpen(void)
{
	SysTick->CTRL |= SysTick_CTRL_ENABLE_Msk;   	//¿ªÆôSYSTICK  
}

/*
************************************************************************************************************************
*                                               SysTick stop
*
* Description : SysTick stop.
*
* Arguments   : void
*
* Returns     : void
************************************************************************************************************************
*/
void Drv_SysTickClose(void)
{
	SysTick->CTRL &= (uint32_t)(~SysTick_CTRL_ENABLE_Msk);
}

/*
************************************************************************************************************************
*                                               SysTick counter update
*
* Description : Update SysTick Counter number.
*
* Arguments   : void
*
* Returns     : void
************************************************************************************************************************
*/
void Drv_SysTickSetReload(uint32_t val)
{
	SysTick->LOAD = val;
}

