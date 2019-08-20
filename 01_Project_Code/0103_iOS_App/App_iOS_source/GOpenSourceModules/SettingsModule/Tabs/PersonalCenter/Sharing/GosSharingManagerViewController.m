//
//  GosSharingManagerViewController.m
//  GOpenSource_AppKit
//
//  Created by Tom on 2016/12/21.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import "GosSharingManagerViewController.h"
#import <GizWifiSDK/GizWifiSDK.h>
#import "GosCommon.h"
#import "GosAddSharingViewController.h"
#import "GosAnonymousLogin.h"

@interface GosSharingManagerViewController () <UITableViewDelegate, UITableViewDataSource, GizDeviceSharingDelegate>

@property (weak, nonatomic) IBOutlet UIButton *btnSharingStatus;
@property (weak, nonatomic) IBOutlet UIButton *btnBindUsers;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSArray *list;

@property (assign, nonatomic) BOOL isEditing;//编辑模式

//添加、编辑、删除按钮
@property (weak, nonatomic) IBOutlet UIView *viewBar;
@property (strong, nonatomic) UIButton *btnAdd;
@property (strong, nonatomic) UIButton *btnEdit;
@property (strong, nonatomic) UIButton *btnCancel;

@end

@implementation GosSharingManagerViewController

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self updateSharingButtons];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"page_back_button.png"] style:UIBarButtonItemStylePlain target:self action:@selector(onBack)];
    
    //初始化一些按钮
    self.btnAdd = [self createButton:[UIImage imageNamed:@"common_add_button.png"] text:NSLocalizedString(@"Add Sharing", nil)];
    self.btnEdit = [self createButton:[UIImage imageNamed:@"devicesharing_info_edit.png"] text:NSLocalizedString(@"Edit Remark", nil)];
    self.btnCancel = [self createButton:[UIImage imageNamed:@"devicesharing_info_edit_cancel.png"] text:NSLocalizedString(@"Cancel", nil)];
    [self.btnAdd addTarget:self action:@selector(onAdd) forControlEvents:UIControlEventTouchUpInside];
    [self.btnEdit addTarget:self action:@selector(onEdit) forControlEvents:UIControlEventTouchUpInside];
    [self.btnCancel addTarget:self action:@selector(onCancel) forControlEvents:UIControlEventTouchUpInside];

    [self.btnSharingStatus setBackgroundImage:[GosCommon tabImage] forState:UIControlStateSelected];
    [self.btnBindUsers setBackgroundImage:[GosCommon tabImage] forState:UIControlStateSelected];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [GizDeviceSharing setDelegate:self];
    [self onSharingStatus:nil];
}

- (void)onUpdateSharingList {
    if (self.device.sharingRole == GizDeviceSharingOwner) { //只有owner支持调接口
        [GosCommon showHUDAddedTo:self.view animated:YES];
        [GizDeviceSharing getDeviceSharingInfos:common.token sharingType:GizDeviceSharingByMe deviceID:self.device.did];
    } else {
        self.list = nil;
        [self.tableView reloadData];
    }
}

- (void)updateTableBottomConstraints:(CGFloat)bottom {
    for (NSLayoutConstraint *constraint in self.view.constraints) {
        if (constraint.firstAttribute == NSLayoutAttributeTop && constraint.secondItem == self.tableView) {
            constraint.constant = bottom;
            [self.view addConstraint:constraint];
            break;
        }
    }
}

- (UIButton *)createButton:(UIImage *)image text:(NSString *)text {
    UIButton *ret = [UIButton buttonWithType:UIButtonTypeCustom];
    ret.frame = CGRectMake(0, 70, 100, 60);
    ret.titleLabel.font = [UIFont systemFontOfSize:15];
    [ret setImage:image forState:UIControlStateNormal];
    [ret setTitle:text forState:UIControlStateNormal];
    [ret setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    CGFloat imageWidth = ret.imageView.frame.size.width;
    CGFloat imageHeight = ret.imageView.frame.size.height;
    CGFloat labelWidth = ret.titleLabel.intrinsicContentSize.width;
    CGFloat labelHeight = ret.titleLabel.intrinsicContentSize.height;
    [ret setImageEdgeInsets:UIEdgeInsetsMake(-labelHeight, 0, 0, -labelWidth)];
    [ret setTitleEdgeInsets:UIEdgeInsetsMake(0, -imageWidth, -imageHeight, 0)];
    return ret;
}

- (void)showButtons:(NSArray *)buttons {
    for (NSInteger i = self.viewBar.subviews.count-1; i>=0; i--) {
        UIButton *button = self.viewBar.subviews[i];
        [button removeFromSuperview];
    }
    if (buttons.count > 0) {
        if (buttons.count == 1) {
            UIButton *button = buttons.firstObject;
            CGRect frame = button.frame;
            frame.origin.x = (self.viewBar.bounds.size.width-button.frame.size.width)/2.0;
            button.frame = frame;
            [self.viewBar addSubview:button];
        } else { //按照2个按钮处理
            CGFloat space = 40;
            UIButton *button_left = buttons.firstObject;
            UIButton *button_right = buttons.lastObject;
            CGFloat left = (self.viewBar.bounds.size.width-2*button_left.frame.size.width-space)/2.0;
            CGRect frame = button_left.frame;
            frame.origin.x = left;
            button_left.frame = frame;
            [self.viewBar addSubview:button_left];
            frame = button_right.frame;
            frame.origin.x = left+button_left.frame.size.width+space;
            button_right.frame = frame;
            [self.viewBar addSubview:button_right];
        }
        [self updateTableBottomConstraints:198];
    } else {
        [self updateTableBottomConstraints:0];
    }
}

- (void)updateSharingButtons {
    NSMutableArray *buttons = [NSMutableArray array];
    if (self.btnSharingStatus.selected) {
        if (self.isEditing) {
            [buttons addObject:self.btnCancel];
        } else {
            [buttons addObject:self.btnAdd];
            if (self.list.count > 0) {
                [buttons addObject:self.btnEdit];
            }
        }
    }
    [self showButtons:buttons];
}

- (IBAction)onSharingStatus:(id)sender {
    self.btnSharingStatus.selected = YES;
    self.btnBindUsers.selected = NO;
    [self onUpdateSharingList];
    [self updateSharingButtons];
}

- (IBAction)onBindUsers:(id)sender {
    self.btnSharingStatus.selected = NO;
    self.btnBindUsers.selected = YES;
    if (self.device.sharingRole == GizDeviceSharingOwner) { //只有owner支持调接口
        [GosCommon showHUDAddedTo:self.view animated:YES];
        [GizDeviceSharing getBindingUsers:common.token deviceID:self.device.did];
    } else {
        self.list = nil;
        [self.tableView reloadData];
    }
    [self updateSharingButtons];
}

- (void)onAdd {
    if (common.currentLoginStatus != GizLoginUser) {
        [GosCommon showAlertAutoDisappear:NSLocalizedString(@"Please login first, then share device", nil)];
    } else {
        [self performSegueWithIdentifier:@"toAddSharing" sender:self.device];
    }
}

- (void)onEdit {
    self.isEditing = YES;
    self.btnBindUsers.enabled = NO;
    [self updateSharingButtons];
}

- (void)onCancel {
    self.isEditing = NO;
    self.btnBindUsers.enabled = YES;
    [self updateSharingButtons];
}

- (void)onBack {
    [GosCommon safePopViewController:self.navigationController currentViewController:self animated:YES];
}

+ (NSString *)userNameFromUserInfo:(GizUserInfo *)userInfo {
    NSString *userName = userInfo.username;
    if (userName.length == 0) {
        userName = userInfo.phone;
    }
    if (userName.length == 0) {
        userName = userInfo.email;
    }
    if (userName.length == 0) {
        if (userInfo.uid.length == 32) { //处理用户信息
            NSString *uidfirst = [userInfo.uid substringToIndex:3];
            NSString *uidlast = [userInfo.uid substringFromIndex:userInfo.uid.length-3];
            userName = [NSString stringWithFormat:@"%@****%@", uidfirst, uidlast];
        }
    }
    return userName;
}

- (BOOL)isSharingInfoTimeout:(GizDeviceSharingInfo *)sharingInfo {
    if (![sharingInfo isKindOfClass:[GizDeviceSharingInfo class]]) {
        return NO;
    }
    NSDate *expiredDate = [GosCommon serviceDateFromString:sharingInfo.expiredAt];
    NSTimeInterval timerInterval = [expiredDate timeIntervalSinceNow];
    return (timerInterval <= 0);
}

- (void)showCancelSharingAlert:(GizUserInfo *)userInfo handler:(void (^ __nullable)(void))handler {
    NSString *tip = NSLocalizedString(@"tip", nil);
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"cancel_sharing_format", nil), [GosSharingManagerViewController userNameFromUserInfo:userInfo]];
    NSString *ok = NSLocalizedString(@"OK", nil);
    NSString *cancel = NSLocalizedString(@"Cancel", nil);
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:tip message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:cancel style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:ok style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [GosCommon showHUDAddedTo:self.view animated:YES];
        if (handler) {
            handler();
        }
    }]];
    [alertController show];
}

#pragma mark - 
- (NSString *)deviceDesc {
    NSString *desc = [common deviceName:self.device];
    if (desc.length == 0) {
        desc = NSLocalizedString(@"Device", nil);
    }
    return desc;
}

- (UIView *)backgroundView {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 180)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 60, self.view.bounds.size.width-40, 60)];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor grayColor];
    label.numberOfLines = 3;
    [view addSubview:label];
    label.text = [NSString stringWithFormat:NSLocalizedString(@"no_sharing_format", nil), [self deviceDesc]];
    return view;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.list.count == 0) {
        tableView.backgroundView = [self backgroundView];
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    } else {
        tableView.backgroundView = nil;
        tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.list.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"sharingIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    
    cell.detailTextLabel.text = nil;
    cell.detailTextLabel.textColor = [UIColor grayColor];
    cell.accessoryView = nil;
    cell.imageView.image = nil;
    
    if (self.list.count > indexPath.row) {
        id obj = self.list[self.list.count-indexPath.row-1];
        if ([obj isKindOfClass:[GizDeviceSharingInfo class]]) { //共享状态
            GizDeviceSharingInfo *sharingInfo = (GizDeviceSharingInfo *)obj;
            
            cell.imageView.image = [UIImage imageNamed:@"devicesharing_user_icon.png"];
            if (sharingInfo.alias.length > 0) { //优先显示别名
                cell.textLabel.text = sharingInfo.alias;
            } else {
                cell.textLabel.text = [GosSharingManagerViewController userNameFromUserInfo:sharingInfo.userInfo];
            }
            
            NSDate *currentDate = [GosCommon serviceDateFromString:sharingInfo.updatedAt];
            cell.detailTextLabel.text = [GosCommon localDateStringFromDate:currentDate];
            
            UILabel *labelStatus = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 80, 30)];
            labelStatus.textColor = [UIColor grayColor];
            labelStatus.textAlignment = NSTextAlignmentRight;
            switch (sharingInfo.status) {
                case GizDeviceSharingNotAccepted:
                    if ([self isSharingInfoTimeout:sharingInfo]) { //超时
                        labelStatus.text = NSLocalizedString(@"Sharing Timeout", nil);
                    } else {
                        labelStatus.text = NSLocalizedString(@"Waiting", nil);
                    }
                    break;
                case GizDeviceSharingAccepted:
                    labelStatus.text = NSLocalizedString(@"Accepted", nil);
                    break;
                case GizDeviceSharingRefused:
                    labelStatus.text = NSLocalizedString(@"Refused", nil);
                    break;
                case GizDeviceSharingCancelled:
                    labelStatus.text = NSLocalizedString(@"Cancelled", nil);
                    break;
                default:
                    labelStatus.text = @"";
                    break;
            }
            cell.accessoryView = labelStatus;
        } else if ([obj isKindOfClass:[GizUserInfo class]]) { //已绑用户
            GizUserInfo *userInfo = (GizUserInfo *)obj;
            cell.imageView.image = [UIImage imageNamed:@"devicesharing_user_icon.png"];
            cell.textLabel.text = [GosSharingManagerViewController userNameFromUserInfo:userInfo];
            NSDate *date = [GosCommon serviceDateFromString:userInfo.deviceBindTime];
            cell.detailTextLabel.text = [GosCommon localDateStringFromDate:date];
        }
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    NSString *text = @"";
    if (self.list.count != 0) {
        if (self.btnSharingStatus.selected) {
            text = [NSString stringWithFormat:NSLocalizedString(@"sharing_to_format", nil), [self deviceDesc]];
        }
        text = [NSString stringWithFormat:NSLocalizedString(@"sharing_bind_users_format", nil), [self deviceDesc]];
    }
    return [GosCommon tableHeaderHeight:tableView text:text offset:24];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *text = @"";
    if (self.list.count != 0) {
        if (self.btnSharingStatus.selected) {
            text = [NSString stringWithFormat:NSLocalizedString(@"sharing_to_format", nil), [self deviceDesc]];
        }
        text = [NSString stringWithFormat:NSLocalizedString(@"sharing_bind_users_format", nil), [self deviceDesc]];
    }
    return [GosCommon tableHeaderView:tableView text:text offset:24];
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    __block id obj = self.list[self.list.count-indexPath.row-1];
    __block BOOL isSharingInfo = [obj isKindOfClass:[GizDeviceSharingInfo class]];
    __block BOOL isUserInfo = [obj isKindOfClass:[GizUserInfo class]];
    __weak typeof(self) weakSelf = self;

    if (isSharingInfo) { //解绑用户
        __block GizDeviceSharingInfo *sharingInfo = (GizDeviceSharingInfo *)obj;
        if ((sharingInfo.status == GizDeviceSharingNotAccepted && [self isSharingInfoTimeout:obj]) ||
            sharingInfo.status == GizDeviceSharingRefused) { //重新分享，删除
            UITableViewRowAction *cancelButton = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:NSLocalizedString(@"Delete", nil) handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
                __strong typeof(self) strongSelf = weakSelf;
                [strongSelf showCancelSharingAlert:sharingInfo.userInfo handler:^{
                    [GosCommon showHUDAddedTo:self.view animated:YES];
                    [GizDeviceSharing revokeDeviceSharing:common.token sharingID:sharingInfo.id];
                }];
            }];
            UITableViewRowAction *reshareButton = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:NSLocalizedString(@"Sharing Again", nil) handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
                __strong typeof(self) strongSelf = weakSelf;
                [GosCommon showHUDAddedTo:strongSelf.view animated:YES];
                [GizDeviceSharing sharingDevice:common.token deviceID:strongSelf.device.did sharingWay:GizDeviceSharingByNormal guestUser:sharingInfo.userInfo.uid guestUserType:GizUserOther];
            }];
            reshareButton.backgroundColor = [UIColor grayColor];
            return @[cancelButton, reshareButton];
        } else if (sharingInfo.status == GizDeviceSharingCancelled) { //重新分享
            UITableViewRowAction *reshareButton = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:NSLocalizedString(@"Sharing Again", nil) handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
                __strong typeof(self) strongSelf = weakSelf;
                [GosCommon showHUDAddedTo:strongSelf.view animated:YES];
                [GizDeviceSharing sharingDevice:common.token deviceID:strongSelf.device.did sharingWay:GizDeviceSharingByNormal guestUser:sharingInfo.userInfo.uid guestUserType:GizUserOther];
            }];
            return @[reshareButton];
        } else { //取消分享
            return @[[UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:NSLocalizedString(@"Cancel Sharing", nil) handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
                __strong typeof(self) strongSelf = weakSelf;
                [strongSelf showCancelSharingAlert:sharingInfo.userInfo handler:^{
                    [GosCommon showHUDAddedTo:self.view animated:YES];
                    [GizDeviceSharing revokeDeviceSharing:common.token sharingID:sharingInfo.id];
                }];
            }]];
        }
    } else if (isUserInfo) { //解绑用户
        __block GizUserInfo *userInfo = (GizUserInfo *)obj;
        return @[[UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:NSLocalizedString(@"Cancel Sharing", nil) handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
            __strong typeof(self) strongSelf = weakSelf;
            [strongSelf showCancelSharingAlert:userInfo handler:^{
                [GosCommon showHUDAddedTo:self.view animated:YES];
                [GizDeviceSharing unbindUser:common.token deviceID:self.device.did guestUID:userInfo.uid];
            }];
        }]];
    }
    return @[];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath { //ios8 only
    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.list.count > indexPath.row) {
        id obj = self.list[self.list.count-indexPath.row-1];
        if ([obj isKindOfClass:[GizDeviceSharingInfo class]]) {
            return YES;
        } else if ([obj isKindOfClass:[GizUserInfo class]]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.list.count > indexPath.row) {
        return self.isEditing;
    }
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    id obj = self.list[self.list.count-indexPath.row-1];
    if ([obj isKindOfClass:[GizDeviceSharingInfo class]]) { //只有共享状态列表，才能编辑别名
        __block GizDeviceSharingInfo *sharingInfo = (GizDeviceSharingInfo *)obj;
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Rename the sharing alias", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.keyboardType = UIKeyboardTypeDefault;
            textField.autocorrectionType = UITextAutocorrectionTypeNo;
            if (sharingInfo.alias.length > 0) {
                textField.text = sharingInfo.alias;
            } else {
                textField.text = [GosSharingManagerViewController userNameFromUserInfo:sharingInfo.userInfo];
            }
        }];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [GosCommon showHUDAddedTo:self.view animated:YES];
            [GizDeviceSharing modifySharingInfo:common.token sharingID:sharingInfo.id sharingAlias:alertController.textFields.firstObject.text];
        }]];
        [alertController show];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (void)didGetDeviceSharingInfos:(NSError *)result deviceID:(NSString *)deviceID deviceSharingInfos:(NSArray<GizDeviceSharingInfo *> *)deviceSharingInfos {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    if (result.code == GIZ_SDK_SUCCESS) {
        //将列表信息按照更新时间排序
        __block NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
        self.list = [deviceSharingInfos sortedArrayUsingComparator:^NSComparisonResult(GizDeviceSharingInfo *_Nonnull obj1, GizDeviceSharingInfo *_Nonnull obj2) {
            NSDate *date1 = [GosCommon serviceDateFromString:obj1.updatedAt];
            NSDate *date2 = [GosCommon serviceDateFromString:obj2.updatedAt];
            return (date1.timeIntervalSince1970 > date2.timeIntervalSince1970);
        }];
        [self.tableView reloadData];
    } else {
        [GosCommon showAlertAutoDisappear:[common checkErrorCode:result.code]];
    }
    [self updateSharingButtons];
}

- (void)didGetBindingUsers:(NSError *)result deviceID:(NSString *)deviceID bindUsers:(NSArray<GizUserInfo *> *)bindUsers {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    if (result.code == GIZ_SDK_SUCCESS) {
        //将列表信息按照更新时间排序
        __block NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
        self.list = [bindUsers sortedArrayUsingComparator:^NSComparisonResult(GizUserInfo *_Nonnull obj1, GizUserInfo *_Nonnull obj2) {
            NSDate *date1 = [GosCommon serviceDateFromString:obj1.deviceBindTime];
            NSDate *date2 = [GosCommon serviceDateFromString:obj2.deviceBindTime];
            return (date1.timeIntervalSince1970 > date2.timeIntervalSince1970);
        }];
        [self.tableView reloadData];
    } else {
        [GosCommon showAlertAutoDisappear:[common checkErrorCode:result.code]];
    }
    [self showButtons:nil];
}

- (void)didUnbindUser:(NSError *)result deviceID:(NSString *)deviceID guestUID:(NSString *)guestUID {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    if (result.code == GIZ_SDK_SUCCESS) {
        [self onBindUsers:nil];
    } else {
        [GosCommon showAlertAutoDisappear:NSLocalizedString(@"Cancel failed", nil)];
    }
}

- (void)didRevokeDeviceSharing:(NSError *)result sharingID:(NSInteger)sharingID {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    if (result.code == GIZ_SDK_SUCCESS) {
        [self onUpdateSharingList];
    } else {
        [GosCommon showAlertAutoDisappear:NSLocalizedString(@"Your request is failed", nil)];
    }
}

- (void)didModifySharingInfo:(NSError *)result sharingID:(NSInteger)sharingID {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    if (result.code == GIZ_SDK_SUCCESS) {
        [GosCommon showAlertAutoDisappear:NSLocalizedString(@"Successfully modified", nil)];
        [self onUpdateSharingList];
    } else {
        [GosCommon showAlertAutoDisappear:NSLocalizedString(@"Failure modified", nil)];
    }
}

- (void)didSharingDevice:(NSError *)result deviceID:(NSString *)deviceID sharingID:(NSInteger)sharingID QRCodeImage:(UIImage *)QRCodeImage {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    if (result.code == GIZ_SDK_SUCCESS) {
        [self onUpdateSharingList];
        [GosCommon showAlertAutoDisappear:NSLocalizedString(@"Send successfully", nil)];
    } else {
        [GosCommon showAlertAutoDisappear:NSLocalizedString(@"Send failed", nil)];
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[GosAddSharingViewController class]]) {
        GosAddSharingViewController *addCtrl = (GosAddSharingViewController *)segue.destinationViewController;
        addCtrl.device = sender;
    }
}

@end
