//
//  ViewController.h
//  NewFlow
//
//  Created by GeHaitong on 16/1/13.
//  Copyright © 2016年 gizwits. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GizWifiDevice;

@protocol GosConfigStartDelegate <NSObject>
@required

- (void)gosConfigDidFinished;
- (void)gosConfigDidSucceed:(GizWifiDevice *)device;

@end

@interface GosConfigStart : UIViewController

@property (assign, nonatomic) BOOL isSoftAPMode; //在配置信息设置页，不管什么模式，重用此页面

+ (void)pushToSoftAP:(UINavigationController *)navCtrl configType:(NSArray *)configType;

@end

