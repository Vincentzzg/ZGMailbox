//
//  ZGComposeHeaderView.m
//  ZGMailbox
//
//  Created by zzg on 2017/4/19.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import "ZGComposeHeaderView.h"

//custom views
#import "ZGMailAddressFlowEditView.h"
#import "ZGSenderButton.h"
#import "ZGMailAddressButton.h"
#import "ZGSubjectEditView.h"

//地址
#import <MailCore/MCOAddress.h>
#import <MailCore/MCOMessageHeader.h>

@interface ZGComposeHeaderView () <ZGSubjectEditViewDelegate, ZGMailAddressFlowEditViewDelegate> {
    MCOMessageHeader *tempHeader;
}

@property (nonatomic, strong) ZGMailAddressFlowEditView *recipientAddressEditView;//收件人
@property (nonatomic, strong) ZGMailAddressFlowEditView *ccAddressEditView;//抄送
@property (nonatomic, strong) ZGMailAddressFlowEditView *bccAddressEditView;//密送

@property (nonatomic, strong) ZGSenderButton *senderButton;
@property (nonatomic, strong) ZGSubjectEditView *subjectEditView;//主题编辑视图

@property (nonatomic, copy) NSMutableArray *recipientAddressArray;//收件人数组
@property (nonatomic, copy) NSMutableDictionary *recipientAddressDic;//收件人去重辅助字典
@property (nonatomic, copy) NSMutableArray *ccAddressArray;//抄送数组
@property (nonatomic, copy) NSMutableDictionary *ccAddressDic;//抄送去重辅助字典
@property (nonatomic, copy) NSMutableArray *bccAddressArray;//密送数组
@property (nonatomic, copy) NSMutableDictionary *bccAddressDic;//密送去重辅助字典

@property (nonatomic, strong) MASConstraint *senderButtonConstraintTop;
@property (nonatomic, strong) MASConstraint *bccAddressEditViewConstraintBottom;
@property (nonatomic, strong) MASConstraint *recipientAddressEditViewConstraintHeight;
@property (nonatomic, strong) MASConstraint *ccAddressEditViewConstraintHeight;
@property (nonatomic, strong) MASConstraint *bccAddressEditViewConstraintHeight;

@property (nonatomic, assign) BOOL isCCOrBCCAddButtonPressed;//抄送或者密送编辑视图中的添加按钮点击，不隐藏抄送、密送视图

@end

@implementation ZGComposeHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithHexString:@"23bdfe" alpha:1.0f];
        [self addSubview:self.recipientAddressEditView];
        [self addSubview:self.ccAddressEditView];
        [self addSubview:self.bccAddressEditView];
        [self addSubview:self.senderButton];

        [self addSubview:self.subjectEditView];
        
        [self layoutViewSubviews];
        
        self.editViewType = MailAddressFlowEditViewTypeNone;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(willHideKeyboard:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
    }
    
    return self;
}

- (void)headerViewBecomeFirstResponder {
    switch (self.editViewType) {
        case MailAddressFlowEditViewTypeRecipient:
        {
            [self.recipientAddressEditView becomeFirstResponder];
        }
            break;
        case MailAddressFlowEditViewTypeCC:
        {
            [self.ccAddressEditView becomeFirstResponder];
            [self showCCAndBCCAddressEditView];
        }
            break;
        case MailAddressFlowEditViewTypeBCC:
        {
            [self.bccAddressEditView becomeFirstResponder];
            [self showCCAndBCCAddressEditView];
        }
            break;
        default:
            break;
    }
}

- (void)headerViewResignFirstResponder {
    switch (self.editViewType) {
        case MailAddressFlowEditViewTypeRecipient:
        {
            [self.recipientAddressEditView resignFirstResponder];
        }
            break;
        case MailAddressFlowEditViewTypeCC:
        {
            [self.ccAddressEditView resignFirstResponder];
            //隐藏抄送和密送视图
            [self hideCCAndBCCAddressEditView];
        }
            break;
        case MailAddressFlowEditViewTypeBCC:
        {
            [self.bccAddressEditView resignFirstResponder];
            //隐藏抄送和密送视图
            [self hideCCAndBCCAddressEditView];
        }
            break;
        default:
            break;
    }

    self.editViewType = MailAddressFlowEditViewTypeNone;
    
    //隐藏完整的地址编辑视图
    [self hideWholeAddressFlowEditView];
}

//- (BOOL)isHeaderViewFirstResponder {
////    return [self.recipientAddressEditView isFirstResponder] || [self.ccAddressEditView isFirstResponder] || [self.bccAddressEditView isFirstResponder];
//}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - ZGSubjectEditViewDelegate

/**
 *  主题编辑视图开始编辑
 *
 *  @param subjectEditView  主题编辑视图
 */
- (void)subjectEditViewBeginEditing:(ZGSubjectEditView *)subjectEditView {
    if (self.editViewType != MailAddressFlowEditViewTypeNone) {
        //隐藏完整的地址编辑视图
        [self hideWholeAddressFlowEditView];
    }
    
    self.editViewType = MailAddressFlowEditViewTypeNone;
    
    //隐藏抄送和密送视图
    [self hideCCAndBCCAddressEditView];
}

- (void)subjectEditViewEndEditing:(ZGSubjectEditView *)subjectEditView {

}

/**
 *  主题编辑视图，附件按钮点击
 *
 *  @param subjectEditView  主题编辑视图
 *  @param button           附件按钮
 */
- (void)subjectEditView:(ZGSubjectEditView *)subjectEditView attachmentButtonPressed:(UIButton *)button {
    if (self.delegate && [self.delegate respondsToSelector:@selector(composeHeaderView:attachmentButtonPressed:)]) {
        [self.delegate composeHeaderView:self attachmentButtonPressed:button];
    }
}

#pragma mark - ZGMailAddressFlowEditViewDelegate

/**
 *  地址编辑视图开始编辑
 *
 *  @param addressFlowEditView  地址编辑视图
 */
- (void)addressFlowEditViewBeginEditing:(ZGMailAddressFlowEditView *)addressFlowEditView {
    //收件人、抄送、密送必须全部满足，没展示全部编辑视图或者视图为空这个条件，才会展示完整的地址编辑视图
    if ((!self.recipientAddressEditView.isShowWholeEditView || self.recipientAddressEditView.isAddressFlowEditViewEmpty) && (!self.ccAddressEditView.isShowWholeEditView || self.ccAddressEditView.isAddressFlowEditViewEmpty) && (!self.bccAddressEditView.isShowWholeEditView || self.bccAddressEditView.isAddressFlowEditViewEmpty)) {
        //展示完整的地址编辑视图
        [self showWholeAddressFlowEditView];
    }
    
    self.editViewType = addressFlowEditView.type;
    
    //点击收件人输入框
    if (addressFlowEditView.type == MailAddressFlowEditViewTypeRecipient) {
        //隐藏抄送和密送视图
        [self hideCCAndBCCAddressEditView];
    }
}

- (void)addressFlowEditViewEndEditing:(ZGMailAddressFlowEditView *)addressFlowEditView {
    
}

- (void)addressFlowEditView:(ZGMailAddressFlowEditView *)addressFlowEditView textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *toBeString = [textField.text stringByReplacingCharactersInRange:range withString:string];//得到输入框的内容
    BOOL tobeEmpty = IsEmptyString(toBeString);
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(composeHeaderView:isAddressTextFieldTobeEmpty:)]) {
        [self.delegate composeHeaderView:self isAddressTextFieldTobeEmpty:tobeEmpty];
    }
}

- (void)addressFlowEditView:(ZGMailAddressFlowEditView *)addressFlowEditView textFieldNextButtonPressed:(NSString *)text {
//    HikContactsInfoRecord *record = [[HikContactsInfoRecord alloc] init];
//    record.inmailAddress = text;
//    [self addAddressArrayToAddressEditView:@[record]];
}

- (void)addressFlowEditView:(ZGMailAddressFlowEditView *)addressFlowEditView heightWillChange:(float)height {
    switch (addressFlowEditView.type) {
        case MailAddressFlowEditViewTypeRecipient:
        {
            self.recipientAddressEditViewConstraintHeight.offset = height;
        }
            break;
        case MailAddressFlowEditViewTypeCC:
        {
            self.ccAddressEditViewConstraintHeight.offset = height;
        }
            break;
        case MailAddressFlowEditViewTypeBCC:
        {
            self.bccAddressEditViewConstraintHeight.offset = height;
        }
            break;
        default:
            break;
    }
    
    [UIView animateWithDuration:0.25 animations:^{
        [self.superview layoutIfNeeded];
    }];
}

/**
 *  联系人编辑视图，添加联系人按钮点击
 *
 *  @param addressFlowEditView  地址编辑视图
 *  @param button               联系人按钮
 */
- (void)addressFlowEditView:(ZGMailAddressFlowEditView *)addressFlowEditView addContactsButtonPressed:(ZGMailAddressButton *)button {
    if (addressFlowEditView.type == MailAddressFlowEditViewTypeCC || addressFlowEditView.type == MailAddressFlowEditViewTypeBCC) {
        self.isCCOrBCCAddButtonPressed = YES;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(composeHeaderView:addContactsButtonPressed:)]) {
        [self.delegate composeHeaderView:self addContactsButtonPressed:button];
    }
}

/**
 *  联系人编辑视图，添加联系人按钮点击
 *
 *  @param addressFlowEditView  联系人编辑视图
 *  @param button               添加联系人按钮
 */
- (void)addressFlowEditView:(ZGMailAddressFlowEditView *)addressFlowEditView deleteAddressButton:(ZGMailAddressButton *)button {
    
    switch (addressFlowEditView.type) {
        case MailAddressFlowEditViewTypeRecipient:
        {
            [self.recipientAddressDic removeObjectForKey:button.address.mailbox];
            [self.recipientAddressArray removeObject:button.address];
        }
            break;
        case MailAddressFlowEditViewTypeCC:
        {
            [self.ccAddressDic removeObjectForKey:button.address.mailbox];
            [self.ccAddressArray removeObject:button.address];
        }
            break;
        case MailAddressFlowEditViewTypeBCC:
        {
            [self.bccAddressDic removeObjectForKey:button.address.mailbox];
            [self.bccAddressArray removeObject:button.address];
        }
            break;
        default:
            break;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(composeHeaderView:deleteAddressButton:)]) {
        [self.delegate composeHeaderView:self deleteAddressButton:button];
    }
}

#pragma mark - public method

- (void)addAddressArrayToAddressEditView:(NSArray *)array {
    switch (self.editViewType) {
        case MailAddressFlowEditViewTypeRecipient:
        {
            NSArray *tempArray = [self addRecipientAddressArray:array];
            [self.recipientAddressEditView addAddressArray:tempArray];
        }
            break;
        case MailAddressFlowEditViewTypeCC:
        {
            NSArray *tempArray = [self addCCAddressArray:array];
            [self.ccAddressEditView addAddressArray:tempArray];
        }
            break;
        case MailAddressFlowEditViewTypeBCC:
        {
            NSArray *tempArray = [self addBccAddressArray:array];
            [self.bccAddressEditView addAddressArray:tempArray];
        }
            break;
        default:
            break;
    }
}

/**
 *  设置附件个数
 *
 *  @param attachmentNumber 附件个数
 */
- (void)setAttachmentNumber:(NSInteger)attachmentNumber {
    [self.subjectEditView setAttachmentNumber:attachmentNumber];
}

/**
 *  设置主题
 *
 *  @param subjectStr   主题
 */
- (void)setSubject:(NSString *)subjectStr {
    [self.subjectEditView setSubject:subjectStr];
}

#pragma mark - IBAction 

- (IBAction)senderButtonPressed:(id)sender {
    //展示抄送和密送视图
    [self showCCAndBCCAddressEditView];
    
    [self.ccAddressEditView becomeFirstResponder];
}

/**
 *  键盘即将隐藏
 */
- (void)willHideKeyboard:(NSNotification *)notification {
    //隐藏抄送和密送视图
    [self hideCCAndBCCAddressEditView];
//    //隐藏完整的地址编辑视图
//    [self hideWholeAddressFlowEditView];
}

#pragma mark - private method

- (void)layoutViewSubviews {
    [self.recipientAddressEditView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(self);
        make.centerX.mas_equalTo(self);
        make.top.mas_equalTo(self);
        self.recipientAddressEditViewConstraintHeight = make.height.mas_equalTo(48);
    }];
    
    [self.ccAddressEditView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(self);
        make.centerX.mas_equalTo(self);
        make.top.mas_equalTo(self.recipientAddressEditView.mas_bottom);
        make.bottom.mas_equalTo(self.bccAddressEditView.mas_top);
        self.ccAddressEditViewConstraintHeight = make.height.mas_equalTo(48);
    }];
    
    [self.bccAddressEditView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(self);
        make.centerX.mas_equalTo(self);
        make.top.mas_equalTo(self.ccAddressEditView.mas_bottom);
        self.bccAddressEditViewConstraintBottom = make.bottom.mas_equalTo(self.mas_bottom).offset(0);
        self.bccAddressEditViewConstraintHeight = make.height.mas_equalTo(48);
    }];
    
    [self.senderButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(self);
        make.centerX.mas_equalTo(self);
        self.senderButtonConstraintTop = make.top.mas_equalTo(self.recipientAddressEditView.mas_bottom).offset(0);
        make.height.mas_equalTo(48);
    }];
    
    [self.subjectEditView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(self);
        make.centerX.mas_equalTo(self);
        make.height.mas_equalTo(48);
        make.bottom.mas_equalTo(self.mas_bottom);
    }];
}

/**
 *  展示抄送和密送视图
 */
- (void)showCCAndBCCAddressEditView {
    self.senderButtonConstraintTop.offset = self.ccAddressEditView.height;
    self.ccAddressEditView.hidden = NO;
    self.bccAddressEditView.hidden = NO;
    self.bccAddressEditViewConstraintBottom.offset = -48;

    [UIView animateWithDuration:0.25 animations:^{
        //需要用self.superview动画才起作用
        [self.superview layoutIfNeeded];
        
        self.ccAddressEditView.alpha = 1;
        self.bccAddressEditView.alpha = 1;
        self.senderButton.alpha = 0;
    } completion:^(BOOL finished) {
        self.senderButton.hidden = YES;
    }];
}

/**
 *  隐藏抄送和密送视图
 */
- (void)hideCCAndBCCAddressEditView {
    //如果抄送、密送都为空，则隐藏这两个输入框，展示抄送/密送 按钮
    if (([self.ccAddressEditView isAddressFlowEditViewEmpty] && self.ccAddressArray.count == 0) && ([self.bccAddressEditView isAddressFlowEditViewEmpty] && self.bccAddressArray.count == 0) && self.senderButton.hidden) {
        self.senderButton.hidden = NO;
        self.senderButtonConstraintTop.offset = 0;

        self.bccAddressEditViewConstraintBottom.offset = 0;

        [UIView animateWithDuration:0.25 animations:^{
            //需要用self.superview动画才起作用
            [self.superview layoutIfNeeded];
            
            self.ccAddressEditView.alpha = 0;
            self.bccAddressEditView.alpha = 0;
            self.senderButton.alpha = 1;
        } completion:^(BOOL finished) {
            self.ccAddressEditView.hidden = YES;
            self.bccAddressEditView.hidden = YES;
        }];
    } else {//输入框内容按钮化，前一个地址按钮显示顿号
        
    }
}

- (void)showWholeAddressFlowEditView {
    //收件人
    float recipientViewHeight = [self.recipientAddressEditView heightOfAddressFlowEditView];
    if (!self.recipientAddressEditView.isShowWholeEditView) {
        [self.recipientAddressEditView showWholeAddressFlowEditView];
        self.recipientAddressEditViewConstraintHeight.offset = recipientViewHeight;
    }
    if (self.recipientAddressArray.count > 0 && self.recipientAddressEditView.isAddressFlowEditViewEmpty) {
        //如果有收件人信息，但是收件人编辑视图为空，则添加收件人信息到收件人编辑视图
        [self.recipientAddressEditView addAddressArray:self.recipientAddressArray];
    }
    
    //抄送
    float ccViewHeight = [self.ccAddressEditView heightOfAddressFlowEditView];
    if (!self.ccAddressEditView.isShowWholeEditView) {
        [self.ccAddressEditView showWholeAddressFlowEditView];
        self.ccAddressEditViewConstraintHeight.offset = ccViewHeight;
    }
    if (self.ccAddressArray.count > 0 && self.ccAddressEditView.isAddressFlowEditViewEmpty) {
        [self.ccAddressEditView addAddressArray:self.ccAddressArray];
    }

    //密送
    float bccViewHeight = [self.bccAddressEditView heightOfAddressFlowEditView];
    if (!self.bccAddressEditView.isShowWholeEditView) {
        [self.bccAddressEditView showWholeAddressFlowEditView];
        self.bccAddressEditViewConstraintHeight.offset = bccViewHeight;
    }
    if (self.bccAddressArray.count > 0 && self.bccAddressEditView.isAddressFlowEditViewEmpty) {
        [self.bccAddressEditView addAddressArray:self.bccAddressArray];
    }
    
    if (recipientViewHeight > 48 || ccViewHeight > 48 || bccViewHeight > 48) {
        [UIView animateWithDuration:0.25 animations:^{
            [self.superview layoutIfNeeded];
        }];
    } else {
    }
}

- (void)hideWholeAddressFlowEditView {
    if (!self.recipientAddressEditView.isAddressFlowEditViewEmpty) {
        [self.recipientAddressEditView hideWholeAddressFlowEditView];
        self.recipientAddressEditViewConstraintHeight.offset = 48;
    }
    
    if (!self.ccAddressEditView.isAddressFlowEditViewEmpty) {
        [self.ccAddressEditView hideWholeAddressFlowEditView];
        self.ccAddressEditViewConstraintHeight.offset = 48;
    }
    
    if (!self.bccAddressEditView.isAddressFlowEditViewEmpty) {
        [self.bccAddressEditView hideWholeAddressFlowEditView];
        self.bccAddressEditViewConstraintHeight.offset = 48;
    }
    [UIView animateWithDuration:0.25 animations:^{
        [self.superview layoutIfNeeded];
    }];
}

/**
 *  添加收件人地址数组
 *
 *  @param array    收件人地址数组
 */
- (NSArray *)addRecipientAddressArray:(NSArray *)array {
    //去重
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    [array enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL * _Nonnull stop) {
//        if ([object isKindOfClass:[HikContactsInfoRecord class]]) {
//            HikContactsInfoRecord *record = (HikContactsInfoRecord *)object;
//            if (![[self.recipientAddressDic allKeys] containsObject:record.inmailAddress]) {
//                //                    [tempArray addObject:record];
//                MCOAddress *address = [MCOAddress addressWithDisplayName:record.commonName mailbox:record.inmailAddress];
//                [tempArray addObject:address];
//            }
//            [self.recipientAddressDic setValue:@"1" forKey:record.inmailAddress];
//        } else  if ([object isKindOfClass:[MCOAddress class]]) {
            MCOAddress *address = (MCOAddress *)object;
            if (![[self.recipientAddressDic allKeys] containsObject:address.mailbox]) {
                [tempArray addObject:address];
            }
            [self.recipientAddressDic setValue:@"1" forKey:address.mailbox];
//        }
    }];
    
    [self.recipientAddressArray addObjectsFromArray:tempArray];
    
    return tempArray;
}

/**
 *  添加抄送地址数组
 *
 *  @param array    抄送地址数组
 */
- (NSArray *)addCCAddressArray:(NSArray *)array {
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    [array enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL * _Nonnull stop) {
//        if ([object isKindOfClass:[HikContactsInfoRecord class]]) {
//            HikContactsInfoRecord *record = (HikContactsInfoRecord *)object;
//            if (![[self.ccAddressDic allKeys] containsObject:record.inmailAddress]) {
//                //                    [tempArray addObject:record];
//                MCOAddress *address = [MCOAddress addressWithDisplayName:record.commonName mailbox:record.inmailAddress];
//                [tempArray addObject:address];
//            }
//            [self.ccAddressDic setValue:@"1" forKey:record.inmailAddress];
//        } else  if ([object isKindOfClass:[MCOAddress class]]) {
            MCOAddress *address = (MCOAddress *)object;
            if (![[self.ccAddressDic allKeys] containsObject:address.mailbox]) {
                [tempArray addObject:address];
            }
            [self.ccAddressDic setValue:@"1" forKey:address.mailbox];
//        }
    }];
    [self.ccAddressArray addObjectsFromArray:tempArray];

    return tempArray;
}

/**
 *  添加密送地址数组
 *
 *  @param array    密送地址数组
 */
- (NSArray *)addBccAddressArray:(NSArray *)array {
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    [array enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL * _Nonnull stop) {
//        if ([object isKindOfClass:[HikContactsInfoRecord class]]) {
//            HikContactsInfoRecord *record = (HikContactsInfoRecord *)object;
//            if (![[self.bccAddressDic allKeys] containsObject:record.inmailAddress]) {
//                //                    [tempArray addObject:record];
//                MCOAddress *address = [MCOAddress addressWithDisplayName:record.commonName mailbox:record.inmailAddress];
//                [tempArray addObject:address];
//            }
//            [self.bccAddressDic setValue:@"1" forKey:record.inmailAddress];
//        } else  if ([object isKindOfClass:[MCOAddress class]]) {
            MCOAddress *address = (MCOAddress *)object;
            if (![[self.bccAddressDic allKeys] containsObject:address.mailbox]) {
                [tempArray addObject:address];
            }
            [self.bccAddressDic setValue:@"1" forKey:address.mailbox];
//        }
    }];
    [self.bccAddressArray addObjectsFromArray:tempArray];
    
    return tempArray;
}

#pragma mark - setter and getter

- (void)setHeader:(MCOMessageHeader *)header {
    tempHeader = header;
    
    [self addRecipientAddressArray:header.to];
    [self addCCAddressArray:header.cc];
    [self addBccAddressArray:header.bcc];
    
    [self.recipientAddressEditView showTruncateContactsViewWithArray:header.to];
    [self.ccAddressEditView showTruncateContactsViewWithArray:header.cc];
    [self.bccAddressEditView showTruncateContactsViewWithArray:header.bcc];

    if (header.cc.count > 0 || header.bcc.count > 0) {
        [self showCCAndBCCAddressEditView];
    }
    [self setSubject:header.subject];
}

- (MCOMessageHeader *)header {
//    HikContactsInfoRecord *accountInfoRecord = [HikAccountInfoManager sharedInstance].accountInfoRecord;
    MCOAddress *sender = [MCOAddress addressWithDisplayName:@"" mailbox:@""];
    if (tempHeader) {
        [tempHeader setSender:sender];//发件人
        [tempHeader setFrom:sender];//
        [tempHeader setTo:self.recipientAddressArray];//收件人
        [tempHeader setCc:self.ccAddressArray];//抄送
        [tempHeader setBcc:self.bccAddressArray];//密送
        [tempHeader setSubject:[self.subjectEditView mailSubject]];//主题
    } else {
        tempHeader = [[MCOMessageHeader alloc] init];
        [tempHeader setSender:sender];//发件人
        [tempHeader setFrom:sender];//
        [tempHeader setTo:self.recipientAddressArray];//收件人
        [tempHeader setCc:self.ccAddressArray];//抄送
        [tempHeader setBcc:self.bccAddressArray];//密送
        [tempHeader setSubject:[self.subjectEditView mailSubject]];//主题
    }
    
    return tempHeader;
}

- (ZGMailAddressFlowEditView *)recipientAddressEditView {
    if (_recipientAddressEditView == nil) {
        _recipientAddressEditView = [[ZGMailAddressFlowEditView alloc] init];
        _recipientAddressEditView.title = @"收件人：";
        _recipientAddressEditView.type = MailAddressFlowEditViewTypeRecipient;
        _recipientAddressEditView.delegate = self;
    }
    
    return _recipientAddressEditView;
}

- (ZGMailAddressFlowEditView *)ccAddressEditView {
    if (_ccAddressEditView == nil) {
        _ccAddressEditView = [[ZGMailAddressFlowEditView alloc] init];
        _ccAddressEditView.title = @"抄送：";
        _ccAddressEditView.type = MailAddressFlowEditViewTypeCC;
        _ccAddressEditView.delegate = self;
        
        _ccAddressEditView.alpha = 0;
        _ccAddressEditView.hidden = YES;
    }
    
    return _ccAddressEditView;
}

- (ZGMailAddressFlowEditView *)bccAddressEditView {
    if (_bccAddressEditView == nil) {
        _bccAddressEditView = [[ZGMailAddressFlowEditView alloc] init];
        _bccAddressEditView.title = @"密送：";
        _bccAddressEditView.type = MailAddressFlowEditViewTypeBCC;
        _bccAddressEditView.delegate = self;
        
        _bccAddressEditView.alpha = 0;
        _bccAddressEditView.hidden = YES;
    }
    
    return _bccAddressEditView;
}

- (ZGSenderButton *)senderButton {
    if (_senderButton == nil) {
        _senderButton = [ZGSenderButton buttonWithType:UIButtonTypeCustom];
        _senderButton.backgroundColor = [UIColor clearColor];
        [_senderButton setTitleColor:[UIColor colorWithHexString:@"969696" alpha:1.0f] forState:UIControlStateNormal];
        _senderButton.titleLabel.font = [UIFont systemFontOfSize:17.0f];
        _senderButton.titleLabel.textAlignment = NSTextAlignmentLeft;
        [_senderButton setTitle:@"抄送/密送" forState:UIControlStateNormal];
        
        [_senderButton addTarget:self action:@selector(senderButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _senderButton;
}

- (ZGSubjectEditView *)subjectEditView {
    if (_subjectEditView == nil) {
        _subjectEditView = [[ZGSubjectEditView alloc] init];
        _subjectEditView.delegate = self;
    }
    
    return _subjectEditView;
}

- (NSMutableArray *)recipientAddressArray {
    if (_recipientAddressArray == nil) {
        _recipientAddressArray = [[NSMutableArray alloc] init];
    }
    
    return _recipientAddressArray;
}

- (NSMutableDictionary *)recipientAddressDic {
    if (_recipientAddressDic == nil) {
        _recipientAddressDic = [[NSMutableDictionary alloc] init];
    }
    
    return _recipientAddressDic;
}

- (NSMutableArray *)ccAddressArray {
    if (_ccAddressArray == nil) {
        _ccAddressArray = [[NSMutableArray alloc] init];
    }
    
    return _ccAddressArray;
}

- (NSMutableDictionary *)ccAddressDic {
    if (_ccAddressDic == nil) {
        _ccAddressDic = [[NSMutableDictionary alloc] init];
    }
    
    return _ccAddressDic;
}

- (NSMutableArray *)bccAddressArray {
    if (_bccAddressArray == nil) {
        _bccAddressArray = [[NSMutableArray alloc] init];
    }
    
    return _bccAddressArray;
}

- (NSMutableDictionary *)bccAddressDic {
    if (_bccAddressDic == nil) {
        _bccAddressDic = [[NSMutableDictionary alloc] init];
    }
    
    return _bccAddressDic;
}

@end
