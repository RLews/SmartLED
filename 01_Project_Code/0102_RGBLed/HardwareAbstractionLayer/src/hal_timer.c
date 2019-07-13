/*
************************************************************************************************************************
* file : E:\KeilWorkspace\M3\uCOS_III_mdk5\HardwareAbstractionLayer\src\hal_timer.c
* Description : 
* Owner : Lews Hammond
* Time : 2019-6-4
************************************************************************************************************************
*/


#include "hal_timer.h"

/*
************************************************************************************************************************
* Function Name    : Hal_SysTickInit
* Description      : 
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-7-11
************************************************************************************************************************
*/

void Hal_SysTickInit(uint16_t tim)
{
	uint32_t tReload = 0;
	const uint32_t *pSysCoreClock = &SystemCoreClock;

	tReload = (*pSysCoreClock) / 8000000;//ÿ���ӵļ������� ��λΪK	   
	tReload *= 1000000 / (tim);//����delay_ostickspersec�趨���ʱ��

	//Hal_SysISRSet(EN_SYS_TICK_ISR, Bsp_Os_SysTickHandler);
	Drv_SysTickIntDisable();
	Drv_SysTickSetReload(tReload);
	Drv_SysTickOpen();
	Drv_SysTickIntEnable();
}



