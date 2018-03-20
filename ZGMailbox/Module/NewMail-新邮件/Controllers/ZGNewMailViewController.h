//
//  ZGNewMailViewController.h
//  ZGMailbox
//
//  Created by zzg on 2017/3/28.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MCOAddress;
@class MCOIMAPMessage;
@class MCOIMAPSession;
@class MCOMessageParser;
@class ZGMailMessage;

typedef NS_ENUM(NSUInteger, NewMailType) {
    NewMailTypeDefault,//新邮件
    NewMailTypeReply,//回复
    NewMailTypeReplyAll,//回复全部
    NewMailTypeForward,//转发
    NewMailTypeDraft,//草稿
    NewMailTypeSending,//发件箱邮件
};


@interface ZGNewMailViewController : UIViewController

@property (nonatomic, strong) MCOAddress *recipientAddress;
@property (nonatomic, assign) NewMailType newMailType;

//回复、转发邮件，加载原始邮件使用
@property (nonatomic, strong) MCOIMAPMessage *originImapMessage;
@property (nonatomic, strong) MCOIMAPSession *session;
@property (nonatomic, copy) NSString *originMessageFolder;


//草稿、发件箱邮件数据源
@property (nonatomic, strong) ZGMailMessage *mailMessage;

@end
