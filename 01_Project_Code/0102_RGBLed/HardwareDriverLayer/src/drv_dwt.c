/*
************************************************************************************************************************
* file : E:\KeilWorkspace\M3\uCOS_III_mdk5\HardwareDriverLayer\src\drv_dwt.c
* Description : 
* Owner : Lews Hammond
* Time : 2019-6-4
************************************************************************************************************************
*/


#include "drv_dwt.h"

static stdBoolean_t dwtInitFinished = EN_STD_FALSE;


/*
************************************************************************************************************************
*                                               mcu dwt model initial
*
* Description : enable dwt model and initial status
*
* Arguments   : void
*
* Returns     : void
************************************************************************************************************************
*/
void Drv_DwtInit(void)
{
	DEM_CR |= (uint32_t)DEM_CR_TRCENA;/* enable dwt */
	DWT_CYCCNT = (uint32_t)0;/* clear counter */
	DWT_CR |= (uint32_t)DWT_CR_CYCCNTENA;
	dwtInitFinished = EN_STD_TRUE;
}

/*
************************************************************************************************************************
* Function Name    : Drv_GetDwtInitSta
* Description      : get dwt initial status
* Input Arguments  : void
* Output Arguments : void
* Returns          : stdBoolean_t : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-10
************************************************************************************************************************
*/

stdBoolean_t Drv_GetDwtInitSta(void)
{
	return dwtInitFinished;
}


/*
************************************************************************************************************************
*                                               Get dwt model counter number
*
* Description : Get dwt model counter number
*
* Arguments   : void
*
* Returns     : void
************************************************************************************************************************
*/
uint32_t Drv_GetDwtCnt(void)
{
 	return ((uint32_t)DWT_CYCCNT);
}

/*
************************************************************************************************************************
*                                               Get mcu running frequency
*
* Description : Get mcu running frequency
*
* Arguments   : void
*
* Returns     : void
************************************************************************************************************************
*/
uint32_t Drv_GetCpuFreq(void)
{
	RCC_ClocksTypeDef  rccClock = {0};

    RCC_GetClocksFreq(&rccClock);

    return ((uint32_t)rccClock.HCLK_Frequency);
}

