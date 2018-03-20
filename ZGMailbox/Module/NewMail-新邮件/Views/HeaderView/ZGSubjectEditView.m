//
//  ZGSubjectEditView.m
//  ZGMailbox
//
//  Created by zzg on 2017/4/24.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import "ZGSubjectEditView.h"

@interface ZGSubjectEditView () <UITextFieldDelegate>

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UITextField *subjectTextField;
@property (nonatomic, strong) UIButton *attachmentButton;
@property (nonatomic, strong) UILabel *attachmentNumberLabel;
@property (nonatomic, strong) UIView *separatorView;

@property (nonatomic, strong) MASConstraint *attachmentNumberLabelWidthConstraint;

@end

@implementation ZGSubjectEditView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.titleLabel];
        [self addSubview:self.subjectTextField];
        [self addSubview:self.attachmentButton];
        [self addSubview:self.attachmentNumberLabel];
        [self addSubview:self.separatorView];

        [self layoutViewSubviews];
    }
    
    return self;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (self.delegate && [self.delegate respondsToSelector:@selector(subjectEditViewBeginEditing:)]) {
        [self.delegate subjectEditViewBeginEditing:self];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (self.delegate && [self.delegate respondsToSelector:@selector(subjectEditViewEndEditing:)]) {
        [self.delegate subjectEditViewEndEditing:self];
    }
}

#pragma mark - public method

/**
 *  获取邮件主题
 *
 *  @return
 */
- (NSString *)mailSubject {
    return self.subjectTextField.text;
}

- (void)setAttachmentNumber:(NSInteger)attachmentNumber {
    if (attachmentNumber == 0) {
        self.attachmentNumberLabel.text = @"";
        self.attachmentNumberLabelWidthConstraint.offset = 0;
    } else {
        NSString *text = [NSString stringWithFormat:@"%ld", (long)attachmentNumber];
        self.attachmentNumberLabel.text = text;
        
        CGRect frame = [text boundingRectWithSize:CGSizeZero options:NSStringDrawingUsesLineFragmentOrigin attributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:13.0f], NSFontAttributeName, nil] context:nil];
        self.attachmentNumberLabelWidthConstraint.offset = ceil(frame.size.width);//向上取整
    }
    
//    [UIView animateWithDuration:0.25 animations:^{
        [self layoutIfNeeded];
//    }];
}

/**
 *  设置主题
 *
 *  @param subjectStr
 */
- (void)setSubject:(NSString *)subjectStr {
    self.subjectTextField.text = subjectStr;
}

#pragma mark - IBAction 

- (IBAction)attachmentButtonPressed:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(subjectEditView:attachmentButtonPressed:)]) {
        [self.delegate subjectEditView:self attachmentButtonPressed:sender];
    }
}

#pragma mark - private method

- (void)layoutViewSubviews {
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.mas_leading).offset(15);
        make.centerY.mas_equalTo(self);
        make.width.mas_equalTo(52);
    }];
    
    [self.subjectTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.titleLabel.mas_trailing).offset(5);
        make.centerY.mas_equalTo(self);
        make.trailing.mas_equalTo(self.attachmentButton.mas_leading).offset(-5);
        make.height.mas_equalTo(self);
    }];
    
    [self.attachmentButton mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.trailing.mas_equalTo(self.mas_trailing);
        make.size.mas_equalTo(CGSizeMake(40, 48));
        make.centerY.mas_equalTo(self);
    }];
    
    [self.attachmentNumberLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.attachmentButton.imageView.mas_trailing);
        make.trailing.mas_equalTo(self.mas_trailing).offset(-8);
        make.bottom.mas_equalTo(self.attachmentButton.imageView.mas_bottom).offset(2);
        self.attachmentNumberLabelWidthConstraint = make.width.mas_equalTo(0);
    }];
    
    //设置设备上显示1个像素的线
    float floatsortaPixel = 1.0 / [UIScreen mainScreen].scale;
    [self.separatorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(self.mas_bottom).offset(-floatsortaPixel);
        make.height.mas_equalTo(floatsortaPixel);
        make.leading.mas_equalTo(self.mas_leading).offset(15);
        make.trailing.mas_equalTo(self);
    }];
}

#pragma mark - setter and getter 

- (UILabel *)titleLabel {
    if (_titleLabel == nil) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = [UIColor colorWithHexString:@"969696" alpha:1.0f];
        _titleLabel.font = [UIFont systemFontOfSize:17.0f];
        _titleLabel.text = @"主题：";
    }
    
    return _titleLabel;
}

- (UITextField *)subjectTextField {
    if (_subjectTextField == nil) {
        _subjectTextField = [[UITextField alloc] init];
        _subjectTextField.font = [UIFont systemFontOfSize:17.0f];
        _subjectTextField.delegate = self;
    }
    
    return _subjectTextField;
}

- (UIButton *)attachmentButton {
    if (_attachmentButton == nil) {
        _attachmentButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_attachmentButton setImage:[UIImage imageNamed:@"wmAttachment"] forState:UIControlStateNormal];
        [_attachmentButton addTarget:self action:@selector(attachmentButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _attachmentButton;
}

- (UILabel *)attachmentNumberLabel {
    if (_attachmentNumberLabel == nil) {
        _attachmentNumberLabel = [[UILabel alloc] init];
        _attachmentNumberLabel.textColor = [UIColor colorWithHexString:@"31353B" alpha:1.0f];
        _attachmentNumberLabel.font = [UIFont systemFontOfSize:13.0f];
    }
    
    return _attachmentNumberLabel;
}

- (UIView *)separatorView {
    if (_separatorView == nil) {
        _separatorView = [[UIView alloc] init];
        _separatorView.backgroundColor = [UIColor colorWithHexString:@"c8c8c8" alpha:1.0f];
    }
    
    return _separatorView;
}

@end
