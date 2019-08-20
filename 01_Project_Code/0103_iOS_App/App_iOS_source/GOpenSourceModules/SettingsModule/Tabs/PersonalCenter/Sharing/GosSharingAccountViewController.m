//
//  GosSharingAccountViewController.m
//  GOpenSource_AppKit
//
//  Created by Tom on 2016/12/22.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import "GosSharingAccountViewController.h"
#import <GizWifiSDK/GizWifiSDK.h>
#import "GosAddSharingViewController.h"
#import "GosCommon.h"

@interface GosSharingAccountViewController () <UIActionSheetDelegate, GizDeviceSharingDelegate>

@property (weak, nonatomic) IBOutlet UILabel *labelDescription;
@property (weak, nonatomic) IBOutlet UITextField *textUserName;

@property (strong, nonatomic) GizWifiDevice *device;
@property (weak, nonatomic) IBOutlet UIButton *confirmBtn;

@end

@implementation GosSharingAccountViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [GosCommon updateButtonStyle:self.confirmBtn];
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
}

- (void)onCheckDetail:(GizUserAccountType)accountType {
    [GosCommon showHUDAddedTo:self.view animated:YES];
    [GizDeviceSharing sharingDevice:common.token deviceID:self.device.did sharingWay:GizDeviceSharingByNormal guestUser:self.textUserName.text guestUserType:accountType];
}

- (BOOL)isPhone:(NSString *)phone {
    NSString *regular = @"^[0-9]{1,31}$";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self MATCHES %@", regular];
    if ([predicate evaluateWithObject:phone]) {
        return YES;
    }
    return NO;
}

- (BOOL)isEmail:(NSString *)email {
    NSString *regular = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self MATCHES %@", regular];
    if ([predicate evaluateWithObject:email]) {
        return YES;
    }
    return NO;
}

- (BOOL)isUid:(NSString *)uid {
    NSString *regular = @"[A-Z0-9a-z]{32}$";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self MATCHES %@", regular];
    if ([predicate evaluateWithObject:uid]) {
        return YES;
    }
    return NO;
}

- (IBAction)onConfirm:(id)sender {
    if (self.textUserName.text.length == 0) {
        [GosCommon showAlertWithTip:NSLocalizedString(@"User account can not be empty", nil)];
        return;
    }
    
    GizUserAccountType accountType = GizUserNormal;
    if ([self isPhone:self.textUserName.text]) {
        accountType = GizUserPhone;
    } else if ([self isEmail:self.textUserName.text]) {
        accountType = GizUserEmail;
    } else if ([self isUid:self.textUserName.text]) {
        accountType = GizUserOther;
    }
    [self onCheckDetail:accountType];
}

- (void)onBack {
    [GosCommon safePopViewController:self.navigationController currentViewController:self animated:YES];
}

- (void)didSharingDevice:(NSError *)result deviceID:(NSString *)deviceID sharingID:(NSInteger)sharingID QRCodeImage:(UIImage *)QRCodeImage {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    if (result.code == GIZ_SDK_SUCCESS) {
        [GosCommon showAlertAutoDisappear:NSLocalizedString(@"Send successfully", nil)];
    } else {
        NSString *message = NSLocalizedString(@"Send failed", nil);
        switch (result.code) {
            case GIZ_OPENAPI_USER_INVALID:
                message = NSLocalizedString(@"Account input is incorrect", nil);
                break;
            case GIZ_OPENAPI_USER_NOT_EXIST:
                message = NSLocalizedString(@"User not exist", nil);
                break;
            case GIZ_OPENAPI_GUEST_ALREADY_BOUND:
                message = NSLocalizedString(@"Account has been shared", nil);
                break;
            case GIZ_OPENAPI_CANNOT_SHARE_TO_SELF:
                message = NSLocalizedString(@"can not share device to self!", nil);
                break;
            default:
                break;
        }
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
