/*
************************************************************************************************************************
* file : hal_key.c
* Description : 
* Author : Lews Hammond
* Time : 2019-6-18
************************************************************************************************************************
*/

#include "hal_key.h"

static keyManage_t keyManage[EN_KEY_ALL_TYPE] = {(stdBoolean_t)0};
static keyShake_t keyShake = {0};

static void Hal_KeyStateManage(uint8_t id);


/*
************************************************************************************************************************
* Function Name    : Hal_KeyScan
* Description      : key scanf
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : period schedule
* Author           : Lews Hammond
* Time             : 2019-6-18
************************************************************************************************************************
*/

void Hal_KeyScan(void)
{
	uint8_t i = 0;
	gpioName_t ioName = (gpioName_t)0;
	keyShake_t *pShake = &keyShake;

	for (i = 0; i < EN_KEY_ALL_TYPE; i++)
	{
		ioName = (gpioName_t)(i + EN_WIFI_KEY_IO);
		if (Drv_GpioNameIn(ioName) == EN_GPIO_LOW)
		{
			if (pShake->shakeBuf[i] < 255)
			{
				pShake->shakeBuf[i]++;
			}
		}
		else
		{
			pShake->shakeBuf[i] = 0;
		}
		Hal_KeyStateManage(i);
	}
}

#if (D_ENABLE_KEY_DOUBLE_PRESS == D_SYS_STD_ON)
/*
************************************************************************************************************************
* Function Name    : Hal_KeyStateManage
* Description      : key state switch . support double press. 
* Input Arguments  : uint8_t id: key identifier
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-18
************************************************************************************************************************
*/

static void Hal_KeyStateManage(uint8_t id)
{
	keyShake_t *pShake = &keyShake;
	keyManage_t *pKey = keyManage;
	
	switch (pKey[id].keySta)
	{
		case EN_KEY_NONE:
			if (pShake->shakeBuf[id] >= D_KEY_PRESS_SHAKE_TIME)
			{
				pKey[id].keySta = EN_KEY_PRESS_DOWN;
				pShake->keyPrsTim[id] = Osal_GetCurTs();
			}
			break;
			
		case EN_KEY_PRESS_DOWN:
			if (pShake->shakeBuf[id] == 0)//release
			{
				pKey[id].keySta = EN_KEY_WAIT_PRESS_UP;
				pShake->keyPrsTim[id] = Osal_GetCurTs();
			}
			if (Osal_DiffTsToUsec(pShake->keyPrsTim[id]) >= D_KEY_REPEAT_TIME)
			{
				pKey[id].keySta = EN_KEY_REPEAT;
				pKey[id].newKeyFlg = EN_STD_TRUE;
			}
			break;
			
		case EN_KEY_WAIT_PRESS_UP:
			if (Osal_DiffTsToUsec(pShake->keyPrsTim[id]) >= D_KEY_DOUBLE_PRESS_TIME)
			{
				pKey[id].keySta = EN_KEY_PRESS_UP;
				pKey[id].newKeyFlg = EN_STD_TRUE;
			}
			if ((pShake->dblKeyLock[id] == EN_STD_FALSE) && (pShake->shakeBuf[id] >= D_KEY_PRESS_SHAKE_TIME))
			{
				pKey[id].keySta = EN_KEY_DOUBLE_PRESS;
			}
			break;
			
		case EN_KEY_PRESS_UP:
			if (pKey[id].newKeyFlg == EN_STD_FALSE)//up leyer handle completed
			{
				pKey[id].keySta = EN_KEY_NONE;
			}
			break;
			
		case EN_KEY_REPEAT:
			if (pShake->shakeBuf[id] == 0)//release
			{
				pKey[id].keySta = EN_KEY_NONE;//repeat none double press
			}
			break;
			
		case EN_KEY_DOUBLE_PRESS:			
			if (pShake->shakeBuf[id] == 0)//release
			{
				pKey[id].keySta = EN_KEY_DOUBLE_PRESS_UP;
				pKey[id].newKeyFlg = EN_STD_TRUE;
			}
			break;

		case EN_KEY_DOUBLE_PRESS_UP:
			if (pKey[id].newKeyFlg == EN_STD_FALSE)//up leyer handle completed
			{
				pKey[id].keySta = EN_KEY_NONE;
				pShake->dblKeyLock[id] = EN_STD_TRUE;
				pShake->keydblPrsTim[id] = Osal_GetCurTs();
			}
			break;
		
		default:
			break;
	}

	if ( (pShake->dblKeyLock[id] == EN_STD_TRUE) 
	  && (Osal_DiffTsToUsec(pShake->keydblPrsTim[id]) >= D_KEY_DOUBLE_PRESS_SPACE_TIME) )
	{
		pShake->dblKeyLock[id] = EN_STD_FALSE;
	}
}
#else

/*
************************************************************************************************************************
* Function Name    : Hal_KeyStateManage
* Description      : key state switch .  
* Input Arguments  : uint8_t id: key identifier
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-18
************************************************************************************************************************
*/

static void Hal_KeyStateManage(uint8_t id)
{
	keyShake_t *pShake = &keyShake;
	keyManage_t *pKey = keyManage;

	switch (pKey[id].keySta)
	{
		case EN_KEY_NONE:
			if (pShake->shakeBuf[id] >= D_KEY_PRESS_SHAKE_TIME)
			{
				pKey[id].keySta = EN_KEY_PRESS_DOWN;
				pShake->keyPrsTim[id] = Osal_GetCurTs();
			}
			break;
			
		case EN_KEY_PRESS_DOWN:
			if (pShake->shakeBuf[id] == 0)//release
			{
				pKey[id].keySta = EN_KEY_PRESS_UP;
				pKey[id].newKeyFlg = EN_STD_TRUE;
			}
			if (Osal_DiffTsToUsec(pShake->keyPrsTim[id]) >= D_KEY_REPEAT_TIME)
			{
				pKey[id].keySta = EN_KEY_REPEAT;
				pKey[id].newKeyFlg = EN_STD_TRUE;
			}
			break;

		case EN_KEY_PRESS_UP:
			if (pKey[id].newKeyFlg == EN_STD_FALSE)
			{
				pKey[id].keySta = EN_KEY_NONE;
			}
			break;

		case EN_KEY_REPEAT:
			if (pShake->shakeBuf[id] == 0)//release
			{
				pKey[id].keySta = EN_KEY_NONE;
			}
			break;

		default:
			break;
	}
}

#endif

/*
************************************************************************************************************************
* Function Name    : Hal_CheckNewKey
* Description      : 
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-18
************************************************************************************************************************
*/

stdBoolean_t Hal_CheckNewKey(uint8_t id)
{
	return keyManage[id].newKeyFlg;
}

/*
************************************************************************************************************************
* Function Name    : Hal_ClearNewKeyFlg
* Description      : 
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-18
************************************************************************************************************************
*/

void Hal_ClearNewKeyFlg(uint8_t id)
{
	keyManage[id].newKeyFlg = EN_STD_FALSE;
}

/*
************************************************************************************************************************
* Function Name    : Hal_GetKeySta
* Description      : 
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-18
************************************************************************************************************************
*/

keyState_t Hal_GetKeySta(uint8_t id)
{
	return keyManage[id].keySta;
}



