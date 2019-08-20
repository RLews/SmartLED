//
//  GosPersonalCenterTableViewController.m
//  GOpenSource_AppKit
//
//  Created by Tom on 2016/12/21.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import "GosPersonalCenterTableViewController.h"
#import "GosCommon.h"

#import "GosUserLoginCell.h"
#import "GosUserManagementCell.h"

typedef UITableViewCell *(^GosPersonalCenterTableViewControllerCellHandler)(UITableView *tableView, UITableViewCell *cell, NSDictionary *dict);
typedef void(^GosPersonalCenterTableViewControllerHandler)(UINavigationController *navCtrl, NSDictionary *dict);

@interface GosPersonalCenterTableViewController ()

@property (strong, nonatomic, readonly) NSMutableArray *firstGroupItems;

@end

@implementation GosPersonalCenterTableViewController

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if ([[UIDevice currentDevice].systemVersion integerValue] < 11) { //ios11以下才需要
        self.tableView.contentInset = UIEdgeInsetsMake(64, 0, 64, 0);
    }
}

- (void)addGroupItem:(NSString *)title image:(NSString *)image cellHandler:(GosPersonalCenterTableViewControllerCellHandler)cellHandler clickHandler:(GosPersonalCenterTableViewControllerHandler)clickHandler {
    if (nil == _firstGroupItems) {
        _firstGroupItems = [NSMutableArray array];
    }
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:title forKey:@"title"];
    [dictionary setValue:image forKey:@"image"];
    [dictionary setValue:cellHandler forKey:@"cellHandler"];
    [dictionary setValue:clickHandler forKey:@"clickHandler"];
    [_firstGroupItems addObject:dictionary];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (common.isDeviceSharingSupport) {
        [self addGroupItem:NSLocalizedString(@"Device Sharing", nil) image:@"personalCenter_deviceSharing_icon.png" cellHandler:nil clickHandler:^(UINavigationController *navCtrl, NSDictionary *dict){
            UINavigationController *newNavCtrl = [[UIStoryboard storyboardWithName:@"GosSharing" bundle:nil] instantiateInitialViewController];
            [GosCommon safePushViewController:navCtrl viewController:newNavCtrl.viewControllers.firstObject animated:YES];
        }];
    }
    [self addGroupItem:NSLocalizedString(@"About", nil) image:@"personal_about_icon.png" cellHandler:nil clickHandler:^(UINavigationController *navCtrl, NSDictionary *dict) {
        UIViewController *aboutCtrl = [[UIStoryboard storyboardWithName:@"GosSettings" bundle:nil] instantiateViewControllerWithIdentifier:@"GosAbout"];
        [GosCommon safePushViewController:navCtrl viewController:aboutCtrl animated:YES];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tabBarController.navigationItem.title = self.tabBarItem.title;
    self.tabBarController.navigationItem.leftBarButtonItem = nil;
    self.tabBarController.navigationItem.rightBarButtonItem = nil;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return self.firstGroupItems.count;
        case 1:
            return 1;
        default:
            break;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"personalIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    
    switch (indexPath.section) {
        case 0: {
            NSDictionary *dict = self.firstGroupItems[indexPath.row];
            GosPersonalCenterTableViewControllerCellHandler cellHandler = [dict valueForKey:@"cellHandler"];
            cell.imageView.image = [UIImage imageNamed:[dict stringValueForKey:@"image" defaultValue:nil]];
            cell.textLabel.text = [dict stringValueForKey:@"title" defaultValue:nil];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            if (cellHandler) {
                return cellHandler(tableView, cell, dict);
            }
            break;
        }
        case 1:
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
                cell.imageView.image = [UIImage imageNamed:@"personalCenter_usermanger_icon.png"];
                return cell;
            } else {
                GosUserLoginCell *cell = [GosCommon controllerWithClass:[GosUserLoginCell class] tableView:tableView reuseIdentifier:@"GosUserLoginIdentifier"];
                cell.imageView.image = [UIImage imageNamed:@"personalCenter_usermanger_icon.png"];
                return cell;
            }
            break;
        default:
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.section) {
        case 0: {
            NSDictionary *dict = self.firstGroupItems[indexPath.row];
            GosPersonalCenterTableViewControllerHandler cellHandler = [dict valueForKey:@"clickHandler"];
            if (cellHandler) {
                cellHandler(self.tabBarController.navigationController, dict);
            }
            break;
        }
        case 1:
            if (common.currentLoginStatus == GizLoginUser) {
                UINavigationController *nav = [[UIStoryboard storyboardWithName:@"GosUserManager" bundle:nil] instantiateInitialViewController];
                UIViewController *userManagerController = nav.viewControllers.firstObject;
                [GosCommon safePushViewController:self.navigationController viewController:userManagerController animated:YES];
            } else {
                [GosCommon safePopToRootViewController:self.navigationController animated:YES];
            }
            break;
            
        default:
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
