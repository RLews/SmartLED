//
//  GosDeviceListCell.h
//  GosGokit
//
//  Created by Zono on 16/6/8.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GizWifiSDK/GizWifiSDK.h>

@class GosDeviceListCell;
typedef void(^deviceListCellBtnOnSwitch)(GosDeviceListCell *cell);

@interface GosDeviceListCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *macLabel;
@property (weak, nonatomic) IBOutlet UISwitch *switchBtn;
@property (nonatomic, weak) GizWifiDevice *device;
@property (nonatomic, strong) deviceListCellBtnOnSwitch onSwitch;

@end
