/*
************************************************************************************************************************
* file : E:\KeilWorkspace\M3\uCOS_III_mdk5\HardwareDriverLayer\inc\drv_sd.h
* Description : 
* Author : Lews Hammond
* Time : 2019-6-5
************************************************************************************************************************
*/


#ifndef _DRV_SD_H
#define _DRV_SD_H

#include "drv_public.h"




#define D_SD_CARD_BLOCK_SIZE			512

#define D_SD_CARD_DATA_START_TOKEN		0xFEu
#define D_SD_CARD_DATA_END_CMD			0xFDu


/* data write response define */
#define D_SD_MSD_DATA_OK				0x05
#define D_SD_MSD_DATA_CRC_ERR			0x0B
#define D_SD_MSD_DATA_WRITE_ERR			0x0D
#define D_SD_MSD_DATA_OTHER_ERR			0xFF


#endif

