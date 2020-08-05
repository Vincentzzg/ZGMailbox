//
//  ZGMailRecord.h
//  ZGMailbox
//
//  Created by zzg on 2017/3/21.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MCOIMAPMessage;
@class ZGMailMessage;

@interface ZGMailRecord : NSObject

@property (nonatomic, copy) NSString *messageID;

@property (nonatomic, copy) NSString *sender;//发件人
@property (nonatomic, copy) NSString *senderPortrait;//发件人头像

@property (nonatomic, copy) NSString *receiver;//收件人
@property (nonatomic, copy) NSString *receiverPortrait;//收件人头像（如果有多个只取第一个）

@property (nonatomic, copy) NSString *subject;//主题
@property (nonatomic, copy) NSDate *date;//时间

@property (nonatomic, assign) BOOL isUnread;//未读
@property (nonatomic, assign) BOOL isReply;//回复（回复别人的邮件、别人回复了你的邮件）
@property (nonatomic, assign) BOOL isForwarded;//转发（转发了邮件）
@property (nonatomic, assign) BOOL isStarred;//星标
@property (nonatomic, assign) BOOL isHaveAttachment;//附件

- (instancetype)initWithImapMessage:(MCOIMAPMessage *)message;

/**
 *  草稿箱、发件箱数据
 *
 *  @param message  自定义消息对象
 *
 *  @return         返回
 */
- (instancetype)initWithMailMessage:(ZGMailMessage *)message;

@end
