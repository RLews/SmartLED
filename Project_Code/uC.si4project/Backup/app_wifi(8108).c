/*
************************************************************************************************************************
* file : app_wifi.c
* Description : 
* Author : Lews Hammond
* Time : 2019-6-17
************************************************************************************************************************
*/

#include "app_wifi.h"

#if (D_UC_OS_III_ENABLE == D_SYS_STD_ON)

/* wifi task */
#define D_WIFI_TASK_PRIO					5
#define D_WIFI_TASK_STACK_SIZE				200
#define D_WIFI_TASK_MAX_MSG_NUM				0
#define D_WIFI_TASK_TICK					0
#define D_WIFI_TASK_OPT						(D_OSAL_OPT_TASK_STK_CHK | D_OSAL_OPT_TASK_STK_CLR)

static OSAL_TCB wifiTaskTCB = {0};
static OSAL_CPU_STACK wifiTaskStack[D_WIFI_TASK_STACK_SIZE] = {0};

#define D_WIFI_TIMER_TICK					1//

static OSAL_TMR wifiTmr;

static void WifiTaskHandle(void);

#endif

static void WifiTmrCallBack(void);
static void WifiKeyHandle(void);
static void WifiLedCtrl(void);
static void WifiUpdateTime(void);
static void WifiDataHandle(void);


/*
************************************************************************************************************************
* Function Name    : WifiTaskInit
* Description      : wifi task initial
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-17
************************************************************************************************************************
*/

void WifiTaskInit(void)
{
#if (D_UC_OS_III_ENABLE == D_SYS_STD_ON)
	OSAL_ERROR tErr = (OSAL_ERROR)0;
#endif
	D_OSAL_ALLOC_CRITICAL_SR();

	Srv_WifiCommInit();
	gizwitsInit();
	userInit();
	
#if (D_UC_OS_III_ENABLE == D_SYS_STD_ON)
	(void)Osal_TmrCreate(&wifiTmr, "Wifi_Tmr", D_WIFI_TIMER_TICK, D_OSAL_OPT_TMR_PERIODIC, (OSAL_TMR_CALLBACK_PTR)WifiTmrCallBack);

	D_OSAL_ENTER_CRITICAL();
	D_OSAL_CREATE_TASK_FUNC((OSAL_TCB *)&wifiTaskTCB,
							(OSAL_CHAR *)"WIFI_Task",
							(OSAL_TASK_FUNC_PTR)WifiTaskHandle,
							(void *)0,
							(OSAL_PRIO)D_WIFI_TASK_PRIO,
							(OSAL_CPU_STACK *)&wifiTaskStack[0],
							(OSAL_CPU_STK_SIZE)(D_WIFI_TASK_STACK_SIZE / 10),
							(OSAL_CPU_STK_SIZE)D_WIFI_TASK_STACK_SIZE,
							(OSAL_MSG_QTY)D_WIFI_TASK_MAX_MSG_NUM,
							(OSAL_TICK)D_WIFI_TASK_TICK,
							(void *)0,
							(OSAL_OPT)D_WIFI_TASK_OPT,
							(OSAL_ERROR *)&tErr
	);
	D_OSAL_EXIT_CRITICAL();
	
	Osal_TmrStart(&wifiTmr);
#endif
}

#if (D_UC_OS_III_ENABLE == D_SYS_STD_ON)

/*
************************************************************************************************************************
* Function Name    : WifiTaskHandle
* Description      : wifi task handle
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-17
************************************************************************************************************************
*/

static void WifiTaskHandle(void)
{
	uint8_t revDat = 0;

	while (1)
	{
		Srv_WifiCommWaitRev();
		(void)Hal_UartReadByte(EN_WIFI_COM, &revDat);
		(void)gizPutData(&revDat, 1);
		
#if (D_WIFI_UART_DEBUG == D_SYS_STD_ON)
		(void)Hal_UartWrite(EN_SYS_COM, (uint8_t *)&revDat, 1);
#endif
	}
}

#else
/*
************************************************************************************************************************
* Function Name    : WifiTaskHandle
* Description      : 
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-24
************************************************************************************************************************
*/

void WifiTaskHandle(void)
{
	static uint32_t Ts = 0;
	uint8_t revDat = 0;

	if (EN_QUEUE_OPT_OK == Hal_UartReadByte(EN_WIFI_COM, &revDat))
	{
		(void)gizPutData(&revDat, 1);
		
#if (D_WIFI_UART_DEBUG == D_SYS_STD_ON)
		(void)Hal_UartWrite(EN_SYS_COM, (uint8_t *)&revDat, 1);
#endif
	}

	if (Osal_DiffTsToUsec(Ts) >= 5000)
	{
		Ts = Osal_GetCurTs();
		WifiTmrCallBack();
	}
}

#endif

/*
************************************************************************************************************************
* Function Name    : WifiUpdateTime
* Description      : request netework time
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-19
************************************************************************************************************************
*/

static void WifiUpdateTime(void)
{
	static uint32_t reqNtpTim = 0;

	if (Osal_DiffTsToUsec(reqNtpTim) >= D_WIFI_REQUEST_TIME)
	{
		reqNtpTim = Osal_GetCurTs();
		if (Wifi_GetConnectSta() == D_SYS_STD_ON)
		{
			gizwitsGetNTP();
		}
	}
}

/*
************************************************************************************************************************
* Function Name    : WifiDataHandle
* Description      : user data handle
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-19
************************************************************************************************************************
*/

static void WifiDataHandle(void)
{
	static uint32_t updateTim = 0;

	if (Osal_DiffTsToUsec(updateTim) >= D_WIFI_UPDATE_PERIOD)
	{
		updateTim = Osal_GetCurTs();
		userHandle();
		gizwitsHandle((dataPoint_t *)&currentDataPoint);
	}
}

/*
************************************************************************************************************************
* Function Name    : WifiTmrCallBack
* Description      : period schedule
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-17
************************************************************************************************************************
*/

static void WifiTmrCallBack(void)
{
	uint8_t i = 0;

    for (i = 0; i < D_WIFI_TMR_MS; i++)
	{
		gizTimerMs();
	}
	
	Hal_KeyScan();
	WifiKeyHandle();
	WifiDataHandle();
	WifiUpdateTime();
}


/*
************************************************************************************************************************
* Function Name    : WifiKeyHandle
* Description      : 
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-18
************************************************************************************************************************
*/

static void WifiKeyHandle(void)
{
	if (Hal_CheckNewKey(EN_KEY_WIFI) == EN_STD_TRUE)
	{
		switch (Hal_GetKeySta(EN_KEY_WIFI))
		{
			case EN_KEY_PRESS_UP:
				WifiLedCtrl();
				break;
				
			case EN_KEY_REPEAT:
				gizwitsSetMode(WIFI_AIRLINK_MODE);//Air-link mode
                Hal_WifiLedOn();
				break;

			case EN_KEY_DOUBLE_PRESS_UP:
				gizwitsSetMode(WIFI_RESET_MODE);
                Hal_WifiLedOff();
				break;
				
			default:
				break;
		}
        Hal_ClearNewKeyFlg(EN_KEY_WIFI);
	}
}

/*
************************************************************************************************************************
* Function Name    : WifiLedCtrl
* Description      : wifi led control
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-18
************************************************************************************************************************
*/

static void WifiLedCtrl(void)
{
	if (Hal_GetWifiLedSta() == D_SYS_STD_OFF)
	{
		Hal_WifiLedOn();
	}
	else
	{
		Hal_WifiLedOff();
	}
}


