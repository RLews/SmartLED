/*
************************************************************************************************************************
* file : app_shock.h
* Description : 
* Author : Lews Hammond
* Time : 2019-7-11
************************************************************************************************************************
*/

#ifndef _APP_SHOCK_H
#define _APP_SHOCK_H

#include "app_public.h"


#define D_SHOCK_VAILD_SCAN_TIMES		1
#define D_SHOCK_PRESS_SCAN_VALUE		0x100
#define D_SHOCK_SHAKE_TIMES				(50 * D_SYS_MS_COUNT)

typedef enum _SHOCK_SENSOR_STA_T
{
	EN_SHOCK_NONE = 0,
	EN_SHOCK_PRESS,
	EN_SHOCK_ALL_STA
}shockSensorSta_t;


shockSensorSta_t Shk_GetSnsSta(void);
void Shk_ClrSnsSta(void);
void Shk_PeriodHandle(void);


#endif

