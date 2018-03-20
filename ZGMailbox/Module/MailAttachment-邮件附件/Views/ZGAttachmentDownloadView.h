//
//  ZGAttachmentDownloadView.h
//  ZGMailbox
//
//  Created by zzg on 2017/4/13.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZGAttachmentDownloadView : UIView

@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UILabel *progressLabel;
@property (nonatomic, strong) UILabel *fileNameLabel;
@property (nonatomic, copy) NSString *mimeType;
@property (nonatomic, copy) NSString *filename;

@end
