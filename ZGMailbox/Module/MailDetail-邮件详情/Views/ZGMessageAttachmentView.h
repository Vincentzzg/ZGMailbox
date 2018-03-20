//
//  ZGMessageAttachmentView.h
//  ZGMailbox
//
//  Created by zzg on 2017/4/13.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MCOIMAPPart;
@protocol ZGMessageAttachmentViewDelegate;

/**
 *  插件视图
 */
@interface ZGMessageAttachmentView : UIView

@property (nonatomic, strong) UITableView *myTableView;
@property (nonatomic, copy) NSArray *attachments;
@property (nonatomic, weak) id<ZGMessageAttachmentViewDelegate> delegate;

- (float)heightOfAttachmentView;

- (void)reloadTableView;

@end

@protocol ZGMessageAttachmentViewDelegate <NSObject>

- (void)messageAttachmentView:(ZGMessageAttachmentView *)attachmentView selectAttachment:(MCOIMAPPart *)part;

@end
