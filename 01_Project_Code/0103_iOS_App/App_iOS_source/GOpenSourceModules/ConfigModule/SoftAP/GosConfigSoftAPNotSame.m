//
//  GizConfigSoftAPNotSame.m
//  NewFlow
//
//  Created by GeHaitong on 16/1/14.
//  Copyright © 2016年 gizwits. All rights reserved.
//

#import "GosConfigSoftAPNotSame.h"
#import "GosCommon.h"
#import "GosSoftAPDetection.h"

@interface GosConfigSoftAPNotSame () <GizSoftAPDetectionDelegate>

@property (strong, nonatomic) GosSoftAPDetection *softapDetection;
@property (weak, nonatomic) IBOutlet UITextView *textTips;

@property (weak, nonatomic) IBOutlet UIButton *btnConnect;

@end

@implementation GosConfigSoftAPNotSame

- (void)viewDidLoad {
    [super viewDidLoad];
    [GosCommon updateButtonStyle:self.btnConnect];
    if (nil == common.ssid) {
        common.ssid = @"";
    }
    self.textTips.text = [self.textTips.text stringByReplacingOccurrencesOfString:@"xxwifixx" withString:common.ssid];
    
    NSString *btnTitle = [self.btnConnect.titleLabel.text stringByReplacingOccurrencesOfString:@"xxwifixx" withString:common.ssid];
    [self.btnConnect setTitle:btnTitle forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)didSoftAPModeDetected:(NSString *)ssid {
    GIZ_LOG_DEBUG("ssid:%s", ssid.UTF8String);
    
    if (nil == ssid) {
        return NO;
    }

    NSString *ossid = common.ssid;
    
    if ([ossid isEqualToString:ssid]) {
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.fireDate = [NSDate date];
        notification.timeZone = [NSTimeZone defaultTimeZone];
        notification.alertBody = NSLocalizedString(@"Connect successfully, click to return App", nil);
        notification.soundName = UILocalNotificationDefaultSoundName;
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];

        GIZ_LOG_BIZ("switch_wifi_notify_show", "success", "wifi switch success notify is shown");

        return YES;
    }
    
    return NO;
}

- (void)willEnterForeground {
    // 检测到 soft ap 模式，则跳转页面
    if ([GosCommon.currentSSID isEqualToString:common.ssid]) {
        [common onCancel];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)didBecomeActive {
    self.softapDetection = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (IBAction)onGoConnect:(id)sender {
    // 开启后台 SoftAP 状态检测
    NSString *ssid = common.ssid;
    self.softapDetection = [[GosSoftAPDetection alloc] initWithSoftAPSSID:ssid delegate:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    NSURL *url = GosCommon.wifiURL;
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    } else {
        [GosCommon showAlertAutoDisappear:NSLocalizedString(@"Manually click \"Settings\" icon on your desktop, then select \"Wi-Fi\"", nil)];
    }
}

- (IBAction)onCancel:(id)sender {
    [GosCommon showAlertConfigDiscard:^(UIAlertAction *action) {
        [common onCancel];
    }];
}

@end
