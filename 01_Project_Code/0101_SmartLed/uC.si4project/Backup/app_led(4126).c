/*
************************************************************************************************************************
* file : E:\KeilWorkspace\M3\uCOS_III_mdk5\ApplicationLayer\src\app_led.c
* Description : 
* Owner : Lews Hammond
* Time : 2019-6-4
************************************************************************************************************************
*/


#include "app_led.h"

#if (D_UC_OS_III_ENABLE == D_SYS_STD_ON)
/* System Run Led Task */
#define D_SYSTEM_RUN_FLAG_TASK_PRIO			6
#define D_SYSTEM_RUN_FLAG_TASK_STACK_SIZE	128
#define D_SYSTEM_RUN_FLAG_TASK_MAX_MSG_NUM	0
#define D_SYSTEM_RUN_FLAG_TICK				0
#define D_SYSTEM_RUN_FLAG_OPT				(D_OSAL_OPT_TASK_STK_CHK | D_OSAL_OPT_TASK_STK_CLR)

static OSAL_TCB runFlagTaskTCB = {0};
static OSAL_CPU_STACK	runFlagTaskStack[D_SYSTEM_RUN_FLAG_TASK_STACK_SIZE] = {0};


static void Sys_LedFlash(void);
#endif

/*
************************************************************************************************************************
* Function Name    : Sys_LedInit
* Description      : System led flash init
* Input Arguments  : void
* Output Arguments : void
* Returns          : void
* Notes            : 
* Owner            : Lews
* Time             : 2019-6-4
************************************************************************************************************************
*/

void Sys_LedInit(void)
{
#if (D_UC_OS_III_ENABLE == D_SYS_STD_ON)
	OSAL_ERROR tErr = (OSAL_ERROR)0;
	D_OSAL_ALLOC_CRITICAL_SR();

	D_OSAL_ENTER_CRITICAL();
	D_OSAL_CREATE_TASK_FUNC((OSAL_TCB *)&runFlagTaskTCB,
							(OSAL_CHAR *)"Run_Led",
							(OSAL_TASK_FUNC_PTR)Sys_LedFlash,
							(void *) 0,
							(OSAL_PRIO)D_SYSTEM_RUN_FLAG_TASK_PRIO,
							(OSAL_CPU_STACK *)&runFlagTaskStack[0],
							(OSAL_CPU_STK_SIZE)(D_SYSTEM_RUN_FLAG_TASK_STACK_SIZE / 10),
							(OSAL_CPU_STK_SIZE)D_SYSTEM_RUN_FLAG_TASK_STACK_SIZE,
							(OSAL_MSG_QTY)D_SYSTEM_RUN_FLAG_TASK_MAX_MSG_NUM,
							(OSAL_TICK)D_SYSTEM_RUN_FLAG_TICK,
							(void *)0,
							(OSAL_OPT)D_SYSTEM_RUN_FLAG_OPT,
							(OSAL_ERROR *)&tErr
	);
	D_OSAL_EXIT_CRITICAL();
#endif
}

#if (D_UC_OS_III_ENABLE == D_SYS_STD_ON)
/*
************************************************************************************************************************
*                                               System Running Led Flash Task
*
* Description : Control Led Flash.
*
* Arguments   : void
*
* Returns     : void
************************************************************************************************************************
*/
static void Sys_LedFlash(void)
{
#if (D_SYS_LED_STACK_DEBUG == D_SYS_STD_ON)
	OSAL_CPU_STK_SIZE free = 0;
	OSAL_CPU_STK_SIZE used = 0;
#endif
	while (1)
	{
		Hal_RunLedOn();
		Osal_DelayMs(D_SYS_LED_FLASH_TIME);
		Hal_RunLedOff();
		Osal_DelayMs(D_SYS_LED_FLASH_TIME);
	#if (D_SYS_LED_STACK_DEBUG == D_SYS_STD_ON)
		(void)Osal_TaskStkChk(&runFlagTaskTCB, &free, &used);
	#endif
	}
}

#else

/*
************************************************************************************************************************
* Function Name    : Sys_LedFlash
* Description      : 
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-24
************************************************************************************************************************
*/

void Sys_LedFlash(void)
{
	static uint32_t Ts = 0;
	static uint8_t runFlag = D_SYS_STD_OFF;

	if (Osal_DiffTsToUsec(Ts) >= (500*D_SYS_MS_COUNT))
	{
		Ts = Osal_GetCurTs();
		if (runFlag == D_SYS_STD_OFF)
		{
			runFlag = D_SYS_STD_ON;
			Hal_RunLedOn();
		}
		else
		{
			runFlag = D_SYS_STD_OFF;
			Hal_RunLedOff();
		}
	}
}
#endif

