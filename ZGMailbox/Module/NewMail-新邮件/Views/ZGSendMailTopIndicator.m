//
//  ZGSendMailTopIndicator.m
//  ZGMailbox
//
//  Created by zzg on 2017/5/10.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import "ZGSendMailTopIndicator.h"
#import "ZGSendingMailListViewController.h"//发件箱页面

#import "AppDelegate.h"

#import <AudioToolbox/AudioToolbox.h>


@interface ZGSendMailTopIndicator ()

@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIImageView *sendingImageView;
@property (nonatomic, strong) UILabel *sendingProgressLabel;
@property (nonatomic, strong) UIProgressView *progressView;

@property (nonatomic, strong) UIImageView *successImageView;//成功图标
@property (nonatomic, strong) UIImageView *failureImageView;//失败图标
@property (nonatomic, strong) UILabel *tipLabel;//提示

@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;//触摸手势

@end

@implementation ZGSendMailTopIndicator

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.windowLevel = 1001;
        [self makeKeyAndVisible];
        [self resignKeyWindow];
        self.hidden = YES;
        
        [self addSubview:self.backgroundView];
        [self.backgroundView addSubview:self.sendingImageView];
        [self.backgroundView addSubview:self.sendingProgressLabel];
        [self.backgroundView addSubview:self.progressView];
        
        [self.backgroundView addSubview:self.successImageView];
        [self.backgroundView addSubview:self.failureImageView];
        [self.backgroundView addSubview:self.tipLabel];

        self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didRecognizeTapGesture:)];
        self.tapGesture.numberOfTapsRequired = 1;
        [self.backgroundView addGestureRecognizer:self.tapGesture];

        [self layoutPageSubviews];
    }
    
    return self;
}

#pragma mark - override

//不接收手势事件，事件穿透当前视图
//Hit-Test探测器
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    
    // If the hitView is THIS view, return nil and allow hitTest:withEvent: to continue traversing the hierarchy to find the underlying view.
    if (hitView == self) {
        return nil;
    }
    
    return hitView;
}

#pragma mark - public method

/**
 *  展示
 */
- (void)show {
    self.hidden = NO;
}

/**
 *  是否正在展示
 *
 *  @return
 */
- (BOOL)isPresenting {
    return !self.hidden;
}

/**
 *  隐藏
 */
- (void)hide {
    [UIView animateWithDuration:0.25 animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        self.hidden = YES;
        self.alpha = 1;
        
        //状态还原
        self.progressView.hidden = NO;
        [self.progressView setProgress:0];
        self.sendingImageView.hidden = NO;
        
        self.successImageView.hidden = YES;
        self.failureImageView.hidden = YES;
        self.tipLabel.text = @"";
    }];
}

- (void)setProgress:(float)progress {
    [self.progressView setProgress:progress];
}

- (void)setProgressLabel:(NSString *)str {
    self.sendingProgressLabel.text = str;
}

- (void)showSuccessView {
    self.successImageView.hidden = NO;
    self.failureImageView.hidden = YES;
    self.tipLabel.text = @"邮件发送成功";
    self.sendingProgressLabel.text = @"";
    
    self.progressView.hidden = YES;
    self.sendingImageView.hidden = YES;
    
    //震动、声音
    [self promptTone];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self hide];
    });
}

- (void)showSuccessViewWithTotalCount:(NSUInteger)count {
    self.successImageView.hidden = NO;
    self.failureImageView.hidden = YES;
    self.tipLabel.text = [NSString stringWithFormat:@"%lu封邮件发送成功", (unsigned long)count];
    self.sendingProgressLabel.text = @"";
    
    self.progressView.hidden = YES;
    self.sendingImageView.hidden = YES;
    
    //震动、声音
    [self promptTone];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self hide];
    });
}

- (void)showFailureView {
    if (self.isPresenting) {//展示失败视图的前提是正在展示发送视图（当前页面不是发件箱）
        self.successImageView.hidden = YES;
        self.failureImageView.hidden = NO;
        self.tipLabel.text = @"邮件发送失败";
        
        self.progressView.hidden = YES;
        self.sendingImageView.hidden = YES;
        
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [self hide];
//        });
    }
}

#pragma mark - private method

- (void)layoutPageSubviews {
    [self.backgroundView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self);
        make.trailing.mas_equalTo(self);
        make.size.mas_equalTo(CGSizeMake(130, 20));
    }];
    
    [self.tipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.mas_equalTo(self.backgroundView.mas_trailing).offset(-5);
        make.centerY.mas_equalTo(self.backgroundView);
    }];
    
    [self.successImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.mas_equalTo(self.tipLabel.mas_leading).offset(-3);
        make.centerY.mas_equalTo(self.backgroundView);
    }];
    
    [self.failureImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.mas_equalTo(self.tipLabel.mas_leading).offset(-1);
        make.centerY.mas_equalTo(self.backgroundView);
    }];
    
    [self.sendingImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.mas_equalTo(self.sendingProgressLabel.mas_leading).offset(-3);
        make.centerY.mas_equalTo(self.backgroundView);
    }];
    
    [self.sendingProgressLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.mas_equalTo(self.progressView.mas_leading).offset(-2);
        make.centerY.mas_equalTo(self.backgroundView);
    }];
    
    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.mas_equalTo(self.backgroundView.mas_trailing).offset(-5);
        make.centerY.mas_equalTo(self.backgroundView);
        make.size.mas_equalTo(CGSizeMake(60, 4));
    }];
}

- (void)promptTone {
    AudioServicesPlaySystemSound((UInt32)1001);
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);//震动
}

/**
 *  单击事件
 */
- (void)didRecognizeTapGesture:(UITapGestureRecognizer *)gesture {
    if (self.isPresenting) {
        dispatch_async(dispatch_get_main_queue(), ^{
//            AppDelegate *del = (AppDelegate *)[UIApplication sharedApplication].delegate;
            UITabBarController *tabBarcontroller = (UITabBarController *)[[UIApplication sharedApplication].delegate window].rootViewController;
            UINavigationController *naVC = tabBarcontroller.selectedViewController;
            UIViewController *visibleVC = naVC.visibleViewController;
            if (visibleVC.presentingViewController){
                //顶部视图是模态视图，不跳转发件箱
            } else {
                ZGSendingMailListViewController *sendingMailListVC = [[ZGSendingMailListViewController alloc] init];
                sendingMailListVC.hidesBottomBarWhenPushed = YES;
                [naVC pushViewController:sendingMailListVC animated:YES];
            }
        });
    }
}

#pragma mark - setter and getter

- (UIView *)backgroundView {
    if (_backgroundView == nil) {
        _backgroundView = [[UIView alloc] init];
        _backgroundView.backgroundColor = [UIColor colorWithRed:196/255.0f green:38/255.0f blue:29/255.0f alpha:1.0f];
    }
    
    return _backgroundView;
}

- (UIImageView *)sendingImageView {
    if (_sendingImageView == nil) {
        _sendingImageView = [[UIImageView alloc] init];
        _sendingImageView.image = [UIImage imageNamed:@"icon_statusbar_sending"];
    }
    
    return _sendingImageView;
}

- (UILabel *)sendingProgressLabel {
    if (_sendingProgressLabel == nil) {
        _sendingProgressLabel = [[UILabel alloc] init];
        _sendingProgressLabel.textColor = [UIColor whiteColor];
        _sendingProgressLabel.font = [UIFont systemFontOfSize:12];
    }
    
    return _sendingProgressLabel;
}

- (UIProgressView *)progressView {
    if (_progressView == nil) {
        _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        _progressView.progressTintColor = [UIColor whiteColor];
        _progressView.trackTintColor = [UIColor colorWithRed:196/255.0f green:38/255.0f blue:29/255.0f alpha:1.0f];
        _progressView.layer.borderColor = [UIColor whiteColor].CGColor;
        _progressView.layer.borderWidth = 0.5;
        _progressView.layer.cornerRadius = 2;
        _progressView.clipsToBounds = YES;
    }
    
    return _progressView;
}

- (UIImageView *)successImageView {
    if (_successImageView == nil) {
        _successImageView = [[UIImageView alloc] init];
        _successImageView.image = [UIImage imageNamed:@"icon_statusbar_successful"];
        _successImageView.hidden = YES;
    }
    
    return _successImageView;
}

- (UIImageView *)failureImageView {
    if (_failureImageView == nil) {
        _failureImageView = [[UIImageView alloc] init];
        _failureImageView.image = [UIImage imageNamed:@"icon_statusbar_failed"];
        _failureImageView.hidden = YES;
    }
    
    return _failureImageView;
}

- (UILabel *)tipLabel {
    if (_tipLabel == nil) {
        _tipLabel = [[UILabel alloc] init];
        _tipLabel.textColor = [UIColor whiteColor];
        _tipLabel.font = [UIFont systemFontOfSize:12];
    }
    
    return _tipLabel;
}

@end
