/*
************************************************************************************************************************
* file : E:\KeilWorkspace\M3\uCOS_III_mdk5\HardwareAbstractionLayer\src\hal_uart.c
* Description : 
* Owner : Lews Hammond
* Time : 2019-6-4
************************************************************************************************************************
*/


#include "hal_uart.h"

static volatile uint8_t sysUartTxBuf[D_SYSTEM_ALL_UART_NUM][D_SYS_UART_TX_BUFFER_SIZE] = {0};
static volatile uint8_t sysUartRxBuf[D_SYSTEM_ALL_UART_NUM][D_SYS_UART_RX_BUFFER_SIZE] = {0};
static volatile srvQueue_t sysUartTxQueue[D_SYSTEM_ALL_UART_NUM] = {0};
static volatile srvQueue_t sysUartRxQueue[D_SYSTEM_ALL_UART_NUM] = {0};

static void Hal_SysComIsrHandle(void);
static void Hal_WifiComIsrHandle(void);


static UartRxSemPost SysRxSemPostFunc = (UartRxSemPost)0;
static UartRxSemPost WifiRxSemPostFunc = (UartRxSemPost)0;

/*
************************************************************************************************************************
*                                               hal uart initial
*
* Description : hal uart initial.
*
* Arguments   : void.
*
* Returns     : void.
************************************************************************************************************************
*/
void Hal_SysUartInit(void)
{
	uint8_t i = 0;
	
	for (i = 0; i < D_SYSTEM_ALL_UART_NUM; i++)
	{
		Srv_QueueInit(&sysUartTxQueue[i], (volatile uint8_t *)&sysUartTxBuf[i], D_SYS_UART_TX_BUFFER_SIZE);
		Srv_QueueInit(&sysUartRxQueue[i], (volatile uint8_t *)&sysUartRxBuf[i], D_SYS_UART_RX_BUFFER_SIZE);
	}

	/* TODO: add uart interrupt function */
	Hal_SysISRSet(EN_USART1_ISR, Hal_SysComIsrHandle);
	Hal_SysISRSet(EN_USART2_ISR, Hal_WifiComIsrHandle);

	Drv_SysUartInit();
}

/*
************************************************************************************************************************
* Function Name    : Hal_SetSysRxSemPostFunc
* Description      : Set Rx Sem Post function
* Input Arguments  : UartRxSemPost pFunc : sem post function pointer
* Output Arguments : void
* Returns          : void
* Notes            : 
* Owner            : Lews
* Time             : 2019-6-4
************************************************************************************************************************
*/

void Hal_SetSysRxSemPostFunc(UartRxSemPost pFunc)
{
	SysRxSemPostFunc = pFunc;
}

/*
************************************************************************************************************************
* Function Name    : Hal_SetWifiRxSemPostFunc
* Description      : set wifi sem post function
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-17
************************************************************************************************************************
*/

void Hal_SetWifiRxSemPostFunc(UartRxSemPost pFunc)
{
	WifiRxSemPostFunc = pFunc;
}

/*
************************************************************************************************************************
*                                               uart read one byte data
*
* Description : uart read one byte data.
*
* Arguments   : uartName_t name.	which one uart.
*				uint8_t *dat.		read data point.
*
* Returns     : srvQueueError_t.	read operation result.
************************************************************************************************************************
*/
srvQueueError_t Hal_UartReadByte(uartName_t name, uint8_t *dat)
{
	srvQueueError_t opt = EN_QUEUE_OPT_OK;

	Drv_UartITRxDisable(name);

	opt = Srv_QueueOut(&sysUartRxQueue[name], dat);
	
	Drv_UartITRxEnable(name);

	return opt;
}

/*
************************************************************************************************************************
*                                               uart write data
*
* Description : uart write data.
*
* Arguments   : uartName_t name.	which one uart.
*				uint8_t dat[].		read data point.
*				uint8_t len.		data length.
*
* Returns     : srvQueueError_t.	write operation result.
************************************************************************************************************************
*/
srvQueueError_t Hal_UartWrite(uartName_t name, const uint8_t dat[], uint8_t len)
{
	srvQueueError_t opt = EN_QUEUE_OPT_OK;
	uint8_t i = 0;
	volatile srvQueue_t *pQueue = &sysUartTxQueue[name];
	stdBoolean_t txFlagTrigger = EN_STD_FALSE;
	uint8_t firstDat = 0;
	D_OSAL_ALLOC_CRITICAL_SR();
	
	if ((len == 0) || (len > D_SYS_UART_TX_BUFFER_SIZE))
	{
		opt = EN_QUEUE_OPT_NONE;
		return opt;
	}

	Drv_UartITTxDisable(name);
	D_OSAL_ENTER_CRITICAL();
	
	if (Srv_QueueIsEmpty(pQueue) == EN_STD_TRUE)
	{
		txFlagTrigger = EN_STD_TRUE;/* need trigger tx interrupt */
	}

	for (i = 0; i < len; i++)
	{
		opt = Srv_QueueIn(pQueue, dat[i]);
		if (opt != EN_QUEUE_OPT_OK)
		{
			break;/* exception */
		}
	}

	if (txFlagTrigger == EN_STD_TRUE)
	{
		opt = Srv_ReadQueueHead(pQueue, &firstDat);
		if (opt == EN_QUEUE_OPT_OK)
		{
			Drv_UartTxByte(name, firstDat);/* Trigger new transfer */
		}
	}

	D_OSAL_EXIT_CRITICAL();
	Drv_UartITTxEnable(name);
	
	return opt;
}

/*
************************************************************************************************************************
*                                               uart interrupt handler function
*
* Description : uart interrupt hander function.
*
* Arguments   : void.
*
* Returns     : void.
************************************************************************************************************************
*/
static void Hal_SysComIsrHandle(void)
{
	volatile srvQueue_t *pTxQueue = &sysUartTxQueue[EN_SYS_COM];
	volatile srvQueue_t *pRxQueue = &sysUartRxQueue[EN_SYS_COM];
	uint8_t uartDat = 0;
	
	if (Drv_IsUartTxInt(EN_SYS_COM) == EN_STD_TRUE)
	{
		/* Make sure to queue out after the send completed */
		if (EN_QUEUE_OPT_EMPTY == Srv_QueueOut(pTxQueue, &uartDat))
		{
			Drv_UartITTxDisable(EN_SYS_COM);/* send finish */
		}
		else
		{
			Srv_ReadQueueHead(pTxQueue, &uartDat);
			Drv_UartTxByte(EN_SYS_COM, uartDat);
		}
	}

	if (Drv_IsUartRxInt(EN_SYS_COM) == EN_STD_TRUE)
	{
		uartDat = Drv_UartGetRevData(EN_SYS_COM);
		(void)Srv_QueueIn(pRxQueue, uartDat);
		if (SysRxSemPostFunc != (UartRxSemPost)0)
		{
			SysRxSemPostFunc();
		}
	}
}

/*
************************************************************************************************************************
* Function Name    : Hal_WifiComIsrHandle
* Description      : wifi uart interrupt handle
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-17
************************************************************************************************************************
*/

static void Hal_WifiComIsrHandle(void)
{
	volatile srvQueue_t *pTxQueue = &sysUartTxQueue[EN_WIFI_COM];
	volatile srvQueue_t *pRxQueue = &sysUartRxQueue[EN_WIFI_COM];
	uint8_t uartDat = 0;
	
	if (Drv_IsUartTxInt(EN_WIFI_COM) == EN_STD_TRUE)
	{
		/* Make sure to queue out after the send completed */
		if (EN_QUEUE_OPT_EMPTY == Srv_QueueOut(pTxQueue, &uartDat))
		{
			Drv_UartITTxDisable(EN_WIFI_COM);/* send finish */
		}
		else
		{
			Srv_ReadQueueHead(pTxQueue, &uartDat);
			Drv_UartTxByte(EN_WIFI_COM, uartDat);
		}
	}

	if (Drv_IsUartRxInt(EN_WIFI_COM) == EN_STD_TRUE)
	{
		uartDat = Drv_UartGetRevData(EN_WIFI_COM);
		(void)Srv_QueueIn(pRxQueue, uartDat);
		if (WifiRxSemPostFunc != (UartRxSemPost)0)
		{
			WifiRxSemPostFunc();
		}
	}
}

