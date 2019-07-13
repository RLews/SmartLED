/*
************************************************************************************************************************
* file : hal_sd.h
* Description : 
* Author : Lews Hammond
* Time : 2019-6-12
************************************************************************************************************************
*/

#ifndef _HAL_SD_H
#define _HAL_SD_H

#include "hal_public.h"

/* sd card type */
#define D_SD_TYPE_ERR					0x00
#define D_SD_TYPE_MMC					0x01
#define D_SD_TYPE_V1					0x02
#define D_SD_TYPE_V2					0x04
#define D_SD_TYPE_V2HC					0x06



#define D_SD_CARD_SECTOR_SIZE			512
#define D_SD_CARD_CID_SIZE				16
#define D_SD_CARD_CSD_SIZE				16



#endif

