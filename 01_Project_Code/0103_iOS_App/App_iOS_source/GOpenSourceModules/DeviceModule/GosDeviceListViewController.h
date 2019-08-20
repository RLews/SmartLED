//
//  DeviceListViewController.h
//  GBOSA
//
//  Created by Zono on 16/5/6.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GosConfigStart.h"

@interface GosDeviceListViewController : UITableViewController <GosConfigStartDelegate>

@property (nonatomic, strong) UIViewController *parent;
@property (nonatomic, strong) NSArray *deviceListArray;

- (void)safePushViewController:(UIViewController *)viewController;

@end
