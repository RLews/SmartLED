/*
************************************************************************************************************************
* file : E:\KeilWorkspace\M3\uCOS_III_mdk5\ServicesLayer\DataStructOpt\inc\srv_queue.h
* Description : 
* Owner : Lews Hammond
* Time : 2019-6-4
************************************************************************************************************************
*/


#ifndef _SRV_QUEUE_H
#define _SRV_QUEUE_H

#include "platforms.h"


typedef enum _QUEUE_ERROR_T
{
	EN_QUEUE_OPT_OK = 0,
	EN_QUEUE_OPT_FULL,
	EN_QUEUE_OPT_EMPTY,
	EN_QUEUE_OPT_NONE
}srvQueueError_t;

typedef struct _SRV_QUEUE_T
{
	uint8_t frontInx;
	uint8_t rearInx;
	volatile uint8_t *qBuffer;
	uint8_t bufSize;
	uint8_t maxBufSize;
}srvQueue_t;

void Srv_QueueInit(volatile srvQueue_t *pQue, volatile uint8_t pBuf[], uint8_t bufSize);

srvQueueError_t Srv_QueueIn(volatile srvQueue_t *pQue, uint8_t dat);

srvQueueError_t Srv_QueueOut(volatile srvQueue_t *pQue, uint8_t *dat);

stdBoolean_t Srv_QueueIsEmpty(volatile srvQueue_t *pQue);

stdBoolean_t Srv_QueueIsFull(volatile srvQueue_t *pQue);

srvQueueError_t Srv_ReadQueueHead(volatile srvQueue_t *pQue, uint8_t *dat);

#endif

