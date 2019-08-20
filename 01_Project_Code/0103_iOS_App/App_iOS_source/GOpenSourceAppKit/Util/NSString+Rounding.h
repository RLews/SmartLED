//
//  NSString+Rounding.h
//  GOpenSource_AppKit
//
//  Created by danly on 2017/2/9.
//  Copyright © 2017年 Gizwits. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NSString (Rounding)

/**
 获取给定浮点值取指定小数点后有效位数的值（四舍五入的方式）
 
 @param str 给定浮点值
 @param position 小数点后保留的有效位数
 @return 取指定有效位小数后的str值
 */
+ (NSString *)getFormateStr:(double)str afterPoint:(NSUInteger)position;

/**
 根据radio和addition获取有效小数位数
 计算方法：radio为小数时，以radio的小数位数为准, 如radio = 0.1， 返回1
 radio为整数时，以addition的小数位数为准 如radio = 1, addition = 0.01, 返回2
 
 @param radio 分辨率
 @param addition 增量值
 @return 最长的小数位位数
 */
+ (NSInteger)getDecimalPointLengthByRadio: (NSString *)radio andAddition: (NSString *)addition;

@end
