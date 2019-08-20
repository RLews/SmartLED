//
//  NSString+HexToBytes.h
//  GOpenSource_AppKit
//
//  Created by danly on 2017/2/17.
//  Copyright © 2017年 Gizwits. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (HexToBytes)

/**
 将当前字符串等值转换为二进制值 如：str = "ff11"; 二进制值：data = <ff11>
 
 @return 二进制值
 */
- (NSData *)hexToBytes;

/**
 将二进制值等比转换为字符串， 如二进制data = <ff11>, 则str = "ff11";
 
 @param data 给定的二进制
 @return 返回相应字符串
 */
+ (NSString *)hexStrByData:(NSData *)data;

@end
