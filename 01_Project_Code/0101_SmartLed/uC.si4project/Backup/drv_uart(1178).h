/*
************************************************************************************************************************
* file : E:\KeilWorkspace\M3\uCOS_III_mdk5\HardwareDriverLayer\inc\drv_uart.h
* Description : 
* Owner : Lews Hammond
* Time : 2019-6-4
************************************************************************************************************************
*/


#ifndef __DRV_UART_H
#define __DRV_UART_H

#include "drv_public.h"



typedef struct _UART_CONFIG_T
{
	uartName_t uartName;
	uint32_t uartClock;
	USART_TypeDef * uartReg;
	uint8_t uartIrqCh;
	uint8_t uartPriority;
	uint8_t uartSubPrioirity;
	uint32_t uartBaudRate;
	uint16_t uartWordLen;
	uint16_t uartStopBits;
	uint16_t uartParity;
	uint16_t uartHwFlowControl;
	uint16_t uartMode;
}uartConfig_t;

#define D_UART_CONFIG_TABLE		\
	{EN_SYS_COM, RCC_APB2Periph_USART1, USART1, USART1_IRQn, 3, 3, 115200, USART_WordLength_8b, \
	 USART_StopBits_1, USART_Parity_No, USART_HardwareFlowControl_None, (USART_Mode_Rx | USART_Mode_Tx)}, \
	{EN_WIFI_COM, RCC_APB1Periph_USART2, USART2, USART2_IRQn, 2, 3, 115200, USART_WordLength_8b, \
	 USART_StopBits_1, USART_Parity_No, USART_HardwareFlowControl_None, (USART_Mode_Rx | USART_Mode_Tx)}



#define D_DRV_UART_ITRX_ENABLE(reg)			USART_ITConfig(reg, USART_IT_RXNE, ENABLE)
#define D_DRV_UART_ITRX_DISABLE(reg)		USART_ITConfig(reg, USART_IT_RXNE, DISABLE)

#define D_DRV_UART_ITTX_ENABLE(reg)			USART_ITConfig(reg, USART_IT_TXE, ENABLE)
#define D_DRV_UART_ITTX_DISABLE(reg)		USART_ITConfig(reg, USART_IT_TXE, DISABLE)




#endif

