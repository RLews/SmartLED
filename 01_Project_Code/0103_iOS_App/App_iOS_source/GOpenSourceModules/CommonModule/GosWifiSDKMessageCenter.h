//
//  GosWifiSDKMessageCenter.h
//  GOpenSource_AppKit
//
//  Created by Tom on 2017/9/30.
//  Copyright © 2017年 Gizwits. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GizWifiSDK/GizWifiSDK.h>

@interface GosWifiSDKMessageCenter : NSObject

@property (class, nonatomic, weak) id <GizWifiSDKDelegate> delegate;

@end
