//
//  GosDeviceExtendCell.h
//  GOpenSource_AppKit
//
//  Created by danly on 2017/2/10.
//  Copyright © 2017年 Gizwits. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 扩展数据点控件
 */
@class GosDeviceExtendCell;
@protocol GosDeviceExtendCellDelegete <NSObject>
/**
 扩展数据点编辑结束回调

 @param cell 控件本身
 @param value 扩展数据点值
 */
- (void)deviceExtendCellEditStop:(GosDeviceExtendCell *)cell value:(NSString *)value;

@end

@interface GosDeviceExtendCell : UITableViewCell

// 数据点名称
@property (nonatomic, copy) NSString *title;

// 当前的扩展数据点值
@property (nonatomic, strong) NSString *value;

// 标识当前数据点是否可写类型
@property (nonatomic, assign) BOOL isWrite;

@property (nonatomic, weak) id<GosDeviceExtendCellDelegete> delegate;

// 数据点标识：用于标识本控件代表的数据点
@property (nonatomic, assign) int dataPoint;

@end
