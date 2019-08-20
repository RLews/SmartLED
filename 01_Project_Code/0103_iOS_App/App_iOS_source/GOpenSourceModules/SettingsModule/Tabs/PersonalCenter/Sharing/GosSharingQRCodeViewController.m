//
//  GosSharingQRCodeViewController.m
//  GOpenSource_AppKit
//
//  Created by Tom on 2016/12/22.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import "GosSharingQRCodeViewController.h"
#import <GizWifiSDK/GizWifiSDK.h>
#import "GosAddSharingViewController.h"
#import "GosCommon.h"

@interface GosSharingQRCodeViewController () <GizDeviceSharingDelegate>

@property (weak, nonatomic) IBOutlet UILabel *labelDescription;
@property (weak, nonatomic) IBOutlet UILabel *labelStatus;
@property (weak, nonatomic) IBOutlet UIImageView *imageQRCode;

@property (strong, nonatomic) GizWifiDevice *device;
@property (strong, nonatomic) NSTimer *timer;//倒计时计时器
@property (strong, nonatomic) NSDate *expiredDate;

@end

@implementation GosSharingQRCodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"page_back_button.png"] style:UIBarButtonItemStylePlain target:self action:@selector(onBack)];
    
    //分享的设备名称提示
    GizWifiDevice *device = nil;
    GosAddSharingViewController *lastCtrl = (GosAddSharingViewController *)self.navigationController.viewControllers[self.navigationController.viewControllers.count-2];
    if ([lastCtrl isMemberOfClass:[GosAddSharingViewController class]]) {
        device = [lastCtrl sharingDevice];
    }
    self.device = device;
    NSString *desc = [common deviceName:device];
    if (desc.length == 0) {
        desc = NSLocalizedString(@"Device", nil);
    }
    self.labelDescription.text = [NSString stringWithFormat:NSLocalizedString(@"sharing_device_info_format", nil), desc];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [GizDeviceSharing setDelegate:self];
    
    [GosCommon showHUDAddedTo:self.view animated:YES];
    [GizDeviceSharing sharingDevice:common.token deviceID:self.device.did sharingWay:GizDeviceSharingByQRCode guestUser:nil guestUserType:GizUserOther];
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
            self.labelStatus.text = NSLocalizedString(@"QR code has been expired", nil);
            return;
        }
        float n;
        float p = modff(expired/60, &n);
        if (p > 0) {
            n = n + 1;
        }
        self.labelStatus.text = [NSString stringWithFormat:NSLocalizedString(@"qrcode_sharing_status_format", nil), @(n)];
    } else {
        self.labelStatus.text = nil;
    }
}

- (void)onBack {
    [GosCommon safePopViewController:self.navigationController currentViewController:self animated:YES];
}

- (void)didSharingDevice:(NSError *)result deviceID:(NSString *)deviceID sharingID:(NSInteger)sharingID QRCodeImage:(UIImage *)QRCodeImage {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    if (result.code == GIZ_SDK_SUCCESS) {
        self.imageQRCode.image = QRCodeImage;
        
        //启动计时器
        self.expiredDate = [[NSDate date] dateByAddingTimeInterval:900];
        [self onTimer];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(onTimer) userInfo:nil repeats:YES];
    } else {
        NSString *message = @"";
        if (result.code == GIZ_SDK_REQUEST_TIMEOUT ||
            (result.code <= GIZ_SDK_INTERNET_NOT_REACHABLE && result.code >= GIZ_SDK_DNS_FAILED)) {
            message = NSLocalizedString(@"Sorry unable sharing device, please check your internet connection", nil);
        } else {
            message = NSLocalizedString(@"Failed to sharing device", nil);
        }
        self.labelStatus.text = message;
        self.labelStatus.textColor = [UIColor redColor];
        [GosCommon showAlertAutoDisappear:message];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
