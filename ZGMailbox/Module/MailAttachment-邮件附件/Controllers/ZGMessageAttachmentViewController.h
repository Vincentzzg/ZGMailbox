//
//  ZGMessageAttachmentViewController.h
//  ZGMailbox
//
//  Created by zzg on 2017/4/13.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MCOIMAPPart;
//@class MCOAttachment;
@class MCOIMAPSession;
@class MCOIMAPMessage;

@interface ZGMessageAttachmentViewController : UIViewController

@property (nonatomic, strong) MCOIMAPPart *part;
//@property (nonatomic, strong) MCOAttachment *attachment;
@property (nonatomic, copy) NSString *folder;
@property (nonatomic, strong) MCOIMAPSession *session;
@property (nonatomic, strong) MCOIMAPMessage *message;

@end
