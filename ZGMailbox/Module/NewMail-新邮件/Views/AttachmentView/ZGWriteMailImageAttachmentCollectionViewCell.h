//
//  ZGWriteMailImageAttachmentCollectionViewCell.h
//  ZGMailbox
//
//  Created by zzg on 2017/4/26.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ZGWriteMailImageAttachmentCollectionViewCellDelegate;

/**
 *  写邮件图片附件cell
 */
@interface ZGWriteMailImageAttachmentCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) id<ZGWriteMailImageAttachmentCollectionViewCellDelegate> delegate;

//@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, strong) UIImageView *attachmentPreviewImageView;

@property (nonatomic, strong) NSData *imageData;
@property (nonatomic, copy) NSString *imageName;
@property (nonatomic, strong) NSIndexPath *indexPath;

@end

@protocol ZGWriteMailImageAttachmentCollectionViewCellDelegate <NSObject>

- (void)writeMailImageAttachmentCollectionViewCell:(ZGWriteMailImageAttachmentCollectionViewCell *)attachmentViewCell deleteButtonPressed:(UIButton *)button;

@end
