//
//  ZGWriteMailImageAttachmentCollectionViewCell.m
//  ZGMailbox
//
//  Created by zzg on 2017/4/26.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import "ZGWriteMailImageAttachmentCollectionViewCell.h"

#import "ZGMailModule.h"

//分类
#import "NSString+Mail.h"

@interface ZGWriteMailImageAttachmentCollectionViewCell ()

@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UIImageView *maskImageView;
@property (nonatomic, strong) UILabel *attachmentSizeLabel;

@end

@implementation ZGWriteMailImageAttachmentCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self.contentView addSubview:self.attachmentPreviewImageView];
        [self.contentView addSubview:self.maskImageView];
        [self.contentView addSubview:self.deleteButton];
        [self.contentView addSubview:self.attachmentSizeLabel];
        
        [self layoutViewSubviews];
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.attachmentSizeLabel.text = [NSString formatStringOfSize:self.imageData.length];
    self.deleteButton.tag = self.indexPath.row;
}

#pragma mark - IBAction

- (IBAction)deleteButtonPressed:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(writeMailImageAttachmentCollectionViewCell:deleteButtonPressed:)]) {
        [self.delegate writeMailImageAttachmentCollectionViewCell:self deleteButtonPressed:sender];
    }
}

#pragma mark - private method

- (void)layoutViewSubviews {
    [self.attachmentPreviewImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(self.contentView);
        make.center.mas_equalTo(self.contentView);
    }];
    
    [self.maskImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(self.contentView);
        make.center.mas_equalTo(self.contentView);
    }];
    
    [self.deleteButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.contentView);
        make.top.mas_equalTo(self.contentView);
    }];
    
    [self.attachmentSizeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.contentView.mas_leading).offset(5);
        make.bottom.mas_equalTo(self.contentView.mas_bottom).offset(-4);
    }];
}

#pragma mark - setter and getter

- (UIImageView *)attachmentPreviewImageView {
    if (_attachmentPreviewImageView == nil) {
        _attachmentPreviewImageView = [[UIImageView alloc] init];
        _attachmentPreviewImageView.layer.cornerRadius = 4;
        _attachmentPreviewImageView.clipsToBounds = YES;
    }
    
    return _attachmentPreviewImageView;
}

- (UIImageView *)maskImageView {
    if (_maskImageView == nil) {
        _maskImageView = [[UIImageView alloc] init];
        UIImage *image = [UIImage imageNamed:@"attach_mask"];
        image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(4, 4, 60, 4)];
        _maskImageView.image = image;
    }
    
    return _maskImageView;
}

- (UIButton *)deleteButton {
    if (_deleteButton == nil) {
        _deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_deleteButton setBackgroundImage:[UIImage imageNamed:@"attach_delete"] forState:UIControlStateNormal];
        [_deleteButton setBackgroundImage:[UIImage imageNamed:@"attach_delete_presses"] forState:UIControlStateSelected];
        [_deleteButton addTarget:self action:@selector(deleteButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _deleteButton;
}

- (UILabel *)attachmentSizeLabel {
    if (_attachmentSizeLabel == nil) {
        _attachmentSizeLabel = [[UILabel alloc] init];
        _attachmentSizeLabel.font = [UIFont systemFontOfSize:12.0f];
        _attachmentSizeLabel.textColor = [UIColor whiteColor];
    }
    
    return _attachmentSizeLabel;
}

@end
