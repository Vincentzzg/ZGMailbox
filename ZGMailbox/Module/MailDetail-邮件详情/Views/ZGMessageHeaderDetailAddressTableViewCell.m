//
//  ZGMessageHeaderDetailAddressTableViewCell.m
//  ZGMailbox
//
//  Created by zzg on 2017/4/10.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import "ZGMessageHeaderDetailAddressTableViewCell.h"

#import "ZGAddressShadowButton.h"

#import <MailCore/MCOAddress.h>

@interface ZGMessageHeaderDetailAddressTableViewCell ()

@property (nonatomic, strong) ZGAddressShadowButton *addressButton;

@end

@implementation ZGMessageHeaderDetailAddressTableViewCell

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
    [self.addressButton setAttributedTitle:[self attributedStringAddresWithAddress:self.address] forState:UIControlStateNormal];
    NSString *mailbox = self.address.mailbox;
    mailbox = [mailbox stringByReplacingOccurrencesOfString:@"%" withString:@"/"];
    self.addressButton.mailbox = mailbox;
}

#pragma mark - IBAction

- (IBAction)addressButtonPressed:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(headerDetailAddressCell:addressButtonPressed:)]) {
        [self.delegate headerDetailAddressCell:self addressButtonPressed:sender];
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
        make.top.mas_equalTo(self.contentView.mas_top).offset(6);
    }];
}

- (NSMutableAttributedString *)attributedStringAddresWithAddress:(MCOAddress *)address {
    NSMutableAttributedString *addressStr = [[NSMutableAttributedString alloc] init];
    NSString *name = [address displayName];
    NSString *mailbox = [address mailbox];
    mailbox = [mailbox stringByReplacingOccurrencesOfString:@"%" withString:@"/"];
    if (IsEmptyString(name)) {
        NSArray *array = [mailbox componentsSeparatedByString:@"@"];
        name = [array firstObject];
    } else {
        //都有值，不需要处理
        name = [mailbox stringByReplacingOccurrencesOfString:@"%" withString:@"/"];
    }
    
    NSAttributedString *attStr = [[NSAttributedString alloc] initWithString:name attributes:@{NSForegroundColorAttributeName : [UIColor blackColor]}];
    NSAttributedString *attMailbox = [[NSAttributedString alloc] initWithString:mailbox attributes:@{NSForegroundColorAttributeName : [UIColor colorWithHexString:@"999999" alpha:1.0f]}];
    [addressStr appendAttributedString:attStr];
    [addressStr appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
    [addressStr appendAttributedString:attMailbox];
    
    [addressStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:12.0f] range:NSMakeRange(0, addressStr.length)];
    
    return addressStr;
}

#pragma mark - setter and getter 

- (UILabel *)titleLabel {
    if (_titleLabel == nil) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:12.0f];
        _titleLabel.textColor = [UIColor colorWithHexString:@"999999" alpha:1.0f];
    }
    
    return _titleLabel;
}

- (ZGAddressShadowButton *)addressButton {
    if (_addressButton == nil) {
        _addressButton = [ZGAddressShadowButton buttonWithType:UIButtonTypeCustom];
        [_addressButton addTarget:self action:@selector(addressButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _addressButton;
}

@end
