/*
************************************************************************************************************************
* file : E:\KeilWorkspace\M3\uCOS_III_mdk5\HardwareDriverLayer\src\drv_timer.c
* Description : 
* Owner : Lews Hammond
* Time : 2019-6-4
************************************************************************************************************************
*/


#include "drv_timer.h"


static const pwmConfig_t timerConfig[EN_TIMER_ALL_TYPE] = {D_TIMER_CONFIG_TABLE};


/*
************************************************************************************************************************
* Function Name    : Drv_PwmInit
* Description      : 
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-7-10
************************************************************************************************************************
*/

void Drv_PwmInit(void)
{
	uint8_t i = 0;
	TIM_TimeBaseInitTypeDef TIM_TimeBaseStructure = {0};
	TIM_OCInitTypeDef TIM_OCInitStructure = {0};
	const pwmConfig_t *pConfig = timerConfig;

	for (i = 0; i < (uint8_t)EN_TIMER_ALL_TYPE; i++)
	{
		RCC_APB1PeriphClockCmd(pConfig[i].timerClock, ENABLE);
		TIM_TimeBaseStructure.TIM_Period = pConfig[i].timerPreiod;
		TIM_TimeBaseStructure.TIM_Prescaler = pConfig[i].timerPerscaler;
		TIM_TimeBaseStructure.TIM_ClockDivision = pConfig[i].timerClockDiv;
		TIM_TimeBaseStructure.TIM_CounterMode = pConfig[i].timerCntMode;
		TIM_TimeBaseInit(pConfig[i].timerReg, &TIM_TimeBaseStructure);
		TIM_OCInitStructure.TIM_OCMode = pConfig[i].timerOcMode;
		TIM_OCInitStructure.TIM_OutputState = pConfig[i].timerOutSta;
		TIM_OCInitStructure.TIM_OCPolarity = pConfig[i].timerOcPolarity;
		switch (pConfig[i].timerPwmCh)
		{
			case EN_TIMER_PWM_CH1:
				TIM_OC1Init(pConfig[i].timerReg, &TIM_OCInitStructure);
				TIM_OC1PreloadConfig(pConfig[i].timerReg, TIM_OCPreload_Enable);
				break;
			case EN_TIMER_PWM_CH2:
				TIM_OC2Init(pConfig[i].timerReg, &TIM_OCInitStructure);
				TIM_OC2PreloadConfig(pConfig[i].timerReg, TIM_OCPreload_Enable);
				break;
			case EN_TIMER_PWM_CH3:
				TIM_OC3Init(pConfig[i].timerReg, &TIM_OCInitStructure);
				TIM_OC3PreloadConfig(pConfig[i].timerReg, TIM_OCPreload_Enable);
				break;
			case EN_TIMER_PWM_CH4:
				TIM_OC4Init(pConfig[i].timerReg, &TIM_OCInitStructure);
				TIM_OC4PreloadConfig(pConfig[i].timerReg, TIM_OCPreload_Enable);
				break;
			default:
				break;
		}
		
		TIM_Cmd(pConfig[i].timerReg, ENABLE);
	}
}

/*
************************************************************************************************************************
* Function Name    : Drv_PwmSetDuty
* Description      : 
* Input Arguments  : uint16_t duty
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-7-10
************************************************************************************************************************
*/

void Drv_PwmSetDuty(timerName_t name, uint16_t duty)
{
	const pwmConfig_t *pConfig = timerConfig;
	
	if (name >= EN_TIMER_ALL_TYPE)
	{
		return ;
	}
	
	switch (pConfig[(uint8_t)name].timerPwmCh)
	{
		case EN_TIMER_PWM_CH1:
			TIM_SetCompare1(pConfig[(uint8_t)name].timerReg, duty);
			break;
		case EN_TIMER_PWM_CH2:
			TIM_SetCompare2(pConfig[(uint8_t)name].timerReg, duty);
			break;
		case EN_TIMER_PWM_CH3:
			TIM_SetCompare3(pConfig[(uint8_t)name].timerReg, duty);
			break;
		case EN_TIMER_PWM_CH4:
			TIM_SetCompare4(pConfig[(uint8_t)name].timerReg, duty);
			break;
		default:
			break;
	}
	
}

/*
************************************************************************************************************************
*                                               SysTick interrupt enable
*
* Description : SysTick interrupt enable.
*
* Arguments   : void
*
* Returns     : void
************************************************************************************************************************
*/
void Drv_SysTickIntEnable(void)
{
	SysTick->CTRL |= SysTick_CTRL_TICKINT_Msk;   	//¿ªÆôSYSTICKÖÐ¶Ï
}

/*
************************************************************************************************************************
*                                               SysTick interrupt disable
*
* Description : SysTick interrupt disable.
*
* Arguments   : void
*
* Returns     : void
************************************************************************************************************************
*/
void Drv_SysTickIntDisable(void)
{
	SysTick->CTRL &= (uint32_t)(~SysTick_CTRL_TICKINT_Msk);
}

/*
************************************************************************************************************************
*                                               SysTick Start
*
* Description : SysTick start.
*
* Arguments   : void
*
* Returns     : void
************************************************************************************************************************
*/
void Drv_SysTickOpen(void)
{
	SysTick->CTRL |= SysTick_CTRL_ENABLE_Msk;   	//¿ªÆôSYSTICK  
}

/*
************************************************************************************************************************
*                                               SysTick stop
*
* Description : SysTick stop.
*
* Arguments   : void
*
* Returns     : void
************************************************************************************************************************
*/
void Drv_SysTickClose(void)
{
	SysTick->CTRL &= (uint32_t)(~SysTick_CTRL_ENABLE_Msk);
}

/*
************************************************************************************************************************
*                                               SysTick counter update
*
* Description : Update SysTick Counter number.
*
* Arguments   : void
*
* Returns     : void
************************************************************************************************************************
*/
void Drv_SysTickSetReload(uint32_t val)
{
	SysTick->LOAD = val;
}

