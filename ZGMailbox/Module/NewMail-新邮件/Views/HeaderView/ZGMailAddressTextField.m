//
//  ZGMailAddressTextField.m
//  ZGMailbox
//
//  Created by zzg on 2017/4/21.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import "ZGMailAddressTextField.h"

@interface ZGMailAddressTextField ()

@property (nonatomic, strong) UIView *addressTextFieldMaskView;
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;

@end

@implementation ZGMailAddressTextField

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didRecognizeTapGesture:)];
        self.tapGesture.numberOfTapsRequired = 1;
        [self.addressTextFieldMaskView addGestureRecognizer:self.tapGesture];
    }
    
    return self;
}

- (void)deleteBackward {
    if ([self.addressTextFieldDelegate respondsToSelector:@selector(textFieldDidDelete)]){
        [self.addressTextFieldDelegate textFieldDidDelete];
    }
    [super deleteBackward];
}

- (void)dealloc {
    [self.addressTextFieldMaskView removeGestureRecognizer:self.tapGesture];
}

#pragma mark - IBAction

/**
 *  textField遮罩视图点击事件
 */
- (void)didRecognizeTapGesture:(UITapGestureRecognizer *)gesture  {
    if (self.addressTextFieldDelegate && [self.addressTextFieldDelegate respondsToSelector:@selector(mailAddressTextField:didRecognizeTapGesture:)]) {
        [self.addressTextFieldDelegate mailAddressTextField:self didRecognizeTapGesture:gesture];
    }
}

#pragma mark - public method 

- (void)showCursor {
    //显示光标
    self.tintColor = [UIColor colorWithHexString:@"007AFF" alpha:1.0f];
    if ([self.addressTextFieldMaskView isDescendantOfView:self]) {
        //移除遮罩视图
        [self.addressTextFieldMaskView removeFromSuperview];
    }
}

- (void)hideCuresor {
    //隐藏光标
    self.tintColor = [UIColor clearColor];
    [self addSubview:self.addressTextFieldMaskView];
    [self.addressTextFieldMaskView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(self);
        make.center.mas_equalTo(self);
    }];
}

#pragma mark - setter and getter

- (UIView *)addressTextFieldMaskView {
    if (_addressTextFieldMaskView == nil) {
        _addressTextFieldMaskView = [[UIView alloc] init];
        _addressTextFieldMaskView.backgroundColor = [UIColor clearColor];
    }
    
    return _addressTextFieldMaskView;
}

@end
