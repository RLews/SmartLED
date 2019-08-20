//
//  GosChangeUserPasswordViewController.m
//  GOpenSource_AppKit
//
//  Created by Tom Ge on 2016/11/18.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import "GosChangeUserPasswordViewController.h"

#import "GosCommon.h"

#import "GosUserPasswordTableViewCell.h"

@interface GosChangeUserPasswordViewController () <GizWifiSDKDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) UITextField *textOrigin;
@property (weak, nonatomic) UITextField *textNew;
@property (weak, nonatomic) UITextField *textRepeat;

@end

@implementation GosChangeUserPasswordViewController

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if ([[UIDevice currentDevice].systemVersion integerValue] < 11) { //ios11以下才需要
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    GosWifiSDKMessageCenter.delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    GosWifiSDKMessageCenter.delegate = nil;
}

- (IBAction)onConfirm:(id)sender {
    //确认修改密码
    if (self.textOrigin.text.length == 0) {
        [GosCommon showAlertAutoDisappear:NSLocalizedString(@"Enter current password", nil)];
        return;
    }
    if (self.textNew.text.length == 0) {
        [GosCommon showAlertAutoDisappear:NSLocalizedString(@"Enter new password", nil)];
        return;
    }
    if (self.textRepeat.text.length == 0) {
        [GosCommon showAlertAutoDisappear:NSLocalizedString(@"Re-enter new password", nil)];
        return;
    }
    if (self.textNew.text.length < 6) {
        [GosCommon showAlertAutoDisappear:NSLocalizedString(@"Password is at least 6 characters", nil)];
        return;
    }
    
    if (![self.textNew.text isEqualToString:self.textRepeat.text]) {
        [GosCommon showAlertAutoDisappear:NSLocalizedString(@"Password does not match the confirm password", nil)];
        return;
    }
    
    [self.textOrigin resignFirstResponder];
    [self.textNew resignFirstResponder];
    [self.textRepeat resignFirstResponder];
    
    [GosCommon showHUDAddedTo:self.view tips:NSLocalizedString(@"Now saving, please wait...", nil) tag:0 animated:YES];
    [[GizWifiSDK sharedInstance] changeUserPassword:common.token oldPassword:self.textOrigin.text newPassword:self.textNew.text];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Configure the cell...
    GosUserPasswordTableViewCell *passwordCell = [GosCommon controllerWithClass:[GosUserPasswordTableViewCell class] tableView:tableView reuseIdentifier:@"GosUserPasswordTableViewCell"];
    switch (indexPath.row) {
        case 0:
            self.textOrigin = passwordCell.textPassword;
            self.textOrigin.placeholder = NSLocalizedString(@"Enter current password", nil);
            self.textOrigin.returnKeyType = UIReturnKeyNext;
            self.textOrigin.delegate = self;
            break;
        case 1:
            self.textNew = passwordCell.textPassword;
            self.textNew.placeholder = NSLocalizedString(@"Enter new password", nil);
            self.textNew.returnKeyType = UIReturnKeyNext;
            self.textNew.delegate = self;
            break;
        case 2:
            self.textRepeat = passwordCell.textPassword;
            self.textRepeat.placeholder = NSLocalizedString(@"Re-enter new password", nil);
            self.textRepeat.returnKeyType = UIReturnKeyDone;
            self.textRepeat.delegate = self;
            break;
            
        default:
            break;
    }
    return passwordCell;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)wifiSDK:(GizWifiSDK *)wifiSDK didChangeUserPassword:(NSError *)result {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    if (result.code == GIZ_SDK_SUCCESS) {
        [common saveUserDefaults:GizUserNameLogin userName:common.tmpUser password:self.textNew.text tokenSecret:nil uid:nil token:nil];
        [GosCommon showAlertAutoDisappear:NSLocalizedString(@"Password change successful", nil)];
        [GosCommon safePopViewController:self.navigationController currentViewController:self animated:YES];
    } else {
        if (result.code == GIZ_OPENAPI_USERNAME_PASSWORD_ERROR) {
            [GosCommon showAlertAutoDisappear:NSLocalizedString(@"Old password invalid", nil)];
        } else {
            [GosCommon showAlertAutoDisappear:NSLocalizedString(@"Password change failed", nil)];
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.textOrigin) {
        [self.textNew becomeFirstResponder];
    } else if (textField == self.textNew) {
        [self.textRepeat becomeFirstResponder];
    } else if (textField == self.textRepeat) {
        [textField resignFirstResponder];
    }
    return NO;
}

@end
