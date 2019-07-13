/*
************************************************************************************************************************
* file : app_shock.c
* Description : 
* Author : Lews Hammond
* Time : 2019-7-11
************************************************************************************************************************
*/


#include "app_shock.h"

static uint16_t shockScanDat = 0;

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
	shockScanDat = Hal_ScanShock();
	printf("\nthe sensor ad value is %x\n", shockScanDat);
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

	if (Osal_DiffTsToUsec(Ts) >= (5*D_SYS_MS_COUNT))
	{
		Ts = Osal_GetCurTs();
		Shk_Scan();
	}
}

