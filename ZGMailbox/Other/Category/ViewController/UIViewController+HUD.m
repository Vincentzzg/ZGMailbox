//
//  UIViewController+HUD.m
//  ZGMailbox
//
//  Created by zzg on 16/8/16.
//  Copyright © 2016年 zzg. All rights reserved.
//

#import "UIViewController+HUD.h"

#import <MBProgressHUD/MBProgressHUD.h>

static float const HUDTipShowTime = 1.6f;

@implementation UIViewController (HUD)

/**
 *  展示没有文字的loading视图
 *
 *  @param cover  loading视图是否覆盖导航栏
 */
- (void)showHUDCoverNavbar:(BOOL)cover {
    if (cover && self.navigationController) {
        if (![MBProgressHUD HUDForView:self.navigationController.view]) {//还没有hud展示在self.navigationController.view上
            [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
        }
    } else {
        if (![MBProgressHUD HUDForView:self.view]) {//还没有hud展示在self.view上
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        }
    }
}

/**
 *  展示有文字的loading视图
 *
 *  @param cover       是否要覆盖navbar
 *  @param loadingText 文字
 */
- (void)showHUDCoverNavbar:(BOOL)cover loadingText:(NSString *)loadingText {
    MBProgressHUD *hud;
    if (cover) {
        hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    } else {
        hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }
    // Set the label text.
    hud.label.text = loadingText;
    // You can also adjust other label properties if needed.
    // hud.label.font = [UIFont italicSystemFontOfSize:16.f];
}

/**
 *  隐藏loading视图
 *
 */
- (void)hideHUD {
    if ([MBProgressHUD HUDForView:self.navigationController.view]) {
        [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
    } else {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    }
}

/**
 *  展示提示文字
 *
 *  @param tipText 提示文字
 */
- (void)showTipText:(NSString *)tipText {
    MBProgressHUD *hud = [self hudOfViewController];
    
    // Set the annular determinate mode to show task progress.
    hud.mode = MBProgressHUDModeText;
    hud.label.text = tipText;
    
//    hud.detailsLabel.text = tipText;//字体12 太小
    
    // Move to bottm center.
//    hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
    
    [hud hideAnimated:YES afterDelay:HUDTipShowTime];
}

/**
 *  展示提示文字
 *
 *  @param tipText 提示文字
 */
- (void)showTipText:(NSString *)tipText completion:(void (^ __nullable)(void))completion {
    MBProgressHUD *hud = [self hudOfViewController];
    
    // Set the annular determinate mode to show task progress.
    hud.mode = MBProgressHUDModeText;
    hud.label.text = tipText;
    // Move to bottm center.
//    hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
    
    //    [hud hideAnimated:YES afterDelay:3.f];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(HUDTipShowTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [hud hideAnimated:YES];
        if (completion) {
            completion();
        }
    });
}

/**
 *  带成功图标的提示
 *
 *  @param successTipText 提示文字
 */
- (void)showSuccessTipText:(NSString *)successTipText {
    MBProgressHUD *hud = [self hudOfViewController];
    
    UIImage *image = [[UIImage imageNamed:@"Checkmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    hud.customView = imageView;
    hud.mode = MBProgressHUDModeCustomView;
    hud.label.text = successTipText;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(HUDTipShowTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [hud hideAnimated:YES];
    });
}

/**
 *  带成功图标的提示
 *
 *  @param successTipText 提示文字
 *  @param completion   隐藏之后需要执行的block
 */
- (void)showSuccessTipText:(NSString *)successTipText completion:(void (^ __nullable)(void))completion {
    MBProgressHUD *hud = [self hudOfViewController];
    
    UIImage *image = [[UIImage imageNamed:@"Checkmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    hud.customView = imageView;
    hud.mode = MBProgressHUDModeCustomView;
    hud.label.text = successTipText;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(HUDTipShowTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [hud hideAnimated:YES];
        if (completion) {
            completion();
        }
    });
}

#pragma mark - private method

/**
 *  ViewController的hud，已有就直接取，没有就创建
 *
 *  @return hud对象
 */
- (MBProgressHUD *)hudOfViewController {
    MBProgressHUD *hud;
    if ([MBProgressHUD HUDForView:self.navigationController.view]) {//已有hud展示在self.navigationController.view上
        hud = [MBProgressHUD HUDForView:self.navigationController.view];
    } else if ([MBProgressHUD HUDForView:self.view]) {//已有hud展示在self.view上
        hud = [MBProgressHUD HUDForView:self.view];
    } else if (self.navigationController.view) {//有navigationController的页面
        hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    } else {
        hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }
    
    return hud;
}

@end
