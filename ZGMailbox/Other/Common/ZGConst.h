//
//  ZGConst.h
//  ZGMailbox
//
//  Created by zzg on 2018/1/16.
//  Copyright © 2018年 zzg. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZGConst : NSObject

//收到新邮件
extern NSString *const ZGNotificationReceivedNewMail;

//邮件目录
extern NSString *const MailFolderTypeINBOX;
extern NSString *const MailFolderTypeDraft;
extern NSString *const MailFolderTypeSending;
extern NSString *const MailFolderTypeSent;
extern NSString *const MailFolderTypeTrash;
extern NSString *const MailFolderTypeOther;

@end
