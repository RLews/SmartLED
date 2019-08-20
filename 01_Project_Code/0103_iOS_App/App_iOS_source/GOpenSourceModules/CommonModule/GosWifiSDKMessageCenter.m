//
//  GosWifiSDKMessageCenter.m
//  GOpenSource_AppKit
//
//  Created by Tom on 2017/9/30.
//  Copyright © 2017年 Gizwits. All rights reserved.
//

#import "GosWifiSDKMessageCenter.h"
#import "GosAnonymousLogin.h"
#import "GosCommon.h"

static GosWifiSDKMessageCenter *centerInstance = nil;
static id <GizWifiSDKDelegate>_delegate = nil;

/* GizWifiSDK类消息中转站
 为了实现匿名登录时，uid、token不会因为页面切换而不能获得的特殊需求 */
@interface GosWifiSDKMessageCenter() <GizWifiSDKDelegate>

@end

@implementation GosWifiSDKMessageCenter

+ (void)setDelegate:(id<GizWifiSDKDelegate>)delegate {
    _delegate = delegate;
}

+ (id<GizWifiSDKDelegate>)delegate {
    return _delegate;
}

+ (instancetype)shardInstance {
    if (nil == centerInstance) {
        centerInstance = [[GosWifiSDKMessageCenter alloc] init];
    }
    return centerInstance;
}

+ (void)initialize {
    [GizWifiSDK sharedInstance].delegate = [self shardInstance];
}

- (void)wifiSDK:(GizWifiSDK * _Nonnull)wifiSDK didSetDeviceOnboarding:(NSError * _Nonnull)result mac:(NSString * _Nullable)mac did:(NSString * _Nullable)did productKey:(NSString * _Nullable)productKey {
    if ([GosWifiSDKMessageCenter.delegate respondsToSelector:@selector(wifiSDK:didSetDeviceOnboarding:mac:did:productKey:)]) {
        [GosWifiSDKMessageCenter.delegate wifiSDK:wifiSDK didSetDeviceOnboarding:result mac:mac did:did productKey:productKey];
    }
}

- (void)wifiSDK:(GizWifiSDK * _Nonnull)wifiSDK didSetDeviceOnboarding:(NSError * _Nonnull)result device:(GizWifiDevice * _Nullable)device {
    if ([GosWifiSDKMessageCenter.delegate respondsToSelector:@selector(wifiSDK:didSetDeviceServerInfo:mac:)]) {
        [GosWifiSDKMessageCenter.delegate wifiSDK:wifiSDK didSetDeviceOnboarding:result device:device];
    }
}

- (void)XPGWifiSDK:(GizWifiSDK * _Null_unspecified)wifiSDK didSetDeviceWifi:(GizWifiDevice * _Null_unspecified)device result:(int)result {
    if ([GosWifiSDKMessageCenter.delegate respondsToSelector:@selector(XPGWifiSDK:didSetDeviceWifi:result:)]) {
        [GosWifiSDKMessageCenter.delegate XPGWifiSDK:wifiSDK didSetDeviceWifi:device result:result];
    }
}

- (void)wifiSDK:(GizWifiSDK * _Nonnull)wifiSDK didGetSSIDList:(NSError * _Nonnull)result ssidList:(NSArray <GizWifiSSID *>* _Nullable)ssidList {
    if ([GosWifiSDKMessageCenter.delegate respondsToSelector:@selector(wifiSDK:didGetSSIDList:ssidList:)]) {
        [GosWifiSDKMessageCenter.delegate wifiSDK:wifiSDK didGetSSIDList:result ssidList:ssidList];
    }
}

- (void)XPGWifiSDK:(GizWifiSDK * _Null_unspecified)wifiSDK didGetSSIDList:(NSArray * _Null_unspecified)ssidList result:(int)result {
    if ([GosWifiSDKMessageCenter.delegate respondsToSelector:@selector(XPGWifiSDK:didGetSSIDList:result:)]) {
        [GosWifiSDKMessageCenter.delegate XPGWifiSDK:wifiSDK didGetSSIDList:ssidList result:result];
    }
}

- (void)wifiSDK:(GizWifiSDK * _Nonnull)wifiSDK didDiscovered:(NSError * _Nonnull)result deviceList:(NSArray <GizWifiDevice *>* _Nullable)deviceList {
    if ([GosWifiSDKMessageCenter.delegate respondsToSelector:@selector(wifiSDK:didDiscovered:deviceList:)]) {
        [GosWifiSDKMessageCenter.delegate wifiSDK:wifiSDK didDiscovered:result deviceList:deviceList];
    }
}

- (void)XPGWifiSDK:(GizWifiSDK * _Null_unspecified)wifiSDK didDiscovered:(NSArray * _Null_unspecified)deviceList result:(int)result {
    if ([GosWifiSDKMessageCenter.delegate respondsToSelector:@selector(XPGWifiSDK:didDiscovered:result:)]) {
        [GosWifiSDKMessageCenter.delegate XPGWifiSDK:wifiSDK didDiscovered:deviceList result:result];
    }
}

- (void)wifiSDK:(GizWifiSDK * _Null_unspecified)wifiSDK didUpdateProduct:(NSError * _Null_unspecified)result producKey:(NSString * _Null_unspecified)productKey productUI:(NSString * _Null_unspecified)productUI {
    if ([GosWifiSDKMessageCenter.delegate respondsToSelector:@selector(wifiSDK:didUpdateProduct:producKey:productUI:)]) {
        [GosWifiSDKMessageCenter.delegate wifiSDK:wifiSDK didUpdateProduct:result producKey:productKey productUI:productUI];
    }
}

- (void)XPGWifiSDK:(GizWifiSDK * _Null_unspecified)wifiSDK didUpdateProduct:(NSString * _Null_unspecified)product result:(int)result {
    if ([GosWifiSDKMessageCenter.delegate respondsToSelector:@selector(XPGWifiSDK:didUpdateProduct:result:)]) {
        [GosWifiSDKMessageCenter.delegate XPGWifiSDK:wifiSDK didUpdateProduct:product result:result];
    }
}

- (void)wifiSDK:(GizWifiSDK * _Nonnull)wifiSDK didBindDevice:(NSError * _Nonnull)result did:(NSString * _Nullable)did {
    if ([GosWifiSDKMessageCenter.delegate respondsToSelector:@selector(wifiSDK:didBindDevice:did:)]) {
        [GosWifiSDKMessageCenter.delegate wifiSDK:wifiSDK didBindDevice:result did:did];
    }
}

- (void)XPGWifiSDK:(GizWifiSDK * _Null_unspecified)wifiSDK didBindDevice:(NSString * _Null_unspecified)did error:(NSNumber * _Null_unspecified)error errorMessage:(NSString * _Null_unspecified)errorMessage {
    if ([GosWifiSDKMessageCenter.delegate respondsToSelector:@selector(XPGWifiSDK:didBindDevice:error:errorMessage:)]) {
        [GosWifiSDKMessageCenter.delegate XPGWifiSDK:wifiSDK didBindDevice:did error:error errorMessage:errorMessage];
    }
}

- (void)wifiSDK:(GizWifiSDK * _Nonnull)wifiSDK didUnbindDevice:(NSError * _Nonnull)result did:(NSString * _Nullable)did {
    if ([GosWifiSDKMessageCenter.delegate respondsToSelector:@selector(wifiSDK:didUnbindDevice:did:)]) {
        [GosWifiSDKMessageCenter.delegate wifiSDK:wifiSDK didUnbindDevice:result did:did];
    }
}

- (void)XPGWifiSDK:(GizWifiSDK * _Null_unspecified)wifiSDK didUnbindDevice:(NSString * _Null_unspecified)did error:(NSNumber * _Null_unspecified)error errorMessage:(NSString * _Null_unspecified)errorMessage {
    if ([GosWifiSDKMessageCenter.delegate respondsToSelector:@selector(XPGWifiSDK:didUnbindDevice:error:errorMessage:)]) {
        [GosWifiSDKMessageCenter.delegate XPGWifiSDK:wifiSDK didUnbindDevice:did error:error errorMessage:errorMessage];
    }
}

- (void)wifiSDK:(GizWifiSDK * _Nonnull)wifiSDK didGetCaptchaCode:(NSError * _Nonnull)result token:(NSString * _Nullable)token captchaId:(NSString * _Nullable)captchaId captchaURL:(NSString * _Nullable)captchaURL {
    if ([GosWifiSDKMessageCenter.delegate respondsToSelector:@selector(wifiSDK:didGetCaptchaCode:token:captchaId:captchaURL:)]) {
        [GosWifiSDKMessageCenter.delegate wifiSDK:wifiSDK didGetCaptchaCode:result token:token captchaId:captchaId captchaURL:captchaURL];
    }
}

- (void)wifiSDK:(GizWifiSDK * _Nonnull)wifiSDK didRequestSendPhoneSMSCode:(NSError * _Nonnull)result token:(NSString * _Nullable)token {
    if ([GosWifiSDKMessageCenter.delegate respondsToSelector:@selector(wifiSDK:didRequestSendPhoneSMSCode:token:)]) {
        [GosWifiSDKMessageCenter.delegate wifiSDK:wifiSDK didRequestSendPhoneSMSCode:result token:token];
    }
}

- (void)wifiSDK:(GizWifiSDK * _Null_unspecified)wifiSDK didRequestSendPhoneSMSCode:(NSError * _Null_unspecified)result {
    if ([GosWifiSDKMessageCenter.delegate respondsToSelector:@selector(wifiSDK:didRequestSendPhoneSMSCode:)]) {
        [GosWifiSDKMessageCenter.delegate wifiSDK:wifiSDK didRequestSendPhoneSMSCode:result];
    }
}

- (void)wifiSDK:(GizWifiSDK * _Nonnull)wifiSDK didVerifyPhoneSMSCode:(NSError * _Nonnull)result {
    if ([GosWifiSDKMessageCenter.delegate respondsToSelector:@selector(wifiSDK:didVerifyPhoneSMSCode:)]) {
        [GosWifiSDKMessageCenter.delegate wifiSDK:wifiSDK didVerifyPhoneSMSCode:result];
    }
}

- (void)wifiSDK:(GizWifiSDK * _Nonnull)wifiSDK didRegisterUser:(NSError * _Nonnull)result uid:(NSString * _Nullable)uid token:(NSString * _Nullable)token {
    if ([GosWifiSDKMessageCenter.delegate respondsToSelector:@selector(wifiSDK:didRegisterUser:uid:token:)]) {
        [GosWifiSDKMessageCenter.delegate wifiSDK:wifiSDK didRegisterUser:result uid:uid token:token];
    }
}

- (void)XPGWifiSDK:(GizWifiSDK * _Null_unspecified)wifiSDK didRegisterUser:(NSNumber * _Null_unspecified)error errorMessage:(NSString * _Null_unspecified)errorMessage uid:(NSString * _Null_unspecified)uid token:(NSString * _Null_unspecified)token {
    if ([GosWifiSDKMessageCenter.delegate respondsToSelector:@selector(XPGWifiSDK:didRegisterUser:errorMessage:uid:token:)]) {
        [GosWifiSDKMessageCenter.delegate XPGWifiSDK:wifiSDK didRegisterUser:error errorMessage:errorMessage uid:uid token:token];
    }
}

- (void)wifiSDK:(GizWifiSDK * _Nonnull)wifiSDK didUserLogin:(NSError * _Nonnull)result uid:(NSString * _Nullable)uid token:(NSString * _Nullable)token {

    if (common.isAnonymous) {
        [GosAnonymousLogin didUserLogin:result uid:uid token:token];
    }

    if ([GosWifiSDKMessageCenter.delegate respondsToSelector:@selector(wifiSDK:didUserLogin:uid:token:)]) {
        [GosWifiSDKMessageCenter.delegate wifiSDK:wifiSDK didUserLogin:result uid:uid token:token];
    }
}

- (void)XPGWifiSDK:(GizWifiSDK * _Null_unspecified)wifiSDK didUserLogin:(NSNumber * _Null_unspecified)error errorMessage:(NSString * _Null_unspecified)errorMessage uid:(NSString * _Null_unspecified)uid token:(NSString * _Null_unspecified)token DEPRECATED_ATTRIBUTE {
    if ([GosWifiSDKMessageCenter.delegate respondsToSelector:@selector(XPGWifiSDK:didUserLogin:errorMessage:uid:token:)]) {
        [GosWifiSDKMessageCenter.delegate XPGWifiSDK:wifiSDK didUserLogin:error errorMessage:errorMessage uid:uid token:token];
    }
}

- (void)XPGWifiSDK:(GizWifiSDK * _Null_unspecified)wifiSDK didUserLogout:(NSNumber * _Null_unspecified)error errorMessage:(NSString * _Null_unspecified)errorMessage {
    if ([GosWifiSDKMessageCenter.delegate respondsToSelector:@selector(XPGWifiSDK:didUserLogout:errorMessage:)]) {
        [GosWifiSDKMessageCenter.delegate XPGWifiSDK:wifiSDK didUserLogout:error errorMessage:errorMessage];
    }
}

- (void)wifiSDK:(GizWifiSDK * _Nonnull)wifiSDK didChangeUserPassword:(NSError * _Nonnull)result {
    if ([GosWifiSDKMessageCenter.delegate respondsToSelector:@selector(wifiSDK:didChangeUserPassword:)]) {
        [GosWifiSDKMessageCenter.delegate wifiSDK:wifiSDK didChangeUserPassword:result];
    }
}

- (void)XPGWifiSDK:(GizWifiSDK * _Null_unspecified)wifiSDK didChangeUserPassword:(NSNumber * _Null_unspecified)error errorMessage:(NSString * _Null_unspecified)errorMessage {
    if ([GosWifiSDKMessageCenter.delegate respondsToSelector:@selector(XPGWifiSDK:didChangeUserPassword:errorMessage:)]) {
        [GosWifiSDKMessageCenter.delegate XPGWifiSDK:wifiSDK didChangeUserPassword:error errorMessage:errorMessage];
    }
}

- (void)wifiSDK:(GizWifiSDK * _Nonnull)wifiSDK didChangeUserInfo:(NSError * _Nonnull)result {
    if ([GosWifiSDKMessageCenter.delegate respondsToSelector:@selector(wifiSDK:didChangeUserInfo:)]) {
        [GosWifiSDKMessageCenter.delegate wifiSDK:wifiSDK didChangeUserInfo:result];
    }
}

- (void)wifiSDK:(GizWifiSDK * _Nonnull)wifiSDK didGetUserInfo:(NSError * _Nonnull)result userInfo:(GizUserInfo * _Nullable)userInfo {
    if ([GosWifiSDKMessageCenter.delegate respondsToSelector:@selector(wifiSDK:didGetUserInfo:userInfo:)]) {
        [GosWifiSDKMessageCenter.delegate wifiSDK:wifiSDK didGetUserInfo:result userInfo:userInfo];
    }
}

- (void)wifiSDK:(GizWifiSDK * _Nonnull)wifiSDK didTransAnonymousUser:(NSError * _Nonnull)result {
    if ([GosWifiSDKMessageCenter.delegate respondsToSelector:@selector(wifiSDK:didTransAnonymousUser:)]) {
        [GosWifiSDKMessageCenter.delegate wifiSDK:wifiSDK didTransAnonymousUser:result];
    }
}

- (void)XPGWifiSDK:(GizWifiSDK * _Null_unspecified)wifiSDK didTransUser:(NSNumber * _Null_unspecified)error errorMessage:(NSString * _Null_unspecified)errorMessage {
    if ([GosWifiSDKMessageCenter.delegate respondsToSelector:@selector(XPGWifiSDK:didTransUser:errorMessage:)]) {
        [GosWifiSDKMessageCenter.delegate XPGWifiSDK:wifiSDK didTransUser:error errorMessage:errorMessage];
    }
}

- (void)wifiSDK:(GizWifiSDK * _Null_unspecified)wifiSDK didGetGroups:(NSError * _Null_unspecified)result groupList:(NSArray * _Null_unspecified)groupList {
    if ([GosWifiSDKMessageCenter.delegate respondsToSelector:@selector(wifiSDK:didGetGroups:groupList:)]) {
        [GosWifiSDKMessageCenter.delegate wifiSDK:wifiSDK didGetGroups:result groupList:groupList];
    }
}

/*
 @deprecated 此接口已废弃，不再提供支持。请使用替代接口：[GizWifiSDKDelegate wifiSDK:didGetGroups:groupList:]
 */
- (void)XPGWifiSDK:(GizWifiSDK * _Null_unspecified)wifiSDK didGetGroups:(NSArray * _Null_unspecified)groupList result:(int)result {
    if ([GosWifiSDKMessageCenter.delegate respondsToSelector:@selector(XPGWifiSDK:didGetGroups:result:)]) {
        [GosWifiSDKMessageCenter.delegate XPGWifiSDK:wifiSDK didGetGroups:groupList result:result];
    }
}

- (void)wifiSDK:(GizWifiSDK * _Nonnull)wifiSDK didNotifyEvent:(GizEventType)eventType eventSource:(id _Nonnull)eventSource eventID:(GizWifiErrorCode)eventID eventMessage:(NSString * _Nullable)eventMessage {
    if ([GosWifiSDKMessageCenter.delegate respondsToSelector:@selector(wifiSDK:didNotifyEvent:eventSource:eventID:eventMessage:)]) {
        [GosWifiSDKMessageCenter.delegate wifiSDK:wifiSDK didNotifyEvent:eventType eventSource:eventSource eventID:eventID eventMessage:eventMessage];
    }
}

- (void)wifiSDK:(GizWifiSDK * _Nonnull)wifiSDK didGetCurrentCloudService:(NSError * _Nonnull)result cloudServiceInfo:(NSDictionary * _Nullable)cloudServiceInfo {
    
    if ([GosWifiSDKMessageCenter.delegate respondsToSelector:@selector(wifiSDK:didGetCurrentCloudService:cloudServiceInfo:)]) {
        [GosWifiSDKMessageCenter.delegate wifiSDK:wifiSDK didGetCurrentCloudService:result cloudServiceInfo:cloudServiceInfo];
    }
    if (result.code == GIZ_SDK_SUCCESS) {
        NSString *openAPIDomain = cloudServiceInfo[@"openAPIDomain"];
        if ([openAPIDomain isEqualToString:@"usapi.gizwits.com"] || [openAPIDomain isEqualToString:@"euapi.gizwits.com"]) {
            common.unChineseServer = YES;
            return;
        }
    }
    common.unChineseServer = NO;
}

- (void)wifiSDK:(GizWifiSDK * _Nonnull)wifiSDK didChannelIDBind:(NSError * _Nonnull)result {
    if ([GosWifiSDKMessageCenter.delegate respondsToSelector:@selector(wifiSDK:didChannelIDBind:)]) {
        [GosWifiSDKMessageCenter.delegate wifiSDK:wifiSDK didChannelIDBind:result];
    }
}

- (void)wifiSDK:(GizWifiSDK * _Nonnull)wifiSDK didChannelIDUnBind:(NSError * _Nonnull)result {
    if ([GosWifiSDKMessageCenter.delegate respondsToSelector:@selector(wifiSDK:didChannelIDUnBind:)]) {
        [GosWifiSDKMessageCenter.delegate wifiSDK:wifiSDK didChannelIDUnBind:result];
    }
}

- (void)wifiSDK:(GizWifiSDK * _Nonnull)wifiSDK didDisableLAN:(NSError * _Nonnull)result {
    if ([GosWifiSDKMessageCenter.delegate respondsToSelector:@selector(wifiSDK:didDisableLAN:)]) {
        [GosWifiSDKMessageCenter.delegate wifiSDK:wifiSDK didDisableLAN:result];
    }
}

- (void)wifiSDK:(GizWifiSDK * _Nonnull)wifiSDK didGetDevicesToSetServerInfo:(NSError * _Nonnull)result devices:(NSArray <NSDictionary *>* _Nullable)devices {
    if ([GosWifiSDKMessageCenter.delegate respondsToSelector:@selector(wifiSDK:didGetDevicesToSetServerInfo:devices:)]) {
        [GosWifiSDKMessageCenter.delegate wifiSDK:wifiSDK didGetDevicesToSetServerInfo:result devices:devices];
    }
}

- (void)wifiSDK:(GizWifiSDK * _Nonnull)wifiSDK didSetDeviceServerInfo:(NSError * _Nonnull)result mac:(NSString * _Nullable)mac {
    if ([GosWifiSDKMessageCenter.delegate respondsToSelector:@selector(wifiSDK:didSetDeviceServerInfo:mac:)]) {
        [GosWifiSDKMessageCenter.delegate wifiSDK:wifiSDK didSetDeviceServerInfo:result mac:mac];
    }
}

@end
