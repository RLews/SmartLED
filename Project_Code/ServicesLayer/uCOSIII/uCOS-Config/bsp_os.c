/*
************************************************************************************************************************
* file : E:\KeilWorkspace\M3\uCOS_III_mdk5\ServicesLayer\uCOSIII\uCOS-Config\bsp_os.c
* Description : 
* Owner : Lews Hammond
* Time : 2019-6-4
************************************************************************************************************************
*/


#include "bsp_os.h"

static void Bsp_OsTimeStampInit(void);
static uint32_t Bsp_GetOsTimeStamp(void);
static uint32_t Bsp_GetCpuFreq(void);
static void Bsp_Os_SysTickHandler(void);


/*
************************************************************************************************************************
*                                               uC/OS iii Time Stamp Init
*
* Description : initial stm32f10x dwt model.
*
* Arguments   : void
*
* Returns     : void
************************************************************************************************************************
*/
static void Bsp_OsTimeStampInit(void)
{
	Drv_DwtInit();
}

/*
************************************************************************************************************************
*                                               uC/OS iii Get Time Stamp
*
* Description : Read dwt model counter number.
*
* Arguments   : void
*
* Returns     : uint32_t model counter number.
************************************************************************************************************************
*/
static uint32_t Bsp_GetOsTimeStamp(void)
{
	return Drv_GetDwtCnt();
}

/*
************************************************************************************************************************
*                                               uC/OS iii Get Ecu Running Frequency
*
* Description : Calculate Ecu Running Frequency.
*
* Arguments   : void
*
* Returns     : uint32_t Running Frequency.
************************************************************************************************************************
*/
static uint32_t Bsp_GetCpuFreq(void)
{
	return Drv_GetCpuFreq();
}

/*
************************************************************************************************************************
*                                               uC/OS iii SysTick Model initial
*
* Description : uC/OS iii SysTick Model initial
*
* Arguments   : void
*
* Returns     : void
************************************************************************************************************************
*/
void Bsp_OsTickInit(void)
{
	uint32_t tReload = 0;
	const uint32_t *pSysCoreClock = &SystemCoreClock;
	const uint32_t *pOsTickRateHz = &OSCfg_TickRate_Hz;

	tReload = (*pSysCoreClock) / 8000000;//每秒钟的计数次数 单位为K	   
	tReload *= 1000000 / (*pOsTickRateHz);//根据delay_ostickspersec设定溢出时间

	Hal_SysISRSet(EN_SYS_TICK_ISR, Bsp_Os_SysTickHandler);
	Drv_SysTickIntEnable();
	Drv_SysTickSetReload(tReload);
	Drv_SysTickOpen();
}


#if (CPU_CFG_TS_TMR_EN == DEF_ENABLED)
/*
************************************************************************************************************************
*                                               uC/OS iii Timer Model initial
*
* Description : uC/OS iii Timer Model initial
*
* Arguments   : void
*
* Returns     : void
************************************************************************************************************************
*/
void  CPU_TS_TmrInit (void)
{
    CPU_INT32U  tCpuFreq = 0u;

    Bsp_OsTimeStampInit();

    tCpuFreq = Bsp_GetCpuFreq();
    CPU_TS_TmrFreqSet(tCpuFreq);
}
#endif

#if (CPU_CFG_TS_TMR_EN == DEF_ENABLED)
/*
************************************************************************************************************************
*                                               uC/OS iii Timer Model Read Timestamp
*
* Description : uC/OS iii Timer Model Read Timestamp
*
* Arguments   : void
*
* Returns     : void
************************************************************************************************************************
*/
CPU_TS_TMR  CPU_TS_TmrRd (void)
{
    return Bsp_GetOsTimeStamp();
}
#endif


#if (CPU_CFG_TS_32_EN == DEF_ENABLED)
/*
************************************************************************************************************************
*                                               uC/OS iii running frequency convert to us
*
* Description : uC/OS iii running frequency convert to us
*
* Arguments   : void
*
* Returns     : void
************************************************************************************************************************
*/
CPU_INT64U CPU_TS32_to_uSec(CPU_TS32 ts_cnts)
{
	CPU_INT64U tUs = 0u;
	CPU_INT64U tFreq = 0u;

	tFreq = Bsp_GetCpuFreq();
	tUs = ts_cnts / (tFreq / DEF_TIME_NBR_uS_PER_SEC);

	return tUs;
}
#endif

#if (CPU_CFG_TS_64_EN == DEF_ENABLED)
/*
************************************************************************************************************************
*                                               uC/OS iii running frequency convert to us
*
* Description : uC/OS iii running frequency convert to us
*
* Arguments   : void
*
* Returns     : void
************************************************************************************************************************
*/
CPU_INT64U CPU_TS64_to_uSec(CPU_TS64 ts_cnts)
{
	CPU_INT64U tUs = 0u;
	CPU_INT64U tFreq = 0u;

	tFreq = Bsp_GetCpuFreq();
	tUs = ts_cnts / (tFreq / DEF_TIME_NBR_uS_PER_SEC);

	return tUs;
}
#endif

/*
************************************************************************************************************************
*                                               uC/OS iii SysTick interrupt Handle
*
* Description : uC/OS iii SysTick Handler
*
* Arguments   : void
*
* Returns     : void
************************************************************************************************************************
*/
static void Bsp_Os_SysTickHandler(void)
{	
	if(OSRunning==1)						
	{
		OS_CPU_SysTickHandler();       	 					
	}
}

