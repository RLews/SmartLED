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
 
	RCC_APB1PeriphClockCmd(RCC_APB1Periph_PWR | RCC_APB1Periph_BKP, ENABLE);	//使能PWR和BKP外设时钟   
	PWR_BackupAccessCmd(ENABLE);	//使能后备寄存器访问 
	
	if (BKP_ReadBackupRegister(BKP_DR1) != D_RTC_BACKUP_REG_DEFAULT_VAL)		//从指定的后备寄存器中读出数据:读出了与写入的指定数据不相乎
	{	 			
		BKP_DeInit();	//复位备份区域 	
		RCC_LSEConfig(RCC_LSE_ON);	//设置外部低速晶振(LSE),使用外设低速晶振
		
		do {
			temp++;
			Drv_RtcDelay(10);
			if (temp >= 250)
			{
				break;
			}
		}while (RCC_GetFlagStatus(RCC_FLAG_LSERDY) == RESET);	//检查指定的RCC标志位设置与否,等待低速晶振就绪
		
		if(temp >= 250)
		{
			RCC_RTCCLKConfig(RCC_RTCCLKSource_HSE_Div128);
		}
		else
		{
			RCC_RTCCLKConfig(RCC_RTCCLKSource_LSI);		//设置RTC时钟(RTCCLK),选择LSE作为RTC时钟    
		}
		
		RCC_RTCCLKCmd(ENABLE);	//使能RTC时钟  
		RTC_WaitForLastTask();	//等待最近一次对RTC寄存器的写操作完成
		RTC_WaitForSynchro();		//等待RTC寄存器同步  
		D_DRV_ENABLE_RTC_SEC_INT();		//使能RTC秒中断
		RTC_WaitForLastTask();	//等待最近一次对RTC寄存器的写操作完成
		RTC_EnterConfigMode();/// 允许配置	
		if (temp>=250)
		{
			RTC_SetPrescaler(62500-1);
		}
		else
		{
			RTC_SetPrescaler(32767); //设置RTC预分频的值
		}
		
		RTC_WaitForLastTask();	//等待最近一次对RTC寄存器的写操作完成
		Drv_RtcSetCount(D_RTC_DEFAULT_TIME_COUNTER);  //设置时间	
		RTC_ExitConfigMode(); //退出配置模式  
		BKP_WriteBackupRegister(BKP_DR1, D_RTC_BACKUP_REG_DEFAULT_VAL);	//向指定的后备寄存器中写入用户程序数据
	}
	else//系统继续计时
	{
		RTC_WaitForSynchro();	//等待最近一次对RTC寄存器的写操作完成
		D_DRV_ENABLE_RTC_SEC_INT();	//使能RTC秒中断
		RTC_WaitForLastTask();	//等待最近一次对RTC寄存器的写操作完成
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
	
	NVIC_InitStructure.NVIC_IRQChannel = RTC_IRQn;		//RTC全局中断
	NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0;	//先占优先级1位,从优先级3位
	NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0;	//先占优先级0位,从优先级4位
	NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;		//使能该通道中断
	NVIC_Init(&NVIC_InitStructure);		//根据NVIC_InitStruct中指定的参数初始化外设NVIC寄存器
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
	RCC_APB1PeriphClockCmd(RCC_APB1Periph_PWR | RCC_APB1Periph_BKP, ENABLE);	//使能PWR和BKP外设时钟  
	PWR_BackupAccessCmd(ENABLE);	//使能RTC和后备寄存器访问 
	RTC_SetCounter(secCnt);	//设置RTC计数器的值

	RTC_WaitForLastTask();	//等待最近一次对RTC寄存器的写操作完成  	
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
	RTC_ClearITPendingBit(RTC_IT_SEC|RTC_IT_OW);		//清闹钟中断
	RTC_WaitForLastTask();	
}



