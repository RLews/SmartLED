/*
************************************************************************************************************************
* file : E:\KeilWorkspace\M3\uCOS_III_mdk5\ApplicationLayer\inc\app_comm.h
* Description : 
* Owner : Lews Hammond
* Time : 2019-6-4
************************************************************************************************************************
*/


#ifndef __APP_COMM_H
#define __APP_COMM_H

#include "app_public.h"

#if (D_SRV_UDS_ENABLE == D_SYS_STD_ON)
#include "udstp_conf.h"
#include "uds_conf.h"
#include "uds_pub.h"
#endif


#define D_COMM_TASK_STACK_DEBUG			D_SYS_STD_OFF

#define D_COMM_TIMER_FLAG_INIT			(0)



#endif

