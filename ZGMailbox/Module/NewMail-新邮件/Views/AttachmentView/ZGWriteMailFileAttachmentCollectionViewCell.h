//
//  ZGWriteMailFileAttachmentCollectionViewCell.h
//  ZGMailbox
//
//  Created by zzg on 2017/5/8.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MCOIMAPPart;
@protocol ZGWriteMailFileAttachmentCollectionViewCellDelegate;

/**
 *  写邮件文件附件cell
 */
@interface ZGWriteMailFileAttachmentCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *backgroudImageView;

@property (nonatomic, strong) MCOIMAPPart *part;
@property (nonatomic, weak) id<ZGWriteMailFileAttachmentCollectionViewCellDelegate> delegate;

@end

@protocol ZGWriteMailFileAttachmentCollectionViewCellDelegate <NSObject>

- (void)writeMailFileAttachmentCollectionViewCell:(ZGWriteMailFileAttachmentCollectionViewCell *)attachmentViewCell deleteButtonPressed:(UIButton *)button;

@end
