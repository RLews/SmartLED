/*
************************************************************************************************************************
* file : srv_wifi_comm.c
* Description : 
* Author : Lews Hammond
* Time : 2019-6-17
************************************************************************************************************************
*/

#include "srv_wifi_comm.h"

#if (D_UC_OS_III_ENABLE == D_SYS_STD_ON)
static OSAL_SEM wifiUartRxSem;

static void Srv_WifiCommRxSemPost(void);
#endif
/*
************************************************************************************************************************
* Function Name    : Srv_WifiCommInit
* Description      : wifi communication initial
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-17
************************************************************************************************************************
*/

void Srv_WifiCommInit(void)
{
	D_OSAL_ALLOC_CRITICAL_SR();
	
#if (D_UC_OS_III_ENABLE == D_SYS_STD_ON)
	Osal_SemCreate(&wifiUartRxSem, 0, "WIFI_UART_RX");
	D_OSAL_ENTER_CRITICAL();
	Hal_SetWifiRxSemPostFunc(Srv_WifiCommRxSemPost);
	D_OSAL_EXIT_CRITICAL();
#endif
}

/*
************************************************************************************************************************
* Function Name    : Srv_WifiCommWaitRev
* Description      : wait sem for wifi uart data 
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-17
************************************************************************************************************************
*/

void Srv_WifiCommWaitRev(void)
{
#if (D_UC_OS_III_ENABLE == D_SYS_STD_ON)
	Osal_SemWait(&wifiUartRxSem, 0);
#endif	
}

/*
************************************************************************************************************************
* Function Name    : Srv_WifiCommTx
* Description      : wifi uart data transmit
* Input Arguments  : const uint8_t pDat[], uint16_t len
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-17
************************************************************************************************************************
*/

void Srv_WifiCommTx(const uint8_t pDat[], uint16_t len)
{
	(void)Hal_UartWrite(EN_WIFI_COM, pDat, len);
}

#if (D_UC_OS_III_ENABLE == D_SYS_STD_ON)

/*
************************************************************************************************************************
* Function Name    : Srv_WifiCommRxSemPost
* Description      : wifi receiver data sem post
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-17
************************************************************************************************************************
*/

static void Srv_WifiCommRxSemPost(void)
{
	Osal_SemPost(&wifiUartRxSem);
}
#endif

