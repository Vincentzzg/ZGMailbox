//
//  ZGMailListTitleView.m
//  ZGMailbox
//
//  Created by zzg on 2017/3/23.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import "ZGMailListTitleView.h"

@interface ZGMailListTitleView ()

@property (nonatomic, strong) UIButton *myButton;
@property (nonatomic, strong) UIImageView *arrowImageView;

@end

@implementation ZGMailListTitleView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.titleLabel];
        [self addSubview:self.arrowImageView];
        [self addSubview:self.myButton];
        self.isArrowDown = NO;
        
        [self layoutViewSubviews];
    }
    
    return self;
}

#pragma mark - IBAction

- (IBAction)buttonPressed:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(mailListTitleViewPrssed:)]) {
        [self.delegate mailListTitleViewPrssed:self];
        self.isArrowDown = !self.isArrowDown;
        
//        if (self.isArrowDown) {
//            [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
//                self.arrowImageView.transform = CGAffineTransformMakeRotation(0 * (M_PI / 180.0f));
//            } completion:^(BOOL finished) {
//                self.isArrowDown = NO;
//            }];
//        } else {
//            [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
//                self.arrowImageView.transform = CGAffineTransformMakeRotation(180 * (M_PI / 180.0f));
//            } completion:^(BOOL finished) {
//                self.isArrowDown = YES;
//            }];
//        }
    }
}

#pragma mark - private method

- (void)layoutViewSubviews {
    [self.myButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(self);
        make.center.mas_equalTo(self);
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self);
    }];
    
    [self.arrowImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.titleLabel.mas_bottom).offset(0);
        make.centerX.mas_equalTo(self);
    }];
}

#pragma mark - setter and getter 

- (void)setIsArrowDown:(BOOL)isArrowDown {
    if (!isArrowDown) {
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            self.arrowImageView.transform = CGAffineTransformMakeRotation(0 * (M_PI / 180.0f));
        } completion:^(BOOL finished) {
        }];
    } else {
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            self.arrowImageView.transform = CGAffineTransformMakeRotation(180 * (M_PI / 180.0f));
        } completion:^(BOOL finished) {
        }];
    }
    
    _isArrowDown = isArrowDown;
}

- (UIButton *)myButton {
    if (_myButton == nil) {
        _myButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_myButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _myButton;
}

- (UILabel *)titleLabel {
    if (_titleLabel == nil) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = [UIColor blackColor];
        _titleLabel.font = [UIFont boldSystemFontOfSize:18.0f];
    }
    
    return _titleLabel;
}

- (UIImageView *)arrowImageView {
    if (_arrowImageView == nil) {
        _arrowImageView = [[UIImageView alloc] init];
        _arrowImageView.image = [UIImage imageNamed:@"icon_nav_arrow_down"];
        _arrowImageView.tintColor = [UIColor whiteColor];
    }
    
    return _arrowImageView;
}

@end
