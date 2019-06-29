/*
************************************************************************************************************************
* file : std_lib.c
* Description : redefine stand function 
* Author : Lews Hammond
* Time : 2019-6-27
************************************************************************************************************************
*/

#include "std_lib.h"


/* need MicroLib */
int fputc(int ch, FILE *f)
{
	(void)Hal_UartWrite(EN_SYS_COM, (uint8_t *)&ch, 1);
    
    return ch;
}

