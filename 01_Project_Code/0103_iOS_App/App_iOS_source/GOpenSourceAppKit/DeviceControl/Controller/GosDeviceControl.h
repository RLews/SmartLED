//
//  GosDeviceControl.h
//  GOpenSource_AppKit
//
//  Created by danly on 2017/2/16.
//  Copyright © 2017年 Gizwits. All rights reserved.
//

// 设备收发数据的工具类
#import <UIKit/UIKit.h>
#import <GizWifiSDK/GizWifiDevice.h>

// 数据点标识符
#define Data__Attr_Led_WarmSta @"Led_WarmSta"
#define Data__Attr_LedOnOff @"LedOnOff"
#define Data__Attr_Led_RVal @"Led_RVal"
#define Data__Attr_Led_GVal @"Led_GVal"
#define Data__Attr_Led_BVal @"Led_BVal"
#define Data__Attr_Led_Brightness @"Led_Brightness"

// 标识各个数据点的枚举值
typedef enum
{
    GosDevice_Led_WarmSta,
    GosDevice_LedOnOff,
    GosDevice_Led_RVal,
    GosDevice_Led_GVal,
    GosDevice_Led_BVal,
    GosDevice_Led_Brightness,
}GosDeviceDataPoint;

// 设备控制类
@interface GosDeviceControl : NSObject

// 以下是存储各个数据点值的属性
@property (nonatomic, assign) BOOL key_Led_WarmSta;
@property (nonatomic, assign) BOOL key_LedOnOff;
@property (nonatomic, assign) NSInteger key_Led_RVal;
@property (nonatomic, assign) NSInteger key_Led_GVal;
@property (nonatomic, assign) NSInteger key_Led_BVal;
@property (nonatomic, assign) NSInteger key_Led_Brightness;

// 设备
@property (nonatomic, strong)  GizWifiDevice *device;

+ (instancetype)sharedInstance;

/**
 *  初始化设备  ，即将设备的值都设为默认值
 */
- (void)initDevice;

/**
 *  写数据点的值到设备
 *
 *  @param dataPoint 标识数据点的枚举值
 *  @param value     数据点值
 */
- (void)writeDataPoint:(GosDeviceDataPoint)dataPoint value:(id)value;

/**
 *  从数据点集合中获取数据点的值
 *
 *  @param dataMap 数据点集合
 */
- (void)readDataPointsFromData:(NSDictionary *)dataMap;


@end