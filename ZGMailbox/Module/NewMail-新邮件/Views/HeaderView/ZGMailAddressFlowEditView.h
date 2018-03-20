//
//  ZGMailAddressFlowEditView.h
//  ZGMailbox
//
//  Created by zzg on 2017/4/21.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ZGMailAddressFlowEditViewDelegate;
@class ZGMailAddressButton;

typedef NS_ENUM(NSUInteger, MailAddressFlowEditViewType) {
    MailAddressFlowEditViewTypeNone,
    MailAddressFlowEditViewTypeRecipient,//收件人
    MailAddressFlowEditViewTypeCC,//抄送
    MailAddressFlowEditViewTypeBCC//密送
};

/**
 *  邮件地址流式布局编辑视图
 */
@interface ZGMailAddressFlowEditView : UIView

@property (nonatomic, strong) NSString *title;
@property (nonatomic, assign) MailAddressFlowEditViewType type;
@property (nonatomic, assign) BOOL isShowWholeEditView;

@property (nonatomic, weak) id<ZGMailAddressFlowEditViewDelegate> delegate;

//添加地址数组
- (void)addAddressArray:(NSArray *)addressArray;

/**
 *  返回地址编辑视图的高度
 */
- (float)heightOfAddressFlowEditView;

/**
 *  判断地址编辑视图是否为空
 */
- (BOOL)isAddressFlowEditViewEmpty;

/**
 *  隐藏完整的地址编辑视图，展示联系人label
 */
- (void)hideWholeAddressFlowEditView;

/**
 *  展示截断的联系人信息
 */
- (void)showTruncateContactsViewWithArray:(NSArray *)array;

/**
 *  展示完整的地址编辑视图
 */
- (void)showWholeAddressFlowEditView;

@end

@protocol ZGMailAddressFlowEditViewDelegate <NSObject>

/**
 *  地址编辑视图开始编辑
 */
- (void)addressFlowEditViewBeginEditing:(ZGMailAddressFlowEditView *)addressFlowEditView;

/**
 *  地址编辑视图结束编辑
 */
- (void)addressFlowEditViewEndEditing:(ZGMailAddressFlowEditView *)addressFlowEditView;

/**
 *  地址输入框输入
 */
- (void)addressFlowEditView:(ZGMailAddressFlowEditView *)addressFlowEditView textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;

/**
 *  键盘“下一项”点击
 */
- (void)addressFlowEditView:(ZGMailAddressFlowEditView *)addressFlowEditView textFieldNextButtonPressed:(NSString *)text;

/**
 *  地址编辑视图高度即将变化
 */
- (void)addressFlowEditView:(ZGMailAddressFlowEditView *)addressFlowEditView heightWillChange:(float)height;

/**
 *  联系人编辑视图，添加联系人按钮点击
 */
- (void)addressFlowEditView:(ZGMailAddressFlowEditView *)addressFlowEditView addContactsButtonPressed:(ZGMailAddressButton *)button;

/**
 *  联系人编辑视图，添加联系人按钮点击
 */
- (void)addressFlowEditView:(ZGMailAddressFlowEditView *)addressFlowEditView deleteAddressButton:(ZGMailAddressButton *)button;

@end
