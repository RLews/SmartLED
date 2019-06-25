/*
************************************************************************************************************************
* file : E:\KeilWorkspace\M3\uCOS_III_mdk5\ServicesLayer\Communication\inc\srv_comm_check.h
* Description : 
* Owner : Lews Hammond
* Time : 2019-6-4
************************************************************************************************************************
*/


#ifndef __SRV_COMM_CHECK_H
#define __SRV_COMM_CHEKC_H

#include "platforms.h"

#define D_COMM_CRC_SEED				0xFFFAu





uint16_t Srv_CommCrc16(const uint8_t * data, uint16_t len);

uint16_t Srv_CommCrc16Tbl(uint16_t seed, const uint8_t *data, uint16_t len);

uint16_t Srv_CommChkSum16(const uint8_t data[], uint16_t len);


#endif

