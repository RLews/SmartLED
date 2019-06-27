/*
************************************************************************************************************************
* file : E:\KeilWorkspace\M3\uCOS_III_mdk5\HardwareAbstractionLayer\inc\hal_uart.h
* Description : 
* Owner : Lews Hammond
* Time : 2019-6-4
************************************************************************************************************************
*/


#ifndef _HAL_UART_H
#define _HAL_UART_H

#include "hal_public.h"
#include "osal.h"

#define D_SYSTEM_ALL_UART_NUM			EN_ALL_UART_NUM

#define D_SYS_UART_TX_BUFFER_SIZE		(128u)
#define D_SYS_UART_RX_BUFFER_SIZE		(64u)

#define D_SYS_UART_ENABLE_INT(ch)			do {\
	Drv_UartITRxEnable(ch); \
	Drv_UartITTxEnable(ch); \
}while (0)

#define D_SYS_UART_DISABLE_INT(ch)			do {\
	Drv_UartITRxDisable(ch); \
	Drv_UartITTxDisable(ch); \
}while (0)



#endif

