//
//  DeviceListViewController.m
//  GBOSA
//
//  Created by Zono on 16/5/6.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import "GosDeviceListViewController.h"
#import "GosCommon.h"
#import <GizWifiSDK/GizWifiSDK.h>
#import <AVFoundation/AVFoundation.h>
#import "QRCodeController.h"
#import <SSPullToRefresh/SSPullToRefresh.h>
#import "AppDelegate.h"
#import "GosSettingsViewController.h"
#import "GosDeviceListCell.h"

#import "GosPushManager.h"
#import "GosAnonymousLogin.h"
#import "GosDeviceAcceptSharingInfo.h"
#import <TargetConditionals.h>
#import "GosAddSharingViewController.h"

@interface GosDeviceListViewController () <GizWifiSDKDelegate, GizWifiDeviceDelegate, GizWifiCentralControlDeviceDelegate, UITableViewDelegate, UITableViewDataSource, SSPullToRefreshViewDelegate, GizDeviceSharingDelegate>

@property (strong, nonatomic) NSString *lastSharingCode;
@property (strong, nonatomic) GizWifiDevice *lastSubscribedDevice;
@property (strong, nonatomic) SSPullToRefreshView *pullToRefreshView;

@property (assign, nonatomic) BOOL isScheduleUpdate; //滑动时不更新，计划更新
@property (assign, nonatomic) BOOL isSetSubscribe; //防止在其他页面调用的回调触发了错误的事件
@property (strong, nonatomic) GizWifiDevice *lastBeHitDevice; //自动订阅的情况，需要记录最后一个被点击的设备

@end

@implementation GosDeviceListViewController

- (instancetype)initWithStyle:(UITableViewStyle)style {
    if (self = [super initWithStyle:style]) {
        self.navigationItem.title = NSLocalizedString(@"My Devices title", nil);
    }
    return self;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.pullToRefreshView == nil) {
        self.pullToRefreshView = [[SSPullToRefreshView alloc] initWithScrollView:self.tableView delegate:self];//下拉刷新
    }
    if ([[UIDevice currentDevice].systemVersion integerValue] < 11) { //ios11以下才需要
        self.pullToRefreshView.defaultContentInset = UIEdgeInsetsMake(64, 0, 64, 0);
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (common.isNormalDeviceQRCodeScan || common.isDeviceSharingQRCode) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"mydevice_scan_button.png"] style:UIBarButtonItemStylePlain target:self action:@selector(onScan)];
    }
    
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"mydevice_add_button.png"] style:UIBarButtonItemStylePlain target:self action:@selector(onAdd)];
    
    
    self.deviceListArray = @[@[],@[]];
    
    
    if (common.isAnonymous) {
        GosAnonymousLoginStatus lastLoginStatus = [GosAnonymousLogin lastLoginStatus];
        if (common.currentLoginStatus == GizLoginNone || lastLoginStatus == GosAnonymousLoginStatusLogout) {
            [GosAnonymousLogin loginAnonymous:^(NSError *result, NSString *uid, NSString *token) {
                [self onDidUserLoginAnonymous:result uid:uid token:token];
            }];
        }
    }
    
    if (!common.isSoftAP && !common.isAirlink) { //不支持配置时，隐藏按钮
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    GosWifiSDKMessageCenter.delegate = self;
    self.lastSubscribedDevice = nil;
    self.lastBeHitDevice = nil;
    self.isSetSubscribe = NO;
    [GizDeviceSharing setDelegate:self];
    [self refreshTableView];
    
    if (self.tabBarController) {
        self.tabBarController.navigationItem.title = self.navigationItem.title;
        self.tabBarController.navigationItem.leftBarButtonItem = self.navigationItem.leftBarButtonItem;
        self.tabBarController.navigationItem.rightBarButtonItem = self.navigationItem.rightBarButtonItem;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    GosWifiSDKMessageCenter.delegate = nil;
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self.pullToRefreshView finishLoading];
}


- (void)onDidUserLoginAnonymous:(NSError *)result uid:(NSString *)uid token:(NSString *)token {
    if (result.code == GIZ_SDK_SUCCESS) {
        NSString *info = [NSString stringWithFormat:@"%@，%@ - %@", NSLocalizedString(@"Login successful", nil), @(result.code), [result.userInfo objectForKey:@"NSLocalizedDescription"]];
        GIZ_LOG_BIZ("userLoginAnonymous_end", "success", "%s", info.UTF8String);
        [common saveUserDefaults:GizUnknowLogin userName:nil password:nil tokenSecret:nil uid:uid token:token];
        
        [GosPushManager unbindToGDMS:NO];
        [GosPushManager bindToGDMS];
        
    } else { //匿名登录失败，3秒后自动重试
        common.currentLoginStatus = GizLoginNone;
        NSString *info = [NSString stringWithFormat:@"%@，%@ - %@", NSLocalizedString(@"Login failed", nil), @(result.code), [result.userInfo objectForKey:@"NSLocalizedDescription"]];
        GIZ_LOG_BIZ("userLoginAnonymous_end", "failed", "%s", info.UTF8String);
        double delayInSeconds = 3.0;
        __weak typeof(self) weakSelf = self;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            if (common.currentLoginStatus == GizLoginNone) {
                [GosAnonymousLogin loginAnonymous:^(NSError *result, NSString *uid, NSString *token) {
                    __strong typeof(self) strongSelf = weakSelf;
                    [strongSelf onDidUserLoginAnonymous:result uid:uid token:token];
                }];
            }
        });
    }
}


- (void)getBoundDevice {
    NSString *uid = common.uid;
    NSString *token = common.token;
    if (uid.length == 0) {
        uid = nil;
    }
    if (token.length == 0) {
        token = nil;
    }
    [[GizWifiSDK sharedInstance] getBoundDevices:uid token:token];
}

- (void)onAirlink {
#if (!TARGET_IPHONE_SIMULATOR)
    if (GosCommon.currentSSID.length > 0) { //wifi环境监测不到???
#endif
        UINavigationController *nav = [[UIStoryboard storyboardWithName:@"GosAirLink" bundle:nil] instantiateInitialViewController];
        GosConfigStart *configStartVC = nav.viewControllers.firstObject;
        configStartVC.isSoftAPMode = NO;
        common.delegate = self;
        [self safePushViewController:configStartVC];
#if (!TARGET_IPHONE_SIMULATOR)
    } else {
        [GosCommon showAlertWithTip:NSLocalizedString(@"Please switch to Wifi environment", nil)];
    }
#endif
}


- (void)onSoftap {
#if (!TARGET_IPHONE_SIMULATOR)
    if (GosCommon.currentSSID.length > 0) {
#endif
        UINavigationController *nav = [[UIStoryboard storyboardWithName:@"GosAirLink" bundle:nil] instantiateInitialViewController];
        GosConfigStart *configStartVC = nav.viewControllers.firstObject;
        configStartVC.isSoftAPMode = YES;
        common.delegate = self;
        [self safePushViewController:configStartVC];
#if (!TARGET_IPHONE_SIMULATOR)
    } else {
        [GosCommon showAlertWithTip:NSLocalizedString(@"Please switch to Wifi environment", nil)];
    }
#endif
}


- (void)onAdd {
    
    
    if (common.isSoftAP && common.isAirlink) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Airlink Config", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self onAirlink];
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Softap Config", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self onSoftap];
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
        [alertController show];
    }
    
    if (common.isSoftAP && !common.isAirlink) {
        [self onSoftap];
    }
    
    
    if (!common.isSoftAP && common.isAirlink) {
        [self onAirlink];
    }
    
}


- (void)onScan {
    [self intoQRCodeVC];
}


- (UIView *)backgroundView {
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenBounds.size.width, screenBounds.size.height)];
    UIButton *imageBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    imageBtn.frame = CGRectMake(screenBounds.size.width/2-60, screenBounds.size.height/2-140, 120, 120);
    [imageBtn setImage:[UIImage imageNamed:@"config_choose_wifi_tips.png"] forState:UIControlStateNormal];
    [imageBtn addTarget:self action:@selector(toAirLink:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:imageBtn];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(46, screenBounds.size.height/2-20, self.view.bounds.size.width-92, 40);
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    button.titleLabel.numberOfLines = 1;
    [view addSubview:button];
    
    [button.layer setCornerRadius:20.0];
    [button.layer setBorderWidth:1.0];
    [button setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(toAirLink:) forControlEvents:UIControlEventTouchUpInside];
    button.layer.borderColor = [UIColor grayColor].CGColor;
    
    [button setTitle:NSLocalizedString(@"Please add a device!", nil) forState:UIControlStateNormal];
    view.backgroundColor = [UIColor whiteColor];
    
    return view;
}

- (void)refreshTableView {
    if (self.tableView.isDragging || self.tableView.isDecelerating || self.tableView.isEditing) {
        self.isScheduleUpdate = YES;
        return;
    }
    NSArray *devList = [GizWifiSDK sharedInstance].deviceList;
    NSMutableArray *deviceListGroup1 = [[NSMutableArray alloc] init];
    NSMutableArray *deviceListGroup2 = [[NSMutableArray alloc] init];
    for (GizWifiDevice *dev in devList) {
        if (!dev.isBind) {
            [deviceListGroup2 addObject:dev];
        } else {
            [deviceListGroup1 addObject:dev];
        }
    }
    if (!common.isAutoSubscribeDevice) {
        [deviceListGroup1 sortUsingComparator:^NSComparisonResult(GizWifiDevice *obj1, GizWifiDevice *obj2) {
            if (obj1.netStatus == GizDeviceOnline || obj1.netStatus == GizDeviceControlled) {
                return NSOrderedAscending;
            }
            if (obj2.netStatus == GizDeviceOnline || obj2.netStatus == GizDeviceControlled) {
                return NSOrderedDescending;
            }
            return NSOrderedSame;
        }];
        [deviceListGroup2 sortUsingComparator:^NSComparisonResult(GizWifiDevice *obj1, GizWifiDevice *obj2) {
            if (obj1.netStatus == GizDeviceOnline || obj1.netStatus == GizDeviceControlled) {
                return NSOrderedAscending;
            }
            if (obj2.netStatus == GizDeviceOnline || obj2.netStatus == GizDeviceControlled) {
                return NSOrderedDescending;
            }
            return NSOrderedSame;
        }];
    }
    if (devList.count == 0) {
        self.tableView.backgroundView = [self backgroundView];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    } else {
        self.tableView.backgroundView = nil;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    }
    self.tableView.scrollEnabled = NO;
    self.deviceListArray = @[deviceListGroup1, deviceListGroup2];
    [self.tableView reloadData];
    self.tableView.scrollEnabled = YES;
}

#pragma mark - 快捷控制按钮
- (BOOL)isPowerButtonHidden:(GizWifiDevice *)device {
    NSString *dataPoint = [GosCommon dataPointFromProductKey:device.productKey];
    if (dataPoint.length > 0) {
        return NO;
    }
    return YES;
}

#pragma mark - table view
- (NSString *)titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
        return NSLocalizedString(@"My Devices", nil);
        case 1:
        return NSLocalizedString(@"Discovery of New Devices", nil);
        default:
        break;
    }
    return @"";
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([[self.deviceListArray objectAtIndex:0] count] == 0 &&
        [[self.deviceListArray objectAtIndex:1] count] == 0) {
        return 0;
    }
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([[self.deviceListArray objectAtIndex:section] count] == 0) {
        return 1;
    }
    return [[self.deviceListArray objectAtIndex:section] count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 44;
    }
    return 20;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] init];
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, tableView.bounds.size.width-20, 16)];
    if (section == 0) {
        CGRect frame = headerLabel.frame;
        frame.origin.y = 24;
        headerLabel.frame = frame;
    }
    headerLabel.textColor = [UIColor grayColor];
    headerLabel.font = [UIFont systemFontOfSize:12];
    [view addSubview:headerLabel];
    headerLabel.text = [self titleForHeaderInSection:section];
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"GosDeviceListCell";
    GosDeviceListCell *cell = [GosCommon controllerWithClass:[GosDeviceListCell class] tableView:tableView reuseIdentifier:identifier];
    NSMutableArray *devArr = [self.deviceListArray objectAtIndex:indexPath.section];
    cell.accessoryType = UITableViewCellAccessoryNone;
    //设置默认值
    cell.device = nil;
    cell.switchBtn.hidden = YES;
    if ([devArr count] > 0) {
        GizWifiDevice *dev = [devArr objectAtIndex:indexPath.row];
        if (self.navigationController.viewControllers.lastObject == self || self.navigationController.viewControllers.lastObject == self.tabBarController) {
            dev.delegate = self;
        }
        cell.imageView.hidden = NO;
        [self customCell:cell device:dev];
    }
    else {
        cell.textLabel.text = NSLocalizedString(@"No Devices", nil);
        cell.titleLabel.text = nil;
        cell.macLabel.text = nil;
        [cell.imageView setImage:nil];
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *devArr = [self.deviceListArray objectAtIndex:indexPath.section];
    if (devArr.count == 0) {
        return NO;
    }
    return YES;
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isScheduleUpdate) {
        self.isScheduleUpdate = NO;
        [self refreshTableView];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate && self.isScheduleUpdate) {
        self.isScheduleUpdate = NO;
        [self refreshTableView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (self.isScheduleUpdate) {
        self.isScheduleUpdate = NO;
        [self refreshTableView];
    }
}

- (void)customCell:(GosDeviceListCell *)cell device:(GizWifiDevice *)dev {
    // 获取设备名称
    NSString *devName = [common deviceName:dev];
    cell.device = dev;
    if (dev.productType == GizDeviceCenterControl) {
        GizWifiCentralControlDevice *centralDevice = (GizWifiCentralControlDevice *)dev;
        if (common.isSpecialBundleID || common.isDisplayMac) {
            if (centralDevice.subDeviceList.count > 0) {
                NSString *strCount = [NSString stringWithFormat:NSLocalizedString(@"devices_connected_format", nil), centralDevice.subDeviceList.count];
                cell.macLabel.text = [centralDevice.macAddress stringByAppendingFormat:@" %@", strCount];
            } else {
                cell.macLabel.text = centralDevice.macAddress;
            }
            cell.titleLabel.text = devName;
            cell.textLabel.text = nil;
        } else { //其他项目
            if (centralDevice.subDeviceList.count > 0) {
                NSString *strCount = [NSString stringWithFormat:NSLocalizedString(@"devices_connected_format", nil), centralDevice.subDeviceList.count];
                cell.macLabel.text = strCount;
                cell.titleLabel.text = devName;
                cell.textLabel.text = nil;
            } else {
                cell.macLabel.text = @"";
                cell.titleLabel.text = nil;
                cell.textLabel.text = devName;
            }
        }
    } else {
        if (common.isSpecialBundleID || common.isDisplayMac) {
            cell.macLabel.text = dev.macAddress;
            cell.titleLabel.text = devName;
            cell.textLabel.text = nil;
        } else {
            cell.macLabel.text = @"";
            cell.textLabel.text = devName;
            cell.titleLabel.text = nil;
        }
    }
    
    if (dev.netStatus == GizDeviceOnline || dev.netStatus == GizDeviceControlled) {
        if (dev.isLAN) {
            cell.imageView.image = [UIImage imageNamed:@"common_device_lan_online.png"];
        } else {
            cell.imageView.image = [UIImage imageNamed:@"common_device_remote_online.png"];
        }
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        if (dev.isLAN) {
            cell.imageView.image = [UIImage imageNamed:@"common_device_lan_offline.png"];
        } else {
            cell.imageView.image = [UIImage imageNamed:@"common_device_remote_offline.png"];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSMutableArray *devArr = [self.deviceListArray objectAtIndex:indexPath.section];
    if ([devArr count] > 0) {
        GizWifiDevice *dev = [devArr objectAtIndex:indexPath.row];
        if (dev.isSubscribed) {
            // 设备是已订阅状态直接跳转
            [GosCommon sharedInstance].controlHandler(dev, self);
            return;
        }
        // 设备未订阅，执行订阅逻辑
        if ([GosCommon canEnterProductSecret:dev]) {
            [GosCommon enterProductSecret:^(NSString *text) {
                [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                self.isSetSubscribe = YES;
                [dev setSubscribe:text subscribed:YES];
            } controller:self];
        } else if (dev.netStatus == GizDeviceOnline || dev.netStatus == GizDeviceControlled) {
            [GosCommon showHUDAddedTo:self.view animated:YES];
            self.isSetSubscribe = YES;
            [dev setSubscribe:YES];
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *devArr = [self.deviceListArray objectAtIndex:indexPath.section];
    if (devArr.count == 0) {
        return NO;
    }
    GizWifiDevice *device = devArr[indexPath.row];
    if (device.isBind) {
        return YES;
    }
    return NO;
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < 0) { //处理数据错误的特殊情况
        return nil;
    }
    
    NSMutableArray <UITableViewRowAction *>*rowActions = [NSMutableArray array];
    __block GizWifiDevice *device = [self getDeviceFromTable:indexPath];
    if (device.isBind) {
        
        if (common.isUsingUnbindButton) {
            if (!common.isAutoSubscribeDevice) {
                UITableViewRowAction *unbindAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:NSLocalizedString(@"Delete", nil) handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
                    [self unBindDevice:device];
                    [tableView setEditing:NO animated:YES];
                }];
                [rowActions addObject:unbindAction];
            }
        }
        if (common.isDeviceSharingSupport) {
            if (device.sharingRole == GizDeviceSharingOwner || device.sharingRole == GizDeviceSharingSpecial) {
                UITableViewRowAction *cancelSharing = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:NSLocalizedString(@"Sharing", nil) handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
                    if (common.currentLoginStatus != GizLoginUser) {
                        [GosCommon showAlertAutoDisappear:NSLocalizedString(@"Please login first, then share device", nil)];
                    } else {
                        GosAddSharingViewController *addSharing = (GosAddSharingViewController *)[[UIStoryboard storyboardWithName:@"GosSharing" bundle:nil] instantiateViewControllerWithIdentifier:@"toAddSharing"];
                        addSharing.device = device;
                        [self safePushViewController:addSharing];
                    }
                    [tableView setEditing:NO animated:YES];
                }];
                cancelSharing.backgroundColor = [UIColor colorWithRed:0 green:0.5351 blue:1 alpha:1];
                [rowActions addObject:cancelSharing];
            }
        }
        
    }
    return rowActions;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath { //ios8 only
    
}

#pragma mark
- (GizWifiDevice *)getDeviceFromTable:(NSIndexPath *)indexPath {
    if (indexPath.section >= 0) {
        NSArray *deviceArray = [self.deviceListArray objectAtIndex:indexPath.section];
        if (deviceArray.count > indexPath.row && indexPath.row >= 0) {
            return [deviceArray objectAtIndex:indexPath.row];
        }
    }
    return nil;
}


- (void)safePushViewController:(UIViewController *)viewController {
    UINavigationController *navController = nil;
    BOOL isValidPush = NO;
    if (self.tabBarController) {
        navController = self.tabBarController.navigationController;
        if (navController.viewControllers.lastObject == self.tabBarController) {
            isValidPush = YES;
        }
    } else {
        navController = self.navigationController;
        if (navController.viewControllers.lastObject == self) {
            isValidPush = YES;
        }
    }
    
    if (isValidPush) {
        [navController pushViewController:viewController animated:YES];
    }
}

- (void)safePopToViewController:(UIViewController *)viewController {
    BOOL isValidPop = NO;
    UINavigationController *navController = viewController.navigationController;
    NSInteger index = [navController.viewControllers indexOfObject:viewController];
    if (index >= 0 && index != navController.viewControllers.count) {
        isValidPop = YES;
    }
    
    if (isValidPop) {
        [navController popToViewController:viewController animated:YES];
    }
}

- (void)unBindDevice:(GizWifiDevice *)device {
    [GosCommon showHUDAddedTo:self.view animated:YES];
    [[GizWifiSDK sharedInstance] unbindDevice:common.uid token:common.token did:device.did];
}


- (IBAction)toAirLink:(id)sender {
    [self onAdd];
}


- (void)toSettings {
    GosCommon *dataCommon = common;
    if (dataCommon.settingPageHandler) {
        dataCommon.settingPageHandler(self);
    } else {
        UINavigationController *nav = [[UIStoryboard storyboardWithName:@"GosSettings" bundle:nil] instantiateInitialViewController];
        GosSettingsViewController *settingsVC = nav.viewControllers.firstObject;
        [self safePushViewController:settingsVC];
    }
}

#pragma mark - Back to root
- (void)gosConfigDidFinished {
    if (self.tabBarController) {
        [self safePopToViewController:self.tabBarController];
    } else {
        [self safePopToViewController:self];
    }
}

- (void)gosConfigDidSucceed:(GizWifiDevice *)device {
    [common onCancel];
}

#pragma mark - GizWifiSDK Delegate
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didDiscovered:(NSError *)result deviceList:(NSArray *)deviceList {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    if (self.pullToRefreshView.state == SSPullToRefreshViewStateLoading) {
        [self.pullToRefreshView finishLoadingAnimated:YES completion:^{
            [self refreshTableView];
        }];
    } else {
        [self refreshTableView];
    }
}

- (void)wifiSDK:(GizWifiSDK *)wifiSDK didBindDevice:(NSError *)result did:(NSString *)did {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    if (result.code != GIZ_SDK_SUCCESS) {
        NSString *info = [common checkErrorCode:result.code];
        [GosCommon showAlertWithTip:info];
    }
}

- (void)wifiSDK:(GizWifiSDK *)wifiSDK didUnbindDevice:(NSError *)result did:(NSString *)did {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    if (result.code == GIZ_SDK_SUCCESS) {
        [self.tableView setEditing:NO animated:YES];
    }
    else {
        NSString *info = [common checkErrorCode:result.code];
        [GosCommon showAlertWithTip:info];
    }
}


- (void)wifiSDK:(GizWifiSDK *)wifiSDK didChannelIDUnBind:(NSError *)result {
    [GosPushManager didUnbind:result];
}

- (void)wifiSDK:(GizWifiSDK *)wifiSDK didChannelIDBind:(NSError *)result {
    [GosPushManager didBind:result];
}


#pragma mark - GizWifiSDKDeviceDelegate
- (void)device:(GizWifiDevice *)device didSetSubscribe:(NSError *)result isSubscribed:(BOOL)isSubscribed {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    if (self.isSetSubscribe) {
        self.isSetSubscribe = NO;
    } else { //防止在其他页面调用的回调触发了错误的事件
        return;
    }
    if (result.code == GIZ_SDK_SUCCESS) {
        if (isSubscribed == YES) {
            self.lastSubscribedDevice = device;
            [GosCommon sharedInstance].controlHandler(device, self);
        }
    } else {
        [GosCommon showAlertWithTip:[[GosCommon sharedInstance] checkErrorCode:result.code]];
    }
}

- (void)didUpdateSubDevices:(GizWifiCentralControlDevice *)device result:(NSError *)result subDeviceList:(NSArray<GizWifiDevice *> *)subDeviceList {
    if (result.code == GIZ_SDK_SUCCESS) {
        [self refreshTableView];
    }
}


#pragma mark - QRCode
- (void)intoQRCodeVC {
#if (!TARGET_OS_SIMULATOR)
    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *app_Name = [infoDictionary objectForKey:@"CFBundleName"];
    if(authStatus == AVAuthorizationStatusDenied){
        if (IS_VAILABLE_IOS8) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Camera access denyed", nil) message:[NSString stringWithFormat:@"%@ %@ %@", NSLocalizedString(@"Allow camera prepend", nil), app_Name, NSLocalizedString(@"Allow camera access", nil)] preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];
            [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Go to Setting", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                if ([self canOpenSystemSettingView]) {
                    [self systemSettingView];
                }
            }]];
            [alertController show];
        } else {
            [GosCommon showAlert:NSLocalizedString(@"Camera access denyed", nil) message:[NSString stringWithFormat:@"%@ %@ %@", NSLocalizedString(@"Allow camera prepend", nil), app_Name, NSLocalizedString(@"Allow camera access", nil)]];
        }
        
        return;
    }
    
    QRCodeController *qrcodeVC = [[QRCodeController alloc] init];
    qrcodeVC.view.alpha = 0;
    [qrcodeVC setDidCancelBlock:^{
        if (common.recordPageHandler) {
            common.recordPageHandler(self);
        }
    }];
    [qrcodeVC setDidReceiveBlock:^(NSString *result) {
        if ([result rangeOfString:@"type=share&code="].location == 0) { //共享二维码特征
            if (!common.isDeviceSharingQRCode) {
                return ;
            }
            self.lastSharingCode = [result substringFromIndex:16];
            [GosCommon showHUDAddedTo:self.view animated:YES];
            [GizDeviceSharing checkDeviceSharingInfoByQRCode:common.token QRCode:self.lastSharingCode];
        } else {
            if (!common.isNormalDeviceQRCodeScan) {
                return;
            }
            NSDictionary *dict = [self getScanResult:result];
            if (dict != nil) {
                NSString *did = [dict valueForKey:@"did"];
                NSString *passcode = [dict valueForKey:@"passcode"];
                NSString *productkey = [dict valueForKey:@"product_key"];
                
                //这里，要通过did，passcode，productkey获取一个设备
                if (did.length > 0 && passcode.length > 0 && productkey > 0) {
                    [GosCommon showHUDAddedTo:self.view animated:YES];
                    [[GizWifiSDK sharedInstance] bindDeviceWithUid:common.uid token:common.token did:did passCode:passcode remark:nil];
                } else {
                    [GosCommon showAlertWithTip:NSLocalizedString(@"Unknown QR Code", nil)];
                }
            } else {
                [GosCommon showHUDAddedTo:self.view animated:YES];
                [[GizWifiSDK sharedInstance] bindDeviceByQRCode:common.uid token:common.token QRContent:result beOwner:false];
            }
        }
    }];
    AppDelegate *del = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [del.window.rootViewController addChildViewController:qrcodeVC];
    [del.window.rootViewController.view addSubview:qrcodeVC.view];
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        qrcodeVC.view.alpha = 1;
        if (common.recordPageHandler) {
            common.recordPageHandler(qrcodeVC);
        }
    } completion:^(BOOL finished) {
    }];
#else
    NSLog(@"warning: Scan QR code could not be supported by iPhone Simulator.");
#endif
}

- (BOOL)canOpenSystemSettingView {
    if (IS_VAILABLE_IOS8) {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            return YES;
        } else {
            return NO;
        }
    } else {
        return NO;
    }
}

- (void)systemSettingView {
    if (IS_VAILABLE_IOS8) {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
}


- (NSDictionary *)getScanResult:(NSString *)result
{
    NSArray *arr1 = [result componentsSeparatedByString:@"?"];
    if(arr1.count != 2)
    return nil;
    NSMutableDictionary *mdict = [NSMutableDictionary dictionary];
    NSArray *arr2 = [arr1[1] componentsSeparatedByString:@"&"];
    for(NSString *str in arr2)
    {
        NSArray *keyValue = [str componentsSeparatedByString:@"="];
        if(keyValue.count != 2)
        continue;
        
        NSString *key = keyValue[0];
        NSString *value = keyValue[1];
        [mdict setValue:value forKeyPath:key];
    }
    return mdict;
}

- (void)pullToRefreshViewDidStartLoading:(SSPullToRefreshView *)view {
    [self getBoundDevice];
}

- (void)didCheckDeviceSharingInfoByQRCode:(NSError *)result userName:(NSString *)userName productName:(NSString *)productName deviceAlias:(NSString *)deviceAlias expiredAt:(NSString *)expiredAt {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    if (result.code == GIZ_SDK_SUCCESS) {
        NSString *deviceInfo = deviceAlias;//设备名称
        NSString *qrcode = self.lastSharingCode;//二维码
        NSDate *expiredDate = nil;
        if (deviceInfo.length == 0) {
            deviceInfo = productName;
        }
        if (expiredAt.length > 0) {
            expiredDate = [GosCommon serviceDateFromString:expiredAt];//计算剩余分钟数
        }
        GosDeviceAcceptSharingInfo *acceptCtrl = [[GosDeviceAcceptSharingInfo alloc] initWithUser:userName deviceInfo:deviceInfo qrcode:qrcode expiredDate:expiredDate];
        [self safePushViewController:acceptCtrl];
    } else {
        NSString *message = nil;
        if (result.code == GIZ_OPENAPI_SHARING_IS_EXPIRED) {
            message = NSLocalizedString(@"Tips: The device sharing have been expired", nil);
        } else if (result.code == GIZ_SDK_DNS_FAILED ||
                   result.code == GIZ_SDK_CONNECTION_TIMEOUT ||
                   result.code == GIZ_SDK_CONNECTION_REFUSED ||
                   result.code == GIZ_SDK_CONNECTION_ERROR ||
                   result.code == GIZ_SDK_CONNECTION_CLOSED ||
                   result.code == GIZ_SDK_SSL_HANDSHAKE_FAILED) {
            message = NSLocalizedString(@"Sorry unable to get sharing info. Please check your internet connection", nil);
        } else {
            message = NSLocalizedString(@"Sorry unable to get sharing info. Please check your QR code", nil);
        }
        [GosCommon showAlertWithTip:message];
    }
}

@end
