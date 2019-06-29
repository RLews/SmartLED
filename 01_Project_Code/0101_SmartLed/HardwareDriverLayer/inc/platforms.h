/*
************************************************************************************************************************
* file : E:\KeilWorkspace\M3\uCOS_III_mdk5\HardwareDriverLayer\inc\platforms.h
* Description : 
* Owner : Lews Hammond
* Time : 2019-6-4
************************************************************************************************************************
*/


#ifndef __PLATFORMS_H
#define __PLATFORMS_H

#include  <stdarg.h>
#include  <stdio.h>
#include  <stdlib.h>
#include  <math.h>

#include "stm32f10x.h"


typedef enum _STD_BOOLEAN_T
{
	EN_STD_FALSE = 0,
	EN_STD_TRUE
}stdBoolean_t;

#define D_SYS_STD_OFF			(0u)
#define D_SYS_STD_ON			(1u)




#endif
