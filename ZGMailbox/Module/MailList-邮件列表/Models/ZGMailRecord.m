//
//  ZGMailRecord.m
//  ZGMailbox
//
//  Created by zzg on 2017/3/21.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import "ZGMailRecord.h"

#import <MailCore/MailCore.h>
#import <MailCore/MCOAddress.h>

#import "ZGMailMessage.h"
#import "ZGMailModule.h"


@implementation ZGMailRecord

- (instancetype)initWithImapMessage:(MCOIMAPMessage *)message {
    self = [self init];
    if (self) {
        //发件人信息
        NSString *mailbox = [message.header.sender mailbox];
        NSArray *array = [mailbox componentsSeparatedByString:@"@"];
        NSString *senderName = [array firstObject];
        
        NSString *displayName = [message.header.sender displayName];
        if (IsEmptyString(displayName)) {
            displayName = senderName;
        }
        //发件人名称
        self.sender = displayName;
        //发件人头像
        self.senderPortrait = nil;
        
        //自己发出的邮件，需要展示收件人信息
        if ([mailbox isEqualToString:[ZGMailModule sharedInstance].mailAddress]) {//发件人是自己
            //收件人信息
            NSMutableArray *receiverArray = [[NSMutableArray alloc] init];
            [receiverArray addObjectsFromArray:message.header.to];
            [receiverArray addObjectsFromArray:message.header.cc];
            [receiverArray addObjectsFromArray:message.header.bcc];
            
            NSMutableArray *receiverDisplayNameArray = [[NSMutableArray alloc] init];
            [receiverArray enumerateObjectsUsingBlock:^(MCOAddress *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *str = [obj displayName];
                if (IsEmptyString(str)) {
                    NSArray *strArray = [obj.mailbox componentsSeparatedByString:@"@"];
                    NSString *receiverName = [strArray firstObject];
                    str = receiverName;
                }
                
                [receiverDisplayNameArray addObject:str];
                
                //最多拼接五个收件人信息
                if (idx == 4) {
                    *stop = YES;
                    return;
                }
            }];
            self.receiver = [receiverDisplayNameArray componentsJoinedByString:@"、"];
            
            //收件人头像展示
            //            MCOAddress *firstReceiver = [receiverArray firstObject];
            //            NSString *firstReceiverName = [[firstReceiver.mailbox componentsSeparatedByString:@"@"] firstObject];
            self.receiverPortrait = nil;
        }
        
        self.messageID = message.header.messageID;
        self.subject = message.header.subject;
        self.date = message.header.receivedDate;
        
        self.isUnread = !(message.flags & MCOMessageFlagSeen);
        self.isReply = message.flags & MCOMessageFlagAnswered;
        self.isForwarded = message.flags & MCOMessageFlagForwarded;
        self.isStarred = message.flags & MCOMessageFlagFlagged;
        self.isHaveAttachment = [message.attachments count];
    }
    
    return self;
}

/**
 *  草稿箱、发件箱数据
 *
 *  @param message
 *
 *  @return
 */
- (instancetype)initWithMailMessage:(ZGMailMessage *)message {
    self = [self init];
    if (self) {
        NSMutableArray *receiverArray = [[NSMutableArray alloc] init];
        [receiverArray addObjectsFromArray:message.header.to];
        [receiverArray addObjectsFromArray:message.header.cc];
        [receiverArray addObjectsFromArray:message.header.bcc];
        
        if (receiverArray.count > 0) {
            NSMutableArray *receiverDisplayNameArray = [[NSMutableArray alloc] init];
            [receiverArray enumerateObjectsUsingBlock:^(MCOAddress *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *str = [obj displayName];
                if (IsEmptyString(str)) {
                    NSArray *strArray = [obj.mailbox componentsSeparatedByString:@"@"];
                    NSString *receiverShortName = [strArray firstObject];
                    str = receiverShortName;
                }
                
                [receiverDisplayNameArray addObject:str];
                
                //最多拼接五个收件人信息
                if (idx == 4) {
                    *stop = YES;
                    return;
                }
            }];
            self.receiver = [receiverDisplayNameArray componentsJoinedByString:@"、"];
            
            //收件人头像展示
            MCOAddress *firstReceiver = [receiverArray firstObject];
            NSString *firstReceiverShortName = [[firstReceiver.mailbox componentsSeparatedByString:@"@"] firstObject];
            self.receiverPortrait = nil;
        } else {
            self.receiver = @"";
            self.receiverPortrait = nil;
        }
        
        //        self.sender = str;
        
        self.messageID = message.header.messageID;
        self.subject = message.header.subject;
        self.date = message.header.date;
        
        self.isUnread = NO;
        self.isReply = NO;
        self.isForwarded = NO;
        self.isStarred = NO;
        
        self.isHaveAttachment = message.originMessageParts.count || message.attachmentsFilenameArray.count;
    }
    
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    
    return self;
}

@end
