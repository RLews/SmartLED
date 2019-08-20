//
//  GosSharingListViewController.m
//  GOpenSource_AppKit
//
//  Created by Tom on 2016/12/21.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import "GosSharingListViewController.h"
#import "GosSharingInfoCell.h"
#import "GosSharingMessageCell.h"
#import "GosCommon.h"
#import "GosSharingManagerViewController.h"
#import "GosAddSharingViewController.h"

@interface GosSharingListViewController () <UITableViewDelegate, UITableViewDataSource, GizDeviceSharingDelegate>

@property (weak, nonatomic) IBOutlet UIButton *btnSharing;
@property (weak, nonatomic) IBOutlet UIButton *btnMessage;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSArray *list;

@end

@implementation GosSharingListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self onSharing:nil];
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, CGFLOAT_MIN)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"page_back_button.png"] style:UIBarButtonItemStylePlain target:self action:@selector(onBack)];
    
    [self.btnSharing setBackgroundImage:[GosCommon tabImage] forState:UIControlStateSelected];
    [self.btnMessage setBackgroundImage:[GosCommon tabImage] forState:UIControlStateSelected];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [GizDeviceSharing setDelegate:self];
    [self.tableView reloadData];
}

- (IBAction)onSharing:(id)sender { //共享选项卡
    self.btnSharing.selected = YES;
    self.btnMessage.selected = NO;
    
    NSMutableArray *deviceList = [NSMutableArray array];
    for (GizWifiDevice *device in [GizWifiSDK sharedInstance].deviceList) {
        if (device.sharingRole == GizDeviceSharingOwner ||
            device.sharingRole == GizDeviceSharingSpecial) {
            [deviceList addObject:device];
        }
    }
    self.list = deviceList;
    [self.tableView reloadData];
}

- (IBAction)onMessage:(id)sender { //受邀选项卡
    self.btnSharing.selected = NO;
    self.btnMessage.selected = YES;
    [GosCommon showHUDAddedTo:self.view animated:YES];
    [GizDeviceSharing getDeviceSharingInfos:common.token sharingType:GizDeviceSharingToMe deviceID:nil];
}

- (void)onBack {
    [GosCommon safePopViewController:self.navigationController currentViewController:self animated:YES];
}

#pragma mark -
- (UIView *)backgroundView {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 180)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 60, self.view.bounds.size.width-40, 60)];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor grayColor];
    label.numberOfLines = 3;
    [view addSubview:label];
    if (self.btnSharing.selected) {
        label.text = NSLocalizedString(@"No share devices", nil);
    } else {
        label.text = NSLocalizedString(@"No guest users", nil);
    }
    return view;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.list.count == 0) {
        tableView.backgroundView = [self backgroundView];
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    } else {
        tableView.backgroundView = nil;
        tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    }
    return self.list.count;
}

- (UITableViewCell *)defaultCell {
    static NSString *identifier = @"DeviceIdentifier";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    cell.detailTextLabel.text = nil;
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.list.count) {
        id obj = self.list[self.list.count-indexPath.row-1];
        if ([obj isKindOfClass:[GizWifiDevice class]]) { //共享列表
            static NSString *sharingInfoIdentifier = @"sharingInfoIdentifier";
            GizWifiDevice *device = (GizWifiDevice *)obj;
            GosSharingInfoCell *sharingInfoCell = [GosCommon controllerWithClass:[GosSharingInfoCell class] tableView:tableView reuseIdentifier:sharingInfoIdentifier];
            if (device.isLAN) {
                sharingInfoCell.imageView.image = [UIImage imageNamed:@"common_device_lan_online.png"];
            } else {
                sharingInfoCell.imageView.image = [UIImage imageNamed:@"common_device_remote_online.png"];
            }
            sharingInfoCell.deviceName.text = [common deviceName:device];
            sharingInfoCell.macAddress.text = device.macAddress;
            sharingInfoCell.sharingStatus.text = device.sharingRole == GizDeviceSharingSpecial?NSLocalizedString(@"Not Sharing", nil):@"";
            sharingInfoCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            return sharingInfoCell;
        } else if ([obj isKindOfClass:[GizDeviceSharingInfo class]]) { //受邀列表
            static NSString *sharingIdentifier = @"sharingIdentifier";
            GosSharingMessageCell *messageCell = [GosCommon controllerWithClass:[GosSharingMessageCell class] tableView:tableView reuseIdentifier:sharingIdentifier];
            messageCell.sharingInfo = obj;
            messageCell.listView = self.view;
            return messageCell;
        }
    }
    return nil;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.btnSharing.selected) {
        return (self.list.count > 0);
    }
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.btnSharing.selected) {
        GizWifiDevice *device = self.list[self.list.count-indexPath.row-1];
        if ([device isKindOfClass:[GizWifiDevice class]]) {
            [self performSegueWithIdentifier:@"toManage" sender:device];
        } else {
            GIZ_LOG_ERROR("invalid list: %s", self.list.description);
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (void)didGetDeviceSharingInfos:(NSError *)result deviceID:(NSString *)deviceID deviceSharingInfos:(NSArray<GizDeviceSharingInfo *> *)deviceSharingInfos {
    if (self.btnMessage.selected) {
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
        } else {
            self.list = nil;
            [GosCommon showAlertAutoDisappear:[common checkErrorCode:result.code]];
        }
        [self.tableView reloadData];
    }
}

- (void)didAcceptDeviceSharing:(NSError *)result sharingID:(NSInteger)sharingID {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    if (result.code == GIZ_SDK_SUCCESS) {
        [self onMessage:nil];
    } else {
        [GosCommon showAlertAutoDisappear:NSLocalizedString(@"Your request is failed", nil)];
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isMemberOfClass:[GosSharingManagerViewController class]]) {
        GosSharingManagerViewController *managerCtrl = (GosSharingManagerViewController *)segue.destinationViewController;
        managerCtrl.device = sender;
    }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
