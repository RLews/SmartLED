//
//  GosSharingInfoCell.h
//  GOpenSource_AppKit
//
//  Created by Tom on 2017/6/2.
//  Copyright © 2017年 Gizwits. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GosSharingInfoCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *deviceName;
@property (weak, nonatomic) IBOutlet UILabel *macAddress;
@property (weak, nonatomic) IBOutlet UILabel *sharingStatus;

@end
