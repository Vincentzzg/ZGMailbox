//
//  ZGSubjectEditView.h
//  ZGMailbox
//
//  Created by zzg on 2017/4/24.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ZGSubjectEditViewDelegate;

/**
 *  邮件主题编辑视图
 */
@interface ZGSubjectEditView : UIView

@property (nonatomic, weak) id<ZGSubjectEditViewDelegate> delegate;

/**
 *  获取邮件主题
 *
 *  @return 邮件主题
 */
- (NSString *)mailSubject;

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

@protocol ZGSubjectEditViewDelegate <NSObject>

- (void)subjectEditViewBeginEditing:(ZGSubjectEditView *)subjectEditView;
- (void)subjectEditViewEndEditing:(ZGSubjectEditView *)subjectEditView;

/**
 *  附件按钮点击
 *
 *  @param subjectEditView <#subjectEditView description#>
 *  @param button          <#button description#>
 */
- (void)subjectEditView:(ZGSubjectEditView *)subjectEditView attachmentButtonPressed:(UIButton *)button;

@end
