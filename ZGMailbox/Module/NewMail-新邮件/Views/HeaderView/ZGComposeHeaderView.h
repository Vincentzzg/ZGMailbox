//
//  ZGComposeHeaderView.h
//  ZGMailbox
//
//  Created by zzg on 2017/4/19.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZGMailAddressFlowEditView.h"

@protocol ZGComposeHeaderViewDelegate;
@class ZGMailAddressButton;
@class MCOMessageHeader;

/**
 *  写邮件头部视图
 */
@interface ZGComposeHeaderView : UIView

@property (nonatomic, weak) id<ZGComposeHeaderViewDelegate> delegate;
@property (nonatomic, strong) MCOMessageHeader *header;
@property (nonatomic, assign) MailAddressFlowEditViewType editViewType;

- (void)headerViewBecomeFirstResponder;

- (void)headerViewResignFirstResponder;

//- (BOOL)isHeaderViewFirstResponder;

/**
 *  添加地址数组
 *
 *  @param array 地址数组
 */
- (void)addAddressArrayToAddressEditView:(NSArray *)array;

/**
 *  设置附件个数
 *
 *  @param attachmentNumber 附件个数
 */
- (void)setAttachmentNumber:(NSInteger)attachmentNumber;

/**
 *  设置主题
 *
 *  @param subjectStr   邮件主题
 */
- (void)setSubject:(NSString *)subjectStr;

@end

@protocol ZGComposeHeaderViewDelegate <NSObject>

/**
 *  添加联系人按钮点击
 *
 *  @param composeHeaderView    headerView
 *  @param button               邮件地址按钮
 */
- (void)composeHeaderView:(ZGComposeHeaderView *)composeHeaderView addContactsButtonPressed:(ZGMailAddressButton *)button;

/**
 *  删除收件人地址按钮
 *
 *  @param composeHeaderView    headerView
 *  @param button               删除收件人地址按钮
 */
- (void)composeHeaderView:(ZGComposeHeaderView *)composeHeaderView deleteAddressButton:(ZGMailAddressButton *)button;

/**
 *  地址编辑
 *
 *  @param composeHeaderView    headerView
 *  @param tobeEmpty            编辑之后是否为空
 */
- (void)composeHeaderView:(ZGComposeHeaderView *)composeHeaderView isAddressTextFieldTobeEmpty:(BOOL)tobeEmpty;

/**
 *  附件按钮点击
 *
 *  @param composeHeaderView    headerView
 *  @param button               附件按钮
 */
- (void)composeHeaderView:(ZGComposeHeaderView *)composeHeaderView attachmentButtonPressed:(UIButton *)button;

@end
