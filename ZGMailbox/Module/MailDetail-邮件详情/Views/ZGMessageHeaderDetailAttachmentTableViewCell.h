//
//  ZGMessageHeaderDetailAttachmentTableViewCell.h
//  ZGMailbox
//
//  Created by zzg on 2017/4/10.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZGAddressShadowButton;
@protocol ZGMessageHeaderDetailAttachmentTableViewCellDelegate;

@interface ZGMessageHeaderDetailAttachmentTableViewCell : UITableViewCell

@property (nonatomic, weak) id<ZGMessageHeaderDetailAttachmentTableViewCellDelegate> delegate;
@property (nonatomic, copy) NSArray *attachments;

@end

@protocol ZGMessageHeaderDetailAttachmentTableViewCellDelegate <NSObject>

- (void)headerDetailAttachmentCell:(ZGMessageHeaderDetailAttachmentTableViewCell *)cell attacmentButtonPressed:(ZGAddressShadowButton *)button;

@end
