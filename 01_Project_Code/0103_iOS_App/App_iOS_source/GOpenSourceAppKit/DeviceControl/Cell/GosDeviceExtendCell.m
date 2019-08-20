//
//  GosDeviceExtendCell.m
//  GOpenSource_AppKit
//
//  Created by danly on 2017/2/10.
//  Copyright © 2017年 Gizwits. All rights reserved.
//

#import "GosDeviceExtendCell.h"

// 扩展数据点可输入的数字与字母
#define EffectiveNum @"0123456789ABCDEFabcdef"

@interface GosDeviceExtendCell()<UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITextView *valueTextView;

// 当前cell的tableView
@property (nonatomic, weak) UITableView *tableView;
// 存储旧的焦点位置
@property (nonatomic, assign) NSInteger oldFocusLocation;

@end

@implementation GosDeviceExtendCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // 添加textView变化通知
    self.valueTextView.scrollEnabled = NO;
    self.valueTextView.delegate = self;
    self.valueTextView.keyboardType = UIKeyboardTypeASCIICapable;
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:NO animated:animated];
}

#pragma mark - UITextViewTextDidChangeNotification
// 获取用户新输入的字符
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (text.length > 1)
    {
        // 设置最多一次能输入一个字符
        return NO;
    }
    
    if ([text isEqualToString:@"\n"]) {
        // 输入结束
        if ([self.delegate respondsToSelector:@selector(deviceExtendCellEditStop:value:)])
        {
            [self.delegate deviceExtendCellEditStop:self value:self.value];
        }
        [textView resignFirstResponder];
        return NO;
    }
    NSLog(@"text = %@", text);
    NSLog(@"range.location = %zd, range.length = %zd", range.location, range.length);
    
    // 判断输入的值是否在 EffectiveNum的范围内，是 filtered返回当前输入的值，否则：filtered是一个空字符串
    NSCharacterSet *cs = [[NSCharacterSet characterSetWithCharactersInString:EffectiveNum] invertedSet];
    NSString *filtered = [[text componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
    
    
    NSLog(@"text = %@", text);
    NSLog(@"cs = %@", cs);
    NSLog(@"filtered = %@", filtered);
    NSLog(@"changText焦点： %zd", textView.selectedRange.location);
    
    // 设置旧的焦点
    self.oldFocusLocation = textView.selectedRange.location;
    return [text isEqualToString:filtered];
}

// textView的字符串每次发生变化调用
- (void)textViewDidChange:(UITextView *)textView
{
    // 设置扩展数据点显示的格式
    NSInteger newFocusLocation = textView.selectedRange.location;
    if(newFocusLocation >= self.oldFocusLocation)
    {
        // 增加字符，移动焦点
        // 新增字符的个数
        NSInteger newNum = newFocusLocation - self.oldFocusLocation;
        
        if ((self.oldFocusLocation + 1) % 3 == 0)
        {
            newFocusLocation += (newNum + 1) / 2;
        }
        else if((self.oldFocusLocation + 2) % 3 == 0)
        {
            newFocusLocation += (newNum) / 2;
        }
    }
    
    // 移动焦点
    NSLog(@"更改前:textView.text = %@", textView.text);
    textView.text = [self getFormateStringByStr:textView.text];
    textView.selectedRange = NSMakeRange(newFocusLocation, 0);
    NSLog(@"更改后:textView.text = %@", textView.text);
    [self refreshCellByValue];
    self.value = [self getStrByDeleteSpace:textView.text];
    NSLog(@"焦点： %zd", textView.selectedRange.location);
}

#pragma mark - updateUI
// 根据textView的frame值动态改变cell的frame
- (void)refreshCellByValue
{
    CGRect bounds = self.valueTextView.bounds;
    CGSize maxSize = CGSizeMake(bounds.size.width, MAXFLOAT);
    CGSize newSize = [self.valueTextView sizeThatFits:maxSize];
    bounds.size = newSize;
    
    self.valueTextView.bounds = bounds;
    
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

#pragma mark - 字符串格式转换
// 获取去除空格的字符串
- (NSString *)getStrByDeleteSpace:(NSString *)str
{
    return [str stringByReplacingOccurrencesOfString:@" " withString:@""];
}

// 将一个普通字符串格式化成每隔两位加一个空格的形式
// str字符串格式: 63423
// return的字符串格式: 63 42 3
- (NSString *)getFormateStringByStr:(NSString *)str
{
    if (str == nil || [str isEqualToString:@""])
    {
        return str;
    }
    // 删除所有空格
    str = [NSMutableString stringWithFormat:@"%@", [str stringByReplacingOccurrencesOfString:@" " withString:@""]];
    NSInteger length = str.length;
    if (length <= 2)
    {
        return str.uppercaseString;
    }
    
    // 计算格式化后的字符串长度
    NSInteger formateLength = (length / 2 - 1) + length;
    if (length % 2 > 0)
    {
        formateLength++;
    }
    NSLog(@"formateLength = %zd", formateLength);
    
    // 每两位添加一个空格
    NSMutableString *endStr = [NSMutableString stringWithString:str];
    
    for (int i = 0; i < formateLength; ++i)
    {
        if (i > 0 && (i+1) % 3 == 0)
        {
            NSString *tempStr = [endStr substringToIndex:i];
            tempStr = [tempStr stringByAppendingString:@" "];
            [endStr replaceCharactersInRange:NSMakeRange(0, i) withString:tempStr];
            
        }
    }
    
    return endStr.uppercaseString;
}

#pragma mark - Properity
- (void)setTitle:(NSString *)title
{
    _title = title;
    self.titleLabel.text = title;
}

- (void)setIsWrite:(BOOL)isWrite
{
    _isWrite = isWrite;
    if (!isWrite)
    {
        self.titleLabel.textColor = [UIColor darkGrayColor];
        self.valueTextView.textColor = [UIColor darkGrayColor];
        self.userInteractionEnabled = NO;
    }
    else
    {
        self.titleLabel.textColor = [UIColor blackColor];
        self.valueTextView.textColor = [UIColor blackColor];
        self.userInteractionEnabled = YES;
    }
    
}

- (void)setValue:(NSString *)value
{
    _value = value;
    NSLog(@"value = %@, value.class = %@", value, [value class]);
    if (value != nil && ![value isEqualToString:@""])
    {
        self.valueTextView.text = [self getFormateStringByStr:value];
    }
    else
    {
        self.valueTextView.text = @"";
    }
}

- (UITableView *)tableView
{
    if (_tableView == nil)
    {
        UIView *tableView = self.superview;
        if (![tableView isKindOfClass:[UITableView class]] && tableView)
        {
            _tableView = (UITableView *)(tableView.superview);
        }
    }
    return _tableView;
}

@end
