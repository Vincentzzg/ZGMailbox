//
//  ZGSendMailTopIndicator.h
//  ZGMailbox
//
//  Created by zzg on 2017/5/10.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZGSendMailTopIndicator : UIWindow

/**
 *  展示
 */
- (void)show;

/**
 *  是否正在展示
 */
- (BOOL)isPresenting;

/**
 *  隐藏
 */
- (void)hide;

- (void)setProgress:(float)progress;

- (void)setProgressLabel:(NSString *)str;

- (void)showSuccessView;

- (void)showSuccessViewWithTotalCount:(NSUInteger)count;

- (void)showFailureView;

@end
