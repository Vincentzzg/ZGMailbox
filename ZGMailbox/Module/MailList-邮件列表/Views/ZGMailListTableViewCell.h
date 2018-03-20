//
//  ZGMailListTableViewCell.h
//  ZGMailbox
//
//  Created by zzg on 2017/3/21.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZGMailRecord;
@class MCOIMAPMessageRenderingOperation;
@protocol ZGMailListTableViewCellDelegate;

@interface ZGMailListTableViewCell : UITableViewCell

@property (nonatomic, strong) NSString *folderType;//文件夹
@property (nonatomic, strong) ZGMailRecord *mailRecord;
@property (nonatomic, strong) UIImageView *multipleSelectImageView;//多选图片
@property (nonatomic, strong) UILabel *contentLabel;//内容
@property (nonatomic, strong) UILabel *failureLabel;

@property (nonatomic, strong) UIProgressView *progressView;

@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, weak) id<ZGMailListTableViewCellDelegate> delegate;

@property (nonatomic, strong) MCOIMAPMessageRenderingOperation * messageRenderingOperation;

- (void)showStar:(BOOL)isShow;

- (void)showUnseen:(BOOL)isShow;

- (void)showProgressView;

//- (void)showContentLabel;

@end

@protocol ZGMailListTableViewCellDelegate <NSObject>

- (void)mailListTableViewCell:(ZGMailListTableViewCell *)cell cancelButtonPressed:(UIButton *)sender;

@end
