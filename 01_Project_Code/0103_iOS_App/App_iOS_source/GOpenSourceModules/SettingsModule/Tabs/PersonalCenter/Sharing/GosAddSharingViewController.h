//
//  GosAddSharingViewController.h
//  GOpenSource_AppKit
//
//  Created by Tom on 2016/12/21.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GizWifiDevice;

@interface GosAddSharingViewController : UIViewController

@property (strong, nonatomic) GizWifiDevice *device; //从设备列表中设置

- (GizWifiDevice *)sharingDevice;

@end
