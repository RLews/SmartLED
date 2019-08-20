//
//  NSString+Rounding.m
//  GOpenSource_AppKit
//
//  Created by danly on 2017/2/9.
//  Copyright © 2017年 Gizwits. All rights reserved.
//

#import "NSString+Rounding.h"

@implementation NSString (Rounding)


/**
 获取给定浮点值取指定小数点后有效位数的值（四舍五入的方式）

 @param str 给定浮点值
 @param position 小数点后保留的有效位数
 @return 取指定有效位小数后的str值
 */
+ (NSString *)getFormateStr:(double)str afterPoint:(NSUInteger)position
{
    // NSRoundPlain: 表示采用四舍五入的方式进位置
    NSDecimalNumberHandler* roundingBehavior = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundPlain scale:position raiseOnExactness:NO raiseOnOverflow:NO raiseOnUnderflow:NO raiseOnDivideByZero:NO];
    
    NSDecimalNumber *ouncesDecimal;
    NSDecimalNumber *roundedOunces;
    
    ouncesDecimal = [[NSDecimalNumber alloc] initWithDouble:str];
    roundedOunces = [ouncesDecimal decimalNumberByRoundingAccordingToBehavior:roundingBehavior];
    
    return [NSString stringWithFormat:@"%@",roundedOunces];
}

/**
 根据radio和addition获取有效小数位数
 计算方法：radio为小数时，以radio的小数位数为准, 如radio = 0.1， 返回1
        radio为整数时，以addition的小数位数为准 如radio = 1, addition = 0.01, 返回2

 @param radio 分辨率
 @param addition 增量值
 @return 最长的小数位位数
 */
+ (NSInteger)getDecimalPointLengthByRadio: (NSString *)radio andAddition: (NSString *)addition
{
    NSInteger radioNum1 = [self getDecimalPointLength:radio];
    NSInteger additionNum2 = [self getDecimalPointLength:addition];
    if (radioNum1 > 0)
    {
        return radioNum1;
    }
    else
    {
        return additionNum2;
    }
}

// 获取小数点后有多少位
+ (NSUInteger)getDecimalPointLength:(NSString *)decimal
{
    NSArray *strs = [decimal componentsSeparatedByString:@"."];
    if (strs.count == 1)
    {
        return 0;
    }
    else
    {
        NSString *result = strs[1];
        return result.length;
    }
}

@end
