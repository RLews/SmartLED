/**
 * GizDeviceEnumCell.m
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

#import "GosDeviceEnumCell.h"

@interface GosDeviceEnumCell()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;

@end

@implementation GosDeviceEnumCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if(selected == YES && [_delegate respondsToSelector:@selector(deviceEnumCellDidSelected:)])
    {
        [_delegate deviceEnumCellDidSelected:self];
    }
    
    [super setSelected:NO animated:animated];
}

#pragma mark - Properity
- (void)setTitle:(NSString *)title
{
    _title = title;
    self.titleLabel.text = title;
}

- (void)setValues:(NSArray *)values
{
    _values = values;
}

- (void)setIndex:(NSInteger)index
{
    _index = index;
    if(_index >= 0 && _index < _values.count)
    {
        self.valueLabel.text = [NSString stringWithFormat:@"%@", _values[index]];
    }
    else
    {
        self.valueLabel.text = @"";
    }
}

- (void)setIsWrite:(BOOL)isWrite
{
    _isWrite = isWrite;
    if (!isWrite)
    {
        // 不可写控件改为深灰色
        self.userInteractionEnabled = NO;
        self.titleLabel.textColor = [UIColor darkGrayColor];
        self.valueLabel.textColor = [UIColor darkGrayColor];
    }
    else
    {
        self.userInteractionEnabled = YES;
        self.titleLabel.textColor = [UIColor blackColor];
        self.valueLabel.textColor = [UIColor blackColor];
    }
}

@end
