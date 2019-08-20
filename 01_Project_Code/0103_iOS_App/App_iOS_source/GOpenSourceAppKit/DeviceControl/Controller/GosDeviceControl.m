//
//  GosDeviceControl.m
//  GOpenSource_AppKit
//
//  Created by danly on 2017/2/16.
//  Copyright © 2017年 Gizwits. All rights reserved.
//

#import "GosDeviceControl.h"
#import "NSString+HexToBytes.h"

@interface GosDeviceControl()<GizWifiDeviceDelegate>

@end

@implementation GosDeviceControl

+ (instancetype)sharedInstance
{
    return [[self alloc] init];
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [super allocWithZone: zone];
    });
    
    return instance;
}

#pragma mark - write Action
/**
 *  写数据点的值到设备
 *
 *  @param dataPoint 标识数据点的枚举值
 *  @param value     数据点值
 */
- (void)writeDataPoint:(GosDeviceDataPoint)dataPoint value:(id)value
{
    NSDictionary *data = nil;
    switch (dataPoint) {
        case GosDevice_Led_WarmSta:
        {
            self.key_Led_WarmSta = [value boolValue];
            data = @{Data__Attr_Led_WarmSta: value};
            break;
        }
        case GosDevice_LedOnOff:
        {
            self.key_LedOnOff = [value boolValue];
            data = @{Data__Attr_LedOnOff: value};
            break;
        }
        case GosDevice_Led_RVal:
        {
            self.key_Led_RVal = [value integerValue];
            data = @{Data__Attr_Led_RVal: value};
            break;
        }
        case GosDevice_Led_GVal:
        {
            self.key_Led_GVal = [value integerValue];
            data = @{Data__Attr_Led_GVal: value};
            break;
        }
        case GosDevice_Led_BVal:
        {
            self.key_Led_BVal = [value integerValue];
            data = @{Data__Attr_Led_BVal: value};
            break;
        }
        case GosDevice_Led_Brightness:
        {
            self.key_Led_Brightness = [value integerValue];
            data = @{Data__Attr_Led_Brightness: value};
            break;
        }
        default:
            NSLog(@"Error: write invalid datapoint, skip.");
            return;
    }
    NSLog(@"Write data: %@", data);
    [self.device write:data withSN:0];
}

#pragma mark - read Action
/**
 *  从数据点集合中获取数据点的值
 *
 *  @param dataMap 数据点集合
 */
- (void)readDataPointsFromData:(NSDictionary *)dataMap
{
    // 读取普通数据点的值
    NSDictionary *data = [dataMap valueForKey:@"data"];
    [self readDataPoint:GosDevice_Led_WarmSta data:data];
    [self readDataPoint:GosDevice_LedOnOff data:data];
    [self readDataPoint:GosDevice_Led_RVal data:data];
    [self readDataPoint:GosDevice_Led_GVal data:data];
    [self readDataPoint:GosDevice_Led_BVal data:data];
    [self readDataPoint:GosDevice_Led_Brightness data:data];

}


/**
 *  获取普通数据点的各个数据点值
 *
 *  @param data 普通数据点集合
 */
- (void)readDataPoint:(GosDeviceDataPoint)dataPoint data:(NSDictionary *)data
{
    if(![data isKindOfClass:[NSDictionary class]])
    {
        NSLog(@"Error: could not read data, error data format.");
        return;
    }
    switch (dataPoint) {
        case GosDevice_Led_WarmSta:
        {
            NSString *dataPointStr = [data valueForKey:Data__Attr_Led_WarmSta];
            self.key_Led_WarmSta = dataPointStr.boolValue;
            break;
        }
        case GosDevice_LedOnOff:
        {
            NSString *dataPointStr = [data valueForKey:Data__Attr_LedOnOff];
            self.key_LedOnOff = dataPointStr.boolValue;
            break;
        }
        case GosDevice_Led_RVal:
        {
            NSString *dataPointStr = [data valueForKey:Data__Attr_Led_RVal];
            self.key_Led_RVal = dataPointStr.integerValue;
            break;
        }
        case GosDevice_Led_GVal:
        {
            NSString *dataPointStr = [data valueForKey:Data__Attr_Led_GVal];
            self.key_Led_GVal = dataPointStr.integerValue;
            break;
        }
        case GosDevice_Led_BVal:
        {
            NSString *dataPointStr = [data valueForKey:Data__Attr_Led_BVal];
            self.key_Led_BVal = dataPointStr.integerValue;
            break;
        }
        case GosDevice_Led_Brightness:
        {
            NSString *dataPointStr = [data valueForKey:Data__Attr_Led_Brightness];
            self.key_Led_Brightness = dataPointStr.integerValue;
            break;
        }
        default:
            NSLog(@"Error: read invalid datapoint, skip.");
            break;
    }
}
    
/**
 *  初始化设备  ，即将设备的值都设为默认值
 */
- (void)initDevice
{
    // 重新设置设备
    self.key_Led_WarmSta = NO;
    self.key_LedOnOff = NO;
    self.key_Led_RVal = 0;
    self.key_Led_GVal = 0;
    self.key_Led_BVal = 0;
    self.key_Led_Brightness = 0;
}

@end