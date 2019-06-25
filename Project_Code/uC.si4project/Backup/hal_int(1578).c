/*
************************************************************************************************************************
* file : E:\KeilWorkspace\M3\uCOS_III_mdk5\HardwareAbstractionLayer\src\hal_int.c
* Description : 
* Owner : Lews Hammond
* Time : 2019-6-4
************************************************************************************************************************
*/


#include "hal_int.h"

static uint32_t intCount = 0;

static void Hal_SysIntConfig(void);
static void Hal_SysIntHandle(sysIntIsr_t isrId);
static void Hal_ExcptionHandle(void);

static FaultRecordFunc sysFaultFunc = D_HAL_INT_NULL;
static volatile sysIntIsr_t sysIntId = EN_ALL_SYS_ISR_NUM;
static SysISRFunc sysIntVectTbl[EN_ALL_SYS_ISR_NUM] = {D_HAL_INT_NULL};

/*
************************************************************************************************************************
*                                               mcu interrupt priority config
*
* Description : mcu interrupt priority config.
*
* Arguments   : void.
*
* Returns     : void.
************************************************************************************************************************
*/
static void Hal_SysIntConfig(void)
{	//设置NVIC中断分组2:2位抢占优先级，2位响应优先级
	NVIC_PriorityGroupConfig(NVIC_PriorityGroup_2);
}

/*
************************************************************************************************************************
* Function Name    : Hal_EnableAllInt
* Description      : 
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-24
************************************************************************************************************************
*/

void Hal_EnableAllInt(void)
{
	if (intCount > 0)
	{
		intCount--;
	}

	if (intCount == 0)
	{
		D_ENABLE_ALL_INTERRUPT();
	}
}

/*
************************************************************************************************************************
* Function Name    : Hal_DisableAllInt
* Description      : 
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-24
************************************************************************************************************************
*/

void Hal_DisableAllInt(void)
{
	intCount++;

	D_DISABLE_ALL_INTERRUPT();
}

/*
************************************************************************************************************************
*                                               mcu interrupt handler functoin config
*
* Description : mcu interrupt handler functoin config.
*
* Arguments   : void.
*
* Returns     : void.
************************************************************************************************************************
*/
void Hal_SysIntInit(void)
{
	uint8_t i = 0;

	Hal_SysIntConfig();

	for (i = 0; i < (uint8_t)EN_ALL_SYS_ISR_NUM; i++)
	{
		Hal_SysISRSet((sysIntIsr_t)i, Hal_ExcptionHandle);
	}
}

/*
************************************************************************************************************************
*                                               set mcu interrupt handler functoin set
*
* Description : set mcu interrupt handler functoin set.
*
* Arguments   : sysIntIsr_t isrId.	interrupt identifier
* 				SysISRFunc isrFunc. interrupt handler function pointer
*
* Returns     : void.
************************************************************************************************************************
*/
void Hal_SysISRSet(sysIntIsr_t isrId, SysISRFunc isrFunc)
{
	D_OSAL_ALLOC_CRITICAL_SR();
	
	if (isrId < EN_ALL_SYS_ISR_NUM)
	{
#if (D_UC_OS_III_ENABLE == D_SYS_STD_ON)
		D_OSAL_ENTER_CRITICAL();
#else
		Hal_DisableAllInt();
#endif
		sysIntVectTbl[isrId] = isrFunc;
#if (D_UC_OS_III_ENABLE == D_SYS_STD_ON)
		D_OSAL_EXIT_CRITICAL();
#else
		Hal_EnableAllInt();
#endif
	}
}


/*
************************************************************************************************************************
*                                               mcu interrupt exception handler
*
* Description : mcu interrupt exception handler.
*
* Arguments   : void.
*
* Returns     : void.
************************************************************************************************************************
*/
static void Hal_ExcptionHandle(void)
{
	/* 1. record ecu register and hardfault state */ /* 2. save to non-volatile memory */
	if (sysFaultFunc != D_HAL_INT_NULL)
	{
		sysFaultFunc();
	}

	/* 3. disable interrupt and wait watchdog reset */
	D_DISABLE_ALL_INTERRUPT();
	while (1)
	{
		
	}
}

/*
************************************************************************************************************************
* Function Name    : Hal_SetFaultFunc
* Description      : set fault record function
* Input Arguments  : 
* Output Arguments : 
* Returns          : 
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-16
************************************************************************************************************************
*/

void Hal_SetFaultFunc(FaultRecordFunc pFunc)
{
    D_OSAL_ALLOC_CRITICAL_SR();
#if (D_UC_OS_III_ENABLE == D_SYS_STD_ON)
	D_OSAL_ENTER_CRITICAL();
#else
	Hal_DisableAllInt();
#endif
	sysFaultFunc = pFunc;
#if (D_UC_OS_III_ENABLE == D_SYS_STD_ON)
	D_OSAL_EXIT_CRITICAL();
#else
	Hal_EnableAllInt();
#endif
}

/*
************************************************************************************************************************
* Function Name    : Hal_GetCurIntID
* Description      : get current interrupt id
* Input Arguments  : 
* Output Arguments : 
* Returns          : uint8_t
* Notes            : 
* Author           : Lews Hammond
* Time             : 2019-6-16
************************************************************************************************************************
*/

uint8_t Hal_GetCurIntID(void)
{
	return (uint8_t)sysIntId;
}

/*
************************************************************************************************************************
*                                               mcu system interrupt function handler
*
* Description : mcu system interrupt function handler.
*
* Arguments   : void.
*
* Returns     : void.
************************************************************************************************************************
*/
static void Hal_SysIntHandle(sysIntIsr_t isrId)
{
	SysISRFunc isr = D_HAL_INT_NULL;
	D_OSAL_ALLOC_CRITICAL_SR();

#if (D_UC_OS_III_ENABLE == D_SYS_STD_ON)
	D_OSAL_ENTER_CRITICAL();
	D_OSAL_INT_ENTER();/* Tell the OS that we are starting an ISR            */
	D_OSAL_EXIT_CRITICAL();
#endif
	sysIntId = isrId;//update current interrupt id
	
	if (isrId < EN_ALL_SYS_ISR_NUM)
	{
		isr = sysIntVectTbl[isrId];
		if (isr != D_HAL_INT_NULL)
		{
			isr();
		}
	}
#if (D_UC_OS_III_ENABLE == D_SYS_STD_ON)
	D_OSAL_INT_EXIT();/* Tell the OS that we are leaving the ISR            */
#endif
}

/*
************************************************************************************************************************
*                                               all mcu system interrupt function 
*
* Description : all mcu system interrupt function.
*
* Arguments   : void.
*
* Returns     : void.
************************************************************************************************************************
*/
void NMI_Handler(void) {
	Hal_SysIntHandle(EN_NMI_ISR);
}
void HardFault_Handler(void) {
	Hal_SysIntHandle(EN_HARD_FAULT_ISR);
}
void MemManage_Handler(void) {
	Hal_SysIntHandle(EN_MEM_MANAGE_ISR);
}
void BusFault_Handler(void) {
	Hal_SysIntHandle(EN_BUS_FAULT_ISR);
}
void UsageFault_Handler(void) {
	Hal_SysIntHandle(EN_SUAGE_FAULT_ISR);
}
void SVC_Handler(void) {
	Hal_SysIntHandle(EN_SVC_ISR);
}
void DebugMon_Handler(void) {
	Hal_SysIntHandle(EN_DEBUG_MON_ISR);
}
void SysTick_Handler(void) {
	Hal_SysIntHandle(EN_SYS_TICK_ISR);
}
void WWDG_IRQHandler(void) {
	Hal_SysIntHandle(EN_WWDG_ISR);
}
void PVD_IRQHandler(void) {
	Hal_SysIntHandle(EN_PVD_ISR);
}
void TAMPER_IRQHandler(void) {
	Hal_SysIntHandle(EN_TAMPER_ISR);
}
void RTC_IRQHandler(void) {
	Hal_SysIntHandle(EN_RTC_ISR);
}
void FLASH_IRQHandler(void) {
	Hal_SysIntHandle(EN_FLASH_ISR);
}
void RCC_IRQHandler(void) {
	Hal_SysIntHandle(EN_RCC_ISR);
}
void EXTI0_IRQHandler(void) {
	Hal_SysIntHandle(EN_EXTI0_ISR);
}
void EXTI1_IRQHandler(void) {
	Hal_SysIntHandle(EN_EXTI1_ISR);
}
void EXTI2_IRQHandler(void) {
	Hal_SysIntHandle(EN_EXTI2_ISR);
}
void EXTI3_IRQHandler(void) {
	Hal_SysIntHandle(EN_EXTI3_ISR);
}
void EXTI4_IRQHandler(void) {
	Hal_SysIntHandle(EN_EXTI4_ISR);
}
void DMA1_Channel1_IRQHandler(void) {
	Hal_SysIntHandle(EN_DMA1_CH1_ISR);
}
void DMA1_Channel2_IRQHandler(void) {
	Hal_SysIntHandle(EN_DMA1_CH2_ISR);
}
void DMA1_Channel3_IRQHandler(void) {
	Hal_SysIntHandle(EN_DMA1_CH3_ISR);
}
void DMA1_Channel4_IRQHandler(void) {
	Hal_SysIntHandle(EN_DMA1_CH4_ISR);
}
void DMA1_Channel5_IRQHandler(void) {
	Hal_SysIntHandle(EN_DMA1_CH5_ISR);
}
void DMA1_Channel6_IRQHandler(void) {
	Hal_SysIntHandle(EN_DMA1_CH6_ISR);
}
void DMA1_Channel7_IRQHandler(void) {
	Hal_SysIntHandle(EN_DMA1_CH7_ISR);
}
void ADC1_2_IRQHandler(void) {
	Hal_SysIntHandle(EN_ADC1_2_ISR);
}
void USB_HP_CAN1_TX_IRQHandler(void) {
	Hal_SysIntHandle(EN_USB_HP_CAN1_TX_ISR);
}
void USB_LP_CAN1_RX0_IRQHandler(void) {
	Hal_SysIntHandle(EN_USB_LP_CAN1_RX0_ISR);
}
void CAN1_RX1_IRQHandler(void) {
	Hal_SysIntHandle(EN_CAN1_RX1_ISR);
}
void CAN1_SCE_IRQHandler(void) {
	Hal_SysIntHandle(EN_CAN1_SCE_ISR);
}
void EXTI9_5_IRQHandler(void) {
	Hal_SysIntHandle(EN_EXTI9_5_ISR);
}
void TIM1_BRK_IRQHandler(void) {
	Hal_SysIntHandle(EN_TIM1_BRK_ISR);
}
void TIM1_UP_IRQHandler(void) {
	Hal_SysIntHandle(EN_TIM1_UP_ISR);
}
void TIM1_TRG_COM_IRQHandler(void) {
	Hal_SysIntHandle(EN_TIM1_TRG_COM_ISR);
}
void TIM1_CC_IRQHandler(void) {
	Hal_SysIntHandle(EN_TIM1_CC_ISR);
}
void TIM2_IRQHandler(void) {
	Hal_SysIntHandle(EN_TIM2_ISR);
}
void TIM3_IRQHandler(void) {
	Hal_SysIntHandle(EN_TIM3_ISR);
}
void TIM4_IRQHandler(void) {
	Hal_SysIntHandle(EN_TIM4_ISR);
}
void I2C1_EV_IRQHandler(void) {
	Hal_SysIntHandle(EN_I2C1_EV_ISR);
}
void I2C1_ER_IRQHandler(void) {
	Hal_SysIntHandle(EN_I2C1_ER_ISR);
}
void I2C2_EV_IRQHandler(void) {
	Hal_SysIntHandle(EN_I2C2_EV_ISR);
}
void I2C2_ER_IRQHandler(void) {
	Hal_SysIntHandle(EN_I2C2_ER_ISR);
}
void SPI1_IRQHandler(void) {
	Hal_SysIntHandle(EN_SPI1_ISR);
}
void SPI2_IRQHandler(void) {
	Hal_SysIntHandle(EN_SPI2_ISR);
}
void USART1_IRQHandler(void) {
	Hal_SysIntHandle(EN_USART1_ISR);
}
void USART2_IRQHandler(void) {
	Hal_SysIntHandle(EN_USART2_ISR);
}
void USART3_IRQHandler(void) {
	Hal_SysIntHandle(EN_USART3_ISR);
}
void EXTI15_10_IRQHandler(void) {
	Hal_SysIntHandle(EN_EXTI15_10_ISR);
}
void RTCAlarm_IRQHandler(void) {
	Hal_SysIntHandle(EN_RTCAlarm_ISR);
}
void USBWakeUp_IRQHandler(void) {
	Hal_SysIntHandle(EN_USBWakeUp_ISR);
}
void TIM8_BRK_IRQHandler(void) {
	Hal_SysIntHandle(EN_TIM8_BRK_ISR);
}
void TIM8_UP_IRQHandler(void) {
	Hal_SysIntHandle(EN_TIM8_UP_ISR);
}
void TIM8_TRG_COM_IRQHandler(void) {
	Hal_SysIntHandle(EN_TIM8_TRG_COM_ISR);
}
void TIM8_CC_IRQHandler(void) {
	Hal_SysIntHandle(EN_TIM8_CC_ISR);
}
void ADC3_IRQHandler(void) {
	Hal_SysIntHandle(EN_ADC3_ISR);
}
void FSMC_IRQHandler(void) {
	Hal_SysIntHandle(EN_FSMC_ISR);
}
void SDIO_IRQHandler(void) {
	Hal_SysIntHandle(EN_SDIO_ISR);
}
void TIM5_IRQHandler(void) {
	Hal_SysIntHandle(EN_TIM5_ISR);
}
void SPI3_IRQHandler(void) {
	Hal_SysIntHandle(EN_SPI3_ISR);
}
void UART4_IRQHandler(void) {
	Hal_SysIntHandle(EN_UART4_ISR);
}
void UART5_IRQHandler(void) {
	Hal_SysIntHandle(EN_UART5_ISR);
}
void TIM6_IRQHandler(void) {
	Hal_SysIntHandle(EN_TIM6_ISR);
}
void TIM7_IRQHandler(void) {
	Hal_SysIntHandle(EN_TIM7_ISR);
}
void DMA2_Channel1_IRQHandler(void) {
	Hal_SysIntHandle(EN_DMA2_CH1_ISR);
}
void DMA2_Channel2_IRQHandler(void) {
	Hal_SysIntHandle(EN_DMA2_CH2_ISR);
}
void DMA2_Channel3_IRQHandler(void) {
	Hal_SysIntHandle(EN_DMA2_CH3_ISR);
}
void DMA2_Channel4_5_IRQHandler(void) {
	Hal_SysIntHandle(EN_DMA2_CH4_5_ISR);
}


