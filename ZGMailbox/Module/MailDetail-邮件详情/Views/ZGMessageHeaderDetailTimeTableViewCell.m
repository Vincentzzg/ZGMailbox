//
//  ZGMessageHeaderDetailTimeTableViewCell.m
//  ZGMailbox
//
//  Created by zzg on 2017/4/10.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import "ZGMessageHeaderDetailTimeTableViewCell.h"

@interface ZGMessageHeaderDetailTimeTableViewCell ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *timeLablel;

@end

@implementation ZGMessageHeaderDetailTimeTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self.contentView addSubview:self.titleLabel];
        [self.contentView addSubview:self.timeLablel];
        
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
    
    //创建一个时间格式化对象
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    //按照什么样的格式来格式化时间
    formatter.dateFormat = @"yyyy年M月d日 HH:mm";
    NSString *date = [formatter stringFromDate:self.date];
    self.timeLablel.text = date;
}

#pragma mark - private method

- (void)layoutCellSubviews {
    [self.timeLablel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.contentView.mas_leading).offset(65);
        make.centerY.mas_equalTo(self.contentView);
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.mas_equalTo(self.timeLablel.mas_leading).offset(-3);
        make.centerY.mas_equalTo(self.timeLablel);
    }];
}

#pragma mark - setter and getter 

- (UILabel *)titleLabel {
    if (_titleLabel == nil) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:12.0f];
        _titleLabel.textColor = [UIColor colorWithHexString:@"999999" alpha:1.0f];
        _titleLabel.text = @"时间：";
    }
    
    return _titleLabel;
}

- (UILabel *)timeLablel {
    if (_timeLablel == nil) {
        _timeLablel = [[UILabel alloc] init];
        _timeLablel.font = [UIFont systemFontOfSize:12.0f];
        _timeLablel.textColor = [UIColor colorWithHexString:@"999999" alpha:1.0f];
    }
    
    return _timeLablel;
}

@end
