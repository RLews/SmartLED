/*
************************************************************************************************************************
* file : E:\KeilWorkspace\M3\uCOS_III_mdk5\HardwareDriverLayer\src\drv_uart.c
* Description : 
* Owner : Lews Hammond
* Time : 2019-6-4
************************************************************************************************************************
*/



#include "drv_uart.h"

static const uartConfig_t uartConfigTbl[EN_ALL_UART_NUM] = {
	D_UART_CONFIG_TABLE
};

static stdBoolean_t uartInitFinished = EN_STD_FALSE;

/*
************************************************************************************************************************
*                                               uart initial
*
* Description : system all uart inital.
*
* Arguments   : void
*
* Returns     : void
************************************************************************************************************************
*/
void Drv_SysUartInit(void)
{
	USART_InitTypeDef USART_InitStructure = {0};
	NVIC_InitTypeDef NVIC_InitStructure = {0};
	uint8_t i = 0;
	const uartConfig_t *pUartConfig = uartConfigTbl;

	for (i = 0; i < (uint8_t)EN_ALL_UART_NUM; i++)
	{
		if ( (pUartConfig[i].uartReg == USART2)
		  || (pUartConfig[i].uartReg == USART3)
		  || (pUartConfig[i].uartReg == UART4)
		  || (pUartConfig[i].uartReg == UART5) )
		{
			RCC_APB1PeriphClockCmd(pUartConfig[i].uartClock, ENABLE);
		}
		else
		{
			RCC_APB2PeriphClockCmd(pUartConfig[i].uartClock, ENABLE);
		}
		USART_DeInit(pUartConfig[i].uartReg);

		NVIC_InitStructure.NVIC_IRQChannel = pUartConfig[i].uartIrqCh;
		NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = pUartConfig[i].uartPriority;
		NVIC_InitStructure.NVIC_IRQChannelSubPriority = pUartConfig[i].uartSubPrioirity;
		NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
		NVIC_Init(&NVIC_InitStructure);

		USART_InitStructure.USART_BaudRate = pUartConfig[i].uartBaudRate;
		USART_InitStructure.USART_WordLength = pUartConfig[i].uartWordLen;
		USART_InitStructure.USART_StopBits = pUartConfig[i].uartStopBits;
		USART_InitStructure.USART_Parity = pUartConfig[i].uartParity;
		USART_InitStructure.USART_HardwareFlowControl = pUartConfig[i].uartHwFlowControl;
		USART_InitStructure.USART_Mode = pUartConfig[i].uartMode;
		USART_Init(pUartConfig[i].uartReg, &USART_InitStructure);
		D_DRV_UART_ITRX_ENABLE(pUartConfig[i].uartReg);
		USART_Cmd(pUartConfig[i].uartReg, ENABLE);
	}

	uartInitFinished = EN_STD_TRUE;
}


/*
************************************************************************************************************************
* Function Name    : Drv_GetUartInitSta
* Description      : get uart initial status
* Input Arguments  : void
* Output Arguments : void
* Returns          : stdBoolean_t : uart initial status
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-10
************************************************************************************************************************
*/

stdBoolean_t Drv_GetUartInitSta(void)
{
	return uartInitFinished;
}


/*
************************************************************************************************************************
*                                               uart rx interrupt enable
*
* Description : uart rx interrupt enable.
*
* Arguments   : uartName_t name. which uarts.
*
* Returns     : void
************************************************************************************************************************
*/
void Drv_UartITRxEnable(uartName_t name)
{
	D_DRV_UART_ITRX_ENABLE(uartConfigTbl[(uint8_t)name].uartReg);
}

/*
************************************************************************************************************************
*                                               uart rx interrupt disable
*
* Description : uart rx interrupt disable.
*
* Arguments   : uartName_t name. which uarts.
*
* Returns     : void
************************************************************************************************************************
*/
void Drv_UartITRxDisable(uartName_t name)
{
	D_DRV_UART_ITRX_DISABLE(uartConfigTbl[(uint8_t)name].uartReg);
}

/*
************************************************************************************************************************
*                                               uart tx interrupt enable
*
* Description : uart tx interrupt enable.
*
* Arguments   : uartName_t name. which uarts.
*
* Returns     : void
************************************************************************************************************************
*/
void Drv_UartITTxEnable(uartName_t name)
{
	D_DRV_UART_ITTX_ENABLE(uartConfigTbl[(uint8_t)name].uartReg);
}

/*
************************************************************************************************************************
*                                               uart tx interrupt disable
*
* Description : uart tx interrupt disable.
*
* Arguments   : uartName_t name. which uarts.
*
* Returns     : void
************************************************************************************************************************
*/
void Drv_UartITTxDisable(uartName_t name)
{
	D_DRV_UART_ITTX_DISABLE(uartConfigTbl[(uint8_t)name].uartReg);
}

/*
************************************************************************************************************************
*                                               uart transmit one byte of data
*
* Description : uart transmit one byte of data.
*
* Arguments   : uartName_t name. which uarts.
*
* Returns     : void
************************************************************************************************************************
*/
void Drv_UartTxByte(uartName_t name, const uint8_t dat)
{
	USART_SendData(uartConfigTbl[(uint8_t)name].uartReg, (uint16_t)dat);
}

/*
************************************************************************************************************************
*                                               judge uart interrupt type
*
* Description : if interrupt is transmit interrupt then return true.
*
* Arguments   : uartName_t name. which uarts.
*
* Returns     : stdBoolean_t. true or false.
************************************************************************************************************************
*/
stdBoolean_t Drv_IsUartRxInt(uartName_t name)
{
	stdBoolean_t isRx = EN_STD_FALSE;
	
	if(USART_GetITStatus(uartConfigTbl[(uint8_t)name].uartReg, USART_IT_RXNE) != RESET)
	{
		isRx = EN_STD_TRUE;
	}

	return isRx;
}

/*
************************************************************************************************************************
*                                               judge uart interrupt type
*
* Description : if interrupt is receiver interrupt then return true.
*
* Arguments   : uartName_t name. which uarts.
*
* Returns     : stdBoolean_t. true or false.
************************************************************************************************************************
*/
stdBoolean_t Drv_IsUartTxInt(uartName_t name)
{
	stdBoolean_t isTx = EN_STD_FALSE;

	if (USART_GetITStatus(uartConfigTbl[(uint8_t)name].uartReg, USART_IT_TXE) != RESET)
	{
		isTx = EN_STD_TRUE;
	}

	return isTx;
}

/*
************************************************************************************************************************
*                                               read uart receiver data
*
* Description : read uart receiver data.
*
* Arguments   : uartName_t name. which uarts.
*
* Returns     : uint8_t. one byte data.
************************************************************************************************************************
*/
uint8_t Drv_UartGetRevData(uartName_t name)
{
	return USART_ReceiveData(uartConfigTbl[(uint8_t)name].uartReg);
}


