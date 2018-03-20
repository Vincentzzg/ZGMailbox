//
//  ZGAttachmentDownloadView.m
//  ZGMailbox
//
//  Created by zzg on 2017/4/13.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import "ZGAttachmentDownloadView.h"

#import "ZGMailModule.h"

@interface ZGAttachmentDownloadView ()

@property (nonatomic, strong) UIImageView *fileIconImageView;

@end

@implementation ZGAttachmentDownloadView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.fileIconImageView];
        [self addSubview:self.fileNameLabel];
        [self addSubview:self.progressView];
        [self addSubview:self.progressLabel];
        
        [self layoutViewSubview];
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    NSString *imageName = [[ZGMailModule sharedInstance] imageNameWithFileName:self.filename imageSizeType:ImageSizeTypeLarge];
    self.fileIconImageView.image = [UIImage imageNamed:imageName];
}

#pragma mark - private method 

- (void)layoutViewSubview {
    [self.fileIconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self);
        make.bottom.mas_equalTo(self.fileNameLabel.mas_top).offset(-20);
    }];
    
    [self.fileNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self);
        make.bottom.mas_equalTo(self.mas_centerY).offset(-10);
    }];
    
    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self);
        make.top.mas_equalTo(self.mas_centerY).offset(25);
        make.width.mas_equalTo(self.mas_width).offset(-130);
    }];
    
    [self.progressLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self);
        make.top.mas_equalTo(self.progressView.mas_bottom).offset(10);
    }];
}

#pragma mark - setter and getter

- (UIImageView *)fileIconImageView {
    if (_fileIconImageView == nil) {
        _fileIconImageView = [[UIImageView alloc] init];
    }
    
    return _fileIconImageView;
}

- (UILabel *)fileNameLabel {
    if (_fileNameLabel == nil) {
        _fileNameLabel = [[UILabel alloc] init];
        _fileNameLabel.font = [UIFont boldSystemFontOfSize:15.0f];
        _fileNameLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    }
    
    return _fileNameLabel;
}

- (UIProgressView *)progressView {
    if (_progressView == nil) {
        _progressView = [[UIProgressView alloc] init];
        _progressView.progressTintColor = [UIColor colorWithRed:196/255.0f green:38/255.0f blue:29/255.0f alpha:0.8f];
        _progressView.trackTintColor = [UIColor colorWithHexString:@"CAC9CE" alpha:1.0f];
//        _progressView.progressImage = [UIImage imageNamed:@"searchBarBg"];
    }
    
    return _progressView;
}

- (UILabel *)progressLabel {
    if (_progressLabel == nil) {
        _progressLabel = [[UILabel alloc] init];
        _progressLabel.font = [UIFont systemFontOfSize:14.0f];
//        _progressLabel.textColor = [UIColor colorWithHexString:@"666666" alpha:1.0f];
    }
    
    return _progressLabel;
}

@end
