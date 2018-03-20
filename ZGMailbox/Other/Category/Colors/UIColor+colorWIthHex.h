//
//  UIColor+colorWIthHex.h
//  CBExchange
//
//  Created by 周中广 on 15/10/21.
//  Copyright © 2015年 周中广. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  color生成器
 */
@interface UIColor (colorWIthHex)

/**
 *  创建一个颜色
 *
 *  @param color color的16进制字符串值
 *  @param alpha 透明度
 *
 *  @return 根据color的16进制值创建的颜色
 */
+ (UIColor *)colorWithHexString:(NSString *)color alpha:(CGFloat)alpha;

@end
