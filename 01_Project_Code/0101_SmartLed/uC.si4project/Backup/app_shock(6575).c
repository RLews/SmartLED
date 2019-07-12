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
	uint16_t scanRes = 0;
	
	scanRes = Hal_ScanShock();
	if (scanRes <= D_SHOCK_PRESS_SCAN_VALUE)
	{
		if (shockShake < 0xFF)
		{
			shockShake++;
		}
		if (shockShake == D_SHOCK_VAILD_SCAN_TIMES)
		{
			*pSta = EN_SHOCK_PRESS;
		}
	}
	else
	{
		shockShake = 0;
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
	static uint32_t Ts = 0;

	if (Osal_DiffTsToUsec(Ts) >= (D_SYS_MS_COUNT))
	{
		Ts = Osal_GetCurTs();
		Shk_Scan();
	}
}

