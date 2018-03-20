//
//  ZGMailAddressButton.h
//  ZGMailbox
//
//  Created by zzg on 2017/4/21.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MCOAddress;

/**
 *  邮件地址按钮
 */
@interface ZGMailAddressButton : UIButton

@property (nonatomic, strong) MCOAddress *address;

@property (nonatomic, strong) UILabel *commaLabel;

/**
 *  显示顿号
 */
- (void)showCommaLabel;

/**
 *  隐藏顿号
 */
- (void)hideCommaLabel;

@end
