/*
************************************************************************************************************************
* file : E:\KeilWorkspace\M3\uCOS_III_mdk5\ServicesLayer\osal\src\osal.c
* Description : 
* Owner : Lews Hammond
* Time : 2019-6-4
************************************************************************************************************************
*/


#include "osal.h"

#if (D_FILE_SYSTEM_ENABLE == D_STD_ON)
static fsDirAnaySta_t Fsal_AnaysisDir(const FSAL_CHAR *pDir, uint32_t dirLev, uint32_t len, FSAL_CHAR *pDest);
#endif

/*
************************************************************************************************************************
* uC OS III 
************************************************************************************************************************
*/
#if (D_UC_OS_III_ENABLE == D_STD_ON)

/*
************************************************************************************************************************
*                                               osal initial
*
* Description : osal inital.
*
* Arguments   : void.
*
* Returns     : void.
************************************************************************************************************************
*/
void Osal_OsInit(void)
{
    OS_ERR      err;

	Bsp_OsTickInit();
	
	OSInit(&err);
}

/*
************************************************************************************************************************
*                                               osal start task
*
* Description : uC/OS iii model initial.
*
* Arguments   : void.
*
* Returns     : void.
************************************************************************************************************************
*/
void Osal_StartTaskConfig(void)
{
	OS_ERR      err;
	
	CPU_Init();

    Mem_Init();                                                 /* Initialize Memory Management Module                  */

#if OS_CFG_STAT_TASK_EN > 0u
/* First Create Start Task. Must!!! */
/* if not create start task , then into hardfault. */
    OSStatTaskCPUUsageInit(&err);                               /* Compute CPU capacity with no task running            */
#endif
#ifdef  CPU_CFG_INT_DIS_MEAS_EN
    CPU_IntDisMeasMaxCurReset();
#endif
    
#if	OS_CFG_SCHED_ROUND_ROBIN_EN  
	OSSchedRoundRobinCfg(DEF_ENABLED,1,&err);  
#endif		
}


/*
************************************************************************************************************************
* Function Name    : Osal_TaskStkChk
* Description      : task stack useage check
* Input Arguments  : OSAL_TCB *tcb : , OSAL_CPU_STK_SIZE *free : , OSAL_CPU_STK_SIZE *used : 
* Output Arguments : vod
* Returns          : OSAL_BOOL: if check successful then return DEF_OK
* Notes            : 
* Owner            : Lews
* Time             : 2019-6-4
************************************************************************************************************************
*/

OSAL_BOOL Osal_TaskStkChk(OSAL_TCB *tcb, OSAL_CPU_STK_SIZE *free, OSAL_CPU_STK_SIZE *used)
{
	OSAL_ERROR err = (OSAL_ERROR)0;

	OSTaskStkChk((OSAL_TCB *)tcb,
				 (OSAL_CPU_STK_SIZE *)free,
				 (OSAL_CPU_STK_SIZE *)used,
				 (OSAL_ERROR *)&err
	);

	if (err != OS_ERR_NONE)
	{
		return DEF_FAIL;
	}

	return DEF_OK;
}

/*
************************************************************************************************************************
* Function Name    : Osal_TmrCreate
* Description      : Create software timer
* Input Arguments  : OSAL_TMR *pTmr, OSAL_CHAR *name, OSAL_TICK tick, OSAL_OPT opt, OSAL_TMR_CALLBACK_PTR callback
* Output Arguments : void
* Returns          : OSAL_BOOL : if operation successful then return DEF_OK
* Notes            : 
* Owner            : Lews
* Time             : 2019-6-4
************************************************************************************************************************
*/

OSAL_BOOL Osal_TmrCreate(OSAL_TMR *pTmr, OSAL_CHAR *name, OSAL_TICK tick, OSAL_OPT opt, OSAL_TMR_CALLBACK_PTR callback)
{
	OSAL_ERROR err = (OSAL_ERROR)0;

	OSTmrCreate((OSAL_TMR *)pTmr,
				(OSAL_CHAR *)name,
				(OSAL_TICK)0,
				(OSAL_TICK)tick,
				(OSAL_OPT)opt,
				(OSAL_TMR_CALLBACK_PTR)callback,
				(void *)0,
				(OSAL_ERROR *)&err
	);

	if (err != OS_ERR_NONE)
	{
		return DEF_FAIL;
	}

	return DEF_OK;
}

/*
************************************************************************************************************************
* Function Name    : Osal_TmrStart
* Description      : Start software timer
* Input Arguments  : OSAL_TMR *pTmr
* Output Arguments : void
* Returns          : OSAL_BOOL : if operation successful then return DEF_OK
* Notes            : 
* Owner            : Lews
* Time             : 2019-6-4
************************************************************************************************************************
*/

OSAL_BOOL Osal_TmrStart(OSAL_TMR *pTmr)
{
	OSAL_ERROR err = (OSAL_ERROR)0;

	OSTmrStart(pTmr, &err);

	if (err != OS_ERR_NONE)
	{
		return DEF_FAIL;
	}

	return DEF_OK;
}

/*
************************************************************************************************************************
* Function Name    : Osal_TmrStop
* Description      : Stop software timer
* Input Arguments  : OSAL_TMR *pTmr, OSAL_OPT opt
* Output Arguments : void
* Returns          : OSAL_BOOL : if operation successful then return DEF_OK
* Notes            : 
* Owner            : Lews
* Time             : 2019-6-4
************************************************************************************************************************
*/

OSAL_BOOL Osal_TmrStop(OSAL_TMR *pTmr, OSAL_OPT opt)
{
	OSAL_ERROR err = (OSAL_ERROR)0;

	OSTmrStop(pTmr, opt, (void *)0, &err);

	if (err != OS_ERR_NONE)
	{
		return DEF_FAIL;
	}

	return DEF_OK;
}

/*
************************************************************************************************************************
* Function Name    : Osal_SemCreate
* Description      : create sem
* Input Arguments  : OSAL_SEM *pSem, OSAL_SEM_CTR semVal, OSAL_CHAR *name
* Output Arguments : void
* Returns          : OSAL_BOOL : if operation successful then return DEF_OK
* Notes            : 
* Owner            : Lews
* Time             : 2019-6-4
************************************************************************************************************************
*/

OSAL_BOOL Osal_SemCreate(OSAL_SEM *pSem, OSAL_SEM_CTR semVal, OSAL_CHAR *name)
{
	OSAL_ERROR err = (OSAL_ERROR)0;
	
	OSSemCreate((OS_SEM    *)pSem,
                (CPU_CHAR  *)name,
                (OS_SEM_CTR )semVal,
                (OS_ERR    *)&err);

	if (err != OS_ERR_NONE)
	{
		return DEF_FAIL;
	}

	return DEF_OK;
}


/*
************************************************************************************************************************
* Function Name    : Osal_SemWait
* Description      : wait sem
* Input Arguments  : OSAL_SEM *pSem, OSAL_UINT32 ms
* Output Arguments : void
* Returns          : OSAL_BOOL : if operation successful then return DEF_OK
* Notes            : 
* Owner            : Lews
* Time             : 2019-6-4
************************************************************************************************************************
*/

OSAL_BOOL Osal_SemWait(OSAL_SEM *pSem, OSAL_UINT32 ms)
{
	OSAL_ERROR err = (OSAL_ERROR)0;
	OSAL_UINT32 tick = 0;

	tick = ((ms * DEF_TIME_NBR_mS_PER_SEC) / OSCfg_TickRate_Hz);

	OSSemPend((OS_SEM *)pSem,
              (OS_TICK )tick,
              (OS_OPT  )OS_OPT_PEND_BLOCKING,
              (CPU_TS  )0,
              (OS_ERR *)&err);

	if (err != OS_ERR_NONE)
	{
		return DEF_FAIL;
	}

	return DEF_OK;
}

/*
************************************************************************************************************************
* Function Name    : Osal_SemRead
* Description      : Read sem
* Input Arguments  : OSAL_SEM * pSem
* Output Arguments : void
* Returns          : OSAL_BOOL
* Notes            : 
* Owner            : Lews
* Time             : 2019-6-4
************************************************************************************************************************
*/

OSAL_BOOL Osal_SemRead(OSAL_SEM * pSem)
{
	OSAL_ERROR err = (OSAL_ERROR)0;

	OSSemPend((OS_SEM *)pSem,
              (OS_TICK )1,
              (OS_OPT  )OS_OPT_PEND_NON_BLOCKING,
              (CPU_TS  )0,
              (OS_ERR *)&err);

	if (err != OS_ERR_NONE)
	{
		return DEF_FAIL;
	}

	return DEF_OK;
}

/*
************************************************************************************************************************
* Function Name    : Osal_SemPost
* Description      : post sem
* Input Arguments  : OSAL_SEM *pSem
* Output Arguments : void
* Returns          : OSAL_BOOL
* Notes            : 
* Owner            : Lews
* Time             : 2019-6-4
************************************************************************************************************************
*/

OSAL_BOOL Osal_SemPost(OSAL_SEM *pSem)
{
	OSAL_ERROR err = (OSAL_ERROR)0;

	OSSemPost((OS_SEM *)pSem,
              (OS_OPT  )OS_OPT_POST_1,
              (OS_ERR *)&err);

	if (err != OS_ERR_NONE)
	{
		return DEF_FAIL;
	}

	return DEF_OK;
}

/*
************************************************************************************************************************
* Function Name    : Osal_SemSet
* Description      : set sem
* Input Arguments  : OSAL_SEM *pSem, OSAL_SEM_CTR cnt
* Output Arguments : void
* Returns          : OSAL_BOOL
* Notes            : 
* Owner            : Lews
* Time             : 2019-6-4
************************************************************************************************************************
*/

OSAL_BOOL Osal_SemSet(OSAL_SEM *pSem, OSAL_SEM_CTR cnt)
{
	OSAL_ERROR err = (OSAL_ERROR)0;

	OSSemSet((OS_SEM *)pSem,
			 (OS_SEM_CTR)cnt,
			 (OS_ERR *)err);

	if (err != OS_ERR_NONE)
	{
		return DEF_FAIL;
	}

	return DEF_OK;
}

/*
************************************************************************************************************************
*                                               os delay.
*
* Description : delay function. unit: ms.
*
* Arguments   : OSAL_UINT32 ms.	delay ms number.
*
* Returns     : void.
************************************************************************************************************************
*/
void Osal_DelayMs(OSAL_UINT32 ms)
{
	OSAL_UINT16 tMs = 0;
	OSAL_UINT32 tSec = 0;
	OSAL_ERROR tErr;
	
	if (ms > 10000u)
	{
		ms = 10000u;
	}
	
	if (ms >= 1000u)
	{
		tMs = ms % 1000u;
		tSec = ms / 1000u;
	}
	else
	{
		tSec = 0;
		tMs = ms;
	}
	
	OSTimeDlyHMSM(  (OSAL_UINT16) 0u,
				    (OSAL_UINT16) 0u,
					(OSAL_UINT16) tSec,
					(OSAL_UINT16) tMs,
					(OSAL_OPT)OS_OPT_TIME_HMSM_STRICT,
					(OSAL_ERROR *)&tErr					
	);
}

/*
************************************************************************************************************************
* Function Name    : Osal_GetCurTs
* Description      : get current timestamp
* Input Arguments  : void
* Output Arguments : void
* Returns          : uint32_t current timestamp
* Notes            : 
* Owner            : Lews
* Time             : 2019-6-4
************************************************************************************************************************
*/

uint32_t Osal_GetCurTs(void)
{
	return CPU_TS_TmrRd();
}


/*
************************************************************************************************************************
* Function Name    : Osal_DiffTsToUsec
* Description      : calculate different time
* Input Arguments  : uint32_t lastTs : last timestamp
* Output Arguments : void
* Returns          : uint32_t different time. unit:us
* Notes            : 
* Owner            : Lews
* Time             : 2019-6-4
************************************************************************************************************************
*/

uint32_t Osal_DiffTsToUsec(uint32_t lastTs)
{
	uint32_t curTs = Osal_GetCurTs();

	/* counter up */
	if (curTs > lastTs)
	{
		curTs = curTs - lastTs;
	}
	else
	{
		curTs = ((0xFFFFFFFFu - lastTs) + curTs) + 1;
	}
	
	return (uint32_t)CPU_TS32_to_uSec(curTs);
}
#else

/*
************************************************************************************************************************
* Function Name    : Osal_GetCurTs
* Description      : get current timestamp
* Input Arguments  : void
* Output Arguments : void
* Returns          : uint32_t current timestamp
* Notes            : 
* Owner            : Lews
* Time             : 2019-6-4
************************************************************************************************************************
*/

uint32_t Osal_GetCurTs(void)
{
	return Drv_GetDwtCnt();
}


/*
************************************************************************************************************************
* Function Name    : Osal_DiffTsToUsec
* Description      : calculate different time
* Input Arguments  : uint32_t lastTs : last timestamp
* Output Arguments : void
* Returns          : uint32_t different time. unit:us
* Notes            : 
* Owner            : Lews
* Time             : 2019-6-4
************************************************************************************************************************
*/

uint32_t Osal_DiffTsToUsec(uint32_t lastTs)
{
	uint32_t curTs = Osal_GetCurTs();
	uint64_t tUs = 0u;
	uint64_t tFreq = 0u;

	/* counter up */
	if (curTs > lastTs)
	{
		curTs = curTs - lastTs;
	}
	else
	{
		curTs = ((0xFFFFFFFFu - lastTs) + curTs) + 1;
	}

	tFreq = Drv_GetCpuFreq();
	tUs = curTs / (tFreq / 1000000u);

	return (uint32_t)tUs;
}


#endif

/*
************************************************************************************************************************
* FatFS
************************************************************************************************************************
*/
#if (D_FILE_SYSTEM_ENABLE == D_STD_ON)

/*
************************************************************************************************************************
* Function Name    : Fsal_AnaysisDir
* Description      : anaysis file dir
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-13
************************************************************************************************************************
*/

static fsDirAnaySta_t Fsal_AnaysisDir(const FSAL_CHAR *pDir, uint32_t dirLev, uint32_t len, FSAL_CHAR *pDest)
{
	uint32_t i = 0;
	uint32_t volcnt = 0;

	if ( len == 0 )
	{
		return EN_DIR_PARAMTER_ERR;
	}
	
	dirLev += 1;/* root dir is 0 */
	for (i = 0; i < len; i++)
	{
		if (*pDir == '/')
		{
			volcnt++;
			if (volcnt == dirLev)
			{
				break;
			}
		}
		*pDest = *pDir;
		pDest++;
		pDir++;
	}
	if ((i == len) && (pDir[len-1] != '/'))/* search all string finish. last dir not / */
	{
		volcnt++;
	}
	
	if (volcnt == dirLev)
	{
		return EN_DIR_ANAYSIS_OK;
	}
	else
	{
		return EN_DIR_NO_EXIST;
	}
}

/*
************************************************************************************************************************
* Function Name    : Fsal_MkDir
* Description      : create files dir
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-13
************************************************************************************************************************
*/

FSAL_FRES Fsal_MkDir(const FSAL_CHAR *pDir, uint32_t len)
{
	uint32_t i = 1;
	fsDirAnaySta_t anaySta = EN_DIR_ANAYSIS_OK;
	FSAL_CHAR pVol[D_FSAL_MAX_ANAYSIS_DIR_SIZE] = {0};
	FSAL_FRES mkRes = FR_OK;

	if (len > D_FSAL_MAX_ANAYSIS_DIR_SIZE)
	{
		return FR_INVALID_NAME;
	}
	
	do {
		anaySta = Fsal_AnaysisDir(pDir, i, len, pVol);
		if (anaySta == EN_DIR_ANAYSIS_OK)
		{
			i++;
			mkRes = f_mkdir(pVol);
			if ( (mkRes == FR_OK) || (mkRes == FR_EXIST) )
			{
				/* create successful */
			}
			else
			{
				return mkRes;
			}
		}
	}while (anaySta == EN_DIR_ANAYSIS_OK);

	return mkRes;
}

/*
************************************************************************************************************************
* Function Name    : Fsal_OpenW
* Description      : open file. if file isn`t exsit then create
* Input Arguments  : FSAL_FIL *pFil: file, const FSAL_CHAR *pPath, const FSAL_CHAR *pDir, uint32_t dirLen
* Output Arguments : 
* Returns          : FSAL_FRES: operation result
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-13
************************************************************************************************************************
*/

FSAL_FRES Fsal_OpenW(FSAL_FIL *pFil, const FSAL_CHAR *pPath, const FSAL_CHAR *pDir, uint32_t dirLen)
{
	FSAL_FRES res = FR_OK;

	res = f_open(pFil, pPath, FA_WRITE);/* try open */
	if (res != FR_OK)
	{
		res = f_open(pFil, pPath, FA_CREATE_ALWAYS | FA_WRITE);/* try create file and open */
		if (res != FR_OK)
		{
			res = Fsal_MkDir(pDir, dirLen);/* try create dir, create file and open */
			if (res == FR_OK)
			{
				res = f_open(pFil, pPath, FA_CREATE_ALWAYS | FA_WRITE);
			}
		}
	}

	return res;
}

/*
************************************************************************************************************************
* Function Name    : Fsal_OpenR
* Description      : read  file
* Input Arguments  : FSAL_FIL *pFil, const FSAL_CHAR *pCh
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-13
************************************************************************************************************************
*/

FSAL_FRES Fsal_OpenR(FSAL_FIL *pFil, const FSAL_CHAR *pCh)
{
	FSAL_FRES res = FR_OK;

	res = f_open(pFil, pCh, FA_READ);

	return res;
}

/*
************************************************************************************************************************
* Function Name    : Fsal_DiskGetfree
* Description      : calculate disk all free memory
* Input Arguments  : uint8_t *pdrv
* Output Arguments : uint32_t *total, uint32_t *free
* Returns          : FSAL_FRES
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-13
************************************************************************************************************************
*/

FSAL_FRES Fsal_DiskGetfree(uint8_t *pdrv, uint32_t *total, uint32_t *free)
{
	FSAL_FATFS *fs1 = NULL;
	FSAL_DWORD fre_clust=0;
	FSAL_DWORD fre_sect=0;
	FSAL_DWORD tot_sect=0;
	FSAL_FRES res = FR_OK;
	
	res = D_FSAL_GET_FREE((const TCHAR*)pdrv,&fre_clust,&fs1);
	
	tot_sect = (fs1->n_fatent-2) * fs1->csize;	//get all sector number
	fre_sect = fre_clust * fs1->csize;			//get free sector number
#if _MAX_SS!=512		//if sector isn`t 512 then covert 512 
	tot_sect *= fs1->ssize/512;
	fre_sect *= fs1->ssize/512;
#endif	  
	*total = tot_sect >> 1;	//unit: KB
	*free = fre_sect >> 1;	//unit: KB 

	return res;
}

/*
************************************************************************************************************************
* Function Name    : Fsal_Time2Str
* Description      : get system time convert to string
* Input Arguments  : 
* Output Arguments : FSAL_CHAR ch[]: 21 byte
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-13
************************************************************************************************************************
*/

void Fsal_Time2Str(FSAL_CHAR ch[])
{
	rtcTime_t time = {0};
	uint8_t cnt = 0;

	Hal_RtcGetTime(&time);
	ch[cnt] = '\n';//new line
	cnt++;
	/* year convert to string */
	ch[cnt] = (FSAL_CHAR)(((time.rtcYear / 1000) % 10) + '0');
	cnt++;
	ch[cnt] = (FSAL_CHAR)(((time.rtcYear / 100) % 10) + '0');
	cnt++;
	ch[cnt] = (FSAL_CHAR)(((time.rtcYear / 10) % 10) + '0');
	cnt++;
	ch[cnt] = (FSAL_CHAR)(((time.rtcYear / 1) % 10) + '0');
	cnt++;
	ch[cnt] = '-';
	cnt++;
	/* month convert to string */
	ch[cnt] = (FSAL_CHAR)(((time.rtcMon / 10) % 10) + '0');
	cnt++;
	ch[cnt] = (FSAL_CHAR)(((time.rtcMon / 1) % 10) + '0');
	cnt++;
	ch[cnt] = '-';
	cnt++;
	/* day convert to string */
	ch[cnt] = (FSAL_CHAR)(((time.rtcDay / 10) % 10) + '0');
	cnt++;
	ch[cnt] = (FSAL_CHAR)(((time.rtcDay / 1) % 10) + '0');
	cnt++;
	ch[cnt] = ' ';
	cnt++;
	/* hour convert to string */
	ch[cnt] = (FSAL_CHAR)(((time.rtcHour / 10) % 10) + '0');
	cnt++;
	ch[cnt] = (FSAL_CHAR)(((time.rtcHour / 1) % 10) + '0');
	cnt++;
	ch[cnt] = ':';
	cnt++;
	/* min convert to string */
	ch[cnt] = (FSAL_CHAR)(((time.rtcMin / 10) % 10) + '0');
	cnt++;
	ch[cnt] = (FSAL_CHAR)(((time.rtcMin / 1) % 10) + '0');
	cnt++;
	ch[cnt] = ':';
	cnt++;
	/* sec convert to string */
	ch[cnt] = (FSAL_CHAR)(((time.rtcSec / 10) % 10) + '0');
	cnt++;
	ch[cnt] = (FSAL_CHAR)(((time.rtcSec / 1) % 10) + '0');
	cnt++;
	ch[cnt] = '\0';
	cnt++;
}

#endif

