//
//  ZGMailListCellPortraitView.m
//  ZGMailbox
//
//  Created by zzg on 2017/3/23.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import "ZGMailListCellPortraitView.h"

@interface ZGMailListCellPortraitView ()

@end

@implementation ZGMailListCellPortraitView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.myLabel];
        [self addSubview:self.imageView];
        
        [self layoutViewSubViews];
    }
    
    return self;
}

#pragma mark - private method

- (void)layoutViewSubViews {
    [self.myLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self);
        make.size.mas_equalTo(self);
    }];
    
    [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(self);
        make.center.mas_equalTo(self);
    }];
}

#pragma mark - setter and getter 

- (UILabel *)myLabel {
    if (_myLabel == nil) {
        _myLabel = [[UILabel alloc] init];
        _myLabel.font = [UIFont systemFontOfSize:22.0f];
        _myLabel.textAlignment = NSTextAlignmentCenter;
    }
    
    return _myLabel;
}

- (UIImageView *)imageView {
    if (_imageView == nil) {
        _imageView = [[UIImageView alloc] init];
    }
    return _imageView;
}

@end
