//
//  ZGAddAttachmentCollectionViewCell.m
//  ZGMailbox
//
//  Created by zzg on 2017/4/26.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import "ZGAddAttachmentCollectionViewCell.h"

@interface ZGAddAttachmentCollectionViewCell ()

@property (nonatomic, strong) UIImageView *addImageView;

@end

@implementation ZGAddAttachmentCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self.contentView addSubview:self.backgroudImageView];
        [self.contentView addSubview:self.addImageView];
        
        [self layoutViewSubviews];
    }
    
    return self;
}

#pragma mark - private method

- (void)layoutViewSubviews {
    [self.backgroudImageView mas_makeConstraints:^(MASConstraintMaker *make) {
       make.size.mas_equalTo(self.contentView);
       make.center.mas_equalTo(self.contentView);
    }];
    
    [self.addImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self.contentView);
    }];
}

#pragma mark - setter and getter

- (UIImageView *)backgroudImageView {
    if (_backgroudImageView == nil) {
        _backgroudImageView = [[UIImageView alloc] init];
        UIImage *image = [UIImage imageNamed:@"attachment_bg"];
        image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(4, 4, 4, 4)];
        [_backgroudImageView setImage:image];
    }
    
    return _backgroudImageView;
}

- (UIImageView *)addImageView {
    if (_addImageView == nil) {
        _addImageView = [[UIImageView alloc] init];
        _addImageView.image = [UIImage imageNamed:@"attach_add"];
    }
    
    return _addImageView;
}

@end
