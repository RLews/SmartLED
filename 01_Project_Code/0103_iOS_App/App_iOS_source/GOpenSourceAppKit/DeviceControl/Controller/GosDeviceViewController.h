//
//  GizDeviceViewController.h
//  GOpenSource_AppKit
//
//  Created by danly on 2017/2/7.
//  Copyright © 2017年 Gizwits. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GizWifiSDK/GizWifiDevice.h>

/**
 设备控制界面
 */
@interface GosDeviceViewController : UIViewController

- (instancetype)initWithDevice:(GizWifiDevice *)device;

@end
