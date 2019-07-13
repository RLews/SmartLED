/*
************************************************************************************************************************
* file : E:\KeilWorkspace\M3\uCOS_III_mdk5\HardwareDriverLayer\inc\drv_timer.h
* Description : 
* Owner : Lews Hammond
* Time : 2019-6-4
************************************************************************************************************************
*/


#ifndef __DRV_TIMER_H
#define __DRV_TIMER_H



#include "drv_public.h"

typedef enum _TIMER_PWM_CH_T
{
	EN_TIMER_PWM_CH1 = 0,
	EN_TIMER_PWM_CH2,
	EN_TIMER_PWM_CH3,
	EN_TIMER_PWM_CH4,
	EN_TIMER_PWM_ALL
}timerPwmCh_t;

typedef struct _TIMER_CONFIG_T
{
	timerName_t timerName;
	TIM_TypeDef * timerReg;
	timerPwmCh_t timerPwmCh;
	uint32_t timerClock;
	uint16_t timerPreiod;//PWM = 72000/(1023+1)=70Khz
	uint16_t timerPerscaler;
	uint16_t timerClockDiv;
	uint16_t timerCntMode;
	uint16_t timerOcMode;
	uint16_t timerOutSta;
	uint16_t timerOcPolarity;
}pwmConfig_t;


#define D_TIMER_CONFIG_TABLE \
{EN_TEST_PWM, TIM3, EN_TIMER_PWM_CH3, RCC_APB1Periph_TIM3, D_DRV_PWM_LEVEL_MAX, 0, 0, \
TIM_CounterMode_Up, TIM_OCMode_PWM2, TIM_OutputState_Enable, TIM_OCPolarity_Low}, \
{EN_WARM_PWM, TIM2, EN_TIMER_PWM_CH1, RCC_APB1Periph_TIM2, D_DRV_PWM_LEVEL_MAX, 0, 0, \
TIM_CounterMode_Up, TIM_OCMode_PWM2, TIM_OutputState_Enable, TIM_OCPolarity_Low}, \
{EN_RED_PWM, TIM2, EN_TIMER_PWM_CH2, RCC_APB1Periph_TIM2, D_DRV_PWM_LEVEL_MAX, 0, 0, \
TIM_CounterMode_Up, TIM_OCMode_PWM2, TIM_OutputState_Enable, TIM_OCPolarity_Low}, \
{EN_GREEN_PWM, TIM3, EN_TIMER_PWM_CH1, RCC_APB1Periph_TIM3, D_DRV_PWM_LEVEL_MAX, 0, 0, \
TIM_CounterMode_Up, TIM_OCMode_PWM2, TIM_OutputState_Enable, TIM_OCPolarity_Low}, \
{EN_BLUE_PWM, TIM3, EN_TIMER_PWM_CH2, RCC_APB1Periph_TIM3, D_DRV_PWM_LEVEL_MAX, 0, 0, \
TIM_CounterMode_Up, TIM_OCMode_PWM2, TIM_OutputState_Enable, TIM_OCPolarity_Low}




#endif

