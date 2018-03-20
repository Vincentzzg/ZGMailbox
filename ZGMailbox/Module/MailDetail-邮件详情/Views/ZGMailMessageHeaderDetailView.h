//
//  ZGMailMessageHeaderDetailView.h
//  ZGMailbox
//
//  Created by zzg on 2017/4/6.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MCOMessageHeader;
@class MCOIMAPMessage;
@class ZGAddressShadowButton;
@protocol ZGMailMessageHeaderDetailViewDelegate;

/**
 *  邮件消息页面顶部详情视图
 */
@interface ZGMailMessageHeaderDetailView : UIView

@property (nonatomic, strong) MCOIMAPMessage *message;
@property (nonatomic, weak) id<ZGMailMessageHeaderDetailViewDelegate> delegate;

- (void)reloadTableView;

- (float)heightOfMailDetailView;

@end

@protocol ZGMailMessageHeaderDetailViewDelegate <NSObject>

- (void)headerDetailView:(ZGMailMessageHeaderDetailView *)headerDetailView addressButtonPressed:(ZGAddressShadowButton *)button;
- (void)headerDetailView:(ZGMailMessageHeaderDetailView *)headerDetailView attachmentButtonPressed:(ZGAddressShadowButton *)button;

@end
