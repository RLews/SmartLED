//
//  GosDeviceListCell.m
//  GosGokit
//
//  Created by Zono on 16/6/8.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import "GosDeviceListCell.h"

@implementation GosDeviceListCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)onSwitch:(UISwitch *)sender {
    self.onSwitch(self);
}


@end
