//
//  ZGMailAttachmetPhoto.h
//  ZGMailbox
//
//  Created by zzg on 2017/5/22.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import <Foundation/Foundation.h>

//图片浏览
#import "MWPhoto.h"
#import "MWPhotoProtocol.h"

@class MCOIMAPPart;
@class MCOIMAPMessage;

//自定义邮件消息图片附件浏览photo类
@interface ZGMailAttachmetPhoto : NSObject <MWPhoto>

@property (nonatomic, strong) NSString *caption;
@property (nonatomic, readonly) UIImage *image;
@property (nonatomic, readonly) MCOIMAPPart *imagePart;

@property (nonatomic, strong) NSString *folder;
@property (nonatomic, strong) MCOIMAPMessage *message;


+ (ZGMailAttachmetPhoto *)photoWithImagePart:(MCOIMAPPart *)imagePart folder:(NSString *)folder message:(MCOIMAPMessage *)message;

- (id)initWithImagePart:(MCOIMAPPart *)imagePart folder:(NSString *)folder message:(MCOIMAPMessage *)message;

@end
