/**
************************************************************
* @file         gizwits_product.c
* @brief        Gizwits control protocol processing, and platform-related       hardware initialization 
* @author       Gizwits
* @date         2017-07-19
* @version      V03030000
* @copyright    Gizwits
* 
* @note         机智�?只为智能硬件而生
*               Gizwits Smart Cloud  for Smart Products
*               链接|增值ֵ|开放|中立|安全|自有|自由|生�?*               www.gizwits.com
*
***********************************************************/

#include <stdio.h>
#include <string.h>
#include "hal_key.h"
#include "gizwits_product.h"
#include "common.h"

static uint32_t timerMsCount;
static uint8_t wifiConnectSta = D_STD_OFF;

/** User area the current device state structure*/
dataPoint_t currentDataPoint;


/**@} */
/**@name Gizwits User Interface
* @{
*/

/**
* @brief Event handling interface

* Description:

* 1. Users can customize the changes in WiFi module status

* 2. Users can add data points in the function of event processing logic, such as calling the relevant hardware peripherals operating interface

* @param [in] info: event queue
* @param [in] data: protocol data
* @param [in] len: protocol data length
* @return NULL
* @ref gizwits_protocol.h
*/
int8_t gizwitsEventProcess(eventInfo_t *info, uint8_t *gizdata, uint32_t len)
{
  uint8_t i = 0;
  dataPoint_t *dataPointPtr = (dataPoint_t *)gizdata;
  moduleStatusInfo_t *wifiData = (moduleStatusInfo_t *)gizdata;
  protocolTime_t *ptime = (protocolTime_t *)gizdata;
  rtcTime_t setTime = {0};
  
#if MODULE_TYPE
  gprsInfo_t *gprsInfoData = (gprsInfo_t *)gizdata;
#else
  moduleInfo_t *ptModuleInfo = (moduleInfo_t *)gizdata;
#endif

  if((NULL == info) || (NULL == gizdata))
  {
    return -1;
  }

  for(i=0; i<info->num; i++)
  {
    switch(info->event[i])
    {
      case EVENT_Led_WarmSta:
        currentDataPoint.valueLed_WarmSta = dataPointPtr->valueLed_WarmSta;
        GIZWITS_LOG("Evt: EVENT_Led_WarmSta %d \n", currentDataPoint.valueLed_WarmSta);
        if(0x01 == currentDataPoint.valueLed_WarmSta)
        {
          //user handle
          Led_WarmOn();
        }
        else
        {
          //user handle  
          Led_WarmOff();
        }
        break;
      case EVENT_LedOnOff:
        currentDataPoint.valueLedOnOff = dataPointPtr->valueLedOnOff;
        GIZWITS_LOG("Evt: EVENT_LedOnOff %d \n", currentDataPoint.valueLedOnOff);
        if(0x01 == currentDataPoint.valueLedOnOff)
        {
          //user handle
          Led_ModeCycling();
        }
        else
        {
          //user handle
          Led_AllOff();
        }
        break;

		/* RGB value setting */
      case EVENT_Led_RVal:
        currentDataPoint.valueLed_RVal = dataPointPtr->valueLed_RVal;
        GIZWITS_LOG("Evt:EVENT_Led_RVal %d\n",currentDataPoint.valueLed_RVal);
        //user handle
        //break;
      case EVENT_Led_GVal:
        currentDataPoint.valueLed_GVal = dataPointPtr->valueLed_GVal;
        GIZWITS_LOG("Evt:EVENT_Led_GVal %d\n",currentDataPoint.valueLed_GVal);
        //user handle
        //break;
      case EVENT_Led_BVal:
        currentDataPoint.valueLed_BVal = dataPointPtr->valueLed_BVal;
        GIZWITS_LOG("Evt:EVENT_Led_BVal %d\n",currentDataPoint.valueLed_BVal);
        //user handle
        Led_SetRGBDat((uint16_t)dataPointPtr->valueLed_RVal, 
        			  (uint16_t)dataPointPtr->valueLed_GVal, 
        			  (uint16_t)dataPointPtr->valueLed_BVal);
        break;
      case EVENT_Led_Brightness:
        currentDataPoint.valueLed_Brightness = dataPointPtr->valueLed_Brightness;
        GIZWITS_LOG("Evt:EVENT_Led_Brightness %d\n",currentDataPoint.valueLed_Brightness);
        //user handle
        Led_SetWarmDat((uint16_t)dataPointPtr->valueLed_Brightness);
        break;


      case WIFI_SOFTAP:
        break;
      case WIFI_AIRLINK:
        break;
      case WIFI_STATION:
        break;
      case WIFI_CON_ROUTER:
 
        break;
      case WIFI_DISCON_ROUTER:
 
        break;
      case WIFI_CON_M2M:
 		wifiConnectSta = D_STD_ON;
        break;
      case WIFI_DISCON_M2M:
        wifiConnectSta = D_STD_OFF;
        break;
      case WIFI_RSSI:
        GIZWITS_LOG("RSSI %d\n", wifiData->rssi);
        break;
      case TRANSPARENT_DATA:
        GIZWITS_LOG("TRANSPARENT_DATA \n");
        //user handle , Fetch data from [data] , size is [len]
        break;
      case WIFI_NTP:
        GIZWITS_LOG("WIFI_NTP : [%d-%d-%d %02d:%02d:%02d][%d] \n",ptime->year,ptime->month,ptime->day,ptime->hour,ptime->minute,ptime->second,ptime->ntp);
		setTime.rtcYear = ptime->year;
		setTime.rtcMon = ptime->month;
		setTime.rtcDay = ptime->day;
		setTime.rtcHour = ptime->hour;
		setTime.rtcMin = ptime->minute;
		setTime.rtcSec = ptime->second;
        Hal_RtcSetTime(setTime);
        break;
      case MODULE_INFO:
            GIZWITS_LOG("MODULE INFO ...\n");
      #if MODULE_TYPE
            GIZWITS_LOG("GPRS MODULE ...\n");
            //Format By gprsInfo_t
      #else
            GIZWITS_LOG("WIF MODULE ...\n");
            //Format By moduleInfo_t
            GIZWITS_LOG("moduleType : [%d] \n",ptModuleInfo->moduleType);
      #endif
    break;
      default:
        break;
    }
  }

  return 0;
}

/**
* User data acquisition

* Here users need to achieve in addition to data points other than the collection of data collection, can be self-defined acquisition frequency and design data filtering algorithm

* @param none
* @return none
*/
void userHandle(void)
{
	/* TODO: user data report */
	
}

/**
* Data point initialization function

* In the function to complete the initial user-related data
* @param none
* @return none
* @note The developer can add a data point state initialization value within this function
*/
void userInit(void)
{
    memset((uint8_t*)&currentDataPoint, 0, sizeof(dataPoint_t));
    
    /** Warning !!! DataPoint Variables Init , Must Within The Data Range **/ 
    /*
      currentDataPoint.valueLed_WarmSta = ;
      currentDataPoint.valueLedOnOff = ;
      currentDataPoint.valueLed_RVal = ;
      currentDataPoint.valueLed_GVal = ;
      currentDataPoint.valueLed_BVal = ;
      currentDataPoint.valueLed_Brightness = ;
    */

}


/**
* @brief Millisecond timing maintenance function, milliseconds increment, overflow to zero

* @param none
* @return none
*/
void gizTimerMs(void)
{
    timerMsCount++;
}

/**
* @brief Read millisecond count

* @param none
* @return millisecond count
*/
uint32_t gizGetTimerCount(void)
{
    return timerMsCount;
}

/**
* @brief MCU reset function

* @param none
* @return none
*/
void mcuRestart(void)
{
    __set_FAULTMASK(1);
    
    while (1)
    {
		
    }
}






/**
* @brief Serial port write operation, send data to WiFi module
*
* @param buf      : buf address
* @param len      : buf length
*
* @return : Return effective data length;-1，return failure
*/
int32_t uartWrite(uint8_t *buf, uint32_t len)
{
	uint8_t crc[1] = {0x55};
    uint32_t i = 0;
	
    if(NULL == buf)
    {
        return -1;
    }

    for(i=0; i<len; i++)
    {
        (void)Srv_WifiCommTx((uint8_t *)&buf[i], 1);

        if(i >=2 && buf[i] == 0xFF)
        {
			(void)Srv_WifiCommTx((uint8_t *)&crc, 1);
        }
    }

#ifdef PROTOCOL_DEBUG
    GIZWITS_LOG("MCU2WiFi[%4d:%4d]: ", gizGetTimerCount(), len);
    for(i=0; i<len; i++)
    {
        GIZWITS_LOG("%02x ", buf[i]);

        if(i >=2 && buf[i] == 0xFF)
        {
            GIZWITS_LOG("%02x ", 0x55);
        }
    }
    GIZWITS_LOG("\n");
#endif
		
		return len;
}  

/*
************************************************************************************************************************
* Function Name    : Wifi_GetConnectSta
* Description      : 
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-7-13
************************************************************************************************************************
*/

uint8_t Wifi_GetConnectSta(void)
{
	return wifiConnectSta;
}

/*
************************************************************************************************************************
* Function Name    : Bsp_GizPrintf
* Description      : gizwits log printf
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : this function is null. 
* Author           : Lews Hammond
* Time             : 2019-7-13
************************************************************************************************************************
*/

void Bsp_GizPrintf(char *format, ...)
{
	
}

