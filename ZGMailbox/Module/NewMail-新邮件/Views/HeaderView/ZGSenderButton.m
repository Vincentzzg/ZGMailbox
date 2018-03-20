//
//  ZGSenderButton.m
//  ZGMailbox
//
//  Created by zzg on 2017/4/19.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import "ZGSenderButton.h"

@interface ZGSenderButton ()

@property (nonatomic, strong) UIView *separatorView;

@end

@implementation ZGSenderButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.separatorView];
        
        //设置设备上显示1个像素的线
        float floatsortaPixel = 1.0 / [UIScreen mainScreen].scale;
        [self.separatorView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.mas_equalTo(self.mas_bottom).offset(-floatsortaPixel);
            make.height.mas_equalTo(floatsortaPixel);
            make.leading.mas_equalTo(self.mas_leading).offset(15);
            make.trailing.mas_equalTo(self);
        }];
    }
    
    return self;
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect {
    contentRect.origin.x = 15;
    
    return contentRect;
}

#pragma mark - setter and getter 

- (UIView *)separatorView {
    if (_separatorView == nil) {
        _separatorView = [[UIView alloc] init];
        _separatorView.backgroundColor = [UIColor colorWithHexString:@"c8c8c8" alpha:1.0f];
    }
    
    return _separatorView;
}

@end
