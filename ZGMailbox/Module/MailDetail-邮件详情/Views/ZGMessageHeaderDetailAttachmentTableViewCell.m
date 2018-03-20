//
//  ZGMessageHeaderDetailAttachmentTableViewCell.m
//  ZGMailbox
//
//  Created by zzg on 2017/4/10.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import "ZGMessageHeaderDetailAttachmentTableViewCell.h"

#import "ZGAddressShadowButton.h"

#import <MailCore/MCOAddress.h>
#import <MailCore/MCOIMAPPart.h>

@interface ZGMessageHeaderDetailAttachmentTableViewCell ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) ZGAddressShadowButton *addressButton;

@end

@implementation ZGMessageHeaderDetailAttachmentTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self.contentView addSubview:self.titleLabel];
        [self.contentView addSubview:self.addressButton];
        
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
    if ([self.attachments count] > 1) {
        [self.addressButton setTitle:[NSString stringWithFormat:@"%lu", (unsigned long)self.attachments.count] forState:UIControlStateNormal];
    } else {
        MCOIMAPPart *part = [self.attachments firstObject];
        [self.addressButton setTitle:part.filename forState:UIControlStateNormal];
    }
}

#pragma mark - IBAction

- (IBAction)addressButtonPressed:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(headerDetailAttachmentCell:attacmentButtonPressed:)]) {
        [self.delegate headerDetailAttachmentCell:self attacmentButtonPressed:sender];
    }
}

#pragma mark - private method

- (void)layoutCellSubviews {
    [self.addressButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.contentView.mas_leading).offset(62);
        make.centerY.mas_equalTo(self.contentView);
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.mas_equalTo(self.addressButton.mas_leading);
        make.centerY.mas_equalTo(self.addressButton);
    }];
}

#pragma mark - setter and getter

- (UILabel *)titleLabel {
    if (_titleLabel == nil) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:12.0f];
        _titleLabel.textColor = [UIColor colorWithHexString:@"999999" alpha:1.0f];
        _titleLabel.text = @"附件：";
    }
    
    return _titleLabel;
}

- (ZGAddressShadowButton *)addressButton {
    if (_addressButton == nil) {
        _addressButton = [ZGAddressShadowButton buttonWithType:UIButtonTypeCustom];
        [_addressButton setTitleColor:[UIColor colorWithHexString:@"999999" alpha:1.0f] forState:UIControlStateNormal];
        _addressButton.titleLabel.font = [UIFont systemFontOfSize:12.0f];
        [_addressButton addTarget:self action:@selector(addressButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [_addressButton setImage:[UIImage imageNamed:@"icon_status_attach"] forState:UIControlStateNormal];
    }
    
    return _addressButton;
}

@end
