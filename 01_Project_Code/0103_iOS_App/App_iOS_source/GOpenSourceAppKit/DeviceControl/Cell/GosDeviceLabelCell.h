/**
 * GizDeviceLabelCell.h
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

/*
 * ===========================================================
 * 以下属性对应开发者在云端定义的数值型数据点增量值、数据点定义的分辨率
 * addition: 数据点增量值
 * radio:数据点定义的分辨率
 * addition 和 radio在本类中的作用仅仅是计算数据点真实值所需保留的小数点后有效位数
 * 
 * 数据点值小数点后保留有效位数的计算方法：
 * 当addition与radion同为小数：以radion为准取有效位小数，如radio = 0.1, 则当前数据点保留的有效位为1位
 * 当radion为整数，addition为小数，则以addition为准取有效位小数，如addition = 0.01，则当前数据点保留的有效位为2位
 * 注意: 整型数据与浮点型数据都当成浮点型处理，整型数据根据addition与radion计算出来的结果即是保留小数点后0位数
 * ===========================================================
 */


/**
 不可写的数值类型控件：包括整型和浮点型
 */
@interface GosDeviceLabelCell : UITableViewCell

// 数据点名称
@property (nonatomic, strong) NSString *title;

// 数据点当前值
@property (nonatomic, assign) CGFloat value;

// 数据点定义的分辨率
@property (nonatomic, copy) NSString *radio;

// 数据点增量值
@property (nonatomic, copy) NSString *addition;

// 数据点标识：用于标识本控件代表的数据点
@property (nonatomic, assign) int dataPoint;

// 为控件的所有属性赋值之后，必须调用这个方法才能正常显示数据
- (void)updateUI;

@end
