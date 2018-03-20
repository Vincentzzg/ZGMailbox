//
//  ZGMailAddressFlowEditView.m
//  ZGMailbox
//
//  Created by zzg on 2017/4/21.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import "ZGMailAddressFlowEditView.h"

//custom views
#import "ZGMailAddressButton.h"
#import "ZGMailAddressTextField.h"

//流式布局
#import <MyLayout/MyLayout.h>

//地址
#import <MailCore/MCOAddress.h>


@interface ZGMailAddressFlowEditView () <UITextFieldDelegate, ZGMailAddressTextFieldDelegate>

@property (nonatomic, strong) UILabel *titleLabel;//标题
@property (nonatomic, strong) UIView *truncateContactsShowView;//截短的联系人展示视图
@property (nonatomic, strong) UILabel *contactsLabel;//联系人展示
@property (nonatomic, strong) UILabel *contactsSupplementLabel;//联系人展示补充label

@property (nonatomic, strong) MyFlowLayout *flowLayoutView;//联系人地址按钮流式布局
@property (nonatomic, strong) ZGMailAddressTextField *mailAddressTextField;//联系人地址输入textField

@property (nonatomic, strong) UIButton *addContactsButton;//添加按钮
@property (nonatomic, strong) UIView *separatorView;//分割线

@property (nonatomic, strong) ZGMailAddressButton *selectedAddressButton;//选中的地址按钮

@property (nonatomic, strong) MASConstraint *contactsSupplementLabelWidthConstraint;
@property (nonatomic, strong) MASConstraint *flowLayoutHeightConstraint;
@property (nonatomic, strong) MASConstraint *titleLabelWidthConstraint;

@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;//触摸手势

@property (nonatomic, copy) NSMutableArray *contactsArray;//缓存联系人数据，用作阶段展示1、2、3、

@end

@implementation ZGMailAddressFlowEditView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.titleLabel];
        [self addSubview:self.truncateContactsShowView];
        [self.truncateContactsShowView addSubview:self.contactsLabel];
        [self.truncateContactsShowView addSubview:self.contactsSupplementLabel];
        
        [self addSubview:self.flowLayoutView];
        [self addSubview:self.addContactsButton];
        [self addSubview:self.separatorView];
        
        self.mailAddressTextField.widthSize.equalTo(self.flowLayoutView.widthSize);
        self.mailAddressTextField.heightSize.equalTo(@22);
        [self.flowLayoutView addSubview:self.mailAddressTextField];
        [self.flowLayoutView layoutIfNeeded];

        [self layoutViewSubviews];
        
        self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didRecognizeTapGesture:)];
        self.tapGesture.numberOfTapsRequired = 1;
        [self addGestureRecognizer:self.tapGesture];
        
        self.isShowWholeEditView = NO;
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect frame = [self.title boundingRectWithSize:CGSizeZero options:NSStringDrawingUsesLineFragmentOrigin attributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:17.0f], NSFontAttributeName, nil] context:nil];
    self.titleLabelWidthConstraint.offset = frame.size.width;
    self.titleLabel.text = self.title;
}

- (BOOL)becomeFirstResponder {
    [super becomeFirstResponder];
    
    return [self.mailAddressTextField becomeFirstResponder];
}

- (BOOL)isFirstResponder {
    [super isFirstResponder];
    
    return self.mailAddressTextField.isFirstResponder;
}

- (BOOL)resignFirstResponder {
    [super resignFirstResponder];
    
    return [self.mailAddressTextField resignFirstResponder];
}

- (void)dealloc {
    [self removeGestureRecognizer:self.tapGesture];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (self.addContactsButton.hidden) {
        self.addContactsButton.hidden = NO;
    }
    [self.mailAddressTextField showCursor];
    if (self.delegate && [self.delegate respondsToSelector:@selector(addressFlowEditViewBeginEditing:)]) {
        [self.delegate addressFlowEditViewBeginEditing:self];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    //反选上一个选中的地址button
    [self deselectLastselectedAddressButton];
    
    //隐藏添加联系人按钮
    self.addContactsButton.hidden = YES;
    //代理
    if (self.delegate && [self.delegate respondsToSelector:@selector(addressFlowEditViewEndEditing:)]) {
        [self.delegate addressFlowEditViewEndEditing:self];
    }
    
    //把输入框里的内容，添加一个地址按钮
    if (textField.text.length > 0) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(addressFlowEditView:textFieldNextButtonPressed:)]) {
//            //没有后缀的补上后缀
//            if (![textField.text containsString:MailAddressSuffix]) {
//                textField.text = [textField.text stringByAppendingString:MailAddressSuffix];
//            }
            
            [self.delegate addressFlowEditView:self textFieldNextButtonPressed:textField.text];
        }
        //清空输入框
        textField.text = @"";
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([string isEqualToString:@"\n"]) {//下一项（回车按钮类型已被改为UIReturnKeyNext）
//        [textField resignFirstResponder];
        //把输入框里的内容，添加一个地址按钮
        if (textField.text.length > 0) {
            NSString *text = textField.text;
            //清空输入框
            textField.text = @"";
            if (self.delegate && [self.delegate respondsToSelector:@selector(addressFlowEditView:textFieldNextButtonPressed:)]) {
//                //没有后缀的补上后缀
//                if (![text containsString:MailAddressSuffix]) {
//                    text = [text stringByAppendingString:MailAddressSuffix];
//                }
                
                [self.delegate addressFlowEditView:self textFieldNextButtonPressed:text];
            }
        }
        
        return NO;
    } else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(addressFlowEditView:textField:shouldChangeCharactersInRange:replacementString:)]) {
            [self.delegate addressFlowEditView:self textField:textField shouldChangeCharactersInRange:range replacementString:string];
        }
        
        if (IsEmptyString(string)) {//删除输入框里的内容
//            //整体删除输入框内容邮箱地址后缀
//            NSString *text = self.mailAddressTextField.text;
//            if (self.mailAddressTextField.text.length > 17 && [text hasSuffix:MailAddressSuffix]) {//末尾是邮件后缀
//                self.mailAddressTextField.text = [text substringToIndex:text.length - 17];
//                
//                return NO;
//            } else {
//                //末尾不是邮件后缀，不处理
//            }
        } else {
            //不是删除按钮点击，不处理
            //显示光标
            [self.mailAddressTextField showCursor];
            //反选上一个选中的地址button
            [self deselectLastselectedAddressButton];
//            //自动补全邮件地址
//            if ([string isEqualToString:@"@"] && ![textField.text containsString:MailAddressSuffix]) {
//                textField.text = [textField.text stringByAppendingString:MailAddressSuffix];
//
//                return NO;
//            } else {
//
//            }
        }
        
        return YES;
    }
}

#pragma mark - ZGMailAddressTextFieldDelegate

- (void)textFieldDidDelete {
    if ([self.mailAddressTextField.text length] > 0) {
        return;
    }
    
    if (self.selectedAddressButton) {//删除已选中的button
        ZGMailAddressButton *button = self.selectedAddressButton;
        //显示光标
        [self.mailAddressTextField showCursor];
        //移除button
        [self.selectedAddressButton removeFromSuperview];
        [self.flowLayoutView layoutIfNeeded];
        self.selectedAddressButton = nil;
        
        
        NSInteger count = [self.flowLayoutView.subviews count];
        if (count > 1) {//最后一个地址隐藏顿号
            //因为最后一个元素肯定是textField，所以去倒数第二个元素才是button
            //隐藏顿号
            ZGMailAddressButton *button = [self.flowLayoutView.subviews objectAtIndex:count - 2];
            [button hideCommaLabel];
        } else {
            //只有textField一个子视图
        }

        //删除联系人
        [self.contactsArray removeObject:button.currentTitle];
        
        //先回调，更新数据
        if (self.delegate && [self.delegate respondsToSelector:@selector(addressFlowEditView:deleteAddressButton:)]) {
            [self.delegate addressFlowEditView:self deleteAddressButton:button];
        }
        
        //更新textField位置
        [self updateMailAddressTextfieldLayout:self.mailAddressTextField.isFirstResponder];
    } else {//还没有地址button被选中，选中最后一个button
        NSInteger count = [self.flowLayoutView.subviews count];
        if (count > 1) {
            //因为最后一个元素是textField，所以去倒数第二个元素才是最后一个button
            ZGMailAddressButton *button = [self.flowLayoutView.subviews objectAtIndex:count - 2];//
            self.selectedAddressButton = button;
            self.selectedAddressButton.selected = YES;
            [self.selectedAddressButton hideCommaLabel];
        
            //隐藏光标
            [self.mailAddressTextField hideCuresor];
        } else {
            //只有textField一个子视图
        }
    }
}

- (void)mailAddressTextField:(ZGMailAddressTextField *)textField didRecognizeTapGesture:(UITapGestureRecognizer *)gesture {
    //显示光标
    [self.mailAddressTextField showCursor];
    //反选上一个选中的地址button
    [self deselectLastselectedAddressButton];
}

#pragma mark - public method

/**
 *  展示截断的联系人信息
 */
- (void)showTruncateContactsViewWithArray:(NSArray *)array {
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    [array enumerateObjectsUsingBlock:^(MCOAddress *address, NSUInteger idx, BOOL * _Nonnull stop) {
        //缓存联系人数据
        if (IsEmptyString(address.displayName)) {//名字为空，就存储邮箱地址
            [tempArray addObject:address.mailbox];
        } else {
            [tempArray addObject:address.displayName];
        }
    }];
    
    self.isShowWholeEditView = NO;
    NSString *contactsStr = [tempArray componentsJoinedByString:@"、"];
    CGRect frame = [contactsStr boundingRectWithSize:CGSizeMake(1000, 22) options:NSStringDrawingUsesLineFragmentOrigin attributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:17.0f], NSFontAttributeName, nil] context:nil];
    contactsStr = [contactsStr stringByReplacingOccurrencesOfString:@"%" withString:@"/"];
    self.contactsLabel.text = contactsStr;
    
    CGRect titleLabelFrame = [self.title boundingRectWithSize:CGSizeZero options:NSStringDrawingUsesLineFragmentOrigin attributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:17.0f], NSFontAttributeName, nil] context:nil];
    float truncateContactsShowViewMaxWidth = ScreenWidth - 15 - titleLabelFrame.size.width - 5 - 15;
    if (frame.size.width > truncateContactsShowViewMaxWidth) {//显示不全
        NSString *supplementStr = [NSString stringWithFormat:@"等%lu人", (unsigned long)tempArray.count];
        CGRect supplementFrame = [supplementStr boundingRectWithSize:CGSizeMake(100, 22) options:NSStringDrawingUsesLineFragmentOrigin attributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:17.0f], NSFontAttributeName, nil] context:nil];
        self.contactsSupplementLabelWidthConstraint.offset = supplementFrame.size.width;
        self.contactsSupplementLabel.text = supplementStr;
    } else {
        self.contactsSupplementLabel.text = @"";
        self.contactsSupplementLabelWidthConstraint.offset = 0;
    }
    
    self.truncateContactsShowView.hidden = NO;
    self.flowLayoutView.alpha = 0;
    self.mailAddressTextField.alpha = 0;
    self.truncateContactsShowView.alpha = 1;
    self.flowLayoutView.hidden = YES;
    self.mailAddressTextField.hidden = YES;
}

- (float)heightOfAddressFlowEditView {
    return [self heightOfFlowLayoutView] + 26;
}

- (void)addAddressArray:(NSArray *)addressArray {
    //保存原来的状态，用来恢复状态
    BOOL isFirstResponder = self.mailAddressTextField.isFirstResponder;
    [self.mailAddressTextField removeFromSuperview];
    [self.flowLayoutView layoutIfNeeded];
    
    __block ZGMailAddressButton *lastButton;
    NSInteger count = [self.flowLayoutView.subviews count];
    if (count > 0) {//textField已删除，count > 0,至少有一个地址按钮
        //添加更多的按钮，之前最后一个按钮显示顿号
        if ([[self.flowLayoutView.subviews lastObject] isKindOfClass:[ZGMailAddressButton class]]) {
            lastButton = [self.flowLayoutView.subviews lastObject];
            [lastButton showCommaLabel];
        }
    } else {
        //还没有地址按钮，不做操作
    }
    
    [addressArray enumerateObjectsUsingBlock:^(MCOAddress *address, NSUInteger idx, BOOL * _Nonnull stop) {
        ZGMailAddressButton *button = [ZGMailAddressButton buttonWithType:UIButtonTypeCustom];
        if (IsEmptyString(address.displayName)) {
            [button setTitle:[address.mailbox stringByReplacingOccurrencesOfString:@"%" withString:@"/"] forState:UIControlStateNormal];
        } else {
            [button setTitle:[address.displayName stringByReplacingOccurrencesOfString:@"%" withString:@"/" ] forState:UIControlStateNormal];
        }
        button.address = address;
        //这里可以看到尺寸宽度等于自己的尺寸宽度并且再增加10，且最小是40，意思是按钮的宽度是等于自身内容的宽度再加10，但最小的宽度是40
        button.widthSize.equalTo(button.widthSize).add(14).min(40);
        button.myHeight = 22;
        [button sizeToFit];
        [button addTarget:self action:@selector(addressButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.flowLayoutView addSubview:button];
        lastButton = button;
        
        //缓存联系人数据
        if (IsEmptyString(address.displayName)) {//名字为空，就存储邮箱地址
            [self.contactsArray addObject:address.mailbox];
        } else {
            [self.contactsArray addObject:address.displayName];
        }
    }];
    [self.flowLayoutView addSubview:self.mailAddressTextField];
    [self.flowLayoutView layoutIfNeeded];
    //最后一个不展示顿号
    [lastButton hideCommaLabel];
    
    //显示光标
    [self.mailAddressTextField showCursor];
    //反选上一个选中的地址button
    [self deselectLastselectedAddressButton];
    
    [self updateMailAddressTextfieldLayout:isFirstResponder];
}

- (BOOL)isAddressFlowEditViewEmpty {
    if ([self.flowLayoutView.subviews count] == 1 && IsEmptyString(self.mailAddressTextField.text)) {
        return YES;
    } else {
        return NO;
    }
}

/**
 *  隐藏完整的地址编辑视图，展示联系人label
 */
- (void)hideWholeAddressFlowEditView {
    self.isShowWholeEditView = NO;

    NSString *contactsStr = [self.contactsArray componentsJoinedByString:@"、"];
    CGRect frame = [contactsStr boundingRectWithSize:CGSizeMake(1000, 22) options:NSStringDrawingUsesLineFragmentOrigin attributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:17.0f], NSFontAttributeName, nil] context:nil];
    contactsStr = [contactsStr stringByReplacingOccurrencesOfString:@"%" withString:@"/"];
    self.contactsLabel.text = contactsStr;
    if (frame.size.width > self.contactsLabel.width) {//显示不全
        NSString *supplementStr = [NSString stringWithFormat:@"等%lu人", (unsigned long)self.contactsArray.count];
        CGRect supplementFrame = [supplementStr boundingRectWithSize:CGSizeMake(100, 22) options:NSStringDrawingUsesLineFragmentOrigin attributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:17.0f], NSFontAttributeName, nil] context:nil];
        self.contactsSupplementLabelWidthConstraint.offset = supplementFrame.size.width;
        self.contactsSupplementLabel.text = supplementStr;
    } else {
        self.contactsSupplementLabelWidthConstraint.offset = 0;
        self.contactsSupplementLabel.text = @"";
    }
    
    self.truncateContactsShowView.hidden = NO;
    [UIView animateWithDuration:0.25 animations:^{
        self.flowLayoutView.alpha = 0;
        self.mailAddressTextField.alpha = 0;
        self.truncateContactsShowView.alpha = 1;
    } completion:^(BOOL finished) {
        self.flowLayoutView.hidden = YES;
        self.mailAddressTextField.hidden = YES;
    }];
}

/**
 *  展示完整的地址编辑视图
 */
- (void)showWholeAddressFlowEditView {
    self.isShowWholeEditView = YES;

    self.flowLayoutView.hidden = NO;
    self.mailAddressTextField.hidden = NO;
    [UIView animateWithDuration:0.25 animations:^{
        self.flowLayoutView.alpha = 1;
        self.mailAddressTextField.alpha = 1;
        self.truncateContactsShowView.alpha = 0;
    } completion:^(BOOL finished) {
        self.truncateContactsShowView.hidden = YES;
    }];
}

#pragma mark - IBAction

- (IBAction)addressButtonPressed:(ZGMailAddressButton *)sender {
    [self becomeFirstResponder];
    
    //反选上一个选中的地址button
    [self deselectLastselectedAddressButton];
    //隐藏光标
    [self.mailAddressTextField hideCuresor];

    //选中当前点击的地址button
    [sender setSelected:YES];
    [sender hideCommaLabel];
    
    self.selectedAddressButton = sender;
}

- (IBAction)addContactsButtonPressed:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(addressFlowEditView:addContactsButtonPressed:)]) {
        [self.delegate addressFlowEditView:self addContactsButtonPressed:sender];
    }
}

/**
 *  单击事件
 */
- (void)didRecognizeTapGesture:(UITapGestureRecognizer *)gesture {
//    //展示完整的地址编辑视图
//    [self showWholeAddressFlowEditView];
    
    [self.mailAddressTextField becomeFirstResponder];
    //反选上一个选中的地址button
    [self deselectLastselectedAddressButton];
    //显示光标
    [self.mailAddressTextField showCursor];
}

#pragma mark - private method

- (void)layoutViewSubviews {
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.mas_leading).offset(15);
        make.top.mas_equalTo(self.mas_top).offset(14);
        self.titleLabelWidthConstraint = make.width.mas_equalTo(0);
    }];
    
    [self.truncateContactsShowView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(22);
        make.top.mas_equalTo(self.mas_top).offset(13);
        make.leading.mas_equalTo(self.titleLabel.mas_trailing).offset(5);
        make.trailing.mas_equalTo(self.mas_trailing).offset(-15);
    }];
    
    [self.contactsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(self.truncateContactsShowView);
        make.centerY.mas_equalTo(self.truncateContactsShowView);
        make.leading.mas_equalTo(self.truncateContactsShowView);
        make.trailing.mas_equalTo(self.contactsSupplementLabel.mas_leading);
    }];
    
    [self.contactsSupplementLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(self.truncateContactsShowView);
        make.centerY.mas_equalTo(self.truncateContactsShowView);
        self.contactsSupplementLabelWidthConstraint = make.width.mas_equalTo(0);
        make.leading.mas_equalTo(self.contactsLabel.mas_trailing);
        make.trailing.mas_equalTo(self.truncateContactsShowView);
    }];
    
//    __block float height = [self heightOfFlowLayoutView];
    [self.flowLayoutView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.titleLabel.mas_trailing).offset(5);
        make.trailing.mas_equalTo(self.mas_trailing).offset(-50);
        make.top.mas_equalTo(self.mas_top).offset(13);
//        make.bottom.mas_equalTo(self.mas_bottom).offset(-13);
        self.flowLayoutHeightConstraint = make.height.mas_equalTo(22);//默认高度22
    }];
    
    [self.addContactsButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.mas_equalTo(self);
        make.bottom.mas_equalTo(self.mas_bottom).offset(-5);
        make.size.mas_equalTo(CGSizeMake(46, 40));
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

- (void)updateMailAddressTextfieldLayout:(BOOL)isFirstResponder {
//    if ([self.mailAddressTextField isDescendantOfView:self.flowLayoutView]) {
//        [self.mailAddressTextField removeFromSuperview];
//        [self.flowLayoutView layoutIfNeeded];
//    }
    
    //根据最后一个button的位置，设置textField的宽度
    NSInteger count = self.flowLayoutView.subviews.count;
    if (count > 1) {//前面有button
        ZGMailAddressButton *lastButton = [self.flowLayoutView.subviews objectAtIndex:count - 2];
        float width = self.flowLayoutView.width - (lastButton.origin.x + lastButton.size.width + 6);
        if (width < 40) {
            self.mailAddressTextField.widthSize.equalTo(self.flowLayoutView.widthSize);
        } else {
            self.mailAddressTextField.widthSize.equalTo(@(width));
        }
    } else {//只有textField
        self.mailAddressTextField.widthSize.equalTo(self.flowLayoutView.widthSize);
    }
    
//    [self.flowLayoutView addSubview:self.mailAddressTextField];
    [self.flowLayoutView layoutIfNeeded];

    float height = [self heightOfFlowLayoutView];
    //更新高度
    if (self.delegate && [self.delegate respondsToSelector:@selector(addressFlowEditView:heightWillChange:)]) {
        [self.delegate addressFlowEditView:self heightWillChange:height + 26];
    }
    self.flowLayoutHeightConstraint.offset = height;
    
    if (isFirstResponder) {
        [self.mailAddressTextField becomeFirstResponder];
    }
}

- (void)deselectLastselectedAddressButton {
    if (!self.selectedAddressButton) {
        return;
    }
    
    self.selectedAddressButton.selected = NO;
    
    //如果选中的是最后一个地址button就不需要展示顿号
    NSInteger count = [self.flowLayoutView.subviews count];
    if (count > 1) {
        //不是最后一个地址button，展示顿号
        ZGMailAddressButton *button = [self.flowLayoutView.subviews objectAtIndex:count - 2];
        if (self.selectedAddressButton != button) {
            [self.selectedAddressButton showCommaLabel];
        } else {//最后一个地址button，不展示顿号
            [self.selectedAddressButton hideCommaLabel];
        }
    } else {//只有输入视图，不处理
    }
    
    self.selectedAddressButton = nil;
}

- (float)heightOfFlowLayoutView {
    float flowLayoutViewHeight = self.mailAddressTextField.origin.y + self.mailAddressTextField.height;
    
    return flowLayoutViewHeight;
}

#pragma mark - setter and getter

- (UILabel *)titleLabel {
    if (_titleLabel == nil) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = [UIColor colorWithHexString:@"969696" alpha:1.0f];
        _titleLabel.font = [UIFont systemFontOfSize:17.0f];
    }
    
    return _titleLabel;
}

- (UIView *)truncateContactsShowView {
    if (_truncateContactsShowView == nil) {
        _truncateContactsShowView = [[UIView alloc] init];
        _truncateContactsShowView.hidden = YES;
        _truncateContactsShowView.alpha = 0;
    }
    
    return _truncateContactsShowView;
}

- (UILabel *)contactsLabel {
    if (_contactsLabel == nil) {
        _contactsLabel = [[UILabel alloc] init];
        _contactsLabel.textColor = [UIColor colorWithHexString:@"31353B" alpha:1.0f];
        _contactsLabel.font = [UIFont systemFontOfSize:17.0f];
    }
    
    return _contactsLabel;
}

- (UILabel *)contactsSupplementLabel {
    if (_contactsSupplementLabel == nil) {
        _contactsSupplementLabel = [[UILabel alloc] init];
        _contactsSupplementLabel.textColor = [UIColor colorWithHexString:@"31353B" alpha:1.0f];
        _contactsSupplementLabel.font = [UIFont systemFontOfSize:17.0f];
    }
    
    return _contactsSupplementLabel;
}

- (MyFlowLayout *)flowLayoutView {
    if (_flowLayoutView == nil) {
        _flowLayoutView = [MyFlowLayout flowLayoutWithOrientation:MyOrientation_Vert arrangedCount:0];
        _flowLayoutView.subviewHSpace = 6;
        _flowLayoutView.subviewVSpace = 6;
        _flowLayoutView.wrapContentHeight = YES;
    }
    
    return _flowLayoutView;
}

- (ZGMailAddressTextField *)mailAddressTextField {
    if (_mailAddressTextField == nil) {
        _mailAddressTextField = [[ZGMailAddressTextField alloc] init];
        _mailAddressTextField.font = [UIFont systemFontOfSize:17.0f];
        _mailAddressTextField.delegate = self;
        _mailAddressTextField.tintColor = [UIColor colorWithHexString:@"007AFF" alpha:1.0f];
        _mailAddressTextField.addressTextFieldDelegate = self;
        _mailAddressTextField.myHeight = 22;
        _mailAddressTextField.returnKeyType = UIReturnKeyNext;
        _mailAddressTextField.enablesReturnKeyAutomatically = YES;
        _mailAddressTextField.keyboardType = UIKeyboardTypeEmailAddress;
        _mailAddressTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;//关闭首字符大写
        _mailAddressTextField.autocorrectionType = UITextAutocorrectionTypeNo;//关闭自动纠错
        _mailAddressTextField.spellCheckingType = UITextSpellCheckingTypeNo;//关闭拼写检查
    }
    
    return _mailAddressTextField;
}

- (UIButton *)addContactsButton {
    if (_addContactsButton == nil) {
        _addContactsButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _addContactsButton.hidden = YES;
        [_addContactsButton setImage:[UIImage imageNamed:@"btn_add"] forState:UIControlStateNormal];
        [_addContactsButton setImage:[UIImage imageNamed:@"btn_add_highlighted"] forState:UIControlStateHighlighted];
        [_addContactsButton addTarget:self action:@selector(addContactsButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _addContactsButton;
}

- (UIView *)separatorView {
    if (_separatorView == nil) {
        _separatorView = [[UIView alloc] init];
        _separatorView.backgroundColor = [UIColor colorWithHexString:@"c8c8c8" alpha:1.0f];
    }
    
    return _separatorView;
}

- (NSMutableArray *)contactsArray {
    if (_contactsArray == nil) {
        _contactsArray = [[NSMutableArray alloc] init];
    }
    
    return _contactsArray;
}

@end
