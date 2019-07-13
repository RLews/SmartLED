/*
************************************************************************************************************************
* file : drv_adc.h
* Description : 
* Author : Lews Hammond
* Time : 2019-7-11
************************************************************************************************************************
*/

#ifndef _DRV_ADC_H
#define _DRV_ADC_H

#include "drv_public.h"


typedef struct _ADC_CONFIG_T
{
	adcSignalName_t adcSignalName;
	ADC_TypeDef * adcReg;
	uint8_t adcCh;
	uint32_t adcClkDiv;
	uint32_t adcMode;
	uint8_t adcScanConvMode;
	uint8_t adcContConvMode;
	uint32_t adcExtTrigConv;
	uint32_t adcDatAlign;
	uint8_t adcNbrCh;
	uint8_t adcScanCycle;
}adcConfig_t;

#define D_ADC_CONFIG_TABLE	\
{EN_ADC_SHOCK_SNS, ADC1, ADC_Channel_9, RCC_PCLK2_Div6, ADC_Mode_Independent, D_STD_DISABLE, D_STD_DISABLE, ADC_ExternalTrigConv_None, ADC_DataAlign_Right, 1, ADC_SampleTime_239Cycles5}

#endif

