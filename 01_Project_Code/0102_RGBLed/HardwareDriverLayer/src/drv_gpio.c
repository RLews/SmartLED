/*
************************************************************************************************************************
* file : E:\KeilWorkspace\M3\uCOS_III_mdk5\HardwareDriverLayer\src\drv_gpio.c
* Description : 
* Owner : Lews Hammond
* Time : 2019-6-4
************************************************************************************************************************
*/


#include "drv_gpio.h"

static const gpioConfig_t gpioConfigArry[EN_ALL_GPIO_NUM] = {
	D_USED_GPIO_CONFIG
};

static stdBoolean_t gpioInitFinish = EN_STD_FALSE;

/*
************************************************************************************************************************
*                                               All Gpio Initial
*
* Description : initial all gpio status.
*
* Arguments   : void
*
* Returns     : void
************************************************************************************************************************
*/
void Drv_GpioInit(void)
{
	GPIO_InitTypeDef GPIO_InitStructure = {0};
	uint8_t i = 0;
	const gpioConfig_t *pIOConfig = gpioConfigArry;

	for (i = 0; i < (uint8_t)EN_ALL_GPIO_NUM; i++)
	{
		RCC_APB2PeriphClockCmd((pIOConfig[i].gpioPeriphClock | pIOConfig[i].gpioMult), ENABLE);
		GPIO_InitStructure.GPIO_Pin = pIOConfig[i].gpioPin;
		GPIO_InitStructure.GPIO_Mode = pIOConfig[i].gpioMode;
		GPIO_InitStructure.GPIO_Speed = pIOConfig[i].gpioSpd;
		GPIO_Init(pIOConfig[i].gpioGruop, &GPIO_InitStructure);
		if (pIOConfig[i].initIOSta == EN_GPIO_HIGH)
		{
			GPIO_SetBits(pIOConfig[i].gpioGruop, pIOConfig[i].gpioPin);
		}
		else if (pIOConfig[i].initIOSta == EN_GPIO_LOW)
		{
			GPIO_ResetBits(pIOConfig[i].gpioGruop, pIOConfig[i].gpioPin);
		}
		else
		{/* do nothing */}
	}

	gpioInitFinish = EN_STD_TRUE;
}


/*
************************************************************************************************************************
* Function Name    : Drv_GetGpioInitSta
* Description      : get gpio initial status
* Input Arguments  : void
* Output Arguments : void
* Returns          : stdBoolean_t : gpio initial status
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-10
************************************************************************************************************************
*/

stdBoolean_t Drv_GetGpioInitSta(void)
{
	return gpioInitFinish;
}


/*
************************************************************************************************************************
*                                               control gpio output
*
* Description : control gpio output high or low.
*
* Arguments   : void
*
* Returns     : void
************************************************************************************************************************
*/
void Drv_GpioNameOut(gpioName_t name, gpioState_t sta)
{
	const gpioConfig_t *pIOConfig = gpioConfigArry;
	
	if (pIOConfig[name].initIOSta == EN_GPIO_INPUT)
	{
		return ;/* exception */
	}

	if (sta == EN_GPIO_HIGH)
	{
		GPIO_SetBits(pIOConfig[name].gpioGruop, pIOConfig[name].gpioPin);
	}
	else if (sta == EN_GPIO_LOW)
	{
		GPIO_ResetBits(pIOConfig[name].gpioGruop, pIOConfig[name].gpioPin);
	}
	else
	{
		
	}
}

/*
************************************************************************************************************************
*                                               Get gpio status
*
* Description : read gpio status (high or low).
*
* Arguments   : void
*
* Returns     : void
************************************************************************************************************************
*/
gpioState_t Drv_GpioNameIn(gpioName_t name)
{
	const gpioConfig_t *pIOConfig = gpioConfigArry;
	gpioState_t sta = EN_GPIO_LOW;

	if (pIOConfig[name].initIOSta != EN_GPIO_INPUT)
	{
		return EN_GPIO_ERR;/* exception */
	}

	sta = (gpioState_t)GPIO_ReadInputDataBit(pIOConfig[name].gpioGruop, pIOConfig[name].gpioPin);

	return sta;
}

