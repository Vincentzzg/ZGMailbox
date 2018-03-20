//
//  ZGAttachmentTableViewCell.m
//  ZGMailbox
//
//  Created by zzg on 2017/4/13.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import "ZGAttachmentTableViewCell.h"

#import <MailCore/MCOIMAPPart.h>

#import "ZGMailModule.h"

//分类
#import "NSString+Mail.h"

@interface ZGAttachmentTableViewCell ()

@property (nonatomic, strong) UIImageView *fileIconImageView;
@property (nonatomic, strong) UILabel *filenameLabel;
@property (nonatomic, strong) UILabel *sizeLabel;

@end

@implementation ZGAttachmentTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self.contentView addSubview:self.fileIconImageView];
        [self.contentView addSubview:self.filenameLabel];
        [self.contentView addSubview:self.sizeLabel];
        
        [self layoutCellSubviews];
    }
    
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    NSString *filename = [self.part filename];
    self.filenameLabel.text = filename;
    self.sizeLabel.text = [NSString formatStringOfSize:self.part.size];
    
    NSString *imageName = [[ZGMailModule sharedInstance] imageNameWithFileName:filename imageSizeType:ImageSizeTypeSmall];
    self.fileIconImageView.image = [UIImage imageNamed:imageName];
}

#pragma mark - private method

- (void)layoutCellSubviews {
    [self.fileIconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.contentView.mas_leading).offset(10);
        make.centerY.mas_equalTo(self.contentView);
        make.size.mas_equalTo(CGSizeMake(51, 51));
    }];
    
    [self.filenameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.fileIconImageView.mas_trailing).offset(14);
        make.trailing.mas_equalTo(self.contentView.mas_trailing);
        make.top.mas_equalTo(self.contentView.mas_top).offset(14);
    }];
    
    [self.sizeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.fileIconImageView.mas_trailing).offset(14);
        make.top.mas_equalTo(self.filenameLabel.mas_bottom).offset(4);
    }];
}

#pragma mark - setter and getter

- (UIImageView *)fileIconImageView {
    if (_fileIconImageView == nil) {
        _fileIconImageView = [[UIImageView alloc] init];
//        _fileIconImageView.image = [UIImage imageNamed:@"filetype_pdf_51h"];
    }
    
    return _fileIconImageView;
}

- (UILabel *)filenameLabel {
    if (_filenameLabel == nil) {
        _filenameLabel = [[UILabel alloc] init];
        _filenameLabel.font = [UIFont boldSystemFontOfSize:15.0f];
        _filenameLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    }
    
    return _filenameLabel;
}

- (UILabel *)sizeLabel {
    if (_sizeLabel == nil) {
        _sizeLabel = [[UILabel alloc] init];
        _sizeLabel.textColor = [UIColor colorWithHexString:@"666666" alpha:1.0f];
        _sizeLabel.font = [UIFont systemFontOfSize:10.0f];
    }
    
    return _sizeLabel;
}

@end
