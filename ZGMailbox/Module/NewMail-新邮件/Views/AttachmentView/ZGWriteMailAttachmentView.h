//
//  ZGWriteMailAttachmentView.h
//  ZGMailbox
//
//  Created by zzg on 2017/4/26.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZGAddAttachmentCollectionViewCell;
@protocol ZGWriteMailAttachmentViewDelegate;


/**
 *  写邮件附件视图：如果是邮件转发，会在前面展示原始邮件的附件
 */
@interface ZGWriteMailAttachmentView : UIView

@property (nonatomic, weak) id<ZGWriteMailAttachmentViewDelegate> delegate;

@property (nonatomic, strong) NSMutableArray *originMessageAttachments;//原始邮件附件数据(MCOIMAPPart)

//@property (nonatomic, strong) NSMutableArray *attachmentsPhotosArray;//图片数据
//@property (nonatomic, strong) NSMutableArray *attachmentsDataArray;//Data数据，用来计算大小
@property (nonatomic, copy) NSString *messageID;
@property (nonatomic, strong) NSMutableArray *attachmentsFilenameArray;

- (void)reloadAttachmentView;
- (float)calculateHeightOfAttachmentViewWithAttachmentCount:(NSInteger)count;

@end

@protocol ZGWriteMailAttachmentViewDelegate <NSObject>

/**
 *  附件点击
 *
 *  @param attachmentView   附件视图
 *  @param index            附件下标
 */
- (void)writeMailAttachmentView:(ZGWriteMailAttachmentView *)attachmentView didSelectItemAtIndex:(NSInteger)index;

/**
 *  原始邮件附件点击
 *
 *  @param attachmentView   附件视图
 *  @param index            附件下标
 */
- (void)writeMailAttachmentView:(ZGWriteMailAttachmentView *)attachmentView didSelectOriginMessageItemAtIndex:(NSInteger)index;

/**
 *  原始邮件附件删除
 *
 *  @param attachmentView   附件视图
 *  @param index            附件下标
 */
- (void)writeMailAttachmentView:(ZGWriteMailAttachmentView *)attachmentView originMessageDeleteButtonPressed:(NSInteger)index;

/**
 *  附件删除
 *
 *  @param attachmentView   附件视图
 *  @param index            附件下标
 */
- (void)writeMailAttachmentView:(ZGWriteMailAttachmentView *)attachmentView deleteButtonPressed:(NSInteger)index;

/**
 *  添加附件cell点击
 *
 *  @param attachmentView 附件视图
 */
- (void)addAttachmentCollectionViewCellPressed:(ZGWriteMailAttachmentView *)attachmentView;

@end
