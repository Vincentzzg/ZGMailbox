//
//  ZGWriteMailFileAttachmentCollectionViewCell.m
//  ZGMailbox
//
//  Created by zzg on 2017/5/8.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import "ZGWriteMailFileAttachmentCollectionViewCell.h"

#import <MailCore/MCOIMAPPart.h>

#import "ZGMailModule.h"

//分类
#import "NSString+Mail.h"

@interface ZGWriteMailFileAttachmentCollectionViewCell ()

@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UIImageView *fileIconImageView;
@property (nonatomic, strong) UILabel *fileNameLabel;
@property (nonatomic, strong) UILabel *attachmentSizeLabel;

@end

@implementation ZGWriteMailFileAttachmentCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self.contentView addSubview:self.backgroudImageView];

        [self.contentView addSubview:self.deleteButton];
        [self.contentView addSubview:self.fileIconImageView];
        [self.contentView addSubview:self.fileNameLabel];
        [self.contentView addSubview:self.attachmentSizeLabel];
        
        [self layoutViewSubviews];
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    NSString *filename = [self.part filename];
    self.fileNameLabel.text = filename;
    self.attachmentSizeLabel.text = [NSString formatStringOfSize:self.part.size];
        
    NSString *imageName = [[ZGMailModule sharedInstance] imageNameWithFileName:filename imageSizeType:ImageSizeTypeLarge];
    self.fileIconImageView.image = [UIImage imageNamed:imageName];
}

#pragma mark - IBAction

- (IBAction)deleteButtonPressed:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(writeMailFileAttachmentCollectionViewCell:deleteButtonPressed:)]) {
        [self.delegate writeMailFileAttachmentCollectionViewCell:self deleteButtonPressed:sender];
    }
}

#pragma mark - private method

- (void)layoutViewSubviews {
    [self.backgroudImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(self.contentView);
        make.center.mas_equalTo(self.contentView);
    }];
    
    [self.deleteButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.contentView);
        make.top.mas_equalTo(self.contentView);
    }];
    
    [self.fileIconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(30, 30));
        make.centerX.mas_equalTo(self.contentView);
        make.bottom.mas_equalTo(self.fileNameLabel.mas_top).offset(-5);
    }];
    
    [self.fileNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.contentView);
        make.width.mas_equalTo(self.contentView).offset(-30);
        make.centerY.mas_equalTo(self.contentView.mas_centerY).offset(10);
    }];
    
    [self.attachmentSizeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.contentView);
        make.top.mas_equalTo(self.fileNameLabel.mas_bottom).offset(4);
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

- (UIButton *)deleteButton {
    if (_deleteButton == nil) {
        _deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_deleteButton setBackgroundImage:[UIImage imageNamed:@"attach_delete"] forState:UIControlStateNormal];
        [_deleteButton setBackgroundImage:[UIImage imageNamed:@"attach_delete_presses"] forState:UIControlStateSelected];
        [_deleteButton addTarget:self action:@selector(deleteButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _deleteButton;
}

- (UIImageView *)fileIconImageView {
    if (_fileIconImageView == nil) {
        _fileIconImageView = [[UIImageView alloc] init];
    }
    
    return _fileIconImageView;
}

- (UILabel *)fileNameLabel {
    if (_fileNameLabel == nil) {
        _fileNameLabel = [[UILabel alloc] init];
        _fileNameLabel.font = [UIFont systemFontOfSize:14.0f];
        _fileNameLabel.numberOfLines = 2;
        _fileNameLabel.textAlignment = NSTextAlignmentCenter;
    }
    
    return _fileNameLabel;
}

- (UILabel *)attachmentSizeLabel {
    if (_attachmentSizeLabel == nil) {
        _attachmentSizeLabel = [[UILabel alloc] init];
        _attachmentSizeLabel.font = [UIFont systemFontOfSize:12.0f];
        _attachmentSizeLabel.textColor = [UIColor lightGrayColor];
    }
    
    return _attachmentSizeLabel;
}

@end
