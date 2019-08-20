//
//  GosSharingMessageTableViewController.m
//  GOpenSource_AppKit
//
//  Created by Tom on 2016/12/22.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import "GosSharingMessageTableViewController.h"
#import <GizWifiSDK/GizWifiSDK.h>
#import "GosCommon.h"
#import "GosMessageCenterTableViewController.h"

@interface GosSharingMessageTableViewController () <GizDeviceSharingDelegate>

@property (strong, nonatomic) NSArray *list;

@end

@implementation GosSharingMessageTableViewController

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    NSArray *indexPaths = self.tableView.indexPathsForVisibleRows;
    for (NSIndexPath *indexPath in indexPaths) { //小圆点
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        if (self.list.count > indexPath.row) {
            GizMessage *message = self.list[self.list.count-indexPath.row-1];
            BOOL hasUnreadMessage = (message.status == GizMessageUnread);
            [GosCommon markTableViewCell:cell label:cell.textLabel hasUnreadMessage:hasUnreadMessage];
        } else {
            [GosCommon markTableViewCell:cell label:cell.textLabel hasUnreadMessage:NO];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [GizDeviceSharing setDelegate:self];
    [GosCommon showHUDAddedTo:self.view animated:YES];
    [GizDeviceSharing queryMessageList:common.token messageType:GizMessageSharing];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    self.list = common.sharingMessageList;
    if (self.list.count == 0) {
        return 1;
    }
    return self.list.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"sharingIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:14];
    }
    
    // Configure the cell...
    if (self.list.count > indexPath.row) {
        GizMessage *message = self.list[self.list.count-indexPath.row-1];
        cell.textLabel.text = message.content;
        NSDate *date = [GosCommon serviceDateFromString:message.createdAt];
        cell.detailTextLabel.text = [GosCommon localDateStringFromDate:date];
    } else {
        cell.textLabel.text = NSLocalizedString(@"No message", nil);
        cell.detailTextLabel.text = nil;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.list.count > indexPath.row;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.list.count > indexPath.row;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    GizMessage *message = self.list[self.list.count-indexPath.row-1];
    [GizDeviceSharing markMessageStatus:common.token messageID:message.id messageStatus:GizMessageRead];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        GizMessage *message = self.list[self.list.count-indexPath.row-1];
        [GosCommon showHUDAddedTo:self.view animated:YES];
        [GizDeviceSharing markMessageStatus:common.token messageID:message.id messageStatus:GizMessageDeleted];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return NSLocalizedString(@"Delete", nil);
}

- (void)didQueryMessageList:(NSError *)result messageList:(NSArray<GizMessage *> *)messageList {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    if (result.code == GIZ_SDK_SUCCESS) {
        common.sharingMessageList = messageList;
        [self.tableView reloadData];
    } else {
        [GosCommon showAlertWithTip:NSLocalizedString(@"Send failed", nil)];
    }
}

- (void)didMarkMessageStatus:(NSError *)result messageID:(NSString *)messageID {
    if (result.code == GIZ_SDK_SUCCESS) {
        [GizDeviceSharing queryMessageList:common.token messageType:GizMessageSharing];
    } else {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [GosCommon showAlertWithTip:NSLocalizedString(@"Send failed", nil)];
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
