//
//  GosMessageCenterTableViewController.m
//  GOpenSource_AppKit
//
//  Created by Tom on 2016/12/21.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import "GosMessageCenterTableViewController.h"
#import "GosSharingMessageTableViewController.h"

#import "GosCommon.h"

@interface GosMessageCenterTableViewController () <GizDeviceSharingDelegate>

@end

@implementation GosMessageCenterTableViewController

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if ([[UIDevice currentDevice].systemVersion integerValue] < 11) { //ios11以下才需要
        self.tableView.contentInset = UIEdgeInsetsMake(64, 0, 64, 0);
    }
    
    NSArray *indexPaths = self.tableView.indexPathsForVisibleRows;
    for (NSIndexPath *indexPath in indexPaths) { //小圆点
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        if (common.sharingMessageList.count > 0) {
            BOOL hasUnreadMessage = NO;
            for (GizMessage *message in common.sharingMessageList) {
                if (message.status == GizMessageUnread) {
                    hasUnreadMessage = YES;
                    break;
                }
            }
            
            [GosCommon markTableViewCell:cell label:cell.textLabel hasUnreadMessage:hasUnreadMessage];
        }
    }
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
    [GizDeviceSharing setDelegate:self];
    [GizDeviceSharing queryMessageList:common.token messageType:GizMessageSharing];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"messageIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = NSLocalizedString(@"Device Sharing Info", nil);
            break;
        default:
            break;
    }
    
    // Configure the cell...
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.row) {
        case 0: {
            GosSharingMessageTableViewController *sharingMessageCtrl = [[GosSharingMessageTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
            sharingMessageCtrl.navigationItem.title = NSLocalizedString(@"Device Sharing", nil);
            [GosCommon safePushViewController:self.tabBarController.navigationController viewController:sharingMessageCtrl animated:YES];
            break;
        }
            
        default:
            break;
    }
}

- (void)didQueryMessageList:(NSError *)result messageList:(NSArray<GizMessage *> *)messageList {
    if (result.code == GIZ_SDK_SUCCESS) {
        common.sharingMessageList = messageList;
        [self.tableView reloadData];
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
