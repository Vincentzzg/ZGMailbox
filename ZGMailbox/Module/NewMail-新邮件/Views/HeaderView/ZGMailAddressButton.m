//
//  ZGMailAddressButton.m
//  ZGMailbox
//
//  Created by zzg on 2017/4/21.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import "ZGMailAddressButton.h"

//地址
#import <MailCore/MCOAddress.h>

@interface ZGMailAddressButton ()


@end

@implementation ZGMailAddressButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.titleLabel.font = [UIFont systemFontOfSize:17.0f];
        [self setTitleColor:[UIColor colorWithHexString:@"2A83f2" alpha:1.0f] forState:UIControlStateNormal];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        
        UIImage *image = [UIImage imageNamed:@"addressSelectCorrect"];
        image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)];
        [self setBackgroundImage:image forState:UIControlStateSelected];

        [self addSubview:self.commaLabel];
        [self.commaLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(self.titleLabel);
            make.centerY.mas_equalTo(self.titleLabel);
            make.leading.mas_equalTo(self.titleLabel.mas_trailing);
        }];
        UIEdgeInsets insets = self.contentEdgeInsets;
        insets.top = 0;
        insets.bottom = 0;
        insets.left = 2;
        insets.right = 2;
//        self.contentEdgeInsets = insets;
    }
    
    return self;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    
//    self.commaLabel.hidden = selected;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
//    [self setTitle:self.record.commonName forState:UIControlStateNormal];
}

#pragma mark - public method

- (void)showCommaLabel {
    self.commaLabel.hidden = NO;
}

- (void)hideCommaLabel {
    self.commaLabel.hidden = YES;
}

#pragma mark - setter and getter 

- (UILabel *)commaLabel {
    if (_commaLabel == nil) {
        _commaLabel = [[UILabel alloc] init];
        _commaLabel.textColor = [UIColor colorWithHexString:@"2A83f2" alpha:1.0f];
        _commaLabel.font = [UIFont systemFontOfSize:17.0f];
        _commaLabel.text = @"、";
    }
    
    return _commaLabel;
}

@end
