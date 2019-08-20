//
//  GosDeviceSliderCell.h
//  GOpenSource_AppKit
//
//  Created by danly on 2017/2/9.
//  Copyright © 2017年 Gizwits. All rights reserved.
//

#import <UIKit/UIKit.h>

/*
 * ===========================================================
 * 以下属性对应开发者在云端定义的数值型数据点增量值、数据点定义的分辨率
 * addition: 数据点增量值
 * radio:数据点定义的分辨率
 *
 * 步值是相对于滚动条而言的，滚动条的范围：min~max, 每次滑动的距离只能是按整数步来算，不够整数步的时候，按四舍五入取整
 * 数据点的范围则是：minValue ~ maxValue
 *
 * 滚动条滑动值与数据点真实值之间的转换：
 * 当前的数据点值: value = radio * currentStep(滚动条的当前值) + addition;
 *
 * 若对于该转换公式还不太理解，可以开启官网产品的虚拟设备，与虚拟设备上数值型显示的计算公式同理
 *
 * 数据点值小数点后保留有效位数的计算方法：
 * 当addition与radion同为小数：以radion为准取有效位小数，如radio = 0.1, 则当前数据点保留的有效位为1位
 * 当radion为整数，addition为小数，则以addition为准取有效位小数，如addition = 0.01，则当前数据点保留的有效位为2位
 * 注意: 整型数据与浮点型数据都当成浮点型处理，整型数据根据addition与radion计算出来的结果即是保留小数点后0位数
 * ===========================================================
 */

/**
  可写的数值类型控件：包括整型和浮点型
 */
@class GosDeviceSliderCell;
@protocol GosDeviceSliderCellDelegate <NSObject>

/**
 滚动条滚动结束回调

 @param cell 控件本身
 @param value 滚动到的值
 */
- (void)deviceSlideCell:(GosDeviceSliderCell *)cell updateValue:(CGFloat)value;

@end

@interface GosDeviceSliderCell : UITableViewCell

// 数据点名称
@property (nonatomic, copy) NSString *title;
// 数据点定义的分辨率 = 步长
@property (nonatomic, copy) NSString *radio;
// 数据点增量值
@property (nonatomic, copy) NSString *addition;
// 当前数据点值
@property (nonatomic, assign) CGFloat value;

// 滚动条的滚动范围: min ~ max
// 最小步值
@property (nonatomic, assign) NSInteger min;
// 最大步值
@property (nonatomic, assign) NSInteger max;

// 数据点范围： minValue ~ maxValue
// 数据点最小值
@property (nonatomic, copy) NSString *minValue;
@property (nonatomic, copy) NSString *maxValue;

@property (nonatomic, weak) id<GosDeviceSliderCellDelegate> delegate;

// 数据点标识：用于标识本控件代表的数据点
@property (nonatomic, assign) int dataPoint;

// 为控件的所有属性赋值之后，必须调用这个方法才能正常显示数据
- (void)updateUI;

@end
