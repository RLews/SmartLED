//
//  GizConfigSoftAPStart.m
//  NewFlow
//
//  Created by GeHaitong on 16/1/13.
//  Copyright © 2016年 gizwits. All rights reserved.
//

#import "GosConfigSoftAPStart.h"
#import "GosSoftAPDetection.h"
#import "GosCommon.h"
#import "GosConfigSoftAPWaiting.h"
#import <TargetConditionals.h>

@interface GosConfigSoftAPStart () <GizSoftAPDetectionDelegate>

@property (strong) GosSoftAPDetection *softapDetection;
@property (weak, nonatomic) IBOutlet UIButton *btnAutoJump;
@property (weak, nonatomic) IBOutlet UIButton *btnHelp;
@property (weak, nonatomic) IBOutlet UIImageView *imgSoftapTips;

@property (weak, nonatomic) IBOutlet UIButton *connectToSoftApBtn;
@property (weak, nonatomic) IBOutlet UILabel *currentSSID;

@end

@implementation GosConfigSoftAPStart

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [GosCommon updateButtonStyle:self.connectToSoftApBtn];
    
    // 为按钮添加下划线
    NSString *str = self.btnHelp.titleLabel.text;
    NSMutableAttributedString *mstr = [[NSMutableAttributedString alloc] initWithString:str];
    [mstr addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:NSMakeRange(0, str.length)];
    [self.btnHelp setAttributedTitle:mstr forState:UIControlStateNormal];

    self.imgSoftapTips.gifPath = [[NSBundle mainBundle] pathForResource:@"config_softap_tips" ofType:@"gif"];
        
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"page_back_button.png"] style:UIBarButtonItemStylePlain target:self action:@selector(onBack)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.imgSoftapTips startGIF];
    [self onUpdateSSID];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdateSSID) name:UIApplicationDidBecomeActiveNotification object:nil];
    
#if TARGET_OS_SIMULATOR
    [self onPushToConfigurePage];
#endif
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.imgSoftapTips stopGIF];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)onUpdateSSID {
    self.currentSSID.text = [NSString stringWithFormat:@"%@%@", NSLocalizedString(@"current connect", nil), GosCommon.currentSSID];
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
    
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.fireDate = [NSDate date];
    notification.timeZone = [NSTimeZone defaultTimeZone];
    notification.alertBody = NSLocalizedString(@"Connect successfully, click to return App", nil);
    notification.soundName = UILocalNotificationDefaultSoundName;
    
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    
    GIZ_LOG_BIZ("switch_wifi_notify_show", "success", "wifi switch success notify is shown");
    
    return YES;
}

- (void)willEnterForeground {
    // 检测到 soft ap 模式，则跳转页面。每100ms检测一次，直到检测到为止
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        static BOOL isRunning = NO;
        if (!isRunning) {
            isRunning = YES;
            while (self.navigationController.viewControllers.lastObject == self) {
                if ([GosCommon.currentSSID hasPrefix:SSID_PREFIX]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self onPushToConfigurePage];
                    });
                }
                usleep(100000);
            }
            isRunning = NO;
        }
    });
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)didBecomeActive {
    self.softapDetection = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (IBAction)onOpenConfig:(id)sender {
    // 开启后台 SoftAP 状态检测
        
    self.softapDetection = [[GosSoftAPDetection alloc] initWithSoftAPSSID:SSID_PREFIX delegate:self];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    NSURL *url = GosCommon.wifiURL;
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    } else {
        [GosCommon showAlertAutoDisappear:NSLocalizedString(@"Manually click \"Settings\" icon on your desktop, then select \"Wi-Fi\"", nil)];
    }
}

- (void)onPushToConfigurePage {
    if (self.navigationController.viewControllers.lastObject == self) {
        [self.btnAutoJump sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
}

- (IBAction)onBack {
    [GosCommon safePopViewController:self.navigationController currentViewController:self animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[GosConfigSoftAPWaiting class]]) {
        GosConfigSoftAPWaiting *waitCtrl = (GosConfigSoftAPWaiting *)segue.destinationViewController;
        waitCtrl.softapConfigType = self.softapConfigType;
        waitCtrl.isNewInterface = self.isNewInterface;
        waitCtrl.isBindInterface = self.isBindInterface;
    }
}

@end
