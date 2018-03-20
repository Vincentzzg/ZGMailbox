//
//  ZGMailMessage.h
//  ZGMailbox
//
//  Created by zzg on 2017/5/11.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import <Foundation/Foundation.h>

//#import <MailCore/MCOSMTPSendOperation.h>

/**
 *  消息的状态
 */
typedef NS_ENUM(NSInteger, MailMessageStatus) {
    MailMessageStatus_Wait,
    MailMessageStatus_Sending,
    MailMessageStatus_Draft,
    MailMessageStatus_Failure,
};

@class MCOIMAPMessage;
@class MCOMessageHeader;

@interface ZGMailMessage : NSObject <NSCoding>

@property (nonatomic, assign) MailMessageStatus messageStatus;
@property (nonatomic, copy) NSString *failureString;//邮件发送失败原因


@property (nonatomic, strong) MCOMessageHeader *header;
@property (nonatomic, copy) NSString *bodyText;
@property (nonatomic, strong) NSArray *attachmentsFilenameArray;//附件文件名数组

//原始邮件的数据
@property (nonatomic, strong) MCOIMAPMessage *originImapMessage;
@property (nonatomic, copy) NSString *originMessageFolder;//原始邮件的文件夹
@property (nonatomic, strong) NSArray *originMessageParts;//原始邮件附件数据（MCOIMAPPart），用于附件展示、编辑

@end
