/*
************************************************************************************************************************
* file : E:\KeilWorkspace\M3\uCOS_III_mdk5\ApplicationLayer\src\app_comm.c
* Description : 
* Owner : Lews Hammond
* Time : 2019-6-4
************************************************************************************************************************
*/


#include "app_comm.h"

#if (D_SYS_COMM_ENABLE == D_SYS_STD_ON)

/* comm task */
#define D_COMM_TASK_PRIO					3
#define D_COMM_TASK_STACK_SIZE				512
#define D_COMM_TASK_MAX_MSG_NUM				0
#define D_COMM_TASK_TICK					0
#define D_COMM_TASK_OPT						(D_OSAL_OPT_TASK_STK_CHK | D_OSAL_OPT_TASK_STK_CLR)

static OSAL_TCB commTaskTCB = {0};
static OSAL_CPU_STACK commTaskStack[D_COMM_TASK_STACK_SIZE] = {0};

#define D_COMM_TIMER_TICK					2//10ms

static OSAL_TMR comm10MsTmr;


static void SysCommHandle(void);

static void Sys10MsCallBack(void);


/*
************************************************************************************************************************
* Function Name    : SysCommInit
* Description      : Communication init
* Input Arguments  : void
* Output Arguments : void
* Returns          : void
* Notes            : 
* Owner            : Lews
* Time             : 2019-6-4
************************************************************************************************************************
*/

void SysCommInit(void)
{
	
	OSAL_ERROR tErr = (OSAL_ERROR)0;
	D_OSAL_ALLOC_CRITICAL_SR();

	(void)Osal_TmrCreate(&comm10MsTmr, "Comm_Tmr", D_COMM_TIMER_TICK, D_OSAL_OPT_TMR_PERIODIC, (OSAL_TMR_CALLBACK_PTR)Sys10MsCallBack);

	D_OSAL_ENTER_CRITICAL();
	D_OSAL_CREATE_TASK_FUNC((OSAL_TCB *)&commTaskTCB,
							(OSAL_CHAR *)"Comm_Task",
							(OSAL_TASK_FUNC_PTR)SysCommHandle,
							(void *)0,
							(OSAL_PRIO)D_COMM_TASK_PRIO,
							(OSAL_CPU_STACK *)&commTaskStack[0],
							(OSAL_CPU_STK_SIZE)(D_COMM_TASK_STACK_SIZE / 10),
							(OSAL_CPU_STK_SIZE)D_COMM_TASK_STACK_SIZE,
							(OSAL_MSG_QTY)D_COMM_TASK_MAX_MSG_NUM,
							(OSAL_TICK)D_COMM_TASK_TICK,
							(void *)0,
							(OSAL_OPT)D_COMM_TASK_OPT,
							(OSAL_ERROR *)&tErr
	);
	D_OSAL_EXIT_CRITICAL();
}

/*
************************************************************************************************************************
* Function Name    : SysCommHandle
* Description      : communication handle
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-16
************************************************************************************************************************
*/

static void SysCommHandle(void)
{
#if (D_COMM_TASK_STACK_DEBUG == D_SYS_STD_ON)
	OSAL_CPU_STK_SIZE free = 0;
	OSAL_CPU_STK_SIZE used = 0;
#endif
	Osal_TmrStart(&comm10MsTmr);
	while (1)
	{
	#if (D_SRV_COMM_ENABLE == D_SYS_STD_ON)
	    Srv_SysCommDecrypt();
	#else
		Osal_DelayMs(100);
	#endif
	#if (D_COMM_TASK_STACK_DEBUG == D_SYS_STD_ON)
		(void)Osal_TaskStkChk(&commTaskTCB, &free, &used);
	#endif
	}
}

/*
************************************************************************************************************************
* Function Name    : Sys10MsCallBack
* Description      : 10 ms period callback function
* Input Arguments  : void
* Output Arguments : void
* Returns          : void
* Notes            : 
* Owner            : Lews
* Time             : 2019-6-4
************************************************************************************************************************
*/

static void Sys10MsCallBack(void)
{	
	#if (D_SYS_WDG_ENABLE == D_SYS_STD_ON)
		D_HAL_WDG_FEED();
	#endif

	#if (D_SRV_UDS_ENABLE == D_SYS_STD_ON)
		TICK_UDSTP_SESSION1_TIMER();
	    TICK_UDS_SESSION_TIMER();
	    TICK_UDS_APP_TIMER();
	    /*the most of Uds Cyclic handling is put in 10ms task slot*/
		Uds_MainTaskEntryPoint_CyclicTask(); 
		Uds_Processor();
	#endif
}

#endif

