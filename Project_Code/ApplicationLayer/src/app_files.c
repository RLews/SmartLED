/*
************************************************************************************************************************
* file : app_files.c
* Description : run files system and usb
* Author : Lews Hammond
* Time : 2019-6-12
************************************************************************************************************************
*/

#include "app_files.h"

#if (D_FILE_SYSTEM_ENABLE == D_SYS_STD_ON)

/* file system task */
#define D_FILES_TASK_PRIO					4
#define D_FILES_TASK_STACK_SIZE				512
#define D_FILES_TASK_MAX_MSG_NUM			0
#define D_FILES_TASK_TICK					0
#define D_FILES_TASK_OPT					(D_OSAL_OPT_TASK_STK_CHK | D_OSAL_OPT_TASK_STK_CLR)

static OSAL_TCB fileTaskTCB = {0};
static OSAL_CPU_STACK fileTaskStack[D_FILES_TASK_STACK_SIZE] = {0};

static fileSysRunInfo_t fileSysRunInfo = {EN_SD_CARD_UNINITIAL, D_FILE_SYSTEM_NOT_ERROR};


static FSAL_FATFS filesDev[EN_ALL_DEVICE_TYPE] = {0};
static FSAL_FIL filesM[EN_ALL_DEVICE_TYPE] = {0};


static void FileSysHandle(void);
static FSAL_FRES StartUpWriteLog(void);
static void FileSystemInit(void);
static void WaitFileSysReady(void);
static void FaultRecordHandle(void);


/*
************************************************************************************************************************
* Function Name    : FilesTaskInit
* Description      : create file task
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-13
************************************************************************************************************************
*/

void FilesTaskInit(void)
{
	
	OSAL_ERROR tErr = (OSAL_ERROR)0;
	D_OSAL_ALLOC_CRITICAL_SR();
	
	FileSystemInit();

	D_OSAL_ENTER_CRITICAL();
	D_OSAL_CREATE_TASK_FUNC((OSAL_TCB *)&fileTaskTCB,
							(OSAL_CHAR *)"File_System_Task",
							(OSAL_TASK_FUNC_PTR)FileSysHandle,
							(void *)0,
							(OSAL_PRIO)D_FILES_TASK_PRIO,
							(OSAL_CPU_STACK *)&fileTaskStack[0],
							(OSAL_CPU_STK_SIZE)(D_FILES_TASK_STACK_SIZE / 10),
							(OSAL_CPU_STK_SIZE)D_FILES_TASK_STACK_SIZE,
							(OSAL_MSG_QTY)D_FILES_TASK_MAX_MSG_NUM,
							(OSAL_TICK)D_FILES_TASK_TICK,
							(void *)0,
							(OSAL_OPT)D_FILES_TASK_OPT,
							(OSAL_ERROR *)&tErr
	);
	D_OSAL_EXIT_CRITICAL();
}

/*
************************************************************************************************************************
* Function Name    : FileSystemInit
* Description      : files system initial
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-13
************************************************************************************************************************
*/

static void FileSystemInit(void)
{
	uint8_t i = 0;
	FSAL_FRES res = (FSAL_FRES)0;
	fileSysRunInfo_t *pInfo = &fileSysRunInfo;
	
	for (i = 0; i < D_APP_SD_CARD_INIT_MAX_TIME; i++)
	{
		pInfo->fileErrCode = (uint8_t)Hal_SDCardInit();
		if (pInfo->fileErrCode == EN_SD_OPT_OK)
		{
			pInfo->fileSta = EN_SD_CARD_INITIAL;
			break;
		}
	}
	
	res = D_FSAL_MOUNT(&filesDev[EN_SD_CARD_DEVICE], "0:/",D_FILE_SYS_IMMEDIATELY_MOUNT);
	if (res != FR_OK)
	{
		/* mount error */
		pInfo->fileErrCode = (uint8_t)res;
		pInfo->fileSta = EN_FILE_SYS_UNMOUNTED;
	}
	else
	{
		pInfo->fileErrCode = (uint8_t)res;
		pInfo->fileSta = EN_FILE_SYS_MOUNTED;
	}
}

/*
************************************************************************************************************************
* Function Name    : StartUpWriteLog
* Description      : system start up information write to log
* Input Arguments  : 
* Output Arguments : 
* Returns          : FSAL_FRES
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-13
************************************************************************************************************************
*/

static FSAL_FRES StartUpWriteLog(void)
{
	FSAL_FRES res = (FRESULT)0;
	FSAL_UINT bw = 0;
	FSAL_CHAR str[D_FSAL_TIME_STRING_SIZE] = {0};
	fileSysRunInfo_t *pInfo = &fileSysRunInfo;

	pInfo->fileSta = EN_FILE_SYS_RUNNING;
	pInfo->fileErrCode = D_FILE_SYSTEM_NOT_ERROR;

	Fsal_Time2Str(str);
	
	res = Fsal_OpenW(&filesM[EN_SD_CARD_DEVICE], D_FILE_SYS_RUN_LOG_PATH, D_FILE_SYS_RUN_LOG_DIR, sizeof(D_FILE_SYS_RUN_LOG_DIR));
	if (res != FR_OK)
	{
		return res;
	}

	res = D_FSAL_LSEEK(&filesM[EN_SD_CARD_DEVICE], (filesM[EN_SD_CARD_DEVICE].fptr + filesM[EN_SD_CARD_DEVICE].fsize));
	res = D_FSAL_WRITE(&filesM[EN_SD_CARD_DEVICE], str, D_FSAL_TIME_STRING_SIZE, &bw);
	res = D_FSAL_WRITE(&filesM[EN_SD_CARD_DEVICE], "\n\tSystem StartUp.\n", sizeof("\n\tSystem StartUp.\n"), &bw);
	
	res = D_FSAL_CLOSE(&filesM[EN_SD_CARD_DEVICE]);

	return res;
}


/*
************************************************************************************************************************
* Function Name    : FaultRecordHandle
* Description      : record system fault interrupt information
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-16
************************************************************************************************************************
*/

static void FaultRecordHandle(void)
{
	FSAL_CHAR str[D_FSAL_TIME_STRING_SIZE] = {0};
	FSAL_CHAR faultID[2] = "0";
	FSAL_FRES res = (FRESULT)0;
	FSAL_UINT bw = 0;
	
	Fsal_Time2Str(str);
	faultID[0] = (FSAL_CHAR)(Hal_GetCurIntID() + '0');

	res = Fsal_OpenW(&filesM[EN_SD_CARD_DEVICE], D_FILE_SYS_FAULT_LOG_PATH, D_FILE_SYS_FAULT_LOG_DIR, sizeof(D_FILE_SYS_FAULT_LOG_DIR));
	if (res != FR_OK)
	{
		return ;
	}

	res = D_FSAL_LSEEK(&filesM[EN_SD_CARD_DEVICE], (filesM[EN_SD_CARD_DEVICE].fptr + filesM[EN_SD_CARD_DEVICE].fsize));
	res = D_FSAL_WRITE(&filesM[EN_SD_CARD_DEVICE], str, D_FSAL_TIME_STRING_SIZE, &bw);
	res = D_FSAL_WRITE(&filesM[EN_SD_CARD_DEVICE], "\n\tSystem Fault, The Fault ID is: ", sizeof("\n\tSystem Fault, The Fault ID is: "), &bw);
	res = D_FSAL_WRITE(&filesM[EN_SD_CARD_DEVICE], faultID, 2, &bw);
	
	res = D_FSAL_CLOSE(&filesM[EN_SD_CARD_DEVICE]);
}

/*
************************************************************************************************************************
* Function Name    : WaitFileSysReady
* Description      : wait for file system ready
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-13
************************************************************************************************************************
*/

static void WaitFileSysReady(void)
{
	fileSysRunInfo_t *pInfo = &fileSysRunInfo;
	
	while (pInfo->fileSta != EN_FILE_SYS_MOUNTED)
	{
		Osal_DelayMs(20);
		FileSystemInit();
	}
}

/*
************************************************************************************************************************
* Function Name    : FileSysHandle
* Description      : file system main task
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-13
************************************************************************************************************************
*/

static void FileSysHandle(void)
{
	
	WaitFileSysReady();
	(void)StartUpWriteLog();
	Hal_SetFaultFunc(FaultRecordHandle);

	while (1)
	{
		Osal_DelayMs(100);
	}
}

#endif

