/**
************************************************************
* @file         gizwits_product.h
* @brief        Corresponding gizwits_product.c header file (including product hardware and software version definition)
* @author       Gizwits
* @date         2017-07-19
* @version      V03030000
* @copyright    Gizwits
* 
* @note         机智�?只为智能硬件而生
*               Gizwits Smart Cloud  for Smart Products
*               链接|增值ֵ|开放|中立|安全|自有|自由|生�?
*               www.gizwits.com
*
***********************************************************/
#ifndef _GIZWITS_PRODUCT_H
#define _GIZWITS_PRODUCT_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include "gizwits_protocol.h"
#include "srv_wifi_comm.h"

#define D_WIFI_UART_DEBUG			D_STD_ON

#if (D_WIFI_UART_DEBUG == D_STD_ON)

#endif


/**
* MCU software version
*/
#define SOFTWARE_VERSION "03030000"
/**
* MCU hardware version
*/
#define HARDWARE_VERSION "03010100"


/**
* Communication module model
*/
#define MODULE_TYPE 0 //0,WIFI ;1,GPRS







/** User area the current device state structure*/
extern dataPoint_t currentDataPoint;

uint8_t Wifi_GetConnectSta(void);
void gizTimerMs(void);
void userInit(void);
void userHandle(void);
void mcuRestart(void);
uint32_t gizGetTimerCount(void);
int32_t uartWrite(uint8_t *buf, uint32_t len);
int8_t gizwitsEventProcess(eventInfo_t *info, uint8_t *data, uint32_t len);
void WifiBsp_LogPrint(const char *pBuf, ...);

#ifdef __cplusplus
}
#endif

#endif
