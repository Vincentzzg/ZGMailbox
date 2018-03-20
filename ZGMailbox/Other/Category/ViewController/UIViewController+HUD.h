//
//  UIViewController+HUD.h
//  ZGMailbox
//
//  Created by zzg on 16/8/16.
//  Copyright © 2016年 zzg. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (HUD)

////////////////////**********loading**********//////////////////////

/**
 *  展示没有文字的loading视图
 *
 *  @param cover 是否要覆盖navbar
 */
- (void)showHUDCoverNavbar:(BOOL)cover;

/**
 *  展示有文字的loading视图
 *
 *  @param cover       是否要覆盖navbar
 *  @param loadingText 文字
 */
- (void)showHUDCoverNavbar:(BOOL)cover loadingText:(NSString *)loadingText;

////////////////////**********提示文字**********//////////////////////

/**
 *  展示提示文字
 *
 *  @param tipText 提示文字
 */
- (void)showTipText:(NSString *)tipText;

/**
 *  展示提示文字
 *
 *  @param tipText      提示文字
 *  @param completion   隐藏之后需要执行的block
 */
- (void)showTipText:(NSString *)tipText completion:(void (^)(void))completion;


////////////////////**********成功提示**********//////////////////////

/**
 *  带成功图标的提示
 *
 *  @param successTipText 提示文字
 */
- (void)showSuccessTipText:(NSString *)successTipText;

/**
 *  带成功图标的提示
 *
 *  @param successTipText   提示文字
 *  @param completion       隐藏之后需要执行的block
 */
- (void)showSuccessTipText:(NSString *)successTipText completion:(void (^)(void))completion;


////////////////////**********隐藏**********//////////////////////

/**
 *  隐藏loading视图
 *
 */
- (void)hideHUD;


@end
