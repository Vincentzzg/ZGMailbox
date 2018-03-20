//
//  ZGMailListTableViewCell.m
//  ZGMailbox
//
//  Created by zzg on 2017/3/21.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import "ZGMailListTableViewCell.h"

#import "ZGMailModule.h"

//record
#import "ZGMailRecord.h"

//时间转换
#import "NSDate+DDAddition.h"

//view
#import "ZGMailListCellPortraitView.h"

//常量
static CGFloat const leftSpace = 60.0f;
static CGFloat const rightSpace = -15.0f;

@interface ZGMailListTableViewCell ()

@property (nonatomic, strong) ZGMailListCellPortraitView *portraitImageView;//头像
@property (nonatomic, strong) UIImageView *replyImageView;//回复
@property (nonatomic, strong) UIImageView *unreadImageView;//未读
@property (nonatomic, strong) UILabel *senderLabel;//发件人
@property (nonatomic, strong) UIImageView *attachmentImageView;//附件
@property (nonatomic, strong) UIImageView *starImageView;//星标
@property (nonatomic, strong) UILabel *subjectLabel;//主题
@property (nonatomic, strong) UILabel *timeLabel;//时间

@property (nonatomic, strong) UIButton *cancelButton;

@property (nonatomic, strong) MASConstraint *senderLabelLeadingConstraint;

@end

@implementation ZGMailListTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.separatorInset = UIEdgeInsetsMake(0, leftSpace, 0, 0);
        
        [self.contentView addSubview:self.multipleSelectImageView];
        [self.contentView addSubview:self.portraitImageView];
        [self.contentView addSubview:self.replyImageView];
        [self.contentView addSubview:self.senderLabel];
        [self.contentView addSubview:self.attachmentImageView];
        [self.contentView addSubview:self.starImageView];
        [self.contentView addSubview:self.timeLabel];
        [self.contentView addSubview:self.subjectLabel];
        [self.contentView addSubview:self.contentLabel];
        [self.contentView addSubview:self.progressView];
        [self.contentView addSubview:self.cancelButton];
        [self.contentView addSubview:self.failureLabel];
        
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
    
    //主题
    NSString *subject = self.mailRecord.subject;
    if (IsEmptyString(subject)) {
        self.subjectLabel.text = @"（无主题）";
    } else {
        self.subjectLabel.text = subject;
    }
    self.timeLabel.text = [self.mailRecord.date transformToFuzzyDate];
    
    if ([self.folderType isEqualToString:MailFolderTypeINBOX]) {//收件箱，展示发件人信息
        //发件人
        if (self.mailRecord.sender.length > 0) {
            //头像
            if (!IsEmptyString(self.mailRecord.senderPortrait)) {
                self.portraitImageView.myLabel.text = @"";
                self.portraitImageView.myLabel.hidden = YES;
                
                [self.portraitImageView.imageView sd_setImageWithURL:[NSURL URLWithString:self.mailRecord.senderPortrait]];
            } else {
                self.portraitImageView.imageView.image = [UIImage new];
                
                NSString *str = [[self.mailRecord.sender substringToIndex:1] uppercaseString];
                self.portraitImageView.myLabel.hidden = NO;
                self.portraitImageView.myLabel.text = str;
            }
            
            //发件人
            self.senderLabel.text = self.mailRecord.sender;
        } else {
            self.portraitImageView.myLabel.hidden = YES;

            //发件人
            self.senderLabel.text = @"（未填写发件人）";
        }
    } else {//其他文件夹展示收件人信息
        //收件人
        if (self.mailRecord.receiver.length > 0) {
            //头像
            if (!IsEmptyString(self.mailRecord.receiverPortrait)) {
                self.portraitImageView.myLabel.text = @"";
                self.portraitImageView.myLabel.hidden = YES;
                
                [self.portraitImageView.imageView sd_setImageWithURL:[NSURL URLWithString:self.mailRecord.receiverPortrait]];
            } else {
                self.portraitImageView.imageView.image = [UIImage new];
                
                NSString *str = [[self.mailRecord.receiver substringToIndex:1] uppercaseString];
                self.portraitImageView.myLabel.hidden = NO;
                self.portraitImageView.myLabel.text = str;
            }
            
            //发件人
            self.senderLabel.text = self.mailRecord.receiver;
        } else {
            self.portraitImageView.myLabel.hidden = YES;
            
            //发件人
            self.senderLabel.text = @"（未填写收件人）";
        }
    }
    
    //回复标识
    if (self.mailRecord.isReply) {
        self.replyImageView.image = [UIImage imageNamed:@"icon_status_reply"];
        self.replyImageView.hidden = NO;
    } else {
        if (self.mailRecord.isForwarded) {//转发
            self.replyImageView.hidden = NO;
            self.replyImageView.image = [UIImage imageNamed:@"icon_status_forward"];
        } else {
            self.replyImageView.hidden = YES;
        }
    }
    
    //未读标识
    if (self.mailRecord.isUnread && [self.folderType isEqualToString:MailFolderTypeINBOX]) {//只有收件箱需要展示未读标志
        [self.contentView addSubview:self.unreadImageView];
        [self.unreadImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.mas_equalTo(self.contentView.mas_leading).offset(leftSpace);
            make.centerY.mas_equalTo(self.senderLabel);
        }];
        self.senderLabelLeadingConstraint.offset = leftSpace + 13;
    } else {
        if ([self.unreadImageView isDescendantOfView:self.contentView]) {
            [self.unreadImageView removeFromSuperview];
        }
        self.senderLabelLeadingConstraint.offset = leftSpace;
    }
    
    //附件标识
    if (self.mailRecord.isHaveAttachment) {
        [self.contentView addSubview:self.attachmentImageView];
        
        [self.attachmentImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.mas_equalTo(self.senderLabel.mas_trailing).offset(4);
            make.centerY.mas_equalTo(self.senderLabel);
        }];
    } else {
        if ([self.attachmentImageView isDescendantOfView:self.contentView]) {
            [self.attachmentImageView removeFromSuperview];
        }
    }
    
    //星标标识
    if (self.mailRecord.isStarred) {
        [self.contentView addSubview:self.starImageView];
        
        if (self.mailRecord.isHaveAttachment) {
            [self.starImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.leading.mas_equalTo(self.attachmentImageView.mas_trailing).offset(4);
                make.centerY.mas_equalTo(self.attachmentImageView);
            }];
        } else {
            [self.starImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.leading.mas_equalTo(self.senderLabel.mas_trailing).offset(4);
                make.centerY.mas_equalTo(self.senderLabel);
            }];
        }
    } else {
        if ([self.starImageView isDescendantOfView:self.contentView]) {
            [self.starImageView removeFromSuperview];
        }
    }
}

#pragma mark - public method

- (void)showStar:(BOOL)isShow {
    //星标标识
    if (isShow) {
        [self.contentView addSubview:self.starImageView];
        
        if (self.mailRecord.isHaveAttachment) {
            [self.starImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.leading.mas_equalTo(self.attachmentImageView.mas_trailing).offset(4);
                make.centerY.mas_equalTo(self.attachmentImageView);
            }];
        } else {
            [self.starImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.leading.mas_equalTo(self.senderLabel.mas_trailing).offset(4);
                make.centerY.mas_equalTo(self.senderLabel);
            }];
        }
    } else {
        if ([self.starImageView isDescendantOfView:self.contentView]) {
            [self.starImageView removeFromSuperview];
        }
    }

    [UIView animateWithDuration:0.2 animations:^{
        [self layoutIfNeeded];
    }];
}

- (void)showUnseen:(BOOL)isShow {
    //未读标识
    if (isShow) {
        [self.contentView addSubview:self.unreadImageView];
        [self layoutIfNeeded];

        [self.unreadImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.mas_equalTo(self.contentView.mas_leading).offset(leftSpace);
            make.centerY.mas_equalTo(self.senderLabel);
        }];
        self.senderLabelLeadingConstraint.offset = leftSpace + 13;
    } else {
        if ([self.unreadImageView isDescendantOfView:self.contentView]) {
            [self.unreadImageView removeFromSuperview];
        }
        self.senderLabelLeadingConstraint.offset = leftSpace;
    }
    
    [UIView animateWithDuration:0.2 animations:^{
        [self layoutIfNeeded];
    }];
}

- (void)showProgressView {
    self.contentLabel.text = @"";
    self.failureLabel.text = @"";
    
    self.progressView.hidden = NO;
    
    self.cancelButton.hidden = YES;
}

- (void)showContentLabel {
    self.contentLabel.hidden = NO;
    self.progressView.hidden = YES;
    self.cancelButton.hidden = YES;
}

#pragma mark - IBAction 

- (IBAction)cancelButtonPressed:(id)sender {
    [self showContentLabel];
    self.contentLabel.text = @"邮件已取消发送";
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(mailListTableViewCell:cancelButtonPressed:)]) {
        [self.delegate mailListTableViewCell:self cancelButtonPressed:sender];
    }
}

#pragma mark - private method

/**
 *  设置约束
 */
- (void)layoutCellSubviews {
    //多选的勾选图片
    [self.multipleSelectImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(30, 30));
        make.centerY.mas_equalTo(self.contentView);
        make.leading.mas_equalTo(self.contentView.mas_leading).offset(-28);
    }];
    
    [self.portraitImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.subjectLabel.mas_top);
        make.leading.mas_equalTo(self.contentView.mas_leading).offset(8);
        make.size.mas_equalTo(CGSizeMake(42, 42));
    }];
    
    [self.replyImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.portraitImageView);
        make.bottom.mas_equalTo(self.contentView).offset(-7);
    }];
    
    [self.senderLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        self.senderLabelLeadingConstraint = make.leading.mas_equalTo(self.contentView.mas_leading).offset(leftSpace);
        make.trailing.mas_lessThanOrEqualTo(self.contentView).offset(-100);
        make.top.mas_equalTo(self.contentView.mas_top).offset(12);
    }];
    
    [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.mas_equalTo(self.contentView).offset(rightSpace);
        make.centerY.mas_equalTo(self.senderLabel);
    }];
    
    [self.subjectLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.contentView.mas_leading).offset(leftSpace);
        make.top.mas_equalTo(self.senderLabel.mas_bottom).offset(4);
        make.trailing.mas_equalTo(self.contentView.mas_trailing).offset(rightSpace);
    }];
    
    [self.contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.contentView.mas_leading).offset(leftSpace);
        make.top.mas_equalTo(self.subjectLabel.mas_bottom).offset(4);
        make.trailing.mas_equalTo(self.contentView.mas_trailing).offset(rightSpace);
    }];
    
    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.contentView.mas_leading).offset(leftSpace);
        make.top.mas_equalTo(self.subjectLabel.mas_bottom).offset(13);
        make.trailing.mas_equalTo(self.contentView.mas_trailing).offset(-50);
        make.height.mas_equalTo(4);
    }];
    
    [self.cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.progressView.mas_trailing).offset(0);
        make.centerY.mas_equalTo(self.progressView);
        make.size.mas_equalTo(CGSizeMake(34, 30));
    }];
    
    [self.failureLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.contentView.mas_leading).offset(leftSpace);
        make.bottom.mas_equalTo(self.contentView.mas_bottom).offset(-8);
        make.trailing.mas_equalTo(self.contentView.mas_trailing).offset(rightSpace);
    }];
}

#pragma mark - setter and getter

- (UIImageView *)multipleSelectImageView {
    if (_multipleSelectImageView == nil) {
        _multipleSelectImageView = [[UIImageView alloc] init];
        [_multipleSelectImageView setImage:[UIImage imageNamed:@"checkmark_unselected"]];
    }
    
    return _multipleSelectImageView;
}

- (ZGMailListCellPortraitView *)portraitImageView {
    if (_portraitImageView == nil) {
        _portraitImageView = [[ZGMailListCellPortraitView alloc] init];
        
        _portraitImageView.myLabel.layer.cornerRadius = 21;
        _portraitImageView.myLabel.layer.borderColor = [UIColor colorWithHexString:@"2F86CF" alpha:1.0f].CGColor;
        _portraitImageView.myLabel.textColor = [UIColor colorWithHexString:@"2F86CF" alpha:1.0f];
        _portraitImageView.myLabel.layer.borderWidth = 1;
        
        _portraitImageView.imageView.layer.cornerRadius = 21;
        _portraitImageView.imageView.layer.masksToBounds = YES;
    }
    
    return _portraitImageView;
}

- (UIImageView *)replyImageView {
    if (_replyImageView == nil) {
        _replyImageView = [[UIImageView alloc] init];
        _replyImageView.image = [UIImage imageNamed:@"icon_status_reply"];
    }
    
    return _replyImageView;
}

- (UIImageView *)unreadImageView {
    if (_unreadImageView == nil) {
        _unreadImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_status_unread"]];
    }
    
    return _unreadImageView;
}

- (UILabel *)senderLabel {
    if (_senderLabel == nil) {
        _senderLabel = [[UILabel alloc] init];
        _senderLabel.textColor = [UIColor colorWithHexString:@"31353B" alpha:1.0f];
        _senderLabel.font = [UIFont systemFontOfSize:17];
    }
    
    return _senderLabel;
}

- (UIImageView *)attachmentImageView {
    if (_attachmentImageView == nil) {
        _attachmentImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_status_attach"]];
    }
    
    return _attachmentImageView;
}

- (UIImageView *)starImageView {
    if (_starImageView == nil) {
        _starImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_status_star"]];
    }
    
    return _starImageView;
}

- (UILabel *)subjectLabel {
    if (_subjectLabel == nil) {
        _subjectLabel = [[UILabel alloc] init];
        _subjectLabel.textColor = [UIColor colorWithHexString:@"666666" alpha:1.0f];
        _subjectLabel.font = [UIFont systemFontOfSize:13.0f];
    }
    
    return _subjectLabel;
}

- (UILabel *)contentLabel {
    if (_contentLabel == nil) {
        _contentLabel = [[UILabel alloc] init];
        _contentLabel.textColor = [UIColor colorWithHexString:@"81858A" alpha:1.0f];
        _contentLabel.numberOfLines = 1;
        _contentLabel.font = [UIFont systemFontOfSize:12.0f];
    }
    
    return _contentLabel;
}

- (UILabel *)timeLabel {
    if (_timeLabel == nil) {
        _timeLabel = [[UILabel alloc] init];
        _timeLabel.textColor = [UIColor colorWithHexString:@"81858A" alpha:1.0f];
        _timeLabel.font = [UIFont systemFontOfSize:12.0f];
    }
    
    return _timeLabel;
}

- (UIProgressView *)progressView {
    if (_progressView == nil) {
        _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        _progressView.progressTintColor = [UIColor whiteColor];
        _progressView.trackTintColor = [UIColor lightGrayColor];
        _progressView.layer.borderColor = [UIColor lightGrayColor].CGColor;
        _progressView.layer.borderWidth = 0.5;
        _progressView.layer.cornerRadius = 2;
        _progressView.clipsToBounds = YES;
        
        _progressView.hidden = YES;
    }
    
    return _progressView;
}

- (UIButton *)cancelButton {
    if (_cancelButton == nil) {
        _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cancelButton setImage:[UIImage imageNamed:@"btn_dot_stop"] forState:UIControlStateNormal];
        [_cancelButton addTarget:self action:@selector(cancelButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        _cancelButton.hidden = YES;
    }
    
    return _cancelButton;
}

- (UILabel *)failureLabel {
    if (_failureLabel == nil) {
        _failureLabel = [[UILabel alloc] init];
        _failureLabel.textColor = [UIColor redColor];
        _failureLabel.font = [UIFont systemFontOfSize:12.0f];
    }
    
    return _failureLabel;
}

@end
