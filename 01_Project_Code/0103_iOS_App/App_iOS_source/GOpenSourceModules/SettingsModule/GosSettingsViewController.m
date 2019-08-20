//
//  SettingsViewController.m
//  GBOSA
//
//  Created by Zono on 16/5/12.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import "GosSettingsViewController.h"
#import "GosCommon.h"

#import "GosUserLoginCell.h"
#import "GosUserManagementCell.h"

@interface GosSettingsViewController ()

@end

@implementation GosSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - table view
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 56;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellIdentifier"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CellIdentifier"];
    }
    if (indexPath.section == 0) {
        cell.textLabel.text = NSLocalizedString(@"About", nil);
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if (indexPath.section == 1) {
        if (common.currentLoginStatus == GizLoginUser) {
            GosUserManagementCell *cell = [GosCommon controllerWithClass:[GosUserManagementCell class] tableView:tableView reuseIdentifier:@"GosUserManagerIdentifier"];
            if (common.isThirdAccount) {
                NSString *uid = common.uid;
                NSString *uid_pre = [uid substringToIndex:2];
                NSString *uid_end = [uid substringFromIndex:uid.length-4];
                cell.textPhoneNumber.text = [NSString stringWithFormat:@"%@***%@", uid_pre, uid_end];
            } else {
                cell.textPhoneNumber.text = common.tmpUser;
            }
            return cell;
        } else {
            return [GosCommon controllerWithClass:[GosUserLoginCell class] tableView:tableView reuseIdentifier:@"GosUserLoginIdentifier"];
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        [self performSegueWithIdentifier:@"toAbout" sender:self];
    } else if (indexPath.section == 1) {
        if (common.currentLoginStatus == GizLoginUser) {
            UINavigationController *nav = [[UIStoryboard storyboardWithName:@"GosUserManager" bundle:nil] instantiateInitialViewController];
            UIViewController *userManagerController = nav.viewControllers.firstObject;
            [GosCommon safePushViewController:self.navigationController viewController:userManagerController animated:YES];
        } else {
            [GosCommon safePopToRootViewController:self.navigationController animated:YES];
        }
    }
}

@end
