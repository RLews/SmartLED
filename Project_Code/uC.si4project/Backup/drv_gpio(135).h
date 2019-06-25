/*
************************************************************************************************************************
* file : E:\KeilWorkspace\M3\uCOS_III_mdk5\HardwareDriverLayer\inc\drv_gpio.h
* Description : 
* Owner : Lews Hammond
* Time : 2019-6-4
************************************************************************************************************************
*/


#ifndef __DRV_GPIO_H
#define __DRV_GPIO_H

#include "drv_public.h"




typedef struct _DRV_GPIO_CONFIG_T
{
	gpioName_t gpioName;
	GPIO_TypeDef * gpioGruop;
	GPIOMode_TypeDef gpioMode;
	uint16_t gpioPin;
	gpioState_t initIOSta;
	GPIOSpeed_TypeDef gpioSpd;
	uint32_t gpioPeriphClock;
}gpioConfig_t;

#define D_USED_GPIO_CONFIG		\
	{EN_SYSTEM_RUN_LED, GPIOB, GPIO_Mode_Out_PP, GPIO_Pin_11, EN_GPIO_HIGH, GPIO_Speed_50MHz, RCC_APB2Periph_GPIOB}, \
	{EN_WIFI_LED_GPIO, GPIOB, GPIO_Mode_Out_PP, GPIO_Pin_1, EN_GPIO_HIGH, GPIO_Speed_50MHz, RCC_APB2Periph_GPIOB}, \
	{EN_WIFI_KEY_IO, GPIOB, GPIO_Mode_IPU, GPIO_Pin_10, EN_GPIO_INPUT, GPIO_Speed_50MHz, RCC_APB2Periph_GPIOB}, \
	{EN_SYSTEM_UART_TX, GPIOA, GPIO_Mode_AF_PP, GPIO_Pin_9, EN_GPIO_HIGH, GPIO_Speed_50MHz, RCC_APB2Periph_GPIOA}, \
	{EN_SYSTEM_UART_RX, GPIOA, GPIO_Mode_IN_FLOATING, GPIO_Pin_10, EN_GPIO_INPUT, GPIO_Speed_50MHz, RCC_APB2Periph_GPIOA}, \
	{EN_W25Q63_CS, GPIOB, GPIO_Mode_Out_PP, GPIO_Pin_12, EN_GPIO_HIGH, GPIO_Speed_50MHz, RCC_APB2Periph_GPIOB}, \
	{EN_NRFxx_CS, GPIOG, GPIO_Mode_Out_PP, GPIO_Pin_7, EN_GPIO_HIGH, GPIO_Speed_50MHz, RCC_APB2Periph_GPIOG}, \
	{EN_SD_CARD_CS, GPIOD, GPIO_Mode_Out_PP, GPIO_Pin_2, EN_GPIO_HIGH, GPIO_Speed_50MHz, RCC_APB2Periph_GPIOD}, \
	{EN_SPI2_SCK, GPIOB, GPIO_Mode_AF_PP, GPIO_Pin_13, EN_GPIO_HIGH, GPIO_Speed_50MHz, RCC_APB2Periph_GPIOB}, \
	{EN_SPI2_MISO, GPIOB, GPIO_Mode_AF_PP, GPIO_Pin_14, EN_GPIO_HIGH, GPIO_Speed_50MHz, RCC_APB2Periph_GPIOB}, \
	{EN_SPI2_MOSI, GPIOB, GPIO_Mode_AF_PP, GPIO_Pin_15, EN_GPIO_HIGH, GPIO_Speed_50MHz, RCC_APB2Periph_GPIOB}, \
	{EN_WIFI_UART_TX, GPIOA, GPIO_Mode_AF_PP, GPIO_Pin_2, EN_GPIO_HIGH, GPIO_Speed_50MHz, RCC_APB2Periph_GPIOA}, \
	{EN_WIFI_UART_RX, GPIOA, GPIO_Mode_IN_FLOATING, GPIO_Pin_3, EN_GPIO_INPUT, GPIO_Speed_50MHz, RCC_APB2Periph_GPIOA}






#endif

