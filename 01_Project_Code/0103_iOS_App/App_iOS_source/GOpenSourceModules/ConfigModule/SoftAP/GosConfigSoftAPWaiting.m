//
//  GizConfigSoftAPWaiting.m
//  NewFlow
//
//  Created by GeHaitong on 16/1/14.
//  Copyright © 2016年 gizwits. All rights reserved.
//

#import "GosConfigSoftAPWaiting.h"
#import "GosCommon.h"
#import <GizWifiSDK/GizWifiSDK.h>
#import "UAProgressView.h"

#define CONFIG_TIMEOUT      60

@interface GosConfigSoftAPWaiting () <GizWifiSDKDelegate>

@property (strong, nonatomic) NSTimer *timer;
@property (assign, nonatomic) NSInteger timeout;

@property (weak, nonatomic) IBOutlet UIButton *btnAutoJump;
@property (weak, nonatomic) IBOutlet UIButton *btnAutoJump2;

@property (weak, nonatomic) IBOutlet UAProgressView *progressView;

@end

@implementation GosConfigSoftAPWaiting

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.progressView.tintColor = common.backgroundColor;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60.0, 20.0)];
    [label setTextAlignment:NSTextAlignmentCenter];
    self.view.userInteractionEnabled = NO; // Allows tap to pass through to the progress view.
    self.progressView.centralView = label;
    self.progressView.progressChangedBlock = ^(UAProgressView *progressView, CGFloat progress) {
        [(UILabel *)progressView.centralView setText:[NSString stringWithFormat:@"%2.0f%%", progress * 100]];
    };
    [self.progressView setProgress:0.1];
    self.progressView.userInteractionEnabled = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.timeout = CONFIG_TIMEOUT;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(onTimer) userInfo:nil repeats:YES];
    
    NSString *key = [common getPasswrodFromSSID:common.ssid];
    NSArray *wifiGAgentType = common.wifiModuleTypes;
    if (self.softapConfigType) {
        wifiGAgentType = self.softapConfigType;
    }

    GIZ_LOG_BIZ("softap_config_start", "success", "start softap config, current ssid: %s, config ssid: %s", GosCommon.currentSSID.UTF8String, common.ssid.UTF8String);
    
    GosWifiSDKMessageCenter.delegate = self;
    [[GizWifiSDK sharedInstance] setDeviceOnboardingDeploy:common.ssid key:key configMode:GizWifiSoftAP softAPSSIDPrefix:nil timeout:CONFIG_TIMEOUT wifiGAgentType:wifiGAgentType bind:NO];
    common.lastConfigType = self.softapConfigType;
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

- (void)onConfigSSIDMotMatched {
    [common cancelAlertViewDismiss];
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (self.navigationController.viewControllers.lastObject == self) {
            [self.btnAutoJump2 sendActionsForControlEvents:UIControlEventTouchUpInside];
        }
    });
}

- (void)onConfigFailed {
    [common cancelAlertViewDismiss];
    double delayInSeconds = 1.0;
    __weak typeof(self) weakSelf = self;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        __strong typeof(self) strongSelf = weakSelf;
        if (strongSelf.navigationController.viewControllers.lastObject == strongSelf) {
            [strongSelf.btnAutoJump sendActionsForControlEvents:UIControlEventTouchUpInside];
        }
    });
}

- (void)wifiSDK:(GizWifiSDK *)wifiSDK didSetDeviceOnboarding:(NSError *)result mac:(NSString *)mac did:(NSString *)did productKey:(NSString *)productKey {
    NSString *info = [NSString stringWithFormat:@"%@, %@", @(result.code), [result.userInfo objectForKey:@"NSLocalizedDescription"]];
    if (result.code == GIZ_SDK_SUCCESS) {
        GIZ_LOG_BIZ("softap_config_end", "success", "end softap config，result is :%s，current ssid is %s, elapsed: %i(s), mac: %s", info.UTF8String, GosCommon.currentSSID.UTF8String, CONFIG_TIMEOUT-self.timeout, mac.UTF8String);
        [self onConfigSucceed:nil];
    } else if (result.code == GIZ_SDK_ONBOARDING_STOPPED) {
        [common onCancel];
    } else {
        GIZ_LOG_BIZ("softap_config_end", "failed", "end softap config，result is :%s，current ssid is %s, elapsed: %i(s)", info.UTF8String, GosCommon.currentSSID.UTF8String, CONFIG_TIMEOUT-self.timeout);
        if ([GosCommon.currentSSID hasPrefix:SSID_PREFIX]) {
            [self onConfigFailed];
        } else {
            if (GIZ_SDK_DEVICE_CONFIG_SSID_NOT_MATCHED == result.code) {
                [self onConfigSSIDMotMatched];
            } else {
                [self onConfigFailed];
            }
        }
    }
}

- (IBAction)onCancel:(id)sender {
    [common showAlertCancelConfig:^(UIAlertAction *action) {
        [[GizWifiSDK sharedInstance] stopDeviceOnboarding]; //停止配置
    }];
}

@end
