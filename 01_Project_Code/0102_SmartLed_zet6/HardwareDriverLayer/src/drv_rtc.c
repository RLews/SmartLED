/*
************************************************************************************************************************
* file : drv_rtc.c
* Description : 
* Author : Lews Hammond
* Time : 2019-6-11
************************************************************************************************************************
*/

#include "drv_rtc.h"


static void Drv_RtcDelay(uint32_t cnt);
static void Drv_RtcNvicInit(void);

/*
************************************************************************************************************************
* Function Name    : Drv_RtcInit
* Description      : rtc initial
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-11
************************************************************************************************************************
*/

void Drv_RtcInit(void)
{
	uint8_t temp = 0;
 
	RCC_APB1PeriphClockCmd(RCC_APB1Periph_PWR | RCC_APB1Periph_BKP, ENABLE);	//ʹ��PWR��BKP����ʱ��   
	PWR_BackupAccessCmd(ENABLE);	//ʹ�ܺ󱸼Ĵ������� 
	
	if (BKP_ReadBackupRegister(BKP_DR1) != D_RTC_BACKUP_REG_DEFAULT_VAL)		//��ָ���ĺ󱸼Ĵ����ж�������:��������д���ָ�����ݲ����
	{	 			
		BKP_DeInit();	//��λ�������� 	
		RCC_LSEConfig(RCC_LSE_ON);	//�����ⲿ���پ���(LSE),ʹ��������پ���
		
		do {
			temp++;
			Drv_RtcDelay(10);
			if (temp >= 250)
			{
				break;
			}
		}while (RCC_GetFlagStatus(RCC_FLAG_LSERDY) == RESET);	//���ָ����RCC��־λ�������,�ȴ����پ������
		
		if(temp >= 250)
		{
			RCC_RTCCLKConfig(RCC_RTCCLKSource_HSE_Div128);
		}
		else
		{
			RCC_RTCCLKConfig(RCC_RTCCLKSource_LSI);		//����RTCʱ��(RTCCLK),ѡ��LSE��ΪRTCʱ��    
		}
		
		RCC_RTCCLKCmd(ENABLE);	//ʹ��RTCʱ��  
		RTC_WaitForLastTask();	//�ȴ����һ�ζ�RTC�Ĵ�����д�������
		RTC_WaitForSynchro();		//�ȴ�RTC�Ĵ���ͬ��  
		D_DRV_ENABLE_RTC_SEC_INT();		//ʹ��RTC���ж�
		RTC_WaitForLastTask();	//�ȴ����һ�ζ�RTC�Ĵ�����д�������
		RTC_EnterConfigMode();/// ��������	
		if (temp>=250)
		{
			RTC_SetPrescaler(62500-1);
		}
		else
		{
			RTC_SetPrescaler(32767); //����RTCԤ��Ƶ��ֵ
		}
		
		RTC_WaitForLastTask();	//�ȴ����һ�ζ�RTC�Ĵ�����д�������
		Drv_RtcSetCount(D_RTC_DEFAULT_TIME_COUNTER);  //����ʱ��	
		RTC_ExitConfigMode(); //�˳�����ģʽ  
		BKP_WriteBackupRegister(BKP_DR1, D_RTC_BACKUP_REG_DEFAULT_VAL);	//��ָ���ĺ󱸼Ĵ�����д���û���������
	}
	else//ϵͳ������ʱ
	{
		RTC_WaitForSynchro();	//�ȴ����һ�ζ�RTC�Ĵ�����д�������
		D_DRV_ENABLE_RTC_SEC_INT();	//ʹ��RTC���ж�
		RTC_WaitForLastTask();	//�ȴ����һ�ζ�RTC�Ĵ�����д�������
	}
	
	Drv_RtcNvicInit();
}

/*
************************************************************************************************************************
* Function Name    : Drv_RtcDelay
* Description      : delay for wait osc
* Input Arguments  : uint32_t cnt
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-11
************************************************************************************************************************
*/

static void Drv_RtcDelay(uint32_t cnt)
{
	uint32_t dly = 0;
	uint32_t i = 0;

	for (i = 0; i < cnt; i++)
	{
		dly = 0xFFul;
		do{
			dly--;
		}while (dly != 0);
	}
}

/*
************************************************************************************************************************
* Function Name    : Drv_RtcNvicInit
* Description      : rtc interrupt configuration
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-11
************************************************************************************************************************
*/

static void Drv_RtcNvicInit(void)
{
	NVIC_InitTypeDef NVIC_InitStructure = (NVIC_InitTypeDef){0};
	
	NVIC_InitStructure.NVIC_IRQChannel = RTC_IRQn;		//RTCȫ���ж�
	NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0;	//��ռ���ȼ�1λ,�����ȼ�3λ
	NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0;	//��ռ���ȼ�0λ,�����ȼ�4λ
	NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;		//ʹ�ܸ�ͨ���ж�
	NVIC_Init(&NVIC_InitStructure);		//����NVIC_InitStruct��ָ���Ĳ�����ʼ������NVIC�Ĵ���
}

/*
************************************************************************************************************************
* Function Name    : Drv_RtcSetCount
* Description      : set rtc counter
* Input Arguments  : uint32_t secCnt
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-11
************************************************************************************************************************
*/

void Drv_RtcSetCount(uint32_t secCnt)
{
	RCC_APB1PeriphClockCmd(RCC_APB1Periph_PWR | RCC_APB1Periph_BKP, ENABLE);	//ʹ��PWR��BKP����ʱ��  
	PWR_BackupAccessCmd(ENABLE);	//ʹ��RTC�ͺ󱸼Ĵ������� 
	RTC_SetCounter(secCnt);	//����RTC��������ֵ

	RTC_WaitForLastTask();	//�ȴ����һ�ζ�RTC�Ĵ�����д�������  	
}

/*
************************************************************************************************************************
* Function Name    : Drv_RtcGetCount
* Description      : get rtc counter
* Input Arguments  : 
* Output Arguments : 
* Returns          : uint32_t
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-11
************************************************************************************************************************
*/

uint32_t Drv_RtcGetCount(void)
{
	uint32_t count = 0;

	count = RTC->CNTH;
	count <<= 16;
	count += RTC->CNTL;

	return count;
}

/*
************************************************************************************************************************
* Function Name    : Drv_RtcIsSecInt
* Description      : judge interrupt is second
* Input Arguments  : 
* Output Arguments : 
* Returns          : stdBoolean_t
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-11
************************************************************************************************************************
*/

stdBoolean_t Drv_RtcIsSecInt(void)
{
	if (RTC_GetITStatus(RTC_IT_SEC) != RESET)
	{
		return EN_STD_TRUE;
	}
	else
	{
		return EN_STD_FALSE;
	}
}

/*
************************************************************************************************************************
* Function Name    : Drv_RtcIsrHandle
* Description      : rtc interrupt handle. clear interrupt flag and wait task
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-11
************************************************************************************************************************
*/

void Drv_RtcIsrHandle(void)
{
	RTC_ClearITPendingBit(RTC_IT_SEC|RTC_IT_OW);		//�������ж�
	RTC_WaitForLastTask();	
}



