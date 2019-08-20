//
//  GosPushManager.m
//  GOpenSourceAppKit
//
//  Created by Zono on 16/6/20.
//  Copyright © 2016年 Gizwits. All rights reserved.
//
// @note 推送功能仅限于企业开发者使用，目前版本暂不支持推送

#import "GosPushManager.h"
#import "AppDelegate.h"
#import "GosCommon.h"
#import "JPUSHService.h"
#import "BPush.h"

#ifdef __IPHONE_8_0
#define RNTypeAlert UIUserNotificationTypeAlert
#define RNTypeBadge UIUserNotificationTypeBadge
#define RNTypeSound UIUserNotificationTypeSound
#else
#define RNTypeAlert UIRemoteNotificationTypeAlert
#define RNTypeBadge UIRemoteNotificationTypeBadge
#define RNTypeSound UIRemoteNotificationTypeSound
#endif

@implementation GosPushManager

+ (void)initManager:(NSDictionary *)launchOptions {
    switch (PUSH_TYPE) {

        case 0: {
            if ([BPUSH_API_KEY isEqualToString:@"your_bpush_app_key"] || BPUSH_API_KEY.length == 0) {
                [GosCommon showAlert:nil message:@"请替换 GOpenSourceModules/CommonModule/appConfig.json 中的参数定义为您申请到的百度推送 app id"];
                return;
            }
            if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
                UIUserNotificationType myTypes = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
                
                UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:myTypes categories:nil];
                [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
            }
#ifndef __IPHONE_10_0
            else {
                UIRemoteNotificationType myTypes = UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeSound|UIRemoteNotificationTypeAlert;
                [[UIApplication sharedApplication] registerForRemoteNotificationTypes:myTypes];
            }
#endif
            [BPush registerChannel:launchOptions apiKey:BPUSH_API_KEY pushMode:BPushModeProduction withFirstAction:nil withSecondAction:nil withCategory:nil useBehaviorTextInput:NO isDebug:NO];
            
            // App 是用户点击推送消息启动
            NSDictionary *userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
            if (userInfo) {
                [BPush handleNotification:userInfo];
            }
            break;
        }


        case 1: {
            if ([JPUSH_APP_KEY isEqualToString:@"your_jpush_app_key"] || JPUSH_APP_KEY.length == 0) {
                [GosCommon showAlert:nil message:@"请替换 GOpenSourceModules/CommonModule/appConfig.json 中的参数定义为您申请到的极光推送 app id"];
                return;
            }
            // 注册通知
            [JPUSHService registerForRemoteNotificationTypes:(RNTypeAlert|RNTypeBadge|RNTypeSound) categories:nil];
            // 初始化 jPush
            [JPUSHService setupWithOption:launchOptions appKey:JPUSH_APP_KEY channel:nil apsForProduction:YES];
            [JPUSHService setBadge:0];
            
            if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0) {
                //可以添加自定义categories
                [JPUSHService registerForRemoteNotificationTypes:(UIUserNotificationTypeBadge |
                                                                  UIUserNotificationTypeSound |
                                                                  UIUserNotificationTypeAlert)
                                                      categories:nil];
            }
#ifndef __IPHONE_10_0
            else {
                //categories 必须为nil
                [JPUSHService registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                                  UIRemoteNotificationTypeSound |
                                                                UIRemoteNotificationTypeAlert)
                                                      categories:nil];
            }
#endif
            break;
        }

        default:
            break;
    }
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    switch (PUSH_TYPE) {

        case 0: {
            /********** 百度推送 start *********/
            [BPush registerDeviceToken:deviceToken];
            [BPush bindChannelWithCompleteHandler:^(id result, NSError *error) {
                // 需要在绑定成功后进行 settag listtag deletetag unbind 操作否则会失败
                if (result) {
                    NSString *channelID = [BPush getChannelId];
                    if (channelID) {
                        [BPush setTag:channelID withCompleteHandler:^(id result, NSError *error) {
                            if (result) { //成功、失败处理（这里不需要）
                            }
                        }];
                    }
                }
            }];
            /********** 百度推送 end *********/
            break;
        }


        case 1: {
            [JPUSHService registerDeviceToken:deviceToken];
            break;
        }

        default:
            break;
    }
}

+ (void)handleRemoteNotification:(NSDictionary *)remoteInfo {
    switch (PUSH_TYPE) {

        case 0: {
            [BPush handleNotification:remoteInfo];
            break;
        }


        case 1: {
            [JPUSHService handleRemoteNotification:remoteInfo];
            break;
        }

        default:
            break;
    }
}

+ (void)bindToGDMS {
    if (PUSH_TYPE == -1) {
        return;
    }
    if (common.token && common.token.length > 0) {
        NSString *cid = [GosPushManager getCid];
        if (cid == nil) {
            NSLog(@"bindToGDMS cid == nil");
        }
        else {
            NSLog(@"common.token:%@, cid: %@", common.token, cid);
            switch (PUSH_TYPE) {
        
                case 0: {
                    [[GizWifiSDK sharedInstance] channelIDBind:common.token channelID:cid alias:nil pushType:GizPushBaiDu];
                    break;
                }
        
        
                case 1: {
                    [[GizWifiSDK sharedInstance] channelIDBind:common.token channelID:cid alias:nil pushType:GizPushJiGuang];
                    break;
                }
        
                default:
                    break;
            }
        }
    }
}

+ (void)unbindToGDMS:(BOOL)isLogout {
    if (common.token && common.token.length > 0) {

        NSString *jpushCID = [[NSUserDefaults standardUserDefaults] objectForKey:@"JPushCID"];


        NSString *bpushCID = [[NSUserDefaults standardUserDefaults] objectForKey:@"BPushCID"];

        if (isLogout) {
    
            if (jpushCID && jpushCID.length > 0) {
                [[GizWifiSDK sharedInstance] channelIDUnBind:common.token channelID:jpushCID];
            }
    
    
            if (bpushCID && bpushCID.length > 0) {
                [[GizWifiSDK sharedInstance] channelIDUnBind:common.token channelID:bpushCID];
            }
    
        }
        else {
            switch (PUSH_TYPE) {
        
                case 0:
                    if (bpushCID && bpushCID.length > 0) {
                        [[GizWifiSDK sharedInstance] channelIDUnBind:common.token channelID:bpushCID];
                    }
                    break;
        
        
                case 1:
                    if (jpushCID && jpushCID.length > 0) {
                        [[GizWifiSDK sharedInstance] channelIDUnBind:common.token channelID:jpushCID];
                    }
                    break;
        
                default:
                    break;
            }
        }
    }
}

+ (void)didBind:(NSError *)result {
    NSString *cid = [GosPushManager getCid];
    if (cid == nil) {
        NSLog(@"didBind cid == nil");
    }
    if (result.code != GIZ_SDK_SUCCESS) {
        NSString *info = [common checkErrorCode:result.code];
        NSLog(@"bind failed: %@", info);
        [GosCommon showAlertAutoDisappear:info];
    }
    else {
        if (PUSH_TYPE == 0) {
            [[NSUserDefaults standardUserDefaults] setObject:cid forKey:@"BPushCID"];
        } else if (PUSH_TYPE == 1) {
            [[NSUserDefaults standardUserDefaults] setObject:cid forKey:@"JPushCID"];
        }
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}


+ (void)didUnbind:(NSError *)result {
    NSString *cid = [GosPushManager getCid];
    if (cid == nil) {
        NSLog(@"didUnbind cid == nil");
    }
    if (result.code != GIZ_SDK_SUCCESS) {
        NSString *info = [common checkErrorCode:result.code];
        [GosCommon showAlertAutoDisappear:info];
        NSLog(@"unbind failed: %@", info);
    }
    else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"JPushCID"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"BPushCID"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

+ (NSString *)getCid {
    NSString* cid = nil;
    for (int i = 0; i < 10; i++) {
        switch (PUSH_TYPE) {
    
            case 0: {
                cid = [BPush getChannelId];
                break;
            }
    
    
            case 1: {
                cid = [JPUSHService registrationID];
                break;
            }
    
            default:
                break;
        }
        if (cid && cid.length > 0) {
            return cid;
        } else {
            NSLog(@"Could not get cid");
        }
    }
    return nil;
}

@end
