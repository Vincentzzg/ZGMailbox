//
//  ZGMailMessageHeaderView.h
//  ZGMailbox
//
//  Created by zzg on 2017/4/5.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MCOIMAPMessage;
@protocol ZGMailMessageHeaderViewDelegate;
@class ZGAddressShadowButton;

/**
 *  邮件消息顶部视图
 */
@interface ZGMailMessageHeaderView : UIView

@property (nonatomic, strong) MCOIMAPMessage *message;
@property (nonatomic, weak) id<ZGMailMessageHeaderViewDelegate> delegate;

- (float)heightOfMessageHeaderView;
- (float)heightOfSummaryMessageHeaderView;

- (void)hideMailDetailView;

- (void)showStarImageView;

- (void)hideStarImageView;

- (void)showUnseenImageView;

- (void)hideUnseenImageView;

@end

@protocol ZGMailMessageHeaderViewDelegate <NSObject>

- (void)headerView:(ZGMailMessageHeaderView *)headerView detailButtonPressed:(id)sender;

- (void)headerView:(ZGMailMessageHeaderView *)headerView hideButtonPressed:(id)sender;

- (void)headerView:(ZGMailMessageHeaderView *)headerView addressButtonPressed:(ZGAddressShadowButton *)button;

- (void)headerView:(ZGMailMessageHeaderView *)headerView attachmentButtonPressed:(ZGAddressShadowButton *)button;

@end
