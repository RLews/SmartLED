//
//  GizConfigSoftAPFailed.m
//  NewFlow
//
//  Created by GeHaitong on 16/1/14.
//  Copyright © 2016年 gizwits. All rights reserved.
//

#import "GosConfigSoftAPFailed.h"
#import "GosCommon.h"
#import "GosConfigStart.h"

@interface GosConfigSoftAPFailed ()

@property (weak, nonatomic) IBOutlet UIButton *retryBtn;

@end

@implementation GosConfigSoftAPFailed

- (void)viewDidLoad {
    [super viewDidLoad];
    [GosCommon updateButtonStyle:self.retryBtn];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onCancel:(id)sender {
    [GosCommon showAlertConfigDiscard:^(UIAlertAction *action) {
        [common onCancel];
    }];
}

- (IBAction)onRetry:(id)sender {
    UIViewController *startCtrl = [GosCommon firstViewControllerFromClass:self.navigationController class:[GosConfigStart class]];
    [GosCommon safePopToViewController:self.navigationController viewController:startCtrl animated:YES];
}

@end
