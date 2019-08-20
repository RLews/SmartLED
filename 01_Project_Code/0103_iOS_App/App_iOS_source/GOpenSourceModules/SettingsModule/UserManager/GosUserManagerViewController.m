//
//  GosUserManagerViewController.m
//  GOpenSource_AppKit
//
//  Created by Tom Ge on 2016/11/18.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import "GosUserManagerViewController.h"

#import "GosCommon.h"
#import "GosPushManager.h"
#import "GosAnonymousLogin.h"

@interface GosUserManagerViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end

@implementation GosUserManagerViewController

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if ([[UIDevice currentDevice].systemVersion integerValue] < 11) { //ios11以下才需要
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
        if (common.isThirdAccount || !common.isChangePassword) { //按钮往上移动
        for (NSLayoutConstraint *constraint in self.tableView.constraints) {
            if (constraint.firstAttribute == NSLayoutAttributeHeight) {
                constraint.constant -= 70;
                [self.tableView addConstraint:constraint];
                break;
            }
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onUserLogout:(id)sender {
    if (common.currentLoginStatus == GizLoginUser) {
                UIAlertController *alertControler = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"tip", nil) message:NSLocalizedString(@"Logout?", nil) preferredStyle:UIAlertControllerStyleAlert];
        [alertControler addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
        [alertControler addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (self.navigationController.viewControllers.lastObject == self) {

                [GosPushManager unbindToGDMS:YES];

                [common removeUserDefaults];
                [common removeUserValues];
                common.currentLoginStatus = GizLoginNone;
                [GosCommon safePopToRootViewController:self.navigationController animated:YES];
            }
        }]];
        [alertControler show];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (common.isThirdAccount || !common.isChangePassword) { //第三方账户不能修改密码
        return 1;
    }
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"userManagerIdentifier" forIndexPath:indexPath];
    switch (indexPath.row) {
        case 0: { //账号信息
                            cell.textLabel.text = NSLocalizedString(@"User Account", nil);
                        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120, 56)];
            label.textAlignment = NSTextAlignmentRight;
            label.textColor = [UIColor colorWithRed:0.5976 green:0.5976 blue:0.5976 alpha:1];
            if (common.isThirdAccount) {
                NSString *uid = common.uid;
                NSString *uid_pre = [uid substringToIndex:2];
                NSString *uid_end = [uid substringFromIndex:uid.length-4];
                label.text = [NSString stringWithFormat:@"%@***%@", uid_pre, uid_end];
            } else {
                label.text = common.tmpUser;
            }
            cell.accessoryView = label;
            break;
        }

        case 1: //修改密码
            cell.textLabel.text = NSLocalizedString(@"Edit password", nil);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.accessoryView = nil;
            break;

        default:
            break;
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0 && indexPath.section == 0) {
        return NO;
    }
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.row == 1) {
        [self performSegueWithIdentifier:@"toChange" sender:self];
    }

}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

@end
