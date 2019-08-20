//
//  RegisterViewController.m
//  GBOSA
//
//  Created by Zono on 16/4/11.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import "GosRegisterViewController.h"
#import "GosTextFieldCell.h"
#import <GizWifiSDK/GizWifiSDK.h>
#import "AppDelegate.h"
#import "GosLoginViewController.h"

@interface GosRegisterViewController () <GizWifiSDKDelegate, UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) GosTextFieldCell *userCell;
@property (strong, nonatomic) GosTextFieldCell *verifyCell;
@property (strong, nonatomic) GosTextFieldCell *passwordCell;
@property (strong, nonatomic) GosTextFieldCell *passwordVerifyCell;
@property (strong, nonatomic) UIButton *btnType;
@property (strong, nonatomic) UIButton *btnVerify;
@property (assign, nonatomic) GizUserAccountType accountType;
@property (assign, nonatomic) BOOL isGetVerifyCodeSucceed; //上次获取验证码状态

@property (assign, nonatomic) NSInteger verifyCodeCounter;
@property (strong, nonatomic) NSTimer *verifyTimer;

@property (assign, nonatomic) BOOL isSuccess; //注册成功

@end

@implementation GosRegisterViewController 

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = false;
    self.accountType = GizUserPhone;
    if (!common.isRegisterPhoneUser) {
        if (common.isRegisterNormalUser) {
            self.accountType = GizUserNormal;
        } else {
            self.accountType = GizUserEmail;
        }
        [self updateTableHeight:157];
    }
        
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"page_back_button.png"] style:UIBarButtonItemStylePlain target:self action:@selector(onBack)];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController.navigationBar setHidden:NO];
    GosWifiSDKMessageCenter.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated {
    [self.userCell.textField becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.verifyTimer invalidate];
    GosWifiSDKMessageCenter.delegate = nil;
    self.verifyTimer = nil;
    self.verifyCodeCounter = 0;
    if (self.isSuccess) { //事件滞后，只能使用标记
        self.isSuccess = NO;
        //自动登录
        GosLoginViewController *loginCtrl = (GosLoginViewController *)[GosCommon firstViewControllerFromClass:self.navigationController class:[GosLoginViewController class]];
        [loginCtrl autoLogin];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - table view
- (BOOL)displayTypeSelection {
    return (common.isRegisterNormalUser && common.isRegisterPhoneUser) ||
    (common.isRegisterNormalUser && common.isRegisterEmailUser) ||
    (common.isRegisterPhoneUser && common.isRegisterEmailUser);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 1) {
        if (self.accountType == GizUserPhone) {
            return 3;
        } else {
            return 2;
        }
    }
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 13;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: //用户类型
            if (nil == self.userCell) {
                self.userCell = [GosCommon controllerWithClass:[GosTextFieldCell class] tableView:tableView reuseIdentifier:@"userCell"];
                self.userCell.textField.delegate = self;
                self.userCell.textField.returnKeyType = UIReturnKeyNext;
                UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 44)];
                view.backgroundColor = [UIColor lightGrayColor];
                if ([self displayTypeSelection]) {
                    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                    self.btnType = button;
                    [button addSubview:view];
                    button.frame = CGRectMake(0, 0, 120, 44);
                    button.titleLabel.font = [UIFont systemFontOfSize:14];
                    switch (self.accountType) {
                        case GizUserNormal:
                            [button setTitle:NSLocalizedString(@"User name sign up", nil) forState:UIControlStateNormal];
                            break;
                        case GizUserPhone:
                            [button setTitle:NSLocalizedString(@"Phone sign up", nil) forState:UIControlStateNormal];
                            break;
                        default:
                            [button setTitle:NSLocalizedString(@"Email sign up", nil) forState:UIControlStateNormal];
                            break;
                    }
                    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                    [button setImage:[UIImage imageNamed:@"user_choose_arrow.png"] forState:UIControlStateNormal];
                    [self updateTypeButtonInsets];
                    [button addTarget:self action:@selector(onSelectType) forControlEvents:UIControlEventTouchUpInside];
                    self.userCell.accessoryView = button;
                }
            }
            switch (self.accountType) {
                case GizUserNormal:
                    self.userCell.textField.placeholder = NSLocalizedString(@"User name", nil);
                    break;
                case GizUserPhone:
                    self.userCell.textField.placeholder = NSLocalizedString(@"please input cellphone", nil);
                    break;
                default:
                    self.userCell.textField.placeholder = NSLocalizedString(@"please input email", nil);
                    break;
            }
            return self.userCell;
        case 1: //密码框
            if (self.accountType == GizUserPhone) {
                switch (indexPath.row) {
                    case 0:
                        if (nil == self.verifyCell) {
                            self.verifyCell = [GosCommon controllerWithClass:[GosTextFieldCell class] tableView:tableView reuseIdentifier:@"verfiyCell"];
                            self.verifyCell.textField.delegate = self;
                            self.verifyCell.textField.placeholder = NSLocalizedString(@"Verification code", nil);
                            self.verifyCell.textField.returnKeyType = UIReturnKeyNext;
                            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                            self.btnVerify = button;
                            button.frame = CGRectMake(0, 0, 90, 30);
                            button.titleLabel.font = [UIFont systemFontOfSize:14];
                            [button setTitle:NSLocalizedString(@"Get verification code", nil) forState:UIControlStateNormal];
                            [button setTitleColor:[UIColor colorWithRed:1 green:0.582 blue:0 alpha:1] forState:UIControlStateNormal];
                            [button setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
                            [button addTarget:self action:@selector(didSendCodeBtnPressed) forControlEvents:UIControlEventTouchUpInside];
                            self.verifyCell.accessoryView = button;
                        }
                        return self.verifyCell;
                    case 1:
                        if (nil == self.passwordCell) {
                            self.passwordCell = [GosCommon controllerWithClass:[GosTextFieldCell class] tableView:tableView reuseIdentifier:@"passwordCell"];
                            self.passwordCell.textField.delegate = self;
                            self.passwordCell.textField.placeholder = NSLocalizedString(@"Password(at least 6 characters)", nil);
                            self.passwordCell.textField.returnKeyType = UIReturnKeyNext;
                        }
                        return self.passwordCell;
                    case 2:
                        if (nil == self.passwordVerifyCell) {
                            self.passwordVerifyCell = [GosCommon controllerWithClass:[GosTextFieldCell class] tableView:tableView reuseIdentifier:@"passwordVerifyCell"];
                            self.passwordVerifyCell.textField.delegate = self;
                            self.passwordVerifyCell.textField.placeholder = NSLocalizedString(@"Password again(at least 6 characters)", nil);
                            self.passwordVerifyCell.textField.returnKeyType = UIReturnKeyDone;
                        }
                        return self.passwordVerifyCell;
                    default:
                        break;
                }
                break;
            } else {
                switch (indexPath.row) {
                    case 0:
                        if (nil == self.passwordCell) {
                            self.passwordCell = [GosCommon controllerWithClass:[GosTextFieldCell class] tableView:tableView reuseIdentifier:@"passwordCell"];
                            self.passwordCell.textField.delegate = self;
                            self.passwordCell.textField.placeholder = NSLocalizedString(@"Password(at least 6 characters)", nil);
                            self.passwordCell.textField.returnKeyType = UIReturnKeyNext;
                        }
                        return self.passwordCell;
                    case 1:
                        if (nil == self.passwordVerifyCell) {
                            self.passwordVerifyCell = [GosCommon controllerWithClass:[GosTextFieldCell class] tableView:tableView reuseIdentifier:@"passwordVerifyCell"];
                            self.passwordVerifyCell.textField.delegate = self;
                            self.passwordVerifyCell.textField.placeholder = NSLocalizedString(@"Password again(at least 6 characters)", nil);
                            self.passwordVerifyCell.textField.returnKeyType = UIReturnKeyDone;
                        }
                        return self.passwordVerifyCell;
                    default:
                        break;
                }
                break;
            }
        default:
            break;
    }
    return nil;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

#pragma mark - IBAction
- (void)didSendCodeBtnPressed {
    if ([self.userCell.textField.text isEqualToString:@""]) {
        [GosCommon showAlertAutoDisappear:NSLocalizedString(@"please input cellphone", nil)];
        return;
    } else {
        [GosCommon showHUDAddedTo:self.view animated:YES];
        [[GizWifiSDK sharedInstance] requestSendPhoneSMSCode:APP_SECRET phone:self.userCell.textField.text];
    }
}

- (void)updateTypeButtonInsets {
    [self.btnType setTitleEdgeInsets:UIEdgeInsetsMake(0, -self.btnType.imageView.image.size.width, 0, self.btnType.imageView.image.size.width)];
    [self.btnType setImageEdgeInsets:UIEdgeInsetsMake(0, self.btnType.titleLabel.intrinsicContentSize.width+5, 0, -self.btnType.titleLabel.intrinsicContentSize.width)];
}

- (void)updateTableHeight:(CGFloat)height {
    NSLayoutConstraint *constraint = self.tableView.constraints.firstObject;
    constraint.constant = height;
    [self.tableView addConstraint:constraint];
}

- (void)cleanupText {
    self.userCell.textField.text = @"";
    self.verifyCell.textField.text = @"";
    self.passwordCell.textField.text = @"";
    self.passwordVerifyCell.textField.text = @"";
}

- (void)onSelectType {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    if (common.isRegisterPhoneUser) {
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Phone sign up", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self cleanupText];
            [self updateTableHeight:201];
            self.accountType = GizUserPhone;
            [self.btnType setTitle:NSLocalizedString(@"Phone sign up", nil) forState:UIControlStateNormal];
            [self updateTypeButtonInsets];
            [self.tableView reloadData];
        }]];
    }

        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    [alertController show];
}

- (void)onBack {
    [GosCommon safePopViewController:self.navigationController currentViewController:self animated:YES];
}

- (IBAction)registerBtnPressed:(id)sender {
    if (self.accountType == GizUserPhone) {
        // 手机号格式检测
//        NSString *phone = self.userCell.textField.text;
//        NSString *regular = @"^[0-9]+$";
//        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self MATCHES %@", regular];
//        if (phone.length == 0 || ![predicate evaluateWithObject:phone]) {
//            [GosCommon showAlertAutoDisappear:NSLocalizedString(@"Username is not phone number", nil)];
//            return;
//        }
        if (!self.isGetVerifyCodeSucceed) {
            [GosCommon showAlertAutoDisappear:NSLocalizedString(@"SMS Code is error", nil)];
            return;
        }
    } else if (self.accountType == GizUserEmail) {
        NSString *email = self.userCell.textField.text;
        NSString *regular = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self MATCHES %@", regular];
        if (email.length == 0 || ![predicate evaluateWithObject:email]) {
            [GosCommon showAlertAutoDisappear:NSLocalizedString(@"Username is not email", nil)];
            return;
        }
    }
    if (self.passwordCell.textField.text.length < 6) {
        [GosCommon showAlertAutoDisappear:NSLocalizedString(@"Password is at least 6 characters", nil)];
        return;
    }
    if (![self.passwordCell.textField.text isEqualToString:self.passwordVerifyCell.textField.text]) {
        [GosCommon showAlertAutoDisappear:NSLocalizedString(@"Password confirm failed", nil)];
        return;
    }
    [GosCommon showHUDAddedTo:self.view animated:YES];
    [[GizWifiSDK sharedInstance] registerUser:self.userCell.textField.text password:self.passwordCell.textField.text verifyCode:self.verifyCell.textField.text accountType:self.accountType];
}

#pragma mark - GizWifiSDKDelegate
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didRequestSendPhoneSMSCode:(NSError *)result token:(NSString *)token {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    if (result.code == GIZ_SDK_SUCCESS) {
        self.isGetVerifyCodeSucceed = YES;
        [GosCommon showAlertAutoDisappear:NSLocalizedString(@"Phone verification code sent successfully", nil)];
        [self.userCell.textField setEnabled:NO];
        [self.userCell.textField setTextColor:[UIColor grayColor]];
        [self.verifyCell.textField becomeFirstResponder];
        
        self.verifyCodeCounter = 60;
        self.verifyTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateVerifyButton) userInfo:nil repeats:YES];
    } else {
        self.isGetVerifyCodeSucceed = NO;
        [GosCommon showAlertAutoDisappear:NSLocalizedString(@"Phone verification code sent failure", nil)];
    }
}

- (void)wifiSDK:(GizWifiSDK *)wifiSDK didRegisterUser:(NSError *)result uid:(NSString *)uid token:(NSString *)token {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    if (result.code == GIZ_SDK_SUCCESS) {
        [GosCommon showAlertAutoDisappear:NSLocalizedString(@"Registration success", nil)];
        [common saveUserDefaults:GizUserNameLogin userName:self.userCell.textField.text password:self.passwordCell.textField.text tokenSecret:nil uid:nil token:nil];
        [GosCommon safePopViewController:self.navigationController currentViewController:self animated:YES];
        self.isSuccess = YES;
    } else {
        NSString *info = [common checkErrorCode:result.code];
        [GosCommon showAlertAutoDisappear:info];
    }
}

#pragma mark - Event
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.userCell.textField) {
        [self.verifyCell.textField becomeFirstResponder];
    } else if (textField == self.verifyCell.textField) {
        [self.passwordCell.textField becomeFirstResponder];
    } else if (textField == self.passwordCell.textField) {
        [self.passwordVerifyCell.textField becomeFirstResponder];
    } else {
        [self.passwordVerifyCell.textField resignFirstResponder];
    }
    return NO;
}

#pragma mark - Others
- (void)updateVerifyButton {
    if(self.verifyCodeCounter == 0) {
        [self.verifyTimer invalidate];
        self.btnVerify.enabled = true;
        [self.btnVerify setTitle:NSLocalizedString(@"Get verification code", nil) forState:UIControlStateNormal];
        [self.btnVerify setTitleColor:[UIColor colorWithRed:1 green:0.582 blue:0 alpha:1] forState:UIControlStateNormal];
        [self.userCell.textField setEnabled:YES];
        [self.userCell.textField setTextColor:[UIColor blackColor]];
        return;
    }
    NSString *title = [NSString stringWithFormat:@"%is %@", (int)self.verifyCodeCounter, NSLocalizedString(@"Try again", nil)];
    self.btnVerify.enabled = true;
    [self.btnVerify setTitle:title forState:UIControlStateNormal];
    [self.btnVerify setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    self.btnVerify.enabled = false;

    self.verifyCodeCounter--;
}

@end
