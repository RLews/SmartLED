/*
************************************************************************************************************************
* file : srv_wifi_comm.h
* Description : 
* Author : Lews Hammond
* Time : 2019-6-17
************************************************************************************************************************
*/

#ifndef _SRV_WIFI_COMM_H
#define _SRV_WIFI_COMM_H

#include "hal_public.h"
#include "osal.h"









void Srv_WifiCommInit(void);

void Srv_WifiCommWaitRev(void);

void Srv_WifiCommTx(const uint8_t pDat[], uint16_t len);


#endif


