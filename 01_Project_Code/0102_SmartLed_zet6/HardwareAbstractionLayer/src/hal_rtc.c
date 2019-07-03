/*
************************************************************************************************************************
* file : hal_rtc.c
* Description : 
* Author : Lews Hammond
* Time : 2019-6-11
************************************************************************************************************************
*/

#include "hal_rtc.h"


static rtcTime_t sysTime = {0};

static const uint8_t rtcMonTbl[12] = {31,28,31,30,31,30,31,31,30,31,30,31};
static const uint8_t rtcWeekTbl[12] = {0,3,3,6,1,4,6,2,5,0,3,5};

static void Hal_RtcUpdate(void);
static stdBoolean_t Hal_RtcJudgeLeap(uint16_t year);
static uint8_t Hal_RtcGetWeek(uint16_t year, uint8_t mon, uint8_t day);
static void Hal_RtcIsrHandle(void);


/*
************************************************************************************************************************
* Function Name    : Hal_RtcInit
* Description      : rtc initial
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-11
************************************************************************************************************************
*/

void Hal_RtcInit(void)
{
	rtcTime_t *pTime = &sysTime;
	rtcTime_t defaultTime = {
		D_DEFAULT_SYS_TIME_YEAR,D_DEFAULT_SYS_TIME_MON,D_DEFAULT_SYS_TIME_DAY,
		D_DEFAULT_SYS_TIME_HOUR,D_DEFAULT_SYS_TIME_MIN,D_DEFAULT_SYS_TIME_SEC,D_DEFAULT_SYS_TIME_WEEK
	};
	
	Hal_SysISRSet(EN_RTC_ISR, Hal_RtcIsrHandle);
	Drv_RtcInit();
	Hal_RtcUpdate();
	if (pTime->rtcYear < D_DEFAULT_SYS_TIME_YEAR)//system rtc power off
	{
		Hal_RtcSetTime(defaultTime);
	}
}

/*
************************************************************************************************************************
* Function Name    : Hal_RtcGetTime
* Description      : get rtc time
* Input Arguments  : 
* Output Arguments : rtcTime_t *pTime
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-11
************************************************************************************************************************
*/

void Hal_RtcGetTime(rtcTime_t *pTime)
{
	D_DRV_DISABLE_RTC_SEC_INT();
	
	pTime->rtcYear = sysTime.rtcYear;
	pTime->rtcMon = sysTime.rtcMon;
	pTime->rtcDay = sysTime.rtcDay;
	pTime->rtcHour = sysTime.rtcHour;
	pTime->rtcMin = sysTime.rtcMin;
	pTime->rtcSec = sysTime.rtcSec;
	pTime->rtcWeek = sysTime.rtcWeek;
	
	D_DRV_ENABLE_RTC_SEC_INT();
}

/*
************************************************************************************************************************
* Function Name    : Hal_RtcIsrHandle
* Description      : rtc interrupt function
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-11
************************************************************************************************************************
*/

static void Hal_RtcIsrHandle(void)
{
	if (Drv_RtcIsSecInt() == EN_STD_TRUE)
	{
		Hal_RtcUpdate();
	}

	Drv_RtcIsrHandle();
}

/*
************************************************************************************************************************
* Function Name    : Hal_RtcJudgeLeap
* Description      : judge leap year
* Input Arguments  : uint16_t year
* Output Arguments : 
* Returns          : stdBoolean_t
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-11
************************************************************************************************************************
*/

static stdBoolean_t Hal_RtcJudgeLeap(uint16_t year)
{
	if(year % 4 == 0) //必须能被4整除
	{ 
		if(year % 100 == 0) 
		{ 
			if(year % 400 == 0)
			{
				return EN_STD_TRUE;//如果以00结尾,还要能被400整除 	  
			}
			else
			{
				return EN_STD_FALSE;   
			}
		}
		else
		{
			return EN_STD_TRUE;   
		}
	}
	else
	{
		return EN_STD_FALSE;	
	}
}

/*
************************************************************************************************************************
* Function Name    : Hal_RtcUpdate
* Description      : rtc time update
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-11
************************************************************************************************************************
*/

static void Hal_RtcUpdate(void)
{
	static uint16_t dayCnt = 0xFF;
	rtcTime_t *pTime = &sysTime;
	uint32_t timeCnt = Drv_RtcGetCount();
	uint32_t temp = 0;
	uint32_t temp1 = 0;

	temp = timeCnt / D_HAL_SEC_IN_A_DAY;
	if(dayCnt != temp)
	{	  
		dayCnt = temp;
		temp1 = 1970;
		while(temp >= 365)
		{				 
			if(Hal_RtcJudgeLeap(temp1) == EN_STD_TRUE)
			{
				if(temp >= 366)
				{
					temp -= 366;
				}
				else 
				{
					temp1++;
					break;
				}  
			}
			else
			{
				temp -= 365;
			}
			temp1++;  
		}   
		pTime->rtcYear = temp1;
		temp1 = 0;
		while(temp >= 28)
		{
			if((Hal_RtcJudgeLeap(temp1) == EN_STD_TRUE) && (temp1==1))
			{
				if(temp >= 29)
				{
					temp -= 29;
				}
				else
				{
					break; 
				}
			}
			else 
			{
				if(temp >= rtcMonTbl[temp1])
				{
					temp -= rtcMonTbl[temp1];
				}
				else 
				{
					break;
				}
			}
			temp1++;  
		}
		pTime->rtcMon = temp1 + 1;
		pTime->rtcDay = temp + 1;
	}
	temp = timeCnt % D_HAL_SEC_IN_A_DAY;
	pTime->rtcHour = temp / D_HAL_SEC_IN_A_HOUR;
	pTime->rtcMin = (temp % D_HAL_SEC_IN_A_HOUR) / D_HAL_TIME_SEC_IN_A_MIN;
	pTime->rtcSec = (temp % D_HAL_SEC_IN_A_HOUR) % D_HAL_TIME_SEC_IN_A_MIN;
	pTime->rtcWeek = Hal_RtcGetWeek(pTime->rtcYear, pTime->rtcMon, pTime->rtcDay);
}

/*
************************************************************************************************************************
* Function Name    : Hal_RtcSetTime
* Description      : set system time
* Input Arguments  : rtcTime_t times
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-13
************************************************************************************************************************
*/

void Hal_RtcSetTime(rtcTime_t times)
{
	uint16_t t = 0;
	uint32_t seccount = 0;
	
	if( (times.rtcYear < 1970) || (times.rtcYear > 2099) )
	{
		return;
	}
	
	for(t = 1970; t < times.rtcYear; t++)
	{
		if(Hal_RtcJudgeLeap(t) == EN_STD_TRUE)
		{
			seccount += D_HAL_SEC_IN_LEAP_YEAR;
		}
		else 
		{
			seccount += D_HAL_SEC_IN_NOR_YEAR;
		}
	}
	times.rtcMon -= 1;
	for(t = 0; t < times.rtcMon; t++)
	{
		seccount += (uint32_t)rtcMonTbl[t] * D_HAL_SEC_IN_A_DAY;
		if( (Hal_RtcJudgeLeap(times.rtcYear) == EN_STD_TRUE) && (t == 1) )
		{
			seccount += D_HAL_SEC_IN_A_DAY;
		}
	}
	seccount += (uint32_t)(times.rtcDay - 1) * D_HAL_SEC_IN_A_DAY;
	seccount += (uint32_t)times.rtcHour * D_HAL_SEC_IN_A_HOUR;
    seccount += (uint32_t)times.rtcMin * D_HAL_TIME_SEC_IN_A_MIN;
	seccount += times.rtcSec;

	Drv_RtcSetCount(seccount);
}

/*
************************************************************************************************************************
* Function Name    : Hal_RtcGetWeek
* Description      : calculate week
* Input Arguments  : uint16_t year, uint8_t mon, uint8_t day
* Output Arguments : 
* Returns          : uint8_t : week
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-11
************************************************************************************************************************
*/

static uint8_t Hal_RtcGetWeek(uint16_t year, uint8_t mon, uint8_t day)
{
	uint16_t temp2 = 0;
	uint8_t yearH = 0;
	uint8_t yearL = 0;
	
	yearH = year / 100;
	yearL = year % 100; 
	// 如果为21世纪,年份数加100  
	if (yearH > 19)
	{
		yearL+=100;
	}
	// 所过闰年数只算1900年之后的  
	temp2 = yearL + yearL / 4;
	temp2 = temp2 % 7; 
	temp2 = temp2 + day + rtcWeekTbl[mon-1];
	if ( (yearL % 4 == 0) && (mon < 3) )
	{
		temp2--;
	}
	
	return(temp2 % 7);
}

