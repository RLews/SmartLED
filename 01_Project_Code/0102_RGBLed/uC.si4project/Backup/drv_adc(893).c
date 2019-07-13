/*
************************************************************************************************************************
* file : drv_adc.c
* Description : 
* Author : Lews Hammond
* Time : 2019-7-11
************************************************************************************************************************
*/

#include "drv_adc.h"

static const adcConfig_t adcConfig[(uint8_t)EN_ADC_ALL_SIGNAL] = {D_ADC_CONFIG_TABLE};

/*
************************************************************************************************************************
* Function Name    : Drv_AdcInit
* Description      : 
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-7-11
************************************************************************************************************************
*/

void Drv_AdcInit(void)
{
	const adcConfig_t *pAdcConfig = adcConfig;
	ADC_InitTypeDef ADC_InitStructure = {0}; 
	uint8_t i = 0;

	for (i = 0; i < (uint8_t)EN_ADC_ALL_SIGNAL; i++)
	{
		RCC_ADCCLKConfig(pAdcConfig[i].adcClkDiv);
		ADC_DeInit(pAdcConfig[i].adcReg);
		ADC_InitStructure.ADC_Mode = pAdcConfig[i].adcMode;
		ADC_InitStructure.ADC_ScanConvMode = pAdcConfig[i].adcScanConvMode;
		ADC_InitStructure.ADC_ContinuousConvMode = pAdcConfig[i].adcContConvMode;
		ADC_InitStructure.ADC_ExternalTrigConv = pAdcConfig[i].adcExtTrigConv;
		ADC_InitStructure.ADC_DataAlign = pAdcConfig[i].adcDatAlign;
		ADC_InitStructure.ADC_NbrOfChannel = pAdcConfig[i].adcNbrCh;
		ADC_Init(pAdcConfig[i].adcReg, &ADC_InitStructure);
		ADC_Cmd(pAdcConfig[i].adcReg, ENABLE);
		ADC_ResetCalibration(pAdcConfig[i].adcReg);
		do{
		}while(ADC_GetResetCalibrationStatus(pAdcConfig[i].adcReg));
		ADC_StartCalibration(pAdcConfig[i].adcReg);
		do{
		}while(ADC_GetCalibrationStatus(pAdcConfig[i].adcReg));
	}
	
}

/*
************************************************************************************************************************
* Function Name    : Drv_AdcScanCh
* Description      : 
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-7-11
************************************************************************************************************************
*/

uint16_t Drv_AdcScanCh(adcSignalName_t name)
{
	const adcConfig_t *pAdcConfig = adcConfig;
	uint16_t adcRes = 0xFFFFu;
	uint16_t timeout = 12800;

	if (name < EN_ADC_ALL_SIGNAL)
	{
		ADC_RegularChannelConfig(pAdcConfig[(uint8_t)name].adcReg, pAdcConfig[(uint8_t)name].adcCh, 1, pAdcConfig[(uint8_t)name].adcScanCycle );
  
		ADC_SoftwareStartConvCmd(pAdcConfig[(uint8_t)name].adcReg, ENABLE);		//使能指定的ADC1的软件转换启动功能	

		do{
			timeout--;
			if (timeout == 0)
			{
				return adcRes;
			}
		}while(!ADC_GetFlagStatus(pAdcConfig[(uint8_t)name].adcReg, ADC_FLAG_EOC ));//等待转换结束

		adcRes = ADC_GetConversionValue(pAdcConfig[(uint8_t)name].adcReg);
	}

	return adcRes;
}

