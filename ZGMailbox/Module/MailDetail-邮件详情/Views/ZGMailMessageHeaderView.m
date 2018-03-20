//
//  ZGMailMessageHeaderView.m
//  ZGMailbox
//
//  Created by zzg on 2017/4/5.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import "ZGMailMessageHeaderView.h"
#import <MailCore/MCOIMAPMessage.h>
#import <MailCore/MCOMessageHeader.h>
#import <MailCore/MCOAddress.h>

//自定义view
#import "ZGMailMessageHeaderDetailView.h"
#import "ZGAddressShadowButton.h"

//动画
#import <pop/POP.h>

//常量
//static float UnseenImageViewMaxWidth = 9.0f;
//static float UnseenImageViewMinWidth = 4.0f;
static float summaryViewHeight = 34;

@interface ZGMailMessageHeaderView () <ZGMailMessageHeaderDetailViewDelegate> {
    BOOL isDetailViewShow;
}

@property (nonatomic, strong) UILabel *subjectLabel;//主题

@property (nonatomic, strong) UIView *readmailDetailView;

@property (nonatomic, strong) UIView *summaryView;//概要视图
@property (nonatomic, strong) ZGAddressShadowButton *senderButton;//发件人
@property (nonatomic, strong) ZGAddressShadowButton *attachmentButton;//附件图标

@property (nonatomic, strong) ZGAddressShadowButton *detailButton;//详情
@property (nonatomic, strong) ZGAddressShadowButton *hideButton;//隐藏

@property (nonatomic, strong) UIImageView *starImageView;//星标
@property (nonatomic, strong) UIImageView *unseenImageView;//未读标志

@property (nonatomic, strong) ZGMailMessageHeaderDetailView *detailView;//发件人、收件人、抄送、密送、时间、附件列表

@property (nonatomic, strong) UIView *separatorLineView;//分隔线

@property (nonatomic, strong) MASConstraint *readmailDetaiViewHightConstraint;
@property (nonatomic, strong) MASConstraint *detaiViewHightConstraint;
@property (nonatomic, strong) MASConstraint *unseenImageViewWidthConstraint;
@property (nonatomic, strong) MASConstraint *unseenImageViewTrailingConstraint;

@end

@implementation ZGMailMessageHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        isDetailViewShow = NO;
        
        [self addSubview:self.subjectLabel];
        [self addSubview:self.readmailDetailView];
        
        [self.readmailDetailView addSubview:self.summaryView];
        [self.summaryView addSubview:self.senderButton];
        [self.summaryView addSubview:self.attachmentButton];

        [self.readmailDetailView addSubview:self.hideButton];
        [self.readmailDetailView addSubview:self.detailButton];
        
        [self addSubview:self.separatorLineView];
        
        [self layoutViewSubViews];
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

#pragma mark - ZGMailMessageHeaderDetailViewDelegate

- (void)headerDetailView:(ZGMailMessageHeaderDetailView *)headerDetailView addressButtonPressed:(ZGAddressShadowButton *)button {
    if (self.delegate && [self.delegate respondsToSelector:@selector(headerView:addressButtonPressed:)]) {
        [self.delegate headerView:self addressButtonPressed:button];
    }
}

- (void)headerDetailView:(ZGMailMessageHeaderDetailView *)headerDetailView attachmentButtonPressed:(ZGAddressShadowButton *)button {
    if (self.delegate && [self.delegate respondsToSelector:@selector(headerView:attachmentButtonPressed:)]) {
        [self.delegate headerView:self attachmentButtonPressed:button];
    }
}

#pragma mark - public method

- (float)heightOfMessageHeaderView {
    NSString *subject = self.subjectLabel.text;//可能是“（无主题）”
    CGRect size = [subject boundingRectWithSize:CGSizeMake(ScreenWidth - 30, 1000000) options:NSStringDrawingUsesLineFragmentOrigin attributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:17.0f],NSFontAttributeName, nil] context:nil];
    float height = size.size.height;

    return 10 + height + 3 + [self readMailDetailViewHeight];
}

- (float)heightOfSummaryMessageHeaderView {
    NSString *subject = self.subjectLabel.text;//可能是“（无主题）”
    CGRect size = [subject boundingRectWithSize:CGSizeMake(ScreenWidth - 30, 1000000) options:NSStringDrawingUsesLineFragmentOrigin attributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:17.0f],NSFontAttributeName, nil] context:nil];
    float height = size.size.height;
    
    return 10 + height + 3 + summaryViewHeight;
}

- (void)hideMailDetailView {
    [self hideButtonPressed:nil];
//    [UIView animateWithDuration:0.25 animations:^{
//        [self layoutIfNeeded];
//    }];
}

- (void)showStarImageView {
    self.starImageView.alpha = 1;
    self.starImageView.hidden = NO;
    self.starImageView.transform = CGAffineTransformMakeScale(0.1, 0.1);
    [self addSubview:self.starImageView];

    [self.starImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.detailButton);
        make.trailing.mas_equalTo(self.detailButton.mas_leading);
    }];
    
    if ([self.unseenImageView isDescendantOfView:self]) {//已有未读标志
        self.unseenImageViewTrailingConstraint.offset = -16;
        
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            [self layoutIfNeeded];
        } completion:^(BOOL finished) {
            POPSpringAnimation *sprintAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewScaleXY];
            sprintAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(1.0, 1.0)];
            sprintAnimation.velocity = [NSValue valueWithCGPoint:CGPointMake(2, 2)];
            sprintAnimation.springBounciness = 20.f;
            [self.starImageView pop_addAnimation:sprintAnimation forKey:@"springAnimation"];
        }];
    } else {//
        //没有未读标志，不处理未读图片
        POPSpringAnimation *sprintAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewScaleXY];
        sprintAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(1.0, 1.0)];
        sprintAnimation.velocity = [NSValue valueWithCGPoint:CGPointMake(2, 2)];
        sprintAnimation.springBounciness = 20.f;
        [self.starImageView pop_addAnimation:sprintAnimation forKey:@"springAnimation"];

    }
////    self.starImageView.transform = CGAffineTransformMakeScale(0.1, 0.1);
//    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
////        self.starImageView.transform = CGAffineTransformMakeScale(1.0, 1.0);
//        [self layoutIfNeeded];
//    } completion:^(BOOL finished) {
//        POPSpringAnimation *sprintAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewScaleXY];
//        sprintAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(1.0, 1.0)];
//        sprintAnimation.velocity = [NSValue valueWithCGPoint:CGPointMake(2, 2)];
//        sprintAnimation.springBounciness = 20.f;
//        [self.starImageView pop_addAnimation:sprintAnimation forKey:@"springAnimation"];
//    }];
}

- (void)hideStarImageView {
    [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.8 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.starImageView.alpha = 0;
        self.starImageView.transform = CGAffineTransformMakeScale(0.1, 0.1);
    } completion:^(BOOL finished) {
        self.starImageView.hidden = YES;
        [self.starImageView removeFromSuperview];
    }];
    
    if ([self.unseenImageView isDescendantOfView:self]) {//已有未读标志
        self.unseenImageViewTrailingConstraint.offset = 0;
        [UIView animateWithDuration:0.25 delay:0.2 usingSpringWithDamping:1 initialSpringVelocity:0.8 options:UIViewAnimationOptionCurveEaseOut animations:^{
            [self layoutIfNeeded];
        } completion:^(BOOL finished) {
        }];
    }
}

- (void)showUnseenImageView {
    self.unseenImageView.hidden = NO;
    self.unseenImageView.alpha = 1;
    self.unseenImageView.transform = CGAffineTransformMakeScale(0.1, 0.1);
    [self addSubview:self.unseenImageView];

    [self.unseenImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.detailButton);
        self.unseenImageViewTrailingConstraint = make.trailing.mas_equalTo(self.detailButton.mas_leading).offset(0);
    }];
    
    if ([self.starImageView isDescendantOfView:self]) {//已有星标
        self.unseenImageViewTrailingConstraint.offset = -15;
    } else {
        self.unseenImageViewTrailingConstraint.offset = 0;
    }
    
    [self layoutIfNeeded];
    
//    self.unseenImageViewWidthConstraint.offset = UnseenImageViewMaxWidth;
//    [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.8 options:UIViewAnimationOptionCurveLinear animations:^{
//        [self layoutIfNeeded];
//    } completion:^(BOOL finished) {
//        
//    }];
    
//    CABasicAnimation *anima = [CABasicAnimation animationWithKeyPath:@"transform.scale"];//同上
//    anima.toValue = [NSNumber numberWithFloat:2.0f];
//    anima.duration = 1.0f;
//    [self.unseenImageView.layer addAnimation:anima forKey:@"scaleAnimation"];

//    self.unseenImageView.transform = CGAffineTransformMakeScale(0.1, 0.1);
//    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
//        self.unseenImageView.transform = CGAffineTransformMakeScale(1.0, 1.0);
//    } completion:^(BOOL finished) {
//        
//    }];
    
    POPSpringAnimation *sprintAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewScaleXY];
    sprintAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(1.0, 1.0)];
    sprintAnimation.velocity = [NSValue valueWithCGPoint:CGPointMake(2, 2)];
    sprintAnimation.springBounciness = 20.f;
    [self.unseenImageView pop_addAnimation:sprintAnimation forKey:@"springAnimation"];
}

- (void)hideUnseenImageView {
//    self.unseenImageViewWidthConstraint.offset = UnseenImageViewMinWidth;
//    [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.8 options:UIViewAnimationOptionCurveLinear animations:^{
//        [self layoutIfNeeded];
//    } completion:^(BOOL finished) {
//        [self.unseenImageView removeFromSuperview];
//    }];

    [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.8 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.unseenImageView.transform = CGAffineTransformMakeScale(0.1, 0.1);
        self.unseenImageView.alpha = 0;
    } completion:^(BOOL finished) {
        self.unseenImageView.hidden = YES;
        [self.unseenImageView removeFromSuperview];
    }];
}

#pragma mark - IBAction 

/**
 *  详情按钮点击
 */
- (IBAction)detailButtonPressed:(id)sender {
    //隐藏概要视图和详细按钮
    self.detailButton.hidden = YES;
    //显示隐藏按钮和详情视图
    self.hideButton.hidden = NO;
    self.detailView.hidden = NO;
    isDetailViewShow = YES;
    
    if (![self.detailView isDescendantOfView:self.readmailDetailView]) {
        //添加详情视图
        [self.readmailDetailView insertSubview:self.detailView belowSubview:self.hideButton];
        [self.detailView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self.readmailDetailView.mas_top).offset(3);
            make.width.mas_equalTo(self.readmailDetailView);
            make.centerX.mas_equalTo(self.readmailDetailView);
            self.detaiViewHightConstraint = make.height.mas_equalTo(50);
        }];
    } else {
        //详情视图放到最前面展示
        [self.readmailDetailView bringSubviewToFront:self.detailView];
        [self.readmailDetailView bringSubviewToFront:self.hideButton];
    }
    [self layoutIfNeeded];

    //设置
    self.readmailDetaiViewHightConstraint.offset = [self.detailView heightOfMailDetailView];
    self.detaiViewHightConstraint.offset = [self.detailView heightOfMailDetailView];
    
    [UIView animateWithDuration:0.25 animations:^{
        //设置透明度
        self.summaryView.alpha = 0;
        self.detailView.alpha = 1;

        if (self.delegate && [self.delegate respondsToSelector:@selector(headerView:detailButtonPressed:)]) {
            [self.delegate headerView:self detailButtonPressed:sender];
        }
        
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.summaryView.hidden = YES;
    }];
}

/**
 *  隐藏按钮点击
 */
- (IBAction)hideButtonPressed:(id)sender {
    //显示概要视图和详情按钮
    self.detailButton.hidden = NO;
    self.summaryView.hidden = NO;
    //隐藏详情视图和隐藏按钮
    self.hideButton.hidden = YES;
    isDetailViewShow = NO;

    [self.readmailDetailView bringSubviewToFront:self.summaryView];
    [self.readmailDetailView bringSubviewToFront:self.detailButton];
    self.readmailDetaiViewHightConstraint.offset = summaryViewHeight;;
    
    [UIView animateWithDuration:0.25 animations:^{
        //透明度
        self.summaryView.alpha = 1;
        self.detailView.alpha = 0;

        if (self.delegate && [self.delegate respondsToSelector:@selector(headerView:hideButtonPressed:)]) {
            [self.delegate headerView:self hideButtonPressed:sender];
        }
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.detailView.hidden = YES;
    }];
}

- (IBAction)senderButtonPressed:(ZGAddressShadowButton *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(headerView:addressButtonPressed:)]) {
        [self.delegate headerView:self addressButtonPressed:sender];
    }
}

- (IBAction)attachmentButtonPressed:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(headerView:attachmentButtonPressed:)]) {
        [self.delegate headerView:self attachmentButtonPressed:sender];
    }
}

#pragma mark - private method

- (void)layoutViewSubViews {
    [self.subjectLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(self.mas_width).offset(-30);
        make.centerX.mas_equalTo(self);
        make.top.mas_equalTo(self.mas_top).offset(10);
    }];
    
    [self.readmailDetailView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.subjectLabel.mas_bottom);
        make.centerX.mas_equalTo(self);
        make.width.mas_equalTo(self);
        self.readmailDetaiViewHightConstraint = make.height.mas_equalTo(100);
    }];
    
    [self.summaryView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.subjectLabel.mas_bottom);
        make.width.mas_equalTo(self.readmailDetailView);
        make.centerX.mas_equalTo(self.readmailDetailView);
        make.height.mas_equalTo(summaryViewHeight);
    }];
    
    [self.senderButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.summaryView.mas_leading).offset(11);
        make.top.mas_equalTo(self.summaryView.mas_top).offset(2);
    }];
    
    [self.attachmentButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.senderButton);
        make.leading.mas_equalTo(self.senderButton.mas_trailing).offset(5);
    }];
    
    [self.detailButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.senderButton);
        make.trailing.mas_equalTo(self.readmailDetailView.mas_trailing).offset(-15);
    }];
    
    [self.hideButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.senderButton);
        make.trailing.mas_equalTo(self.readmailDetailView.mas_trailing).offset(-15);
    }];

    //设置设备上显示1个像素的线
    float floatsortaPixel = 1.0 / [UIScreen mainScreen].scale;
    [self.separatorLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(floatsortaPixel);
        make.width.mas_equalTo(self);
        make.centerX.mas_equalTo(self);
        make.bottom.mas_equalTo(self.mas_bottom).offset(-floatsortaPixel);
    }];
}

- (float)readMailDetailViewHeight {
    if (isDetailViewShow) {
        return [self.detailView heightOfMailDetailView] + 5;
    } else {
        return summaryViewHeight;
    }
}

#pragma mark - setter and getter 

- (void)setMessage:(MCOIMAPMessage *)message {
    _message = message;
    
    //主题
    NSString *subject = self.message.header.subject;
    if (IsEmptyString(subject)) {
        self.subjectLabel.text = @"(无主题)";
    } else {
        self.subjectLabel.text = subject;
    }
    
    //发件人
    NSString *str = [self.message.header.sender displayName];
    if (IsEmptyString(str)) {
        str = [self.message.header.sender mailbox];
        NSArray *array = [str componentsSeparatedByString:@"@"];
        str = [array firstObject];
    } else {
        //不为空，不处理
    }
    [self.senderButton setTitle:str forState:UIControlStateNormal];
    self.senderButton.mailbox = [self.message.header.sender mailbox];
//    [self.detailView removeFromSuperview];
//    self.detailView = nil;
    
    //收件人详情
    self.detailView.message = self.message;
    self.readmailDetaiViewHightConstraint.offset = summaryViewHeight;
    
    //星标
    if (message.flags & MCOMessageFlagFlagged) {
        if ([self.starImageView isDescendantOfView:self]) {
            //已有星标，不处理
        } else {//添加星标
            [self addSubview:self.starImageView];
            [self.starImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.centerY.mas_equalTo(self.detailButton);
                make.trailing.mas_equalTo(self.detailButton.mas_leading);
            }];
        }
    } else {
        //移除星标
        if ([self.starImageView isDescendantOfView:self]) {
            [self.starImageView removeFromSuperview];
        } else {
            //没有星标，不处理
        }
    }
    
    //附件展示
    if ([message.attachments count] > 0) {
        self.attachmentButton.hidden = NO;
        [self.attachmentButton setTitle:[NSString stringWithFormat:@"%lu", (unsigned long)[message.attachments count]] forState:UIControlStateNormal];
    } else {
        self.attachmentButton.hidden = YES;
    }
}

- (UILabel *)subjectLabel {
    if (_subjectLabel == nil) {
        _subjectLabel = [[UILabel alloc] init];
        _subjectLabel.textColor = [UIColor blackColor];
        _subjectLabel.font = [UIFont systemFontOfSize:17.0f];
        _subjectLabel.numberOfLines = 0;
    }
    
    return _subjectLabel;
}

- (UIView *)readmailDetailView {
    if (_readmailDetailView == nil) {
        _readmailDetailView = [[UIView alloc] init];
        _readmailDetailView.backgroundColor = [UIColor whiteColor];
    }
    
    return _readmailDetailView;
}

- (UIView *)summaryView {
    if (_summaryView == nil) {
        _summaryView = [[UIView alloc] init];
    }
    
    return _summaryView;
}

- (ZGAddressShadowButton *)senderButton {
    if (_senderButton == nil) {
        _senderButton = [ZGAddressShadowButton buttonWithType:UIButtonTypeCustom];
        [_senderButton setTitleColor:[UIColor colorWithHexString:@"27ae60" alpha:1.0f] forState:UIControlStateNormal];
        _senderButton.titleLabel.font = [UIFont systemFontOfSize:14.0f];
        [_senderButton addTarget:self action:@selector(senderButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _senderButton;
}

- (ZGAddressShadowButton *)attachmentButton {
    if (_attachmentButton == nil) {
        _attachmentButton = [ZGAddressShadowButton buttonWithType:UIButtonTypeCustom];
        [_attachmentButton setImage:[UIImage imageNamed:@"icon_status_attach"] forState:UIControlStateNormal];
        [_attachmentButton setTitleColor:[UIColor colorWithHexString:@"999999" alpha:1.0f] forState:UIControlStateNormal];
        _attachmentButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [_attachmentButton addTarget:self action:@selector(attachmentButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        _attachmentButton.hidden = YES;
    }
    
    return _attachmentButton;
}

- (ZGAddressShadowButton *)detailButton {
    if (_detailButton == nil) {
        _detailButton = [ZGAddressShadowButton buttonWithType:UIButtonTypeCustom];
        [_detailButton setTitle:@"详情" forState:UIControlStateNormal];
        [_detailButton setTitleColor:[UIColor colorWithHexString:@"2B85D0" alpha:1.0f] forState:UIControlStateNormal];
        _detailButton.titleLabel.font = [UIFont systemFontOfSize:14.0f];
        [_detailButton addTarget:self action:@selector(detailButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _detailButton;
}

- (ZGAddressShadowButton *)hideButton {
    if (_hideButton == nil) {
        _hideButton = [ZGAddressShadowButton buttonWithType:UIButtonTypeCustom];
        [_hideButton setTitle:@"隐藏" forState:UIControlStateNormal];
        [_hideButton setTitleColor:[UIColor colorWithHexString:@"2B85D0" alpha:1.0f] forState:UIControlStateNormal];
        _hideButton.titleLabel.font = [UIFont systemFontOfSize:14.0f];
        [_hideButton addTarget:self action:@selector(hideButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        _hideButton.hidden = YES;
    }
    
    return _hideButton;
}

- (ZGMailMessageHeaderDetailView *)detailView {
    if (_detailView == nil) {
        _detailView = [[ZGMailMessageHeaderDetailView alloc] init];
        _detailView.backgroundColor = [UIColor whiteColor];
        _detailView.alpha = 0;
        _detailView.delegate = self;
        _detailView.hidden = YES;
    }
    
    return _detailView;
}

- (UIImageView *)starImageView {
    if (_starImageView == nil) {
        _starImageView = [[UIImageView alloc] init];
        _starImageView.image = [UIImage imageNamed:@"icon_status_star"];
    }
    
    return _starImageView;
}

- (UIImageView *)unseenImageView {
    if (_unseenImageView == nil) {
        _unseenImageView = [[UIImageView alloc] init];
        _unseenImageView.image = [UIImage imageNamed:@"icon_status_unread"];
    }
    
    return _unseenImageView;
}

- (UIView *)separatorLineView {
    if (_separatorLineView == nil) {
        _separatorLineView = [[UIView alloc] init];
        _separatorLineView.backgroundColor = [UIColor colorWithHexString:@"c8c8c8" alpha:1.0f];
    }
    
    return _separatorLineView;
}

@end
