/*
************************************************************************************************************************
* file : app_shock.c
* Description : 
* Author : Lews Hammond
* Time : 2019-7-11
************************************************************************************************************************
*/


#include "app_shock.h"

static shockSensorSta_t shockSta = EN_SHOCK_NONE;
static stdBoolean_t shockEnable = EN_STD_FALSE;

static void Shk_Scan(void);


/*
************************************************************************************************************************
* Function Name    : Shk_Scan
* Description      : 
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-7-11
************************************************************************************************************************
*/

static void Shk_Scan(void)
{
	shockSensorSta_t *pSta = &shockSta;
	static uint8_t shockShake = 0;
	static uint32_t dlyTs = 0;/* 防止多次处理 */
	static stdBoolean_t updateFlag = EN_STD_TRUE;
	uint16_t scanRes = 0;
	
	scanRes = Hal_ScanShock();
	if (scanRes <= D_SHOCK_PRESS_SCAN_VALUE)
	{
		dlyTs = Osal_GetCurTs();
		if (shockShake < 0xFF)
		{
			shockShake++;
		}
		
		if (shockShake == D_SHOCK_VAILD_SCAN_TIMES)
		{
			*pSta = (updateFlag == EN_STD_TRUE) ? (EN_SHOCK_PRESS) : (EN_SHOCK_NONE);
			updateFlag = EN_STD_FALSE;
		}
	}
	else
	{
		shockShake = 0;
	}

	if ((updateFlag == EN_STD_FALSE) && (Osal_DiffTsToUsec(dlyTs) > D_SHOCK_SHAKE_TIMES))
	{
		updateFlag = EN_STD_TRUE;
	}
}

/*
************************************************************************************************************************
* Function Name    : Shk_GetSnsSta
* Description      : 
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-7-11
************************************************************************************************************************
*/

shockSensorSta_t Shk_GetSnsSta(void)
{
	return shockSta;
}

/*
************************************************************************************************************************
* Function Name    : Shk_ClrSnsSta
* Description      : 
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-7-11
************************************************************************************************************************
*/

void Shk_ClrSnsSta(void)
{
	shockSta = EN_SHOCK_NONE;	
}

/*
************************************************************************************************************************
* Function Name    : Shk_PeriodHandle
* Description      : 
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-7-11
************************************************************************************************************************
*/

void Shk_PeriodHandle(void)
{
	if (shockEnable == EN_STD_TRUE)
	{
		Shk_Scan();
	}
}

/*
************************************************************************************************************************
* Function Name    : Shk_EnableScan
* Description      : 
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-7-13
************************************************************************************************************************
*/

void Shk_EnableScan(void)
{
	shockEnable = EN_STD_TRUE;
}

/*
************************************************************************************************************************
* Function Name    : Shk_DisableScan
* Description      : 
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-7-13
************************************************************************************************************************
*/

void Shk_DisableScan(void)
{
	shockEnable = EN_STD_FALSE;
}

