/**
 * GizDeviceEnumCell.h
 *
 * Copyright (c) 2014~2015 Xtreme Programming Group, Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import <UIKit/UIKit.h>
#import "GosDeviceEnumSelectionController.h"


/**
 枚举控件类
 */
@class GosDeviceEnumCell;

@protocol GosDeviceEnumCellDelegate <NSObject>

@optional

/**
 控件被点击回调
 @param cell 控件本身
 */
- (void)deviceEnumCellDidSelected:(GosDeviceEnumCell *)cell;

/**
 选中某个枚举值的回调
 @param cell 控件本身
 @param index 选中的枚举值
 */
- (void)deviceEnumCell:(GosDeviceEnumCell *)cell didSelectedIndex:(NSInteger)index;

@end

@interface GosDeviceEnumCell : UITableViewCell

@property (nonatomic, weak) id<GosDeviceEnumCellDelegate> delegate;

// 数据点名称
@property (nonatomic, strong) NSString *title;

// 枚举所包含的所有值
@property (nonatomic, strong) NSArray *values;

// 当前选中的枚举值
@property (nonatomic, assign) NSInteger index;

// 数据点标识：用于标识本控件代表的数据点
@property (nonatomic, assign) int dataPoint;

// 表示本控件所表示的枚举值是否可写
@property (nonatomic, assign) BOOL isWrite;

@end
