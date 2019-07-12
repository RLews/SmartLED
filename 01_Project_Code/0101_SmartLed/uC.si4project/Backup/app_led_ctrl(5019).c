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

static void Led_CtrlHandle(void);
static void Led_Mode0(void);
static void Led_Mode1(void);
static void Led_Mode2Handle(void);

static void Led_Gradient(void);


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
	Hal_SysTickInit(500);
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
	pSetDat->ledSwitch = EN_STD_TRUE;
	pSetDat->redLedDuty = 0;
	pSetDat->warmLedDuty = D_LED_BRIGHTNESS_MAX / 2;
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
	pSetDat->ledSwitch = EN_STD_TRUE;
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

	D_OSAL_ENTER_CRITICAL();
	pData->blueLedDuty = 0;
	pData->greenLedDuty = 0;
	pData->redLedDuty = 0;
	pData->warmLedDuty = duty;
	D_OSAL_EXIT_CRITICAL();
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

	D_OSAL_ENTER_CRITICAL();
	pData->blueLedDuty = bDuty;
	pData->greenLedDuty = gDuty;
	pData->redLedDuty = rDuty;
	pData->warmLedDuty = 0;
	D_OSAL_EXIT_CRITICAL();
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
	pSetDat->ledSwitch = EN_STD_FALSE;
	pSetDat->redLedDuty = 0;
	pSetDat->warmLedDuty = 0;
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
* Description      : 
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
	Led_Gradient();
	Led_Mode2Handle();
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


