//
//  GizConfigWaiting.m
//  NewFlow
//
//  Created by GeHaitong on 16/1/13.
//  Copyright © 2016年 gizwits. All rights reserved.
//

#import "GosConfigWaiting.h"
#import <GizWifiSDK/GizWifiSDK.h>
#import "GosCommon.h"
#import "UAProgressView.h"

#import "GosConfigStart.h"
#import "GizConfigAirlinkConfirm.h"
#import "GosDeviceListViewController.h"

#define CONFIG_TIMEOUT      60

@interface GosConfigWaiting () <GizWifiSDKDelegate>

@property (strong, nonatomic) NSTimer *timer;
@property (assign, nonatomic) NSInteger timeout;

@property (weak, nonatomic) IBOutlet UAProgressView *progressView;

@property (strong, nonatomic) NSArray *airlinkConfigType;

@end

@implementation GosConfigWaiting

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSInteger count = self.navigationController.viewControllers.count;
    if (count > 1) { //配置类型？其实是只有airlink才会进到这个界面，这里可能是多余的逻辑，或者最初设计是重用了这个界面，后来拆掉的
        GizConfigAirlinkConfirm *airlinkConfirm = self.navigationController.viewControllers[count-2];
        if ([airlinkConfirm isKindOfClass:[GizConfigAirlinkConfirm class]]) {
            self.airlinkConfigType = airlinkConfirm.airlinkConfigType;
        }
    }
    
    //进度条控件相关
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60.0, 20.0)];
    [label setTextAlignment:NSTextAlignmentCenter];
    self.view.userInteractionEnabled = NO; // Allows tap to pass through to the progress view.
    self.progressView.centralView = label;
    self.progressView.progressChangedBlock = ^(UAProgressView *progressView, CGFloat progress) {
        [(UILabel *)progressView.centralView setText:[NSString stringWithFormat:@"%2.0f%%", progress * 100]];
    };
    [self.progressView setProgress:0.1];
    self.progressView.userInteractionEnabled = NO;
    self.progressView.tintColor = common.backgroundColor;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.timeout = CONFIG_TIMEOUT;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(onTimer) userInfo:nil repeats:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    GosCommon *dataCommon = common;
    
    BOOL isValidSSID = GosCommon.currentSSID.length > 0;
#if TARGET_OS_SIMULATOR
    isValidSSID = YES;
#endif
    if (isValidSSID) { //airlink和softap实现不一致？airlink有提示，softap没有提示
        NSString *key = [dataCommon getPasswrodFromSSID:dataCommon.ssid];
        NSArray *wifiGAgentType = common.wifiModuleTypes;
        if (self.airlinkConfigType) {
            wifiGAgentType = self.airlinkConfigType;
        }
        
        GIZ_LOG_BIZ("airlink_config_start", "success", "start airlink config, current ssid: %s, config ssid: %s", GosCommon.currentSSID.UTF8String, dataCommon.ssid.UTF8String);
        
        GosWifiSDKMessageCenter.delegate = self;
        [[GizWifiSDK sharedInstance] setDeviceOnboardingDeploy:dataCommon.ssid key:key configMode:GizWifiAirLink softAPSSIDPrefix:nil timeout:CONFIG_TIMEOUT wifiGAgentType:wifiGAgentType bind:NO];
        common.lastConfigType = self.airlinkConfigType;
    } else {
        [self onPushToSoftapFailed];
        [GosCommon showAlertAutoDisappear:NSLocalizedString(@"Device is not connected to Wi-Fi, can not configure", nil)];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    GosWifiSDKMessageCenter.delegate = nil;
    [self.timer invalidate];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setTimeout:(NSInteger)timeout {
    
    _timeout = timeout;
    
    float timeNow = (CONFIG_TIMEOUT-timeout);
    float secOffset = timeNow/CONFIG_TIMEOUT;
    [self.progressView setProgress:secOffset animated:YES];
}

- (void)onTimer {
    self.timeout--;
    if (0 == self.timeout) {
        [self.timer invalidate];
    }
}

- (void)onConfigSucceed:(GizWifiDevice *)device {
    [self.timer invalidate];
    [common cancelAlertViewDismiss];
    [common onSucceed:device];
    [GosCommon showAlertAutoDisappear:NSLocalizedString(@"Configuration successfully", nil)];
}

- (void)onConfigFailed {
    [common cancelAlertViewDismiss];
    if (common.isSoftAP) {
        [self onPushToSoftapFailed];
        [GosCommon showAlertAutoDisappear:NSLocalizedString(@"Configuration timeout, switch to softap mode", nil)];
    } else {
        [GosCommon showAlertAutoDisappear:NSLocalizedString(@"Configuration timeout", nil)];
        UIViewController *startCtrl = [GosCommon firstViewControllerFromClass:self.navigationController class:[GosConfigStart class]];
        [GosCommon safePopToViewController:self.navigationController viewController:startCtrl animated:YES];
    }
}

- (void)onPushToSoftapFailed {
    [GosConfigStart pushToSoftAP:self.navigationController configType:self.airlinkConfigType];
}

- (IBAction)onCancel:(id)sender {
    [common showAlertCancelConfig:^(UIAlertAction *action) {
        [[GizWifiSDK sharedInstance] stopDeviceOnboarding]; //停止配置
    }];
}

- (void)wifiSDK:(GizWifiSDK *)wifiSDK didSetDeviceOnboarding:(NSError *)result mac:(NSString *)mac did:(NSString *)did productKey:(NSString *)productKey {
    NSString *info = [NSString stringWithFormat:@"%@, %@", @(result.code), [result.userInfo objectForKey:@"NSLocalizedDescription"]];
    if (result.code == GIZ_SDK_SUCCESS) {
        GIZ_LOG_BIZ("airlink_config_end", "success", "end airlink config，result is :%s, current ssid is %s, elapsed: %i(s)", info.UTF8String, GosCommon.currentSSID.UTF8String, CONFIG_TIMEOUT-self.timeout);
        [self onConfigSucceed:nil];
    } else if (result.code == GIZ_SDK_DEVICE_CONFIG_IS_RUNNING) {
        GIZ_LOG_BIZ("airlink_config_end", "warn", "end airlink config，result is :%s, current ssid is %s, elapsed: %i(s)", info.UTF8String, GosCommon.currentSSID.UTF8String, CONFIG_TIMEOUT-self.timeout);
        [GosCommon safePopViewController:self.navigationController currentViewController:self animated:YES];
        [GosCommon showAlertWithTip:NSLocalizedString(@"Configuration is busy, please try another after a moment", nil)];
    } else if (result.code == GIZ_SDK_ONBOARDING_STOPPED) {
        [common onCancel];
    } else {
        GIZ_LOG_BIZ("airlink_config_end", "failed", "end airlink config，result is :%s, current ssid is %s, elapsed: %i(s)", info.UTF8String, GosCommon.currentSSID.UTF8String, CONFIG_TIMEOUT-self.timeout);
        [self onConfigFailed];
    }
}

@end
