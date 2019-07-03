/*
************************************************************************************************************************
* file : E:\KeilWorkspace\M3\uCOS_III_mdk5\ServicesLayer\DataStructOpt\src\srv_queue.c
* Description : 
* Owner : Lews Hammond
* Time : 2019-6-4
************************************************************************************************************************
*/


#include "srv_queue.h"

/*
************************************************************************************************************************
*                                               queue initial
*
* Description : queue inital.
*
* Arguments   : volatile srvQueue_t *pQue.	queue data structure pointer.
*				volatile uint8_t pBuf[].	queue data buffer pointer.
*				uint8_t bufSize.			queue data buffer size.
*
* Returns     : void.
************************************************************************************************************************
*/
void Srv_QueueInit(volatile srvQueue_t *pQue, volatile uint8_t pBuf[], uint16_t bufSize)
{
	pQue->frontInx = 0;
	pQue->rearInx = 0;
	pQue->qBuffer = pBuf;
	pQue->bufSize = 0;
	pQue->maxBufSize = bufSize;
}

/*
************************************************************************************************************************
*                                               determine if the queue is emtry
*
* Description : determine if the queue is emtry.
*
* Arguments   : volatile srvQueue_t *pQue.	queue data structure pointer.
*
* Returns     : stdBoolean_t.				if the emtry then return true.
************************************************************************************************************************
*/
stdBoolean_t Srv_QueueIsEmpty(volatile srvQueue_t *pQue)
{
	stdBoolean_t isEmpty = EN_STD_FALSE;

	if (pQue->bufSize == 0)
	{
		isEmpty = EN_STD_TRUE;
	}

	return isEmpty;
}

/*
************************************************************************************************************************
*                                               determine if the queue is full
*
* Description : determine if the queue is full.
*
* Arguments   : volatile srvQueue_t *pQue.	queue data structure pointer.
*
* Returns     : stdBoolean_t.				if the full then return true.
************************************************************************************************************************
*/
stdBoolean_t Srv_QueueIsFull(volatile srvQueue_t *pQue)
{
	stdBoolean_t isFull = EN_STD_FALSE;

	if (pQue->bufSize == pQue->maxBufSize)
	{
		isFull = EN_STD_TRUE;
	}

	return isFull;
}

/*
************************************************************************************************************************
*                                               add one queue element
*
* Description : add one queue element.
*
* Arguments   : volatile srvQueue_t *pQue.	queue data structure pointer.
*				uint8_t dat.				need add data
*
* Returns     : stdBoolean_t.				operation reuslt.
************************************************************************************************************************
*/
srvQueueError_t Srv_QueueIn(volatile srvQueue_t *pQue, uint8_t dat)
{
	srvQueueError_t opt = EN_QUEUE_OPT_OK;

	if (pQue->bufSize < pQue->maxBufSize)
	{
		pQue->qBuffer[pQue->rearInx] = dat;
		pQue->bufSize++;
		pQue->rearInx++;
		if (pQue->rearInx >= pQue->maxBufSize)
		{
			pQue->rearInx = 0;
		}
	}
	else
	{
		opt = EN_QUEUE_OPT_FULL;
	}

	return opt;
}

/*
************************************************************************************************************************
*                                               out one queue element
*
* Description : out one queue element.
*
* Arguments   : volatile srvQueue_t *pQue.	queue data structure pointer.
*				uint8_t dat.				need out queue data
*
* Returns     : stdBoolean_t.				operation reuslt.
************************************************************************************************************************
*/
srvQueueError_t Srv_QueueOut(volatile srvQueue_t *pQue, uint8_t *dat)
{
	srvQueueError_t opt = EN_QUEUE_OPT_OK;

	if (pQue->bufSize != 0)
	{
		*dat = pQue->qBuffer[pQue->frontInx];
		pQue->frontInx++;
		pQue->bufSize--;
		if (pQue->frontInx >= pQue->maxBufSize)
		{
			pQue->frontInx = 0;
		}
	}
	else
	{
		opt = EN_QUEUE_OPT_EMPTY;
	}

	return opt;
}

/*
************************************************************************************************************************
*                                               read queue header element
*
* Description : read queue header element.
*
* Arguments   : volatile srvQueue_t *pQue.	queue data structure pointer.
*				uint8_t *dat.				read data pointer.
*
* Returns     : stdBoolean_t.				operation reuslt.
************************************************************************************************************************
*/
srvQueueError_t Srv_ReadQueueHead(volatile srvQueue_t *pQue, uint8_t *dat)
{
	srvQueueError_t opt = EN_QUEUE_OPT_OK;

	if (pQue->bufSize != 0)
	{
		*dat = pQue->qBuffer[pQue->frontInx];
	}
	else
	{
		opt = EN_QUEUE_OPT_EMPTY;
	}

	return opt;
}



