/**
 * GizDeviceLabelCell.m
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

#import "GosDeviceLabelCell.h"
#import "NSString+Rounding.h"

@interface GosDeviceLabelCell()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;

// 存储小数点位数
@property (nonatomic, assign) NSInteger decimalLength;

@end

@implementation GosDeviceLabelCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:NO animated:animated];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{

}

// 为控件的所有属性赋值之后，必须调用这个方法才能正常显示数据
- (void)updateUI
{
    // 计算小数点后保留有效位
    self.decimalLength = [NSString getDecimalPointLengthByRadio:_radio andAddition:_addition];
    self.valueLabel.text = [NSString stringWithString:[NSString getFormateStr:self.value afterPoint:self.decimalLength]];
}

#pragma mark - Properity
- (void)setTitle:(NSString *)title
{
    _title = title;
    self.titleLabel.text = title;
}

//- (void)setValue:(CGFloat)value
//{
//    _value = value;
//    self.valueLabel.text = [NSString getFormateStr:value afterPoint:self.decimalLength];
//}

@end
