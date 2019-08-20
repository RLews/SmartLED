//
//  ViewController.m
//  NewFlow
//
//  Created by GeHaitong on 16/1/13.
//  Copyright © 2016年 gizwits. All rights reserved.
//

#import "GosConfigStart.h"
#import "GosTextFieldCell.h"
#import "GosCommon.h"
#import "GosConfigModuleType.h"
#import "GizConfigAirlinkConfirm.h"
#import "GosConfigSoftAPConfirm.h"

@interface GosConfigStart () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *textSSID;
@property (weak, nonatomic) IBOutlet UITextField *textPassword;

@property (weak, nonatomic) IBOutlet UIButton *nextBtn;

@end

@implementation GosConfigStart

- (void)didEnterBackground {
    [self.textPassword becomeFirstResponder];
}

- (void)didBecomeActive {
    [self.textPassword becomeFirstResponder];
    [self getCurrentConfig];
}

- (void)getCurrentConfig {
    self.textSSID.text = GosCommon.currentSSID;
    self.textPassword.text = [common getPasswrodFromSSID:GosCommon.currentSSID];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [GosCommon updateButtonStyle:self.nextBtn];
    
    if (0 == GosCommon.currentSSID.length) {
        [GosCommon showAlertAutoDisappear:NSLocalizedString(@"No open Wi-Fi", nil)];
    } else {
        [self getCurrentConfig];
    }
    
    // 左边空出8px
    self.textSSID.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, 8)];
    self.textSSID.leftViewMode = UITextFieldViewModeAlways;
    self.textPassword.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, 8)];
    self.textPassword.leftViewMode = UITextFieldViewModeAlways;
    
    // 给密码按钮添加显示隐藏按钮
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageNamed:@"password_show.png"] forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:@"password_hide.png"] forState:UIControlStateSelected];
    [button addTarget:self action:@selector(onPasswordVisible:) forControlEvents:UIControlEventTouchUpInside];
    button.frame = CGRectMake(0, 0, 64, 44);
    self.textPassword.rightView = button;
    self.textPassword.rightViewMode = UITextFieldViewModeAlways;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"page_back_button.png"] style:UIBarButtonItemStylePlain target:self action:@selector(onBack)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self onTap];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];

    [self.textPassword resignFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onPasswordVisible:(UIButton *)button {
    button.selected = !button.selected;
    self.textPassword.secureTextEntry = !button.selected;
}

- (void)onPushToNextPage {
    GosCommon *dataCommon = common;
    NSLog(@"common.wifiModuleType = %@", common.wifiModuleTypes);
    dataCommon.ssid = self.textSSID.text;
    if (nil == dataCommon.ssid) {
        dataCommon.ssid = NSLocalizedString(@"Please enter the Wi-Fi password", nil);
    }
    //记录ssid、密码
    [dataCommon saveSSID:dataCommon.ssid key:self.textPassword.text];
    
    //传递配置的类型
    NSArray *configTextArray = @[@"ESP", @"MXCHIP", @"HF", @"RTK",
                                 @"WM", @"QCA", @"FlyLink", @"TI", @"FSK",
                                 @"MXCHIP3", @"BL", @"Atmel", @"Other"];
    NSMutableArray *newConfigTextArray = [NSMutableArray array];
    for (NSString *str in configTextArray) {
        NSString *configStr = NSLocalizedString(str, nil);
        if (configStr) {
            [newConfigTextArray addObject:configStr];
        } else {
            [newConfigTextArray addObject:str];
        }
    }
    NSArray *configValueArray = @[@(GizGAgentESP), @(GizGAgentMXCHIP),
                                  @(GizGAgentHF), @(GizGAgentRTK),
                                  @(GizGAgentWM), @(GizGAgentQCA),
                                  @(GizGAgentFlyLink),
                                  @(GizGAgentTI), @(GizGAgentFSK),
                                  @(GizGAgentMXCHIP3), @(GizGAgentBL),
                                  @(GizGAgentAtmelEE), @(GizGAgentOther)];
    if (newConfigTextArray.count > 0 && configValueArray.count > 0 && dataCommon.wifiModuleTypes.count == 0) { //选择模组类型
        [self performSegueWithIdentifier:@"toSelect" sender:@[newConfigTextArray, configValueArray]];
    } else {

        if (self.isSoftAPMode) {
            [GosConfigStart pushToSoftAP:self.navigationController configType:common.wifiModuleTypes];
        }

        else {

            GizConfigAirlinkConfirm *confirmCtrl = [self.storyboard instantiateViewControllerWithIdentifier:@"Confirm"];
            confirmCtrl.airlinkConfigType = common.wifiModuleTypes;
            [GosCommon safePushViewController:self.navigationController viewController:confirmCtrl animated:YES];

        }


        
    }
}

- (IBAction)onNext:(id)sender {
    if (0 == self.textPassword.text.length) {
        [GosCommon showAlertEmptyPassword:^(UIAlertAction *action) {
            [self onPushToNextPage];
        }];
    } else {
        [self onPushToNextPage];
    }
}

- (IBAction)onTap {
    [self.textPassword resignFirstResponder];
}

- (void)onBack {
    [GosCommon safePopViewController:self.navigationController currentViewController:self animated:YES];
}


+ (void)pushToSoftAP:(UINavigationController *)navigationController configType:(NSArray *)configType {
    UIStoryboard *softapFlow =[UIStoryboard storyboardWithName:@"GosSoftAP" bundle:nil];
    UINavigationController *navCtrl = [softapFlow instantiateInitialViewController];
    
    GosConfigSoftAPConfirm *softapStartCtrl = (GosConfigSoftAPConfirm *)navCtrl.viewControllers.firstObject;
    softapStartCtrl.softapConfigType = configType;
    
    NSMutableArray *viewControllers = [navigationController.viewControllers mutableCopy];
    
    @try {
        [viewControllers addObjectsFromArray:@[softapStartCtrl]];
        [navigationController setViewControllers:viewControllers animated:YES];
    }
    @catch (NSException *exception) {
        GIZ_LOG_ERROR("cause exception: %s", exception.description.UTF8String);
    }
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(NSArray *)sender {
    GosConfigModuleType *typeCtrl = segue.destinationViewController;
    typeCtrl.configTextArray = sender.firstObject;
    typeCtrl.configValueArray = sender.lastObject;
    typeCtrl.isSoftAPMode = self.isSoftAPMode;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == self.textSSID) {
        [textField resignFirstResponder];
        NSURL *url = GosCommon.wifiURL;
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        } else {
            [GosCommon showAlertWithTip:NSLocalizedString(@"Manually click \"Settings\" icon on your desktop, then select \"Wi-Fi\"", nil)];
        }
    }
}

@end
