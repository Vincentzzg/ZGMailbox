//
//  NSString+Mail.m
//  ZGMailbox
//
//  Created by zzg on 2018/1/15.
//  Copyright © 2018年 zzg. All rights reserved.
//

#import "NSString+Mail.h"

@implementation NSString (Mail)

/**
 *  格式化size的展示字符
 *
 *  @param size
 *
 *  @return
 */
+ (NSString *)formatStringOfSize:(float)size {
    NSString *strOfNetworkFlow = @"";
    NSString *strOfUnit = @"";
    
    if (size / 1024 >= 1000) {//M
        strOfNetworkFlow = [NSString stringWithFormat:@"%.2f", size / (1024.0 * 1024.0)];
        strOfUnit = @"M";
    } else {//K
        strOfNetworkFlow = [NSString stringWithFormat:@"%.2f", size / 1024.0f];
        strOfUnit = @"K";
    }
    
    return [strOfNetworkFlow stringByAppendingString:strOfUnit];
}

@end
