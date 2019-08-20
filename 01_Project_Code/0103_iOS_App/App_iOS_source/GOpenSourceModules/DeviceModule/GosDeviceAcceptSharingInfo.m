//
//  GosDeviceAcceptSharingInfo.m
//  GOpenSource_AppKit
//
//  Created by Tom on 2017/1/5.
//  Copyright © 2017年 Gizwits. All rights reserved.
//

#import "GosDeviceAcceptSharingInfo.h"
#import <GizWifiSDK/GizWifiSDK.h>
#import "GosCommon.h"

@interface GosDeviceAcceptSharingInfo () <GizDeviceSharingDelegate>

@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UILabel *textSharingInfo;
@property (weak, nonatomic) IBOutlet UILabel *textSharingTips;

@property (strong, nonatomic) NSString *userName;
@property (strong, nonatomic) NSString *deviceInfo;
@property (strong, nonatomic) NSString *qrcode;
@property (strong, nonatomic) NSDate *expiredDate;

@property (strong, nonatomic) NSTimer *timer;//倒计时计时器

@property (weak, nonatomic) IBOutlet UIButton *btnOK;
@property (weak, nonatomic) IBOutlet UIButton *btnCancel;

@end

@implementation GosDeviceAcceptSharingInfo

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if ([UIScreen mainScreen].bounds.size.height == 812) { //iphonex
        for (NSLayoutConstraint *constraint in self.view.constraints) {
            if (constraint.firstItem == self.topView && constraint.firstAttribute == NSLayoutAttributeTop) {
                constraint.constant = 64;
                [self.view addConstraint:constraint];
            }
        }
    }
}

- (id)initWithUser:(NSString *)user deviceInfo:(NSString *)deviceInfo qrcode:(NSString *)qrcode expiredDate:(NSDate *)expiredDate {
    self = [super init];
    if (self) {
        self.userName = user;
        self.deviceInfo = deviceInfo;
        self.qrcode = qrcode;
        self.expiredDate = expiredDate;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [GosCommon updateButtonStyle:self.btnOK];
    [GosCommon updateButtonStyle:self.btnCancel];

    self.navigationItem.title = NSLocalizedString(@"Scan QRCode to bind", nil);
    
    self.textSharingInfo.text = [NSString stringWithFormat:NSLocalizedString(@"qrcode_sharing_format", nil), self.userName, self.deviceInfo];
    [self onTimer];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [GizDeviceSharing setDelegate:self];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(onTimer) userInfo:nil repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.timer invalidate];
    self.timer = nil;
}

- (void)onTimer {
    if (self.expiredDate) {
        NSTimeInterval expired = [self.expiredDate timeIntervalSinceNow];
        if (expired <= 0) {
            [self.timer invalidate];
            self.timer = nil;
            self.textSharingTips.text = NSLocalizedString(@"Tips: The device sharing have been expired", nil);
            self.btnOK.enabled = NO;
            self.btnOK.backgroundColor = [UIColor lightGrayColor];
            self.btnCancel.enabled = NO;
            self.btnCancel.backgroundColor = [UIColor lightGrayColor];
            return;
        }
        float n;
        float p = modff(expired/60, &n);
        if (p > 0) {
            n = n + 1;
        }
        self.textSharingTips.text = [NSString stringWithFormat:NSLocalizedString(@"qrcode_sharing_tip_format", nil), @(n)];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onConfirm:(id)sender {
    [GosCommon showHUDAddedTo:self.view animated:YES];
    [GizDeviceSharing acceptDeviceSharingByQRCode:common.token QRCode:self.qrcode];
}

- (IBAction)onCancel:(id)sender {
    [GosCommon safePopViewController:self.navigationController currentViewController:self animated:YES];
}

- (void)didAcceptDeviceSharingByQRCode:(NSError *)result {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    if (result.code == GIZ_SDK_SUCCESS) {
        [self onCancel:nil];
    } else {
        [GosCommon showAlertAutoDisappear:NSLocalizedString(@"Your request is failed", nil)];
    }
}

@end
