//
//  GizDeviceViewController.m
//  GOpenSource_AppKit
//
//  Created by danly on 2017/2/7.
//  Copyright © 2017年 Gizwits. All rights reserved.
//
#import "GosDeviceViewController.h"
#import "GosDeviceSliderCell.h"
#import "GosDeviceBoolCell.h"
#import "GosDeviceControl.h"

#import "GosTipView.h"
#import "GosAlertView.h"
#import "GosCommon.h"

// 各类Cell的重用标识
#define GosDeviceSliderCellReuseIdentifier @"GosDeviceSliderCellReuseIdentifier"
#define GosDeviceBoolCellReuseIdentifier @"GosDeviceBoolCellReuseIdentifier"

/**
 设备控制界面
 */
@interface GosDeviceViewController ()<UITableViewDataSource, UITableViewDelegate,GosDeviceSliderCellDelegate,GosDeviceBoolCellDelegate, GizWifiDeviceDelegate, UIActionSheetDelegate>

// 当前设备
@property (nonatomic, strong) GizWifiDevice *device;
@property (nonatomic, weak) UITableView *tableView;

// 线程
@property (nonatomic, strong) NSOperationQueue *queue;
// 设备读写工具
@property (nonatomic, strong) GosDeviceControl *deviceControl;
// 设备名称
@property (nonatomic, copy) NSString *deviceName;
//提示框
@property (nonatomic, strong) GosTipView *tipView;
@property (nonatomic, strong) UIAlertView *alertView;
@property (nonatomic, strong) UIActionSheet *actionSheet;

@end

@implementation GosDeviceViewController

- (instancetype)initWithDevice:(GizWifiDevice *)device
{
    if (self = [super init])
    {
        self.device = device;
        self.device.delegate = self;
        self.deviceControl.device = device;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupUI];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // 检查设备状态
    [self checkDeviceStatus];
}

#pragma mark - NavigaitonBar 导航栏部分设置
- (void)setupNavigationBar
{
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back_arrow"] style:UIBarButtonItemStylePlain target:self action:@selector(onBack)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"more"] style:UIBarButtonItemStylePlain target:self action:@selector(menuBtnPressed)];
    self.navigationItem.title = self.deviceName;
}

- (void)onBack
{
    [self.device setSubscribe:nil subscribed:NO];
    self.device.delegate = nil;
    [[GosTipView sharedInstance] hideTipView];
    [_actionSheet dismissWithClickedButtonIndex:0 animated:YES];
    [_alertView dismissWithClickedButtonIndex:0 animated:YES];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)menuBtnPressed
{
    _actionSheet = nil;
    
    _actionSheet = [[UIActionSheet alloc]
                   initWithTitle:nil
                   delegate:self
                   cancelButtonTitle:@"取消"
                   destructiveButtonTitle:nil
                   otherButtonTitles:@"获取设备状态", @"获取硬件信息", @"设置设备信息", nil];
    
    _actionSheet.actionSheetStyle = UIBarStyleBlackTranslucent;
    [_actionSheet showInView:self.view];
}

#pragma mark - actionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
        // 点击了《获取设备状态》
        [self.tipView showLoadTipWithMessage:nil];
        [self.device getDeviceStatus:nil];
    }
    else if (buttonIndex == 1)
    {
        // 点击了《获取硬件信息》
        if (self.device.isLAN)
        {
            [self.device getHardwareInfo];
        }
        else
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.tipView showTipMessage:@"只允许在局域网下获取设备硬件信息" delay:1 completion:nil];
            });
        }
    }
    else if (buttonIndex == 2)
    {
        // 点击了《设置设备信息》
        _alertView = [[UIAlertView alloc] initWithTitle:@"设置别名及备注" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        
        [_alertView setAlertViewStyle:UIAlertViewStyleLoginAndPasswordInput];
        
        UITextField *aliasField = [_alertView textFieldAtIndex:0];
        aliasField.placeholder = @"请输入别名";
        aliasField.text = self.device.alias;
        
        UITextField *remarkField = [_alertView textFieldAtIndex:1];
        [remarkField setSecureTextEntry:NO];
        remarkField.placeholder = @"请输入备注";
        remarkField.text = self.device.remark;
        
        [_alertView show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.firstOtherButtonIndex)
    {
        //设置别名及备注，点击了《确定》
        UITextField *aliasField = [alertView textFieldAtIndex:0];
        UITextField *remarkField = [alertView textFieldAtIndex:1];
        [aliasField resignFirstResponder];
        [remarkField resignFirstResponder];
        if ([aliasField.text isEqualToString:@""] &&[remarkField.text isEqualToString:@""])
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
               [self.tipView showTipMessage:@"请输入设备别名或备注！" delay:1 completion:nil];
            });
        }
        else
        {
            [self.tipView showLoadTipWithMessage:nil];
            [self.device setCustomInfo:remarkField.text alias:aliasField.text];
        }
    }
}

#pragma mark - 检测设备状态
// 检查设备状态
- (void)checkDeviceStatus
{
    if (self.device.netStatus == GizDeviceControlled)
    {
        // 设备可控获取设备状态
        [[GosTipView sharedInstance] hideTipView];
        [self.device getDeviceStatus:nil];
        return;
    }
    
    [[GosTipView sharedInstance] showLoadTipWithMessage:@"正在等待连接"];
    
    // 开启一个子线程 检测设备状态
    NSBlockOperation *operation = [[NSBlockOperation alloc] init];
    
    __weak NSBlockOperation *weakOperation = operation;
    [operation addExecutionBlock:^{
        int timeInterval = self.device.isLAN ? 10 : 20;
        
        // 小循环延时 10s / 大循环延时 20s
        [NSThread sleepForTimeInterval:timeInterval];
        
        if (![weakOperation isCancelled])
        {
            if (self.device.netStatus != GizDeviceControlled)
            {
                // 10s/20s后 设备不可控，退到设备列表
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[GosTipView sharedInstance] hideTipView];
                    // 退到设备列表
                    if (self.navigationController.viewControllers.lastObject == self)
                    {
                        [[GosTipView sharedInstance] showTipMessage:@"设备无响应，请检查设备是否正常工作" delay:1 completion:^{
                            [self onBack];
                        }];
                    }
                });
                
            }
            else
            {
                // 可控，获取设备状态
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.device getDeviceStatus:nil];
                    
                });
            }
            // 关闭所有线程
            [self.queue cancelAllOperations];
        }
        
    }];
    
    // 取消其它所有正在检测设备网络状态的线程
    if (self.queue.operationCount > 0)
    {
        [self.queue cancelAllOperations];
    }
    [self.queue addOperation:operation];
}

#pragma mark - GizWifiDeviceDelegate 
// 获取设备数据点状态回调
- (void)device:(GizWifiDevice *)device didReceiveData:(NSError *)result data:(NSDictionary *)dataMap withSN:(NSNumber *)sn
{
    [[GosTipView sharedInstance] hideTipView];
    
    //读取设备状态
    NSDictionary *data = [dataMap valueForKey:@"data"];
    
    if(data != nil && [data count] != 0)
    {
        // 读取所有数据点值
        [self.deviceControl readDataPointsFromData:dataMap];
        [self.tableView reloadData];
    }
    
}

// 设备离在线状态回调
- (void)device:(GizWifiDevice *)device didUpdateNetStatus:(GizWifiDeviceNetStatus)netStatus
{
    if (netStatus == GizDeviceControlled)
    {
        [self.queue cancelAllOperations];
        [[GosTipView sharedInstance] hideTipView];
        [self.device getDeviceStatus:nil];
        return;
    }
    
    if (netStatus != GizDeviceControlled && self.navigationController.viewControllers.lastObject == self)
    {
        [[GosTipView sharedInstance] showTipMessage:@"连接已断开"  delay:1 completion:^{
            [self onBack];
        }];
    }
}

// 设置设备别名回调
- (void)device:(GizWifiDevice *)device didSetCustomInfo:(NSError *)result
{
    [self.tipView hideTipView];
    if (result.code == GIZ_SDK_SUCCESS)
    {
        [self.tipView showTipMessage:@"设置成功" delay:1 completion:^{
            [self onBack];
        }];
    }
    else
    {
        [self.tipView showTipMessage:@"设置失败" delay:1 completion:nil];
    }
}

// 获取设备硬件信息回调
- (void)device:(GizWifiDevice *)device didGetHardwareInfo:(NSError *)result hardwareInfo:(NSDictionary *)hardwareInfo
{
    NSString *hardWareInfo = [NSString stringWithFormat:@"WiFi Hardware Version: %@,\nWiFi Software Version: %@,\nMCU Hardware Version: %@,\nMCU Software Version: %@,\nFirmware Id: %@,\nFirmware Version: %@,\nProduct Key: %@,\nDevice ID: %@,\nDevice IP: %@,\nDevice MAC: %@"
                              , [hardwareInfo valueForKey:@"wifiHardVersion"]
                              , [hardwareInfo valueForKey:@"wifiSoftVersion"]
                              , [hardwareInfo valueForKey:@"mcuHardVersion"]
                              , [hardwareInfo valueForKey:@"mcuSoftVersion"]
                              , [hardwareInfo valueForKey:@"wifiFirmwareId"]
                              , [hardwareInfo valueForKey:@"wifiFirmwareVer"]
                              , [hardwareInfo valueForKey:@"productKey"]
                              , self.device.did, self.device.ipAddress, self.device.macAddress];
    dispatch_async(dispatch_get_main_queue(), ^{
        _alertView = [[UIAlertView alloc] initWithTitle:@"设备硬件信息" message:hardWareInfo delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [self.alertView show];
    });
}



#pragma mark - Table view data source And delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 6;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row)
    {
        case 0:
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:GosDeviceBoolCellReuseIdentifier forIndexPath:indexPath];
            GosDeviceBoolCell *Led_WarmSta_Cell = (GosDeviceBoolCell *)cell;
            Led_WarmSta_Cell.title = @"Led_WarmSta";
            Led_WarmSta_Cell.value = self.deviceControl.key_Led_WarmSta;
            Led_WarmSta_Cell.dataPoint = GosDevice_Led_WarmSta;
            Led_WarmSta_Cell.isWrite = YES;
            Led_WarmSta_Cell.delegate = self;
            return cell;
  
        }
        case 1:
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:GosDeviceBoolCellReuseIdentifier forIndexPath:indexPath];
            GosDeviceBoolCell *LedOnOff_Cell = (GosDeviceBoolCell *)cell;
            LedOnOff_Cell.title = @"LedOnOff";
            LedOnOff_Cell.value = self.deviceControl.key_LedOnOff;
            LedOnOff_Cell.dataPoint = GosDevice_LedOnOff;
            LedOnOff_Cell.isWrite = YES;
            LedOnOff_Cell.delegate = self;
            return cell;
  
        }
        case 2:
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:GosDeviceSliderCellReuseIdentifier forIndexPath:indexPath];
            GosDeviceSliderCell *Led_RVal_Cell = (GosDeviceSliderCell *)cell;
            Led_RVal_Cell.title = @"Led_RVal";
            Led_RVal_Cell.value = self.deviceControl.key_Led_RVal;
            Led_RVal_Cell.radio = @"1";
            Led_RVal_Cell.addition = @"0";
            Led_RVal_Cell.min = 0;
            Led_RVal_Cell.max = 255;
            Led_RVal_Cell.minValue = @"0";
            Led_RVal_Cell.maxValue = @"255";
            Led_RVal_Cell.dataPoint = GosDevice_Led_RVal;
            Led_RVal_Cell.delegate = self;
            [Led_RVal_Cell updateUI];
            return cell;
  
        }
        case 3:
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:GosDeviceSliderCellReuseIdentifier forIndexPath:indexPath];
            GosDeviceSliderCell *Led_GVal_Cell = (GosDeviceSliderCell *)cell;
            Led_GVal_Cell.title = @"Led_GVal";
            Led_GVal_Cell.value = self.deviceControl.key_Led_GVal;
            Led_GVal_Cell.radio = @"1";
            Led_GVal_Cell.addition = @"0";
            Led_GVal_Cell.min = 0;
            Led_GVal_Cell.max = 255;
            Led_GVal_Cell.minValue = @"0";
            Led_GVal_Cell.maxValue = @"255";
            Led_GVal_Cell.dataPoint = GosDevice_Led_GVal;
            Led_GVal_Cell.delegate = self;
            [Led_GVal_Cell updateUI];
            return cell;
  
        }
        case 4:
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:GosDeviceSliderCellReuseIdentifier forIndexPath:indexPath];
            GosDeviceSliderCell *Led_BVal_Cell = (GosDeviceSliderCell *)cell;
            Led_BVal_Cell.title = @"Led_BVal";
            Led_BVal_Cell.value = self.deviceControl.key_Led_BVal;
            Led_BVal_Cell.radio = @"1";
            Led_BVal_Cell.addition = @"0";
            Led_BVal_Cell.min = 0;
            Led_BVal_Cell.max = 255;
            Led_BVal_Cell.minValue = @"0";
            Led_BVal_Cell.maxValue = @"255";
            Led_BVal_Cell.dataPoint = GosDevice_Led_BVal;
            Led_BVal_Cell.delegate = self;
            [Led_BVal_Cell updateUI];
            return cell;
  
        }
        case 5:
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:GosDeviceSliderCellReuseIdentifier forIndexPath:indexPath];
            GosDeviceSliderCell *Led_Brightness_Cell = (GosDeviceSliderCell *)cell;
            Led_Brightness_Cell.title = @"Led_Brightness";
            Led_Brightness_Cell.value = self.deviceControl.key_Led_Brightness;
            Led_Brightness_Cell.radio = @"1";
            Led_Brightness_Cell.addition = @"0";
            Led_Brightness_Cell.min = 0;
            Led_Brightness_Cell.max = 4095;
            Led_Brightness_Cell.minValue = @"0";
            Led_Brightness_Cell.maxValue = @"4095";
            Led_Brightness_Cell.dataPoint = GosDevice_Led_Brightness;
            Led_Brightness_Cell.delegate = self;
            [Led_Brightness_Cell updateUI];
            return cell;
  
        }
        default:
            return nil;
    }
}

#pragma mark - GosDeviceSliderCellDelegate - 可写数值型回调
// 滚动条滚动停止回调
- (void)deviceSlideCell:(GosDeviceSliderCell *)cell updateValue:(CGFloat )value
{
    [self.deviceControl writeDataPoint:cell.dataPoint value:[NSNumber numberWithDouble:value]];
}

#pragma mark - GosDeviceBoolCellDelegate - 可写布尔型回调
// 开关状态变化回调
- (void)deviceBoolCell:(GosDeviceBoolCell *)cell switchDidUpdateValue:(BOOL)value
{
    NSLog(@"deviceBoolCell布尔值发生改变: %d", value);
    [self.deviceControl writeDataPoint:cell.dataPoint value:[NSNumber numberWithBool:value]];
}

#pragma mark - 界面设置
// 设置显示界面
- (void)setupUI
{
    self.view.backgroundColor = [UIColor whiteColor];
    [self setupTableView];
    [self setupNavigationBar];
    
    // 设置数据点初始值，更新界面
    [self.deviceControl initDevice];
    [self.tableView reloadData];
}

- (void)setupTableView
{
    self.tableView.estimatedRowHeight = 44;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [self.tableView registerNib:[UINib nibWithNibName:@"GosDeviceSliderCell" bundle:nil] forCellReuseIdentifier:GosDeviceSliderCellReuseIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"GosDeviceBoolCell" bundle:nil] forCellReuseIdentifier:GosDeviceBoolCellReuseIdentifier];
}

- (void)onBackControl
{
    // 返回前一个界面
    [self.navigationController popViewControllerAnimated:YES];
}

// tableView移动时退出键盘
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.tableView endEditing:YES];
}

#pragma mark - Properity
- (UITableView *)tableView
{
    if (_tableView == nil)
    {
        UITableView *tb = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
        [self.view addSubview:tb];
        _tableView = tb;
        _tableView.delegate = self;
        _tableView.dataSource = self;
    }
    return _tableView;
}

- (GosDeviceControl *)deviceControl
{
    return [GosDeviceControl sharedInstance];
}

- (NSString *)deviceName
{
    if (_deviceName == nil)
    {
       _deviceName = self.device.alias == nil || [self.device.alias isEqualToString:@""] ? self.device.productName : self.device.alias;
    }
    return _deviceName;
}

- (GosTipView *)tipView
{
    return [GosTipView sharedInstance];
}

@end