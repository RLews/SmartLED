/*
************************************************************************************************************************
* file : E:\KeilWorkspace\M3\uCOS_III_mdk5\ServicesLayer\Communication\src\srv_comm.c
* Description : 
* Owner : Lews Hammond
* Time : 2019-6-4
************************************************************************************************************************
*/


#include "srv_comm.h"

#if (D_SRV_COMM_ENABLE == D_STD_ON)

static const commFrameConfig_t commFrameConfig[EN_COMM_ALL_NUM] = {
	D_COMM_FRAME_CONFIG
};

static commDecryptStep_t commDecryptStep = EN_COMM_STEP_FRAME_HEAD1;
static commFrameCntSta_t commFrameCntSta = EN_COMM_FRAME_COUNT_NOR;

static commFrameData_t commRevDat = {(commName_t)0};

static OSAL_SEM sysUartRxSem;

static void Srv_DecryptHeader1(void);
static void Srv_DecryptHeader2(void);
static void Srv_DecryptFrameCnt(void);
static void Srv_DecryptFrameLen(void);
static stdBoolean_t Srv_SearchRevID(uint8_t id);
static void Srv_DecryptFrameID(void);
static void Srv_DecryptFrameData(void);
static void Srv_DecryptCrc1(void);
static void Srv_DecryptCrc2(void);

static void Srv_RevDataHandle(void);
static void Srv_CommRxSemPost(void);


static const Srv_DecryptFunc_t Srv_DecryptFun[EN_COMM_DECRYPT_ALL_STEP] = {
	Srv_DecryptHeader1,
	Srv_DecryptHeader2,
	Srv_DecryptFrameCnt,
	Srv_DecryptFrameLen,
	Srv_DecryptFrameID,
	Srv_DecryptFrameData,
	Srv_DecryptCrc1,
	Srv_DecryptCrc2
};

/*
************************************************************************************************************************
* Function Name    : Srv_SysCommInit
* Description      : Comm services initial
* Input Arguments  : void
* Output Arguments : void
* Returns          : void
* Notes            : 
* Owner            : Lews
* Time             : 2019-6-4
************************************************************************************************************************
*/

void Srv_SysCommInit(void)
{
	D_OSAL_ALLOC_CRITICAL_SR();
	
	Osal_SemCreate(&sysUartRxSem, 0, "SYS_UART_RX");
	D_OSAL_ENTER_CRITICAL();
	Hal_SetSysRxSemPostFunc(Srv_CommRxSemPost);
	D_OSAL_EXIT_CRITICAL();
}

/*
************************************************************************************************************************
* Function Name    : Srv_DecryptHeader1
* Description      : Decrypt communication header
* Input Arguments  : void
* Output Arguments : void
* Returns          : void
* Notes            : 
* Owner            : Lews
* Time             : 2019-6-4
************************************************************************************************************************
*/

static void Srv_DecryptHeader1(void)
{
	uint8_t data = 0;
	commDecryptStep_t *pStep = &commDecryptStep;

	if (EN_QUEUE_OPT_OK == Hal_UartReadByte(EN_SYS_COM, &data))
	{
		if (data == D_COMM_FRAME_HEAD1)
		{
			*pStep = EN_COMM_STEP_FRAME_HEAD2;
		}
	}
}

/*
************************************************************************************************************************
* Function Name    : Srv_DecryptHeader2
* Description      : Decrypt communication header
* Input Arguments  : void
* Output Arguments : void
* Returns          : void
* Notes            : 
* Owner            : Lews
* Time             : 2019-6-4
************************************************************************************************************************
*/

static void Srv_DecryptHeader2(void)
{
	uint8_t data = 0;
	commDecryptStep_t *pStep = &commDecryptStep;
	
	if (EN_QUEUE_OPT_OK == Hal_UartReadByte(EN_SYS_COM, &data))
	{
		if (data == D_COMM_FRAME_HEAD2)
		{
			*pStep = EN_COMM_STEP_FRAME_CNT;
		}
		else if (data == D_COMM_FRAME_HEAD1)
		{
			/* do nothing */
		}
		else 
		{
			*pStep = EN_COMM_STEP_FRAME_HEAD1;
		}
	}
}

/*
************************************************************************************************************************
* Function Name    : Srv_DecryptFrameCnt
* Description      : Decrypt frame counter
* Input Arguments  : void
* Output Arguments : void
* Returns          : void
* Notes            : 
* Owner            : Lews
* Time             : 2019-6-4
************************************************************************************************************************
*/

static void Srv_DecryptFrameCnt(void)
{
	uint8_t data = 0;
	commDecryptStep_t *pStep = &commDecryptStep;
	commFrameCntSta_t *pCntSta = &commFrameCntSta;
	static uint8_t frameCntBak = 0xFF;

	if (EN_QUEUE_OPT_OK == Hal_UartReadByte(EN_SYS_COM, &data))
	{
		if (frameCntBak == 0xFF)
		{
			frameCntBak = data;
		}
		else
		{
			frameCntBak++;
			if (frameCntBak >= D_COMM_COUNT_MAX_VAL)
			{
				frameCntBak = 0;
			}
			if (frameCntBak != data)
			{
				*pCntSta = EN_COMM_FRAME_COUNT_ERR;
			}
		}

		*pStep = EN_COMM_STEP_FRAME_LEN;
	}
}

/*
************************************************************************************************************************
* Function Name    : Srv_CommFrameCntSta
* Description      : Get Frame Counter Status
* Input Arguments  : void
* Output Arguments : void
* Returns          : commFrameCntSta_t
* Notes            : 
* Owner            : Lews
* Time             : 2019-6-4
************************************************************************************************************************
*/

commFrameCntSta_t Srv_CommFrameCntSta(void)
{
	return commFrameCntSta;
}

/*
************************************************************************************************************************
* Function Name    : Srv_DecryptFrameLen
* Description      : Decrypt frame length
* Input Arguments  : void
* Output Arguments : void
* Returns          : void
* Notes            : 
* Owner            : Lews
* Time             : 2019-6-4
************************************************************************************************************************
*/

static void Srv_DecryptFrameLen(void)
{
	uint8_t data = 0;
	commDecryptStep_t *pStep = &commDecryptStep;

	if (EN_QUEUE_OPT_OK == Hal_UartReadByte(EN_SYS_COM, &data))
	{
		commRevDat.Len = data;
		*pStep = EN_COMM_STEP_FRAME_ID;
	}
}

/*
************************************************************************************************************************
* Function Name    : Srv_SearchRevID
* Description      : search receiver id
* Input Arguments  : uint8_t id : search id
* Output Arguments : void
* Returns          : stdBoolean_t 
* Notes            : 
* Owner            : Lews
* Time             : 2019-6-4
************************************************************************************************************************
*/

static stdBoolean_t Srv_SearchRevID(uint8_t id)
{
	const commFrameConfig_t *pConfig = commFrameConfig;
	uint8_t i = 0;
	stdBoolean_t res = EN_STD_FALSE;
	
	for (i = 0; i < EN_COMM_ALL_NUM; i++)
	{
		if ((pConfig[i].isTx == EN_STD_FALSE) && (pConfig[i].id == id))
		{
			commRevDat.frameName = (commName_t)i;
			res = EN_STD_TRUE;
			break;
		}
	}

	return res;
}

/*
************************************************************************************************************************
* Function Name    : Srv_DecryptFrameID
* Description      : Decrypt frame id
* Input Arguments  : void
* Output Arguments : void
* Returns          : void
* Notes            : 
* Owner            : Lews
* Time             : 2019-6-4
************************************************************************************************************************
*/

static void Srv_DecryptFrameID(void)
{
	uint8_t data = 0;
	commDecryptStep_t *pStep = &commDecryptStep;
	
	if (EN_QUEUE_OPT_OK == Hal_UartReadByte(EN_SYS_COM, &data))
	{
		if (Srv_SearchRevID(data) == EN_STD_TRUE)
		{
			commRevDat.id = data;
			*pStep = EN_COMM_STEP_FRAME_DATA;
		}
		else
		{
			*pStep = EN_COMM_STEP_FRAME_HEAD1;
		}
	}
}

/*
************************************************************************************************************************
* Function Name    : Srv_DecryptFrameData
* Description      : Decrypt frame data
* Input Arguments  : void
* Output Arguments : void
* Returns          : void
* Notes            : 
* Owner            : Lews
* Time             : 2019-6-4
************************************************************************************************************************
*/

static void Srv_DecryptFrameData(void)
{
	uint8_t data = 0;
	commDecryptStep_t *pStep = &commDecryptStep;
	commFrameData_t *pDat = &commRevDat;
	static uint16_t len = 0;

	if (EN_QUEUE_OPT_OK == Hal_UartReadByte(EN_SYS_COM, &data))
	{
		pDat->data[len] = data;
		len++;
		if (len >= (pDat->Len - 1))/* remove id length */
		{
			*pStep = EN_COMM_STEP_FRAME_CHK1;
			len = 0;
		}
	}
}

/*
************************************************************************************************************************
* Function Name    : Srv_DecryptCrc1
* Description      : Decrypt 16bit CRC
* Input Arguments  : void
* Output Arguments : void
* Returns          : void
* Notes            : 
* Owner            : Lews
* Time             : 2019-6-4
************************************************************************************************************************
*/

static void Srv_DecryptCrc1(void)
{
	uint8_t data = 0;
	commDecryptStep_t *pStep = &commDecryptStep;

	if (EN_QUEUE_OPT_OK == Hal_UartReadByte(EN_SYS_COM, &data))
	{
		commRevDat.crc16 = data;
		*pStep = EN_COMM_STEP_FRAME_CHK2;
	}
	
}

/*
************************************************************************************************************************
* Function Name    : Srv_DecryptCrc2
* Description      : Decrypt 16bit CRC
* Input Arguments  : void
* Output Arguments : void
* Returns          : void
* Notes            : 
* Owner            : Lews
* Time             : 2019-6-4
************************************************************************************************************************
*/

static void Srv_DecryptCrc2(void)
{
	uint8_t data = 0;
	commDecryptStep_t *pStep = &commDecryptStep;
	commFrameData_t *pDat = &commRevDat;
	uint16_t crc = 0;

	if (EN_QUEUE_OPT_OK == Hal_UartReadByte(EN_SYS_COM, &data))
	{
		pDat->crc16 <<= 8;
		pDat->crc16 |= data;
		crc = Srv_CommCrc16Tbl(D_COMM_CRC_SEED, pDat->data, (pDat->Len-1));
		if (crc == pDat->crc16)
		{
			/* report others layer */
			Srv_RevDataHandle();
		}
		*pStep = EN_COMM_STEP_FRAME_HEAD1;
	}
}

/*
************************************************************************************************************************
* Function Name    : Srv_SysCommDecrypt
* Description      : communication services
* Input Arguments  : void
* Output Arguments : void
* Returns          : void
* Notes            : 
* Owner            : Lews
* Time             : 2019-6-4
************************************************************************************************************************
*/

void Srv_SysCommDecrypt(void)
{
	static uint32_t commStartTs = 0;
	uint32_t commIntervalUs = 0;

	commStartTs = Osal_GetCurTs();
	
	Osal_SemWait(&sysUartRxSem, 0);/* wait sem */
	
	commIntervalUs = Osal_DiffTsToUsec(commStartTs);
	if (commIntervalUs > D_COMM_REV_TIMEOUT)/* receiver time out. */
	{
		commDecryptStep = EN_COMM_STEP_FRAME_HEAD1;
	}
	
	if (commDecryptStep < EN_COMM_DECRYPT_ALL_STEP)
	{
		(Srv_DecryptFun[commDecryptStep])();
	}
}

/*
************************************************************************************************************************
* Function Name    : Srv_CommRxSemPost
* Description      : rx indication sem post
* Input Arguments  : void
* Output Arguments : void
* Returns          : void
* Notes            : 
* Owner            : Lews
* Time             : 2019-6-4
************************************************************************************************************************
*/

static void Srv_CommRxSemPost(void)
{
	Osal_SemPost(&sysUartRxSem);
}

/*
************************************************************************************************************************
* Function Name    : Srv_RevDataHandle
* Description      : receiver data report handle
* Input Arguments  : void
* Output Arguments : void
* Returns          : void
* Notes            : 
* Owner            : Lews
* Time             : 2019-6-4
************************************************************************************************************************
*/

static void Srv_RevDataHandle(void)
{
	commFrameData_t *pDat = &commRevDat;
	const commFrameConfig_t *pConfig = commFrameConfig;

	switch (pConfig[pDat->frameName].dataType)
	{
		case EN_COMM_APP_MSG:
			
			break;
			
		case EN_COMM_DSG_MSG:
		#if (D_SRV_UDS_ENABLE == D_STD_ON)
			UdsCan_LData_RxIndication(pDat->id, pDat->data[D_COMM_TYPE_OR_CMD_DLC_INDEX], &pDat->data[D_COMM_DATA_INDEX]);
		#endif
			break;
			
		case EN_COMM_NM_MSG:
			break;
			
		default:
			break;
	}
}

/*
************************************************************************************************************************
* Function Name    : Srv_SysCommTransmit
* Description      : trasmit data
* Input Arguments  : uint8_t id : frame id, const uint8_t dat[] : data buffer, uint16_t len : data length
* Output Arguments : void
* Returns          : void
* Notes            : 
* Owner            : Lews
* Time             : 2019-6-4
************************************************************************************************************************
*/

void Srv_SysCommTransmit(uint8_t id, const uint8_t dat[], uint16_t len)
{
	static uint8_t transCount = 0;
	uint16_t i = 0;
	uint8_t buff[D_COMM_BUFFER_SIZE + 7] = {0};
	uint16_t buffInx = 0;
	uint16_t crc16 = 0;
	
	if ((len == 0) || (len >= D_COMM_BUFFER_SIZE))
	{
		return ;
	}

	buff[buffInx] = D_COMM_FRAME_HEAD1;
	buffInx++;
	buff[buffInx] = D_COMM_FRAME_HEAD2;
	buffInx++;
	buff[buffInx] = transCount;
	buffInx++;
	buff[buffInx] = len + 1;
	buffInx++;
	buff[buffInx] = id;
	buffInx++;
	
	for (i = 0; i < len; i++)
	{
		buff[buffInx] = dat[i];
		buffInx++;
	}
	
	crc16 = Srv_CommCrc16Tbl(D_COMM_CRC_SEED, &buff[5], len);

	buff[buffInx] = (uint8_t)(crc16 >> 8);
	buffInx++;
	buff[buffInx] = (uint8_t)crc16;
	buffInx++;

	(void)Hal_UartWrite(EN_SYS_COM, buff, buffInx);

	transCount++;
	if (transCount >= D_COMM_COUNT_MAX_VAL)
	{
		transCount = 0;
	}
}


/*
************************************************************************************************************************
* Function Name    : UdsCan_LData_TxRequest
* Description      : uds data link layer transmit request
* Input Arguments  : uint32_t msgId : can id, uint8_t numBytes : message length, uint8_t *pBytes : data pointer
* Output Arguments : void
* Returns          : void
* Notes            : 
* Owner            : Lews
* Time             : 2019-6-4
************************************************************************************************************************
*/

/* TODO */
void UdsCan_LData_TxRequest( uint32_t msgId, uint8_t numBytes, uint8_t* pBytes )
{
#if (D_SRV_UDS_ENABLE == D_STD_ON)
	uint8_t buf[D_COMM_UDS_FRAME_MAX_SIZE + 1] = {0};
	uint8_t cnt = 0;
	uint8_t i = 0;

	if (numBytes > D_COMM_UDS_FRAME_MAX_SIZE)
	{
		return;
	}
	
	buf[cnt] = numBytes;
	cnt++;
	for (i = 0; i < numBytes; i++)
	{
		buf[cnt] = *pBytes;
		cnt++;
		pBytes++;
	}
	
	Srv_SysCommTransmit(msgId, buf, cnt);

	UdsCan_LData_TxConfirmation( msgId, 0x00 );
	
#endif
}

#endif

