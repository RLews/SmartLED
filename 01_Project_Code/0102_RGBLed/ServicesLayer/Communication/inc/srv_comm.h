/*
************************************************************************************************************************
* file : E:\KeilWorkspace\M3\uCOS_III_mdk5\ServicesLayer\Communication\inc\srv_comm.h
* Description : 
* Owner : Lews Hammond
* Time : 2019-6-4
************************************************************************************************************************
*/


#ifndef __SRV_COMM_H
#define __SRV_COMM_H


#include "hal_public.h"
#include "osal.h"
#include "srv_comm_check.h"

#define D_SRV_COMM_ENABLE				D_STD_OFF
#define D_SRV_UDS_ENABLE				D_STD_OFF

#if (D_SRV_UDS_ENABLE == D_STD_ON)
#include "udscan_callbacks.h"
#endif

#if (D_SRV_COMM_ENABLE == D_STD_ON)

#define D_COMM_FRAME_HEAD1				(0xAB)
#define D_COMM_FRAME_HEAD2				(0xBA)

#define D_COMM_NM_TRANS_ID				(0x7E)
#define D_COMM_NM_REV_ID				(0x7F)
#define D_COMM_APP_TRANS_ID				(0x81)
#define D_COMM_APP_REV_ID				(0x82)

#define D_COMM_UDS_PHY_TX_ADDR			(0x7B)
#define D_COMM_UDS_PHY_RX_ADDR			(0x7A)
#define D_COMM_UDS_FUN_RX_ADDR			(0x7C)

#define D_COMM_COUNT_MAX_VAL			(0x10)/* 0x00 - 0x0F */

#define D_COMM_UDS_FRAME_MAX_SIZE		(8)


#define D_COMM_PADDING_DATA				(0x55)

#define D_COMM_BUFFER_SIZE				(60)

#define D_COMM_TYPE_OR_CMD_DLC_INDEX	(0u)

#define D_COMM_DATA_INDEX				(1u)

#define D_COMM_REV_TIMEOUT				(10000u)/* 10ms */

typedef void (*Srv_DecryptFunc_t)(void);

typedef enum __COMM_NAME_T
{
	EN_COMM_UDS_PHY_REV = 0,
	EN_COMM_UDS_PHY_TX,
	EN_COMM_UDS_FUNC_REV,
	EN_COMM_NM_TX,
	EN_COMM_NM_RX,
	EN_COMM_APP_TX,
	EN_COMM_APP_RX,
	EN_COMM_ALL_NUM
}commName_t;

typedef enum __COMM_TYPE_T
{
	EN_COMM_APP_MSG = 0,
	EN_COMM_NM_MSG,
	EN_COMM_DSG_MSG,
	EN_COMM_ALL_TYPE
}commType_t;

typedef enum __COMM_DECRYPT_STEP_T
{
	EN_COMM_STEP_FRAME_HEAD1 = 0,
	EN_COMM_STEP_FRAME_HEAD2,
	EN_COMM_STEP_FRAME_CNT,
	EN_COMM_STEP_FRAME_LEN,
	EN_COMM_STEP_FRAME_ID,
	EN_COMM_STEP_FRAME_DATA,
	EN_COMM_STEP_FRAME_CHK1,
	EN_COMM_STEP_FRAME_CHK2,
	EN_COMM_DECRYPT_ALL_STEP
}commDecryptStep_t;

typedef enum __COMM_FRAME_CNT_STA_T
{
	EN_COMM_FRAME_COUNT_NOR = 0,
	EN_COMM_FRAME_COUNT_ERR
}commFrameCntSta_t;

typedef struct __COMM_FRAME_DATA_T
{
	commName_t frameName;
	uint8_t Len;
	uint8_t id;
	uint8_t data[D_COMM_BUFFER_SIZE];
	uint16_t crc16;
}commFrameData_t;

typedef struct __COMM_FRAME_CONFIG_T
{
	uint8_t id;
	stdBoolean_t isTx;
	commType_t dataType;
}commFrameConfig_t;

#define D_COMM_FRAME_CONFIG		\
{D_COMM_UDS_PHY_RX_ADDR, EN_STD_FALSE, EN_COMM_DSG_MSG}, \
{D_COMM_UDS_PHY_TX_ADDR, EN_STD_TRUE, EN_COMM_DSG_MSG}, \
{D_COMM_UDS_FUN_RX_ADDR, EN_STD_FALSE, EN_COMM_DSG_MSG}, \
{D_COMM_NM_TRANS_ID, EN_STD_TRUE, EN_COMM_NM_MSG}, \
{D_COMM_NM_REV_ID, EN_STD_FALSE, EN_COMM_NM_MSG}, \
{D_COMM_APP_TRANS_ID, EN_STD_TRUE, EN_COMM_APP_MSG}, \
{D_COMM_APP_REV_ID, EN_STD_FALSE, EN_COMM_APP_MSG}


void Srv_SysCommDecrypt(void);

void Srv_SysCommTransmit(uint8_t id, const uint8_t dat[], uint16_t len);

void Srv_SysCommInit(void);

#endif

#endif


