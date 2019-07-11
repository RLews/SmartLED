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
	uint16_t timerPreiod;
	uint16_t timerPerscaler;
	uint16_t timerClockDiv;
	uint16_t timerCntMode;
	uint16_t timerOcMode;
	uint16_t timerOutSta;
	uint16_t timerOcPolarity;
}timerConfig_t;


#define D_TIMER_CONFIG_TABLE \
{EN_TEST_PWM, TIM3, EN_TIMER_PWM_CH3, RCC_APB1Periph_TIM3, 899, 0, 0, TIM_CounterMode_Up, TIM_OCMode_PWM2, TIM_OutputState_Enable, TIM_OCPolarity_Low}



#endif

