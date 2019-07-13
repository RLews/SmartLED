/*
************************************************************************************************************************
* file : app_led_ctrl.c
* Description : 
* Author : Lews Hammond
* Time : 2019-7-11
************************************************************************************************************************
*/

#include "app_led_ctrl.h"


static volatile ledData_t ledData = {0};
static volatile ledData_t setLedDat = {0};

static ledMode_t ledMode = EN_LED_SLEEP;
static ledMode_t ledModeBak = EN_LED_SLEEP;
static uint16_t ledDutyBak = 0;

static void Led_CtrlHandle(void);
static void Led_Mode0(void);
static void Led_Mode1(void);
static void Led_Mode2Handle(void);

static void Led_Gradient(void);
static void Led_GradientAlgor(void);


/*
************************************************************************************************************************
* Function Name    : Led_CtrlInit
* Description      : 
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-7-11
************************************************************************************************************************
*/

void Led_CtrlInit(void)
{
	Hal_SysISRSet(EN_SYS_TICK_ISR, Led_CtrlHandle);
	Hal_SysTickInit(D_LED_GRADIENT_DEFAULT_FREQ);
	ledDutyBak = D_LED_GRADIENT_DEFAULT_FREQ;
}

/*
************************************************************************************************************************
* Function Name    : Led_GradientAlgor
* Description      : 
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-7-12
************************************************************************************************************************
*/

static void Led_GradientAlgor(void)
{
	volatile ledData_t *pSetDat = &setLedDat;
	volatile ledData_t *pData = &ledData;
	uint16_t calcDuty = 0xFFFFu;
	uint32_t calcTmp = 0;

	if (pSetDat->warmLedDuty != 0)
	{
		/* duty = 0.001x^2 + 200 */
		calcTmp = (uint32_t)(pData->warmLedDuty * pData->warmLedDuty);
		calcTmp = calcTmp / 1000;
		calcTmp += 200;
		calcDuty = (uint16_t)calcTmp;
	}
	else
	{
		calcDuty = D_LED_GRADIENT_DEFAULT_FREQ;
	}

	/* update gradient frequence */
	if (calcDuty != ledDutyBak)
	{
		ledDutyBak = calcDuty;
		Hal_SysTickInit(calcDuty);
	}
}

/*
************************************************************************************************************************
* Function Name    : Led_PeriodProc
* Description      : 
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-7-13
************************************************************************************************************************
*/

void Led_PeriodProc(void)
{
	Led_Mode2Handle();
	Led_GradientAlgor();
}

/*
************************************************************************************************************************
* Function Name    : 
* Description      : 
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-7-11
************************************************************************************************************************
*/

void Led_ModeCycling(void)
{
	ledMode++;
	if (ledMode >= EN_LED_WIFI_MODE)
	{
		ledMode = EN_LED_SLEEP;
	}

	switch (ledMode)
	{
		case EN_LED_SLEEP:
			Led_AllOff();
			break;

		case EN_LED_MODE0:
			Led_Mode0();
			break;

		case EN_LED_MODE1:
			Led_Mode1();
			break;

		default:
			break;
	}
}

/*
************************************************************************************************************************
* Function Name    : Led_Mode0
* Description      : 
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-7-11
************************************************************************************************************************
*/

static void Led_Mode0(void)
{
	volatile ledData_t *pSetDat = &setLedDat;

	pSetDat->blueLedDuty = 0;
	pSetDat->greenLedDuty = 0;
	pSetDat->redLedDuty = 0;
	pSetDat->warmLedDuty = D_LED_BRIGHTNESS_MAX / 5;
}

/*
************************************************************************************************************************
* Function Name    : Led_Mode1
* Description      : 
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-7-11
************************************************************************************************************************
*/

static void Led_Mode1(void)
{
	volatile ledData_t *pSetDat = &setLedDat;

	pSetDat->blueLedDuty = 0;
	pSetDat->greenLedDuty = 0;
	pSetDat->redLedDuty = 0;
	pSetDat->warmLedDuty = D_LED_BRIGHTNESS_MAX;
}

/*
************************************************************************************************************************
* Function Name    : Led_SetWarmDat
* Description      : 
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-7-11
************************************************************************************************************************
*/

void Led_SetWarmDat(uint16_t duty)
{
	volatile ledData_t *pData = &setLedDat;

	if (duty < D_LED_MIN_BRIGHTNESS)
	{
		duty = D_LED_MIN_BRIGHTNESS;
	}

	//D_OSAL_ENTER_CRITICAL();
	pData->blueLedDuty = 0;
	pData->greenLedDuty = 0;
	pData->redLedDuty = 0;
	pData->warmLedDuty = duty;
	//D_OSAL_EXIT_CRITICAL();
}

/*
************************************************************************************************************************
* Function Name    : Led_SetRGBDat
* Description      : 
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-7-11
************************************************************************************************************************
*/

void Led_SetRGBDat(uint16_t rDuty, uint16_t gDuty, uint16_t bDuty)
{
	volatile ledData_t *pData = &setLedDat;

	if ((bDuty == 0) && (gDuty == 0) && (rDuty == 0))
	{
		rDuty = D_LED_MIN_BRIGHTNESS;
		gDuty = D_LED_MIN_BRIGHTNESS;
		bDuty = D_LED_MIN_BRIGHTNESS;
	}
	
	//D_OSAL_ENTER_CRITICAL();
	pData->blueLedDuty = bDuty;
	pData->greenLedDuty = gDuty;
	pData->redLedDuty = rDuty;
	pData->warmLedDuty = 0;
	//D_OSAL_EXIT_CRITICAL();
}

/*
************************************************************************************************************************
* Function Name    : Led_WarmOff
* Description      : 
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-7-11
************************************************************************************************************************
*/

void Led_WarmOff(void)
{
	setLedDat.warmLedDuty = 0;
}

/*
************************************************************************************************************************
* Function Name    : Led_AllOff
* Description      : 
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-7-11
************************************************************************************************************************
*/

void Led_AllOff(void)
{
	volatile ledData_t *pSetDat = &setLedDat;

	pSetDat->blueLedDuty = 0;
	pSetDat->greenLedDuty = 0;
	pSetDat->redLedDuty = 0;
	pSetDat->warmLedDuty = 0;
	ledMode = EN_LED_SLEEP;
}

/*
************************************************************************************************************************
* Function Name    : Led_Gradient
* Description      : 
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-7-11
************************************************************************************************************************
*/

static void Led_Gradient(void)
{
	volatile ledData_t *pSetData = &setLedDat;
	volatile ledData_t *pData = &ledData;
	
	if (pData->warmLedDuty > pSetData->warmLedDuty)
	{
		pData->warmLedDuty--;
		D_HAL_SET_WARM_LED(pData->warmLedDuty);
	}
	else if (pData->warmLedDuty < pSetData->warmLedDuty)
	{
		pData->warmLedDuty++;
		D_HAL_SET_WARM_LED(pData->warmLedDuty);
	}
	else
	{

	}

	if (pData->redLedDuty > pSetData->redLedDuty)
	{
		pData->redLedDuty--;
		D_HAL_SET_RED_LED(pData->redLedDuty);
	}
	else if (pData->redLedDuty < pSetData->redLedDuty)
	{
		pData->redLedDuty++;
		D_HAL_SET_RED_LED(pData->redLedDuty);
	}
	else
	{

	}

	if (pData->greenLedDuty > pSetData->greenLedDuty)
	{
		pData->greenLedDuty--;
		D_HAL_SET_GREEN_LED(pData->greenLedDuty);
	}
	else if (pData->greenLedDuty < pSetData->greenLedDuty)
	{
		pData->greenLedDuty++;
		D_HAL_SET_GREEN_LED(pData->greenLedDuty);
	}
	else
	{

	}

	if (pData->blueLedDuty > pSetData->blueLedDuty)
	{
		pData->blueLedDuty--;
		D_HAL_SET_BLUE_LED(pData->blueLedDuty);
	}
	else if (pData->blueLedDuty < pSetData->blueLedDuty)
	{
		pData->blueLedDuty++;
		D_HAL_SET_BLUE_LED(pData->blueLedDuty);
	}
	else
	{

	}

}


/*
************************************************************************************************************************
* Function Name    : Led_CtrlHandle
* Description      : interrupt control gradient algorithm
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-7-11
************************************************************************************************************************
*/

static void Led_CtrlHandle(void)
{
	if (ledMode != EN_LED_WIFI_MODE)
	{
		Led_Gradient();
	}
}

/*
************************************************************************************************************************
* Function Name    : Led_Mode2Handle
* Description      : 
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-7-11
************************************************************************************************************************
*/

static void Led_Mode2Handle(void)
{
	volatile ledData_t *pSetData = &setLedDat;
	volatile ledData_t *pData = &ledData;
	

	if (ledMode == EN_LED_MODE2)
	{
		if (pData->warmLedDuty == pSetData->warmLedDuty)
		{
			pSetData->warmLedDuty = (pSetData->warmLedDuty == D_LED_BRIGHTNESS_MAX) ? (0) : (D_LED_BRIGHTNESS_MAX);
		}
	}
}

/*
************************************************************************************************************************
* Function Name    : Led_EnterWifiSet
* Description      : 
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-7-13
************************************************************************************************************************
*/

void Led_EnterWifiSet(void)
{
	D_OSAL_ENTER_CRITICAL();
	ledModeBak = ledMode;
	ledMode = EN_LED_WIFI_MODE;
	D_HAL_SET_WARM_LED(0);
	D_HAL_SET_RED_LED(0);
	D_HAL_SET_GREEN_LED(0);
	D_HAL_SET_BLUE_LED(0);
	D_OSAL_EXIT_CRITICAL();
}

/*
************************************************************************************************************************
* Function Name    : Led_ExitWifiSet
* Description      : 
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-7-13
************************************************************************************************************************
*/

void Led_ExitWifiSet(void)
{
	volatile ledData_t *pData = &ledData;
	
	D_OSAL_ENTER_CRITICAL();
	ledMode = ledModeBak;
	D_HAL_SET_WARM_LED(0);
	D_HAL_SET_RED_LED(0);
	D_HAL_SET_GREEN_LED(0);
	D_HAL_SET_BLUE_LED(0);
	pData->warmLedDuty = 0;
	pData->redLedDuty = 0;
	pData->greenLedDuty = 0;
	pData->blueLedDuty = 0;
	D_OSAL_EXIT_CRITICAL();
}

/*
************************************************************************************************************************
* Function Name    : Led_SetFlash
* Description      : control warm led flash
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-7-13
************************************************************************************************************************
*/

void Led_SetFlash(void)
{
	static stdBoolean_t ledFlag = EN_STD_TRUE;

	if (ledFlag == EN_STD_TRUE)
	{
		D_HAL_SET_WARM_LED(D_LED_BRIGHTNESS_MAX / 2);
		ledFlag = EN_STD_FALSE;
	}
	else
	{
		D_HAL_SET_WARM_LED(0);
		ledFlag = EN_STD_TRUE;
	}
}

