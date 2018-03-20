//
//  NSString+Mail.h
//  ZGMailbox
//
//  Created by zzg on 2018/1/15.
//  Copyright © 2018年 zzg. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Mail)

/**
 *  格式化size的展示字符（带两位小数）
 *
 *  @param size 大小
 *
 *  @return 格式化的字符串
 */
+ (NSString *)formatStringOfSize:(float)size;

@end
