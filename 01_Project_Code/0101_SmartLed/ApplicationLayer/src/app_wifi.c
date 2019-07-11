/*
************************************************************************************************************************
* file : app_wifi.c
* Description : 
* Author : Lews Hammond
* Time : 2019-6-17
************************************************************************************************************************
*/

#include "app_wifi.h"

#if (D_UC_OS_III_ENABLE == D_STD_ON)

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

static void Wifi_TaskHandle(void);

#endif
static wifiSetInfo_t wifiSetInfo = {0};

static void Wifi_TmrCallBack(void);
static void Wifi_ShockHandle(void);
static void Wifi_KeyHandle(void);
static void Wifi_LedCtrl(void);
static void Wifi_UpdateTime(void);
static void Wifi_DataHandle(void);
static void Wifi_WorkManage(void);
static stdBoolean_t Wifi_LedSetFlash(uint16_t freq, uint16_t flashTimes);


/*
************************************************************************************************************************
* Function Name    : Wifi_TaskInit
* Description      : wifi task initial
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-17
************************************************************************************************************************
*/

void Wifi_TaskInit(void)
{
#if (D_UC_OS_III_ENABLE == D_STD_ON)
	OSAL_ERROR tErr = (OSAL_ERROR)0;
#endif
	D_OSAL_ALLOC_CRITICAL_SR();
	
#if (D_WIFI_UART_DEBUG == D_STD_ON)
	printf("\n------ Wifi Uart Debug Starting ------");
	printf("\n--------------------------------------\n");
#endif

	Srv_WifiCommInit();
	gizwitsInit();
	userInit();
	
#if (D_UC_OS_III_ENABLE == D_STD_ON)
	(void)Osal_TmrCreate(&wifiTmr, "Wifi_Tmr", D_WIFI_TIMER_TICK, D_OSAL_OPT_TMR_PERIODIC, (OSAL_TMR_CALLBACK_PTR)Wifi_TmrCallBack);

	D_OSAL_ENTER_CRITICAL();
	D_OSAL_CREATE_TASK_FUNC((OSAL_TCB *)&wifiTaskTCB,
							(OSAL_CHAR *)"WIFI_Task",
							(OSAL_TASK_FUNC_PTR)Wifi_TaskHandle,
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

#if (D_UC_OS_III_ENABLE == D_STD_ON)

/*
************************************************************************************************************************
* Function Name    : Wifi_TaskHandle
* Description      : wifi task handle
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-17
************************************************************************************************************************
*/

static void Wifi_TaskHandle(void)
{
	uint8_t revDat = 0;

	while (1)
	{
		Srv_WifiCommWaitRev();
		(void)Hal_UartReadByte(EN_WIFI_COM, &revDat);
		(void)gizPutData(&revDat, 1);
	}
}

#else
/*
************************************************************************************************************************
* Function Name    : Wifi_TaskHandle
* Description      : 
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-24
************************************************************************************************************************
*/

void Wifi_TaskHandle(void)
{
	static uint32_t Ts = 0;
	uint8_t revDat = 0;

	if (EN_QUEUE_OPT_OK == Hal_UartReadByte(EN_WIFI_COM, &revDat))
	{
		(void)gizPutData(&revDat, 1);
	}

	if (Osal_DiffTsToUsec(Ts) >= (5*D_SYS_MS_COUNT))
	{
		Ts = Osal_GetCurTs();
		Wifi_TmrCallBack();
	}
}

#endif

/*
************************************************************************************************************************
* Function Name    : Wifi_UpdateTime
* Description      : request netework time
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-19
************************************************************************************************************************
*/

static void Wifi_UpdateTime(void)
{
	static uint32_t reqNtpTim = 0;
	
	if (Wifi_GetConnectSta() == D_STD_ON)
	{
		if (Osal_DiffTsToUsec(reqNtpTim) >= D_WIFI_REQUEST_TIME)
		{
			reqNtpTim = Osal_GetCurTs();
			gizwitsGetNTP();
		}
	}
}

/*
************************************************************************************************************************
* Function Name    : Wifi_DataHandle
* Description      : user data handle
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-19
************************************************************************************************************************
*/

static void Wifi_DataHandle(void)
{
	static uint32_t updateTim = 0;

	if (Osal_DiffTsToUsec(updateTim) >= D_WIFI_UPDATE_PERIOD)
	{
		updateTim = Osal_GetCurTs();
		gizwitsHandle((dataPoint_t *)&currentDataPoint);
	}
}

/*
************************************************************************************************************************
* Function Name    : WifiLedResetFlash
* Description      : 5ms
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-27
************************************************************************************************************************
*/

static stdBoolean_t Wifi_LedSetFlash(uint16_t freq, uint16_t flashTimes)
{
	stdBoolean_t optRes = EN_STD_FALSE;
	static uint16_t tick = 0;
	static uint16_t times = 0;
	wifiSetInfo_t *pSet = &wifiSetInfo;

	tick++;
	if (tick >= (freq / D_WIFI_LED_PERIOD_TICK) )
	{
		tick = 0;
		times++;
		Wifi_LedCtrl();

		if (times >= flashTimes)
		{
			times = 0;
			optRes = EN_STD_TRUE;
			if (pSet->recordLedSta == D_STD_OFF)
			{
				Hal_WifiLedOff();
			}
			else
			{
				Hal_WifiLedOn();
			}
		}
	}

	return optRes;
}

/*
************************************************************************************************************************
* Function Name    : Wifi_WorkManage
* Description      : 
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-27
************************************************************************************************************************
*/

static void Wifi_WorkManage(void)
{
	wifiSetInfo_t *pSet = &wifiSetInfo;

	switch (pSet->setMode)
	{
		case EN_WIFI_MODE_RUN:
			userHandle();
			Wifi_UpdateTime();
			break;
		case EN_WIFI_MODE_AIR_LINK:
		case EN_WIFI_MODE_SOFT_AP:
			if (Wifi_LedSetFlash(500, 6) == EN_STD_TRUE)
			{
				pSet->setMode = EN_WIFI_MODE_RUN;
			}
			break;
		case EN_WIFI_MODE_RESET:
			if (Wifi_LedSetFlash(200, 10) == EN_STD_TRUE)
			{
				pSet->setMode = EN_WIFI_MODE_RUN;
			}
			break;
		default:
			break;
	}
	
	Wifi_DataHandle();
}

/*
************************************************************************************************************************
* Function Name    : Wifi_TmrCallBack
* Description      : period schedule
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-17
************************************************************************************************************************
*/

static void Wifi_TmrCallBack(void)
{
	uint8_t i = 0;

    for (i = 0; i < D_WIFI_TMR_MS; i++)
	{
		gizTimerMs();
	}
	
	Hal_KeyScan();
	Wifi_KeyHandle();
	Wifi_WorkManage();
	Wifi_ShockHandle();
}

/*
************************************************************************************************************************
* Function Name    : Wifi_ShockHandle
* Description      : 
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-7-11
************************************************************************************************************************
*/

static void Wifi_ShockHandle(void)
{
	if (Shk_GetSnsSta() == EN_SHOCK_PRESS)
	{
#if (D_WIFI_UART_DEBUG == D_STD_ON)
		printf("\nShock Press.\n");
#endif
		Shk_ClrSnsSta();
		Led_ModeCycling();
	}
}

/*
************************************************************************************************************************
* Function Name    : Wifi_KeyHandle
* Description      : 
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-18
************************************************************************************************************************
*/

static void Wifi_KeyHandle(void)
{
	wifiSetInfo_t *pSet = &wifiSetInfo;
	if (Hal_CheckNewKey(EN_KEY_WIFI) == EN_STD_TRUE)
	{
		switch (Hal_GetKeySta(EN_KEY_WIFI))
		{
			case EN_KEY_PRESS_UP:
#if (D_WIFI_UART_DEBUG == D_STD_ON)
				printf("\nKey Press.\n");
#endif
				if (pSet->setMode == EN_WIFI_MODE_RUN)
				{
					Wifi_LedCtrl();
				}
				break;
				
			case EN_KEY_REPEAT:
#if (D_WIFI_UART_DEBUG == D_STD_ON)
				printf("\nKey Repeat.\n");
#endif
				gizwitsSetMode(WIFI_AIRLINK_MODE);//Air-link mode
				pSet->setMode = EN_WIFI_MODE_AIR_LINK;
				pSet->recordLedSta = Hal_GetWifiLedSta();
				pSet->setTs = Osal_GetCurTs();
				break;

			case EN_KEY_DOUBLE_PRESS_UP:
#if (D_WIFI_UART_DEBUG == D_STD_ON)
				printf("\nKey Double Click.\n");
#endif
				gizwitsSetMode(WIFI_RESET_MODE);
				pSet->setMode = EN_WIFI_MODE_RESET;
				pSet->recordLedSta = Hal_GetWifiLedSta();
				pSet->setTs = Osal_GetCurTs();
				break;
				
			default:
#if (D_WIFI_UART_DEBUG == D_STD_ON)
				printf("\nKey Action Is Not Support.\n");
#endif
				break;
		}
        Hal_ClearNewKeyFlg(EN_KEY_WIFI);
	}
}


/*
************************************************************************************************************************
* Function Name    : Wifi_LedCtrl
* Description      : wifi led control
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-18
************************************************************************************************************************
*/

static void Wifi_LedCtrl(void)
{
	if (Hal_GetWifiLedSta() == D_STD_OFF)
	{
		Hal_WifiLedOn();
	}
	else
	{
		Hal_WifiLedOff();
	}
}


