//
//  GosConfigSoftAPConfirm.m
//  GOpenSource_AppKit
//
//  Created by Tom on 2017/6/2.
//  Copyright © 2017年 Gizwits. All rights reserved.
//

#import "GosConfigSoftAPConfirm.h"
#import "GosCommon.h"
#import "GosConfigSoftAPStart.h"

@interface GosConfigSoftAPConfirm ()

@property (weak, nonatomic) IBOutlet UIButton *confirmBtn;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (assign, nonatomic) NSInteger counter; //隐秘操作1
@property (assign, nonatomic) NSInteger counter2; //隐秘操作2

@end

@implementation GosConfigSoftAPConfirm

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [GosCommon updateButtonStyle:self.confirmBtn];
    
    //导航按钮
    UIViewController *lastCtrl = self.navigationController.viewControllers[self.navigationController.viewControllers.count-2];
    if ([NSStringFromClass([lastCtrl class]) isEqualToString:@"GosConfigWaiting"]) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStylePlain target:self action:@selector(onCancel)];
    } else {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"page_back_button.png"] style:UIBarButtonItemStylePlain target:self action:@selector(onBack)];
    }
    
    if ((self.imageView.image.size.width == 5 && self.imageView.image.size.height == 5)) { //特殊图片时换文字
        self.titleLabel.text = NSLocalizedString(@"Power on, then refer to the tips", nil);
    }
    
    self.counter = 0; //进入界面的时候重置计数器
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onBack {
    [GosCommon safePopViewController:self.navigationController currentViewController:self animated:YES];
}

- (void)onCancel {
    [GosCommon showAlertConfigDiscard:^(UIAlertAction *action) {
        [common onCancel];
    }];
}

- (IBAction)onHiddenClick:(id)sender {
    self.counter++;
    if (self.counter == 8) { //隐秘操作不共存
        self.counter2 = 0;
    }
}

- (IBAction)onHidden2Click:(id)sender {
    self.counter2++;
    if (self.counter2 == 8) { //隐秘操作不共存
        self.counter = 0;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[GosConfigSoftAPStart class]]) {
        GosConfigSoftAPStart *startCtrl = (GosConfigSoftAPStart *)segue.destinationViewController;
        startCtrl.softapConfigType = self.softapConfigType;
    }
}

@end
