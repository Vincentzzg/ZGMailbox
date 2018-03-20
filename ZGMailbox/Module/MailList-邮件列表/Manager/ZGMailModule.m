//
//  ZGMailModule.m
//  ZGMailbox
//
//  Created by zzg on 2017/3/21.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import "ZGMailModule.h"

#import <MailCore/MailCore.h>
#import <MailCore/MCORange.h>
#import <MailCore/MCOMessageHeader.h>

//record
#import "ZGMailMessage.h"

//时间转换
#import "NSDate+DDAddition.h"

//邮件发送顶部指示器
#import "ZGSendMailTopIndicator.h"

//rsa加密
#import "RSA.h"

//网络监测
#import "TMReachability.h"

//分类
#import "NSString+Mail.h"

static NSString *const MailSortKey = @"header.receivedDate";

@interface ZGMailModule ()

@property (nonatomic, strong) ZGSendMailTopIndicator *sendMailTopIndicator;

@property (nonatomic, copy) NSString *password;

@property (nonatomic, copy) NSString *imapHost;
@property (nonatomic, assign) unsigned int imapPort;

@property (nonatomic, copy) NSString *smtpHost;
@property (nonatomic, assign) unsigned int smtpPort;


@property (nonatomic, readonly) dispatch_queue_t mailModuleQueue;

@property (nonatomic, strong) MCOSMTPSession *smtpSession;

@property (nonatomic, strong) MCOIMAPOperation *imapCheckOp;
@property (nonatomic, strong) MCOIMAPFetchMessagesOperation *imapMessagesFetchOp;
@property (nonatomic, strong) MCOSMTPSendOperation *sendingOperation;

@property (nonatomic, copy) NSMutableDictionary <NSString *, NSNumber *> *totalNumberOfMessagesDic;//邮件总数数据
@property (nonatomic, copy) NSMutableDictionary <NSString *, NSMutableArray *> *mailMessageListDic;//邮件消息列表数据

@property (nonatomic, copy) NSMutableArray *sendMessageArray;//保存待发送的builder对象
@property (nonatomic, strong) MCOMessageBuilder *sendingBuilder;

@property (nonatomic, assign) uint32_t inboxUidNext;

@property (nonatomic, strong) NSTimer *checkTimer;//定时器设置为属性，方便释放

@property (nonatomic, strong) TMReachability *internetConnectionReach;

@end

@implementation ZGMailModule

+ (instancetype)sharedInstance {
    static ZGMailModule *module;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        module = [[ZGMailModule alloc] init];
    });
    
    return module;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _mailModuleQueue = dispatch_queue_create("com.mailModule", DISPATCH_QUEUE_SERIAL);//串行队列

        [self.totalNumberOfMessagesDic setValue:@(-1) forKey:MailFolderTypeINBOX];
        [self.totalNumberOfMessagesDic setValue:@(-1) forKey:MailFolderTypeSent];
        [self.totalNumberOfMessagesDic setValue:@(-1) forKey:MailFolderTypeTrash];
        
        [self.mailMessageListDic setValue:[NSMutableArray new] forKey:MailFolderTypeINBOX];
        [self.mailMessageListDic setValue:[NSMutableArray new] forKey:MailFolderTypeSent];
        [self.mailMessageListDic setValue:[NSMutableArray new] forKey:MailFolderTypeTrash];
        
        NSNumber *number = [[NSUserDefaults standardUserDefaults] valueForKey:InboxUidNext_KEY];
        self.inboxUidNext = [number intValue];
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _mailModuleQueue = nil;
}

#pragma mark - public method

///设置邮箱地址和密码
- (void)setMailAddress:(NSString *)mailAddress password:(NSString *)password {
    _mailAddress = mailAddress;
    self.password = password;
    
    NSArray *components = [mailAddress componentsSeparatedByString:@"@"];
    NSString *domain = [components lastObject];
    if ([domain isEqualToString:@"qq.com"]) {
        self.imapHost = @"imap.qq.com";
        self.imapPort = 993;

        self.smtpHost = @"smtp.qq.com";
        self.smtpPort = 993;
    }
}

- (NSArray *)showingMailListWithFolder:(NSString *)folder {
    if ([folder isEqualToString:MailFolderTypeDraft] || [folder isEqualToString:MailFolderTypeSending]) {
        NSData *cachedData = [[NSUserDefaults standardUserDefaults] valueForKey:folder];
        if (cachedData) {
            NSMutableDictionary *dic = [NSKeyedUnarchiver unarchiveObjectWithData:cachedData];
            NSArray *array = [dic allValues];
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:MailSortKey ascending:NO];
            //根据邮件头里面的时间排序
            array = [array sortedArrayUsingDescriptors:@[sort]];
            
            return array;
        } else {
            return nil;
        }
    } else {
        return [self.mailMessageListDic objectForKey:folder];
    }
}

/**
 *  保存收件箱未读邮件数
 *
 *  @param unseenNumber
 */
- (void)saveUnseenMessageNumberOfINBOX:(NSUInteger)unseenNumber {
    [[NSUserDefaults standardUserDefaults] setValue:@(unseenNumber) forKey:InboxUnseenMailNumber_KEY];
}

/**
 *  获取收件箱未读邮件数
 *
 *  @param folder
 *
 *  @return
 */
- (NSUInteger)unseenMessageNumberOfINBOX {
    NSNumber *number = [[NSUserDefaults standardUserDefaults] valueForKey:InboxUnseenMailNumber_KEY];
    
    return [number unsignedIntegerValue];
}

/**
 *  获取正在发送的邮件的发送操作对象
 *
 *  @return
 */
- (MCOSMTPSendOperation *)sendingOperation {
    return _sendingOperation;
}

/**
 *  取消邮件的发送
 *
 *  @param messageID
 */
- (void)stopSendOperationOfMessage:(NSString *)messageID {
    //是当前正在发送的邮件，取消发送
    if ([self.sendingBuilder.header.messageID isEqualToString:messageID]) {
        [self.sendingOperation cancel];
        self.sendingOperation = nil;
        self.sendingBuilder = nil;
    } else {
        
    }
    
    [self.sendMessageArray enumerateObjectsUsingBlock:^(MCOMessageBuilder *builder, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([messageID isEqualToString:builder.header.messageID]) {
            [self.sendMessageArray removeObjectAtIndex:idx];
            *stop = YES;
            return;
        }
    }];
    
    //还有未发送的消息
    if (self.sendMessageArray.count > 0) {
        MCOMessageBuilder *builder = [self.sendMessageArray firstObject];
        [self sendMessage:builder];
        [self hideSendMailTopIndicator];
    } else {
        [self hideSendMailTopIndicator];
    }
    
    //发送通知，刷新发件箱
    [[NSNotificationCenter defaultCenter] postNotificationName:MailSendingFolderReloadNotification object:nil];
}

/**
 *  设置发送中的消息为失败（客户端被强制关闭时使用）
 */
- (void)setSendingMailMessageFailure {
    //全部邮件发送失败
    [self.sendMessageArray enumerateObjectsUsingBlock:^(MCOMessageBuilder *builder, NSUInteger idx, BOOL * _Nonnull stop) {
        ZGMailMessage *mailMessage = [self messageInUserDefaultForFolder:MailFolderTypeSending messageID:builder.header.messageID];
        mailMessage.messageStatus = MailMessageStatus_Failure;
        mailMessage.failureString = @"邮件已取消发送";
        [self insertOrUpdateMailMessageInUserDefaultForFolder:MailFolderTypeSending message:mailMessage];
    }];
    [self.sendMessageArray removeAllObjects];
    
    [self.checkTimer invalidate];
    self.checkTimer = nil;
}

/**
 *  关闭邮件检查时间程
 */
- (void)stopMailCheckTimer {
    [self.checkTimer invalidate];
    self.checkTimer = nil;
}

////////////////////////////////////////////////*******邮件相关请求******////////////////////////////////////////////////

#pragma mark - 邮件相关请求

///**
// *  获取邮箱配置信息
// */
//- (void)getMailConfigInformation {
//    [self.configApiManager loadData];
//}

/**
 *  检查收件箱新邮件
 *
 */
- (void)checkInboxNewMessage {
    NSLog(@"timer, checkInboxNewMessage");
    //防止block中循环引用，导致无法释放
    __weak typeof(self) weakSelf = self;
    
    MCOIMAPFolderStatusOperation *inboxFolderInfo = [self.imapSession folderStatusOperation:MailFolderTypeINBOX];
    [inboxFolderInfo start:^(NSError * _Nullable error, MCOIMAPFolderStatus * _Nullable status) {
        __strong typeof(weakSelf) strongSelf = weakSelf;

        if (error) {
            NSLog(@"%@", error);
            [strongSelf handleWithImapError:error];
            
            return;
        }
        
        int uid = [status uidNext];
        //记录未读邮件数
        NSUInteger unseenCount = [status unseenCount];
        [strongSelf saveUnseenMessageNumberOfINBOX:unseenCount];
        if (uid > strongSelf.inboxUidNext) {//有新邮件
            [strongSelf updateMailListWithFolder:MailFolderTypeINBOX completion:^(NSError *error, NSArray *mailListArray) {
                if (error) {
                    [strongSelf handleWithImapError:error];
                } else {
                    NSArray *array = nil;
                    NSArray *messagArray = [strongSelf showingMailListWithFolder:MailFolderTypeINBOX];
                    if (messagArray.count > 20) {
                        NSIndexSet *set = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 20)];
                        array = [messagArray objectsAtIndexes:set];
                    } else {
                        array = messagArray;
                    }
                    
                    //保存第一页的数据
                    NSString *key = MailFolderTypeINBOX;//默认先展示收件箱
                    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:array];
                    [[NSUserDefaults standardUserDefaults] setValue:data forKey:key];
                    
                    //发起新邮件通知
                    [[NSNotificationCenter defaultCenter] postNotificationName:ZGNotificationReceivedNewMail object:nil];
                }
            }];
        } else {//没有新邮件
            
        }
    }];
}

/**
 *  检查收件箱新邮件
 *
 */
- (void)checkInboxNewMessage:(void (^)(BOOL hasNewMail))completionBlock {
    //防止block中循环引用，导致无法释放
    __weak typeof(self) weakSelf = self;
    
    MCOIMAPFolderStatusOperation *inboxFolderInfo = [self.imapSession folderStatusOperation:MailFolderTypeINBOX];
    [inboxFolderInfo start:^(NSError * _Nullable error, MCOIMAPFolderStatus * _Nullable status) {
        __strong typeof(weakSelf) strongSelf = weakSelf;

        if (error) {
            NSLog(@"%@", error);
            [strongSelf handleWithImapError:error];
            
            return;
        }
        int uid = [status uidNext];
        //记录未读邮件数
        NSUInteger unseenCount = [status unseenCount];
        [strongSelf saveUnseenMessageNumberOfINBOX:unseenCount];
        if (uid > strongSelf.inboxUidNext && unseenCount > 0) {//有新的未读邮件
            [strongSelf updateMailListWithFolder:MailFolderTypeINBOX completion:^(NSError *error, NSArray *mailListArray) {
                if (error) {
                    [strongSelf handleWithImapError:error];
                } else {
                    NSArray *array = nil;
                    NSArray *messagArray = [strongSelf showingMailListWithFolder:MailFolderTypeINBOX];
                    if (messagArray.count > 20) {
                        NSIndexSet *set = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 20)];
                        array = [messagArray objectsAtIndexes:set];
                    } else {
                        array = messagArray;
                    }
                    
                    //保存第一页的数据
//                    HikContactsInfoRecord *accountInfoRecord = [HikAccountInfoManager sharedInstance].accountInfoRecord;
//                    NSString *key = [accountInfoRecord.shortName stringByAppendingString:MailFolderTypeINBOX];//默认先展示收件箱
                    NSString *key = [@"" stringByAppendingString:MailFolderTypeINBOX];//默认先展示收件箱
                    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:array];
                    [[NSUserDefaults standardUserDefaults] setValue:data forKey:key];
                    
                    //发起新邮件通知
                    [[NSNotificationCenter defaultCenter] postNotificationName:ZGNotificationReceivedNewMail object:nil];
                    [strongSelf postLocalNotificaiton];
                    if (completionBlock) {
                        completionBlock(YES);
                    }
                }
            }];
        } else {//没有新邮件
            if (completionBlock) {
                completionBlock(NO);
            }
        }
    }];
}

/**
 *  加载更多邮件
 */
- (void)loadMoreHistoryMessagesInFolder:(NSString *)folder completion:(void (^)(NSError *error, NSArray *mailListArray))completion {
    //防止block中循环引用，导致无法释放
    __weak typeof(self) weakSelf = self;
    
    MCOIMAPFolderStatusOperation *inboxFolderInfo = [self.imapSession folderStatusOperation:folder];
    [inboxFolderInfo start:^(NSError * _Nullable error, MCOIMAPFolderStatus * _Nullable status) {
        __strong typeof(weakSelf) strongSelf = weakSelf;

        if (error) {
            [strongSelf handleWithImapError:error];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(error, nil);
                }
            });
        } else {
            //记录未读邮件数、最新邮件uid
            NSUInteger unseenCount = [status unseenCount];
            if ([folder isEqualToString:MailFolderTypeINBOX]) {
                strongSelf.inboxUidNext = [status uidNext];
                [[NSUserDefaults standardUserDefaults] setValue:@(strongSelf.inboxUidNext) forKey:InboxUidNext_KEY];
                
                [strongSelf saveUnseenMessageNumberOfINBOX:unseenCount];
            }
            
            //邮件总数
            NSInteger totalNumber = [status messageCount];
            //更新总数
            [strongSelf.totalNumberOfMessagesDic setValue:@(totalNumber) forKey:folder];
            
            //设置需要抓取的邮件的number区间
            MCORange fetchRange;
            __block NSMutableArray *existMessages = [NSMutableArray arrayWithArray:[strongSelf showingMailListWithFolder:folder]];
            
            if (totalNumber == 0) {//邮件总数为0，说明邮件列表为空
                fetchRange = MCORangeMake(0, 0);
            } else {
                //总数不能超过服务器上的邮件总数
                NSUInteger totalNumberAfterLoad = existMessages.count + NUMBER_OF_MESSAGES_TO_LOAD;
                totalNumberAfterLoad = MIN(totalNumber, totalNumberAfterLoad);
                
                //通过差值，计算出需要加载的新邮件个数（一般是一页的个数）
                NSInteger numberOfMessagesToLoad = totalNumberAfterLoad - existMessages.count;
                if (numberOfMessagesToLoad > 0) {
                        fetchRange = MCORangeMake(totalNumber - existMessages.count - (numberOfMessagesToLoad - 1), (numberOfMessagesToLoad - 1));
                } else {//服务器邮件比本地邮件少，没有更多邮件可以加载
                    fetchRange = MCORangeMake(0, 0);
                }
            }
            
            //抓取邮件
            MCOIMAPMessagesRequestKind requestKind = (MCOIMAPMessagesRequestKind)(MCOIMAPMessagesRequestKindHeaders | MCOIMAPMessagesRequestKindStructure | MCOIMAPMessagesRequestKindInternalDate | MCOIMAPMessagesRequestKindHeaderSubject | MCOIMAPMessagesRequestKindFlags);
            strongSelf.imapMessagesFetchOp = [strongSelf.imapSession fetchMessagesByNumberOperationWithFolder:folder requestKind:requestKind numbers:[MCOIndexSet indexSetWithRange:fetchRange]];
            
            [strongSelf.imapMessagesFetchOp start:^(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages) {
                if (error) {
                    [strongSelf handleWithImapError:error];
                    NSLog(@"%@", error);
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (completion) {
                            completion(error, nil);
                        }
                    });
                } else {
                    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:MailSortKey ascending:NO];
                    NSMutableArray *combinedMessages = [[NSMutableArray alloc] init];
                    //过滤邮件
                    [messages enumerateObjectsUsingBlock:^(MCOIMAPMessage *message, NSUInteger idx, BOOL * _Nonnull stop) {
                        if (message.header.sender && !IsEmptyString(message.header.sender.mailbox)) {
                            [combinedMessages addObject:message];
                        } else {
                            //发件人为空的邮件，不展示，直接过滤掉
                        }
                    }];
                    //已有邮件列表添加在一起
                    [combinedMessages addObjectsFromArray:existMessages];
                    
                    //根据邮件头里面的时间排序
                    existMessages = [NSMutableArray arrayWithArray:[combinedMessages sortedArrayUsingDescriptors:@[sort]]];
                    
                    //缓存邮件列表
                    [strongSelf.mailMessageListDic setValue:[NSMutableArray arrayWithArray:existMessages] forKey:folder];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (completion) {
                            completion(nil, messages);
                        }
                    });
                }
            }];
        }
    }];
}

/**
 *  更新邮件列表
 *
 *  @param folder
 *  @param completion
 */
- (void)updateMailListWithFolder:(NSString *)folder completion:(void (^)(NSError *error, NSArray *mailListArray))completion {
    //防止循环引用，导致无法释放
    __weak typeof(self) weakSelf = self;
    
    MCOIMAPFolderStatusOperation *inboxFolderInfo = [self.imapSession folderStatusOperation:folder];
    [inboxFolderInfo start:^(NSError * _Nullable error, MCOIMAPFolderStatus * _Nullable status) {
        __strong typeof(weakSelf) strongSelf = weakSelf;

        if (error) {
            [strongSelf handleWithImapError:error];
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(error, nil);
                });
            }
        } else {
            //保存收件箱最新邮件消息id
            if ([folder isEqualToString:MailFolderTypeINBOX]) {
                strongSelf.inboxUidNext = [status uidNext];
                [[NSUserDefaults standardUserDefaults] setValue:@(strongSelf.inboxUidNext) forKey:InboxUidNext_KEY];
                
                //保存收件箱未读邮件个数
                NSUInteger unseenCount = [status unseenCount];
                [strongSelf saveUnseenMessageNumberOfINBOX:unseenCount];
            } else {
                //其他文件夹不保存
            }
            
            //邮件个数
            NSUInteger totalNumber = [status messageCount];
            //更新总数
            [strongSelf.totalNumberOfMessagesDic setValue:@(totalNumber) forKey:folder];
            
            //设置需要抓取的邮件的number区间
            MCORange fetchRange;
            __block NSArray *existMessages = [strongSelf showingMailListWithFolder:folder];
            if (totalNumber == 0) {//没有邮件
                fetchRange = MCORangeMake(0, 0);
            } else {
                NSUInteger numberOfMessagesToLoad = existMessages.count;
                //如果本地邮件数大于服务器总邮件数，直接把服务器上的所有邮件拉回来
                if (numberOfMessagesToLoad >= totalNumber) {
                    numberOfMessagesToLoad = totalNumber;
                } else {
                    //如果现有邮件不足一页（中间有邮件被删除），拉取一整页（前提是总数>NUMBER_OF_MESSAGES_TO_LOAD）
                    if (numberOfMessagesToLoad < NUMBER_OF_MESSAGES_TO_LOAD) {
                        //防止出现负数
                        numberOfMessagesToLoad = MIN(totalNumber, NUMBER_OF_MESSAGES_TO_LOAD);
                    }
                }
                
                //把现有的邮件重新加载一遍
                fetchRange = MCORangeMake(totalNumber - (numberOfMessagesToLoad - 1), (numberOfMessagesToLoad - 1));
            }
            
            //抓取邮件
            MCOIMAPMessagesRequestKind requestKind = (MCOIMAPMessagesRequestKind)(MCOIMAPMessagesRequestKindHeaders | MCOIMAPMessagesRequestKindStructure | MCOIMAPMessagesRequestKindInternalDate | MCOIMAPMessagesRequestKindHeaderSubject | MCOIMAPMessagesRequestKindFlags);
            strongSelf.imapMessagesFetchOp = [strongSelf.imapSession fetchMessagesByNumberOperationWithFolder:folder requestKind:requestKind numbers:[MCOIndexSet indexSetWithRange:fetchRange]];
            
            [strongSelf.imapMessagesFetchOp start:^(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages) {
                if (error) {
                    NSLog(@"%@", error);
                    [strongSelf handleWithImapError:error];
                    
                    if (completion) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completion(error, nil);
                        });
                    }
                } else {
                    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:MailSortKey ascending:NO];
                    NSMutableArray *combinedMessages = [[NSMutableArray alloc] init];
                    //过滤邮件
                    [messages enumerateObjectsUsingBlock:^(MCOIMAPMessage *message, NSUInteger idx, BOOL * _Nonnull stop) {
                        if (message.header.sender && !IsEmptyString(message.header.sender.mailbox)) {
                            [combinedMessages addObject:message];
                        } else {
                            //发件人为空的邮件，不展示，直接过滤掉
                        }
                    }];
                    //根据邮件头里面的时间排序
                    existMessages = [combinedMessages sortedArrayUsingDescriptors:@[sort]];
                    
                    //缓存邮件列表
                    [strongSelf.mailMessageListDic setValue:[NSMutableArray arrayWithArray:existMessages] forKey:folder];
                    
                    if (completion) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completion(nil, messages);
                        });
                    }
                }
            }];
        }
    }];
}

/**
 *  修改消息的标志
 *
 *  @param folder   目录
 *  @param messages 消息数组
 *  @param kind
 *  @param flags    标志
 */
- (void)storeFlagsWithFolder:(NSString *)folder messages:(NSArray *)messages kind:(MCOIMAPStoreFlagsRequestKind)kind flags:(MCOMessageFlag)flags {
    //防止block中循环引用，导致无法释放
    __weak typeof(self) weakSelf = self;
    
    MCOIndexSet *indexSet = [MCOIndexSet indexSet];
    [messages enumerateObjectsUsingBlock:^(MCOIMAPMessage *message, NSUInteger idx, BOOL * _Nonnull stop) {
        [indexSet addIndex:message.sequenceNumber];
    }];
    
    MCOIMAPOperation *op = [self.imapSession storeFlagsOperationWithFolder:folder numbers:indexSet kind:kind flags:flags];
    [op start:^(NSError * __nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;

        if (error) {
            NSLog(@"%@", error);
            [strongSelf handleWithImapError:error];
        }
        
        //删除被标记delete的邮件
        BOOL deleted = flags & MCOMessageFlagDeleted;
        if(deleted) {
            MCOIMAPOperation *deleteOp = [strongSelf.imapSession expungeOperation:folder];
            [deleteOp start:^(NSError *error) {
                if (error) {
                    NSLog(@"Error expunging folder:%@", error);
                } else {
                    NSLog(@"Successfully expunged folder");
                }
            }];
        }
    }];
}

/**
 *  修改所有当前展示消息的标志
 *
 *  @param folder 文件夹
 *  @param kind   请求类型
 *  @param flags  标志
 */
- (void)storeAllShowingMessagesFlagsWithFolder:(NSString *)folder kind:(MCOIMAPStoreFlagsRequestKind)kind flags:(MCOMessageFlag)flags {
    NSArray *messages = [self showingMailListWithFolder:folder];
    NSUInteger numberOfMessages = [messages count];
    NSInteger totalNumber = [self totalNumberOfMessagesWithFolder:folder];
    
    //防止block中循环引用，导致无法释放
    __weak typeof(self) weakSelf = self;
    
    MCOIndexSet *indexSet = [MCOIndexSet indexSetWithRange:MCORangeMake(totalNumber - (numberOfMessages - 1), (numberOfMessages - 1))];
    MCOIMAPOperation *op = [self.imapSession storeFlagsOperationWithFolder:folder uids:indexSet kind:kind flags:flags];
    [op start:^(NSError * __nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (error) {
            [strongSelf handleWithImapError:error];
            NSLog(@"%@", error);
        }
    }];
}

/**
 *  对应文件夹消息全部已读
 *
 *  @param folder folder
 */
- (void)storeAllFlagSeenWithFolder:(NSString *)folder {
    //防止block中循环引用，导致无法释放
    __weak typeof(self) weakSelf = self;
    
    MCOIndexSet *indexSet = [MCOIndexSet indexSetWithRange:MCORangeMake(1, UINT64_MAX)];
    MCOIMAPOperation *op = [self.imapSession storeFlagsOperationWithFolder:folder uids:indexSet kind:MCOIMAPStoreFlagsRequestKindAdd flags:MCOMessageFlagSeen];
    [op start:^(NSError * __nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;

        if (error) {
            [strongSelf handleWithImapError:error];
            NSLog(@"%@", error);
        }
    }];
}

/**
 *  对应文件夹消息全部已读
 *
 *  @param folder folder
 */
- (void)getUnseenNumberWithFolder:(NSString *)folder completionBlock:(void (^)(NSError *error, NSInteger unseenNumber))completionBlock {
    //防止block中循环引用，导致无法释放
    __weak typeof(self) weakSelf = self;
    
    MCOIMAPFolderStatusOperation *inboxFolderInfo = [self.imapSession folderStatusOperation:folder];
    [inboxFolderInfo start:^(NSError * _Nullable error, MCOIMAPFolderStatus * _Nullable status) {
        __strong typeof(weakSelf) strongSelf = weakSelf;

        if (error) {
            [strongSelf handleWithImapError:error];
            NSLog(@"%@", error);
        }
        //记录未读邮件数
        NSUInteger unseenCount = [status unseenCount];
        if ([folder isEqualToString:MailFolderTypeINBOX]) {
            [strongSelf saveUnseenMessageNumberOfINBOX:unseenCount];
        }
        
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(error, unseenCount);
            });
        }
    }];
}

////////////////////////////////////////////////*******本地操作******////////////////////////////////////////////////

#pragma mark - 本地操作

/**
 *  删除对应文件夹的邮件数据
 *
 *  @param index  下标
 *  @param folder 文件夹
 */
- (void)removeMessageAtIndex:(NSUInteger)index withFolder:(NSString *)folder {
    if ([folder isEqualToString:MailFolderTypeDraft] || [folder isEqualToString:MailFolderTypeSending]) {//草稿箱，更新本地数据
        NSData *cachedData = [[NSUserDefaults standardUserDefaults] valueForKey:folder];
        NSMutableDictionary *dic = [NSKeyedUnarchiver unarchiveObjectWithData:cachedData];
        NSArray *array = [dic allValues];
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:MailSortKey ascending:NO];
        //根据邮件头里面的时间排序
        array = [array sortedArrayUsingDescriptors:@[sort]];
        ZGMailMessage *msg = array[index];
        [dic removeObjectForKey:msg.header.messageID];
        
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dic];
        [[NSUserDefaults standardUserDefaults] setValue:data forKey:folder];
    } else {
        NSMutableArray *array = [self.mailMessageListDic objectForKey:folder];
        if ([array count] > index) {
            [array removeObjectAtIndex:index];
            [self.mailMessageListDic setValue:array forKey:folder];
        } else {
            //数组越界，不处理
        }
    }
}

/**
 *  删除对应文件夹的邮件数据
 *
 *  @param indexSet 下标集合
 *  @param folder   文件夹
 */
- (void)removeMessageAtIndexes:(NSIndexSet *)indexSet withFolder:(NSString *)folder {
    NSMutableArray *array = [self.mailMessageListDic objectForKey:folder];
//    if ([array count] > index) {
//        [array removeObjectAtIndex:index];
        [array removeObjectsAtIndexes:indexSet];
        [self.mailMessageListDic setValue:array forKey:folder];
//    } else {
//        //数组越界，不处理
//    }
}

/**
 *  替换对应文件夹下的对应下标的邮件数据
 *
 *  @param array      新的数据
 *  @param indexPaths 要替换的下标
 *  @param folder     文件夹
 */
- (void)replaceMessagesInFolder:(NSString *)folder withNewMessages:(NSArray *)array atIndexPaths:(NSArray *)indexPaths {
    NSMutableArray *msgArray = [self.mailMessageListDic objectForKey:folder];
    
    for (NSInteger i = 0; i < [indexPaths count]; i++) {
        NSIndexPath *indexPath = [indexPaths objectAtIndex:i];
        NSInteger idx = indexPath.row;
        MCOIMAPMessage *msg = [array objectAtIndex:i];
        [msgArray replaceObjectAtIndex:idx withObject:msg];
    }
}

- (void)replaceMessagesWithArray:(NSMutableArray *)array folder:(NSString *)folder {
    [self.mailMessageListDic setValue:array forKey:folder];
}

/**
 *  修改邮件
 *
 *  @param folder  目录
 *  @param index   下标
 *  @param message 新的消息实例
 */
- (void)setMessageWithFolder:(NSString *)folder index:(NSUInteger)index newMessage:(MCOIMAPMessage *)message {
    NSMutableArray *array = [self.mailMessageListDic objectForKey:folder];
    if ([array count] > index) {
        [array replaceObjectAtIndex:index withObject:message];
        [self.mailMessageListDic setValue:array forKey:folder];
    } else {
        //数组越界，不处理
    }
}

- (MCOIMAPMessageRenderingOperation *)messageRenderingOperationWithMessage:(MCOIMAPMessage *)message folder:(NSString *)folder {
    return [self.imapSession plainTextBodyRenderingOperationWithMessage:message folder:folder];
}


////////////////////////////////////////////////*******发送邮件******////////////////////////////////////////////////

#pragma mark - 邮件发送

- (void)sendMessageWithHeader:(MCOMessageHeader *)header textBody:(NSString *)textBody attachments:(NSArray *)attachments {
    [self sendMessageWithHeader:header textBody:textBody attachments:attachments originMessage:nil originMessageAttachments:nil originMessageHtmlString:nil originMessageFolder:nil];
}

- (void)sendMessageWithHeader:(MCOMessageHeader *)header textBody:(NSString *)textBody attachments:(NSArray *)attachments originMessage:(MCOIMAPMessage *)originMessage originMessageAttachments:(NSArray *)originMessageAttachments originMessageHtmlString:(NSString *)originMessageHtmlString originMessageFolder:(NSString *)originMessageFolder {
    MCOMessageBuilder *builder = [[MCOMessageBuilder alloc] init];
    builder.header = header;
    
    //文本包装成HTML标签
    NSString *bodyText = [NSString stringWithFormat:@"<div>%@</div>", textBody];
    //设置文本内容：拼接原始邮件htmlString
    textBody = [textBody stringByReplacingOccurrencesOfString:@"\n" withString:@"<br/>"];
    if (!IsEmptyString(originMessageHtmlString)) {
        textBody = [textBody stringByAppendingString:originMessageHtmlString];
    }
    builder.htmlBody = textBody;
    
    //附件
    if (originMessage) {
        //添加正文里的附加资源
        NSArray *inattachments = originMessage.htmlInlineAttachments;
        for (MCOIMAPPart *part in inattachments) {
            NSString *path = [self cachePathForPart:part withMessageID:originMessage.header.messageID];
            NSData *data = [NSData dataWithContentsOfFile:path];
            if (data) {
                MCOAttachment *attachment = [MCOAttachment attachmentWithContentsOfFile:path];
                [attachment setInlineAttachment:YES];
                [attachment setContentID:part.contentID];
                [builder addRelatedAttachment:attachment];//添加html正文里的附加资源（图片）
            } else {
                
            }
        }
        
        //原始邮件附件
        [originMessageAttachments enumerateObjectsUsingBlock:^(MCOIMAPPart *part, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *path = [self cachePathForPart:part withMessageID:originMessage.header.messageID];
            NSData *data = [NSData dataWithContentsOfFile:path];
            if (data) {
                MCOAttachment *attachment = [MCOAttachment attachmentWithData:data filename:part.filename];
                [builder addAttachment:attachment];
            } else {
                
            }
        }];
    }

    //新邮件附件
    [attachments enumerateObjectsUsingBlock:^(NSString *imageName, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *path = [self pathOfImageDataStoreWithMessageID:header.messageID imageName:imageName];
        MCOAttachment *attachment = [MCOAttachment attachmentWithContentsOfFile:path];
        [builder addAttachment:attachment];
    }];

    //保存邮件到发件箱
    ZGMailMessage *mailMessage = [[ZGMailMessage alloc] init];
    mailMessage.messageStatus = MailMessageStatus_Wait;//等待发送
    mailMessage.header = header;
    mailMessage.bodyText = bodyText;
    mailMessage.attachmentsFilenameArray = attachments;
    mailMessage.originImapMessage = originMessage;
    mailMessage.originMessageParts = originMessageAttachments;
    mailMessage.originMessageFolder = originMessageFolder;
    [self insertOrUpdateMailMessageInUserDefaultForFolder:MailFolderTypeSending message:mailMessage];

    //保存到发送列表
    [self.sendMessageArray addObject:builder];
    if (self.sendMessageArray.count > 1 && self.sendingOperation) {//有正在发送的消息
        //等待
        NSUInteger index = [self.sendMessageArray indexOfObject:self.sendingBuilder];
        index = index + 1;
        NSUInteger count = self.sendMessageArray.count;
        NSString *str = [NSString stringWithFormat:@"%lu/%lu", (unsigned long)index, (unsigned long)count];
        [self.sendMailTopIndicator setProgressLabel:str];
    } else {
        [self sendMessage:builder];
    }
}

////////////////////////////////////////////////*******邮件发送指示器操作******////////////////////////////////////////////////

#pragma makr - 邮件发送指示器操作

/**
 *  展示邮件发送指示器
 */
- (void)showSendMailTopIndicator {
    //没有消息正在发送，也没有要发送的消息
    if (!self.sendingOperation && self.sendMessageArray.count == 0) {
        return;
    }
    
    //展示指示器
    [self.sendMailTopIndicator show];
    NSUInteger count = self.sendMessageArray.count;
    if (count > 1) {
        NSUInteger index = [self.sendMessageArray indexOfObject:self.sendingBuilder];
        index = index + 1;
        NSString *str = [NSString stringWithFormat:@"%lu/%lu", (unsigned long)index, (unsigned long)count];
        [self.sendMailTopIndicator setProgressLabel:str];
    } else {
        [self.sendMailTopIndicator setProgressLabel:@""];
    }

    //防止block中循环引用，导致无法释放
    __weak typeof(self) weakSelf = self;
    
    MCOSMTPSendOperation *sendOperation = self.sendingOperation;
    [sendOperation setProgress:^(unsigned int current, unsigned int maximum) {
        __strong typeof(weakSelf) strongSelf = weakSelf;

        float progress = (float)current / maximum;
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf.sendMailTopIndicator setProgress:progress];
        });
    }];
}

/**
 *  隐藏邮件发送指示器
 */
- (void)hideSendMailTopIndicator {
    [self.sendMailTopIndicator hide];
}

////////////////////////////////////////////////*******接收的邮件附件操作******////////////////////////////////////////////////

#pragma mark - 邮件附件操作

/**
 *  根据part生成存储地址
 */
- (NSString *)cachePathForPart:(MCOAbstractPart *)part withMessageID:(NSString *)messageID {
    //mimeType: text/html类型的part没有contentID和fileName
    NSString *key = @"";
    if (!IsEmptyString(part.contentID)) {
        key = [part.contentID stringByAppendingString:part.filename];
    } else {
        key = part.filename;
    }
    if (IsEmptyString(key)) {
        return nil;
    } else {
        NSString *tmpDir = NSTemporaryDirectory();
        //创建文件管理对象
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *dirPath = [tmpDir stringByAppendingPathComponent:messageID];
        if (![fileManager fileExistsAtPath:dirPath]) {//文件夹不存在，创建文件夹
            NSError *error = nil;
            [fileManager createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:@{} error:&error];
            NSLog(@"创建文件夹%@", error);
        }

        NSString *path = [dirPath stringByAppendingPathComponent:key];
      
        return path;
    }
}

/**
 *  保存数据到本地
 */
- (void)cacheData:(NSData *)data forPart:(MCOAbstractPart *)part withMessageID:(NSString *)messageID {
    NSString *path = [self cachePathForPart:part withMessageID:messageID];
    if (!IsEmptyString(path)) {
        BOOL success = [data writeToFile:path atomically:YES];
        if (success) {
            NSLog(@"cache success");
        } else {
            NSLog(@"cache failure");
        }
    }
}



////////////////////////////////////////////////*******草稿箱和发件箱本地数据操作******////////////////////////////////////////////////

#pragma mark - 草稿箱和发件箱本地数据操作

- (ZGMailMessage *)messageInUserDefaultForFolder:(NSString *)folder messageID:(NSString *)messageID {
    NSData *cachedData = [[NSUserDefaults standardUserDefaults] valueForKey:folder];
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:[NSKeyedUnarchiver unarchiveObjectWithData:cachedData]];
    
    ZGMailMessage *message = [dic objectForKey:messageID];
    
    return message;
}

- (void)removeMailMessageFromUserDefaultForFolder:(NSString *)folder messageID:(NSString *)messageID {
    NSData *cachedData = [[NSUserDefaults standardUserDefaults] valueForKey:folder];
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:[NSKeyedUnarchiver unarchiveObjectWithData:cachedData]];
    
    [dic removeObjectForKey:messageID];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dic];
    [[NSUserDefaults standardUserDefaults] setValue:data forKey:folder];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSArray *)localMailArrayForFolder:(NSString *)folder {
    NSData *cachedData = [[NSUserDefaults standardUserDefaults] valueForKey:folder];
    if ([folder isEqualToString:MailFolderTypeINBOX] || [folder isEqualToString:MailFolderTypeSent]) {
        NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithData:cachedData];
        //根据邮件头里面的时间排序
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:MailSortKey ascending:NO];
        array = [array sortedArrayUsingDescriptors:@[sort]];

        return array;
    } else {
        if (cachedData) {
            NSMutableDictionary *dic = [NSKeyedUnarchiver unarchiveObjectWithData:cachedData];
            NSArray *array = [dic allValues];
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:MailSortKey ascending:NO];
            //根据邮件头里面的时间排序
            array = [array sortedArrayUsingDescriptors:@[sort]];
            
            return array;
        } else {
            return nil;
        }
    }
}

- (void)insertOrUpdateMailMessageInUserDefaultForFolder:(NSString *)folder message:(ZGMailMessage *)message {
    NSData *cachedData = [[NSUserDefaults standardUserDefaults] valueForKey:folder];
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:[NSKeyedUnarchiver unarchiveObjectWithData:cachedData]];
    
    [dic setValue:message forKey:message.header.messageID];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dic];
    NSLog(@"insertOrUpdate,dataSize:%@", [NSString formatStringOfSize:data.length]);
    [[NSUserDefaults standardUserDefaults] setValue:data forKey:folder];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

//保存收件箱和已发送的数据
- (void)saveMailListForFolder:(NSString *)folder {
    if ([folder isEqualToString:MailFolderTypeINBOX] || [folder isEqualToString:MailFolderTypeSent]) {
        NSArray *array = [self showingMailListWithFolder:folder];
        if (array.count > 20) {
            NSIndexSet *set = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 20)];
            array = [array objectsAtIndexes:set];
        } else {
            array = array;
        }
        
        //保存第一页的数据
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:array];
        [[NSUserDefaults standardUserDefaults] setValue:data forKey:folder];
    }
}

////////////////////////////////////////////////*******待发送邮件附件本地操作******////////////////////////////////////////////////

#pragma mark - 待发送邮件附件本地操作

/**
 *  根据邮件消息ID和图片名称，保存图片到磁盘
 *
 *  @param imageData 图片数据
 *  @param messageID 邮件消息ID
 *  @param imageName 图片名称
 */
- (void)storeImageDataToDisk:(NSData *)imageData messageID:(NSString *)messageID imageName:(NSString *)imageName {
    NSString *path = [self pathOfImageDataStoreWithMessageID:messageID imageName:imageName];
    BOOL success = [imageData writeToFile:path atomically:YES];
    if (success) {
        NSLog(@"保存图片成功");
    } else {
        NSLog(@"保存图片失败");
    }
}

/**
 *  根据邮件消息ID和图片名称删除图片
 *
 *  @param messageID 邮件消息ID
 *  @param imageName 图片名称
 */
- (void)removeImageFromDiskWithMessageID:(NSString *)messageID imageName:(NSString *)imageName {
    NSString *path = [self pathOfImageDataStoreWithMessageID:messageID imageName:imageName];
    // 创建文件管理对象
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    [fileManager removeItemAtPath:path error:&error];
    NSLog(@"删除图片%@", error);
}

/**
 *  删除对应邮件消息ID的图片存储目录
 *
 *  @param messageID 邮件消息ID
 */
- (void)removeImageStoreDirectoryFromDiskForMessageID:(NSString *)messageID {
    //根据邮件消息ID生成缓存图片的目录
    NSString *dirPath = [self directoryPathForMessageID:messageID];
    // 创建文件管理对象
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:dirPath]) {//文件夹存在，删除这个文件夹
        NSError *error = nil;
        [fileManager removeItemAtPath:dirPath error:&error];
        NSLog(@"删除文件夹%@", error);
    } else {
        //不存在不需要处理
    }
}

/**
 *  根据邮件消息ID和图片名称生成图片保存的地址
 *
 *  @param messageID 邮件消息ID
 *  @param imageName 图片名称
 *
 *  @return 地址
 */
- (NSString *)pathOfImageDataStoreWithMessageID:(NSString *)messageID imageName:(NSString *)imageName {
    //根据邮件消息ID生成缓存图片的目录
    NSString *dirPath = [self directoryPathForMessageID:messageID];
    //创建文件管理对象
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:dirPath]) {//文件夹不存在，创建文件夹
        NSError *error = nil;
        [fileManager createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:@{} error:&error];
        NSLog(@"创建文件夹%@", error);
    }
    
    NSString *path = [NSString stringWithFormat:@"%@/%@", dirPath, imageName];
   
    return path;
}

/**
 *  根据文件名返回相应的文件Icon名称
 */
- (NSString *)imageNameWithFileName:(NSString *)fileName imageSizeType:(ImageSizeType)sizeType {
    NSString *suffix = [fileName pathExtension];
    suffix = [suffix lowercaseString];
    NSString *imageName = @"";
    NSString *imageNameSuffix = @"";
    if (sizeType == ImageSizeTypeSmall) {
        imageNameSuffix = @"51h";
    } else {
        imageNameSuffix = @"105h";
    }
    if ([suffix isEqualToString:@"doc"] || [suffix isEqualToString:@"docx"]) {//doc
        imageName = @"filetype_word_";
    } else if ([suffix isEqualToString:@"jpg"] || [suffix isEqualToString:@"png"]) {//jpg
        imageName = @"filetype_image_";
    } else if ([suffix isEqualToString:@"text"]) {//text
        imageName = @"filetype_txt_";
    } else if ([suffix isEqualToString:@"pdf"]) {//pdf
        imageName = @"filetype_pdf_";
    } else if ([suffix isEqualToString:@"xlsx"]) {//xlsx
        imageName = @"filetype_excel_";
    } else {
        imageName = @"filetype_others_";
    }
    
    imageName = [imageName stringByAppendingString:imageNameSuffix];
    
    return imageName;
}

//#pragma mark - CTAPIManagerCallBackDelegate
//
//- (void)managerCallAPIDidSuccess:(CTAPIBaseManager *)manager {
//    NSDictionary *dic = [manager fetchDataWithReformer:nil];
//    if (manager == self.configApiManager) {
//        NSDictionary *data = [dic objectForKey:@"mail"];
//        if (data) {
//            NSString *imapAddress = [data objectForKey:@"imapAddress"];
//            NSNumber *imapPort = [data objectForKey:@"imapPort"];
//            NSString *smtpAddress = [data objectForKey:@"smtpAddress"];
//            NSNumber *smtpPort = [data objectForKey:@"smtpPort"];
//            
//            [[NSUserDefaults standardUserDefaults] setObject:imapAddress forKey:IMAPAddress_KEY];
//            [[NSUserDefaults standardUserDefaults] setObject:imapPort forKey:IMAPPort_KEY];
//            [[NSUserDefaults standardUserDefaults] setObject:smtpAddress forKey:SMTPAddress_KEY];
//            [[NSUserDefaults standardUserDefaults] setObject:smtpPort forKey:SMTPPort_KEY];
//            
//            //关闭之前的连接，重建连接
//            MCOIMAPOperation *op = [self.imapSession disconnectOperation];
//            [op start:^(NSError * __nullable error) {
//                NSLog(@"disconnectOperation:%@", error);
//            }];
//            self.imapSession = nil;
//            
//            //重新建立连接
//            //设置服务器地址和端口
//            self.imapSession.hostname = imapAddress;
//            self.imapSession.port = [imapPort unsignedIntValue];
//            
//            HikContactsInfoRecord *accountInfoRecord = [HikAccountInfoManager sharedInstance].accountInfoRecord;
//            self.imapSession.username = accountInfoRecord.inmailAddress;
//            
//            NSString *mailPassword = [[NSUserDefaults standardUserDefaults] stringForKey:MailPassword_KEY];
//            if (mailPassword) {
//                NSString *password = [RSA decryptString:mailPassword publicKey:publickey];
//                self.imapSession.password = password;
//                
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    if (!self.checkTimer) {
//                        self.checkTimer = [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(checkInboxNewMessage) userInfo:nil repeats:YES];//timer自动添加到NSDefaultRunLoopMode中去执行
//                        [self.checkTimer fire];//马上执行一次
//                    }
//                });
//            } else {
//                [self.passwordDecryptApiManager loadData];
//            }
//        } else {
//            
//        }
//    } else {
//        NSString *data = [dic objectForKey:@"data"];
//        [[NSUserDefaults standardUserDefaults] setValue:data forKey:MailPassword_KEY];
//        
//        NSString *password = [RSA decryptString:data publicKey:publickey];
//        self.imapSession.password = password;
//        dispatch_async(dispatch_get_main_queue(), ^{
//            if (!self.checkTimer.isValid) {
//                self.checkTimer = [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(checkInboxNewMessage) userInfo:nil repeats:YES];//timer自动添加到NSDefaultRunLoopMode中去执行
//                [self.checkTimer fire];
//            }
//        });
//    }
//}

//- (void)managerCallAPIDidFailed:(CTAPIBaseManager *)manager {
//    if (manager == self.configApiManager) {//邮箱配置
////        NSString *host = [[NSUserDefaults standardUserDefaults] stringForKey:IMAPAddress_KEY];
////        if (IsEmptyString(host)) {
////            [self.configApiManager loadData];
////        }
//    } else {//邮箱密码
//        NSString *mailPassword = [[NSUserDefaults standardUserDefaults] stringForKey:MailPassword_KEY];
//        if (IsEmptyString(mailPassword)) {
//            [self.passwordDecryptApiManager loadData];
//        }
//    }
//}

//#pragma mark - CTAPIManagerParamSource
//
//- (NSDictionary *)paramsForApi:(CTAPIBaseManager *)manager {
//    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
//    if (manager == self.passwordDecryptApiManager) {
//        NSString *rsaPassword = [[NSUserDefaults standardUserDefaults] valueForKey:Password_KEY];
//        [dic setValue:rsaPassword forKey:@"text"];
//    }
//    
//    return dic;
//}

#pragma mark - private method

- (NSUInteger)totalNumberOfMessagesWithFolder:(NSString *)folder {
    return [[self.totalNumberOfMessagesDic objectForKey:folder] unsignedIntegerValue];
}

/**
 *  根据邮件消息ID生成缓存图片的目录
 *
 *  @param messageID 邮件消息ID
 *
 *  @return 图片缓存地址
 */
- (NSString *)directoryPathForMessageID:(NSString *)messageID {
    //创建图片缓存路径
    NSString *cacheDirPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *dirPath = [cacheDirPath stringByAppendingPathComponent:@"mailPicture"];
    dirPath = [dirPath stringByAppendingPathComponent:messageID];
    
    return dirPath;
}

- (void)sendMessage:(MCOMessageBuilder *)builder {
    self.sendingBuilder = builder;
    ZGMailMessage *msg = [self messageInUserDefaultForFolder:MailFolderTypeSending messageID:builder.header.messageID];
    msg.header.date = [NSDate date];
    msg.messageStatus = MailMessageStatus_Sending;
    [self insertOrUpdateMailMessageInUserDefaultForFolder:MailFolderTypeSending message:msg];
    //发送通知，刷新发件箱
    [[NSNotificationCenter defaultCenter] postNotificationName:MailSendingFolderReloadNotification object:nil];
    msg = nil;
    
    NSData *rfc822Data = [builder data];
    MCOSMTPSendOperation *sendOperation = [self.smtpSession sendOperationWithData:rfc822Data];
    sendOperation.shouldRunWhenCancelled = NO;
    self.sendingOperation = sendOperation;
    
    //防止block中循环引用，导致无法释放
    __weak typeof(self) weakSelf = self;
    [sendOperation setProgress:^(unsigned int current, unsigned int maximum) {
        __strong typeof(weakSelf) strongSelf = weakSelf;

        float progress = (float)current / maximum;
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf.sendMailTopIndicator setProgress:progress];
        });
    }];
    //展示指示器
    [self.sendMailTopIndicator show];
    
    [sendOperation start:^(NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;

        if (error) {
            NSLog(@"%@", error);
        }
        strongSelf.sendingOperation = nil;
        
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf.sendMailTopIndicator showFailureView];
            });
            
            NSLog(@"Error sending email:%@", error);
            NSString *failureString = @"";
            if (error.code == 27) {//邮件太大：The SMTP storage limit was hit while trying to send a large message.
                failureString = @"邮件大小超过限制，发送失败";
            } else if (error.code == 1) {//A stable connection to the server could not be established.
                failureString = @"连接不稳定，发送失败";
            } else {
                failureString = @"发送失败";
            }
            
            //全部邮件发送失败
            [strongSelf.sendMessageArray enumerateObjectsUsingBlock:^(MCOMessageBuilder *builder, NSUInteger idx, BOOL * _Nonnull stop) {
                ZGMailMessage *mailMessage = [strongSelf messageInUserDefaultForFolder:MailFolderTypeSending messageID:builder.header.messageID];
                mailMessage.messageStatus = MailMessageStatus_Failure;
                mailMessage.failureString = failureString;
                [strongSelf insertOrUpdateMailMessageInUserDefaultForFolder:MailFolderTypeSending message:mailMessage];
            }];
            [strongSelf.sendMessageArray removeAllObjects];
            strongSelf.sendingBuilder = nil;
            //发送通知，刷新发件箱
            [[NSNotificationCenter defaultCenter] postNotificationName:MailSendingFolderReloadNotification object:nil];
            
            
            //TODO
            //如果是因为没有网络导致的失败，列表中全部的邮件都失败
            //如果是因为像邮件超大导致的失败，继续发送下一封邮件
        } else {//发送成功
            NSLog(@"Successfully sent email!");
            if (strongSelf.sendMessageArray.count == 1) {//只有一个消息
                dispatch_async(dispatch_get_main_queue(), ^{
                    [strongSelf.sendMailTopIndicator showSuccessView];
                });
                [strongSelf.sendMessageArray removeAllObjects];
                strongSelf.sendingBuilder = nil;
            } else {
                NSUInteger index = [strongSelf.sendMessageArray indexOfObject:builder];
                if (index == strongSelf.sendMessageArray.count - 1) {//已经是最后一条消息，全部发送成功
                    strongSelf.sendingBuilder = nil;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [strongSelf.sendMailTopIndicator showSuccessViewWithTotalCount:strongSelf.sendMessageArray.count];
                    });
                    [strongSelf.sendMessageArray removeAllObjects];
                } else {
                    //继续发送下一条消息
                    NSUInteger nextItemIndex = index + 1;
                    MCOMessageBuilder *builder = [strongSelf.sendMessageArray objectAtIndex:nextItemIndex];
                    nextItemIndex = nextItemIndex + 1;
                    NSString *str = [NSString stringWithFormat:@"%lu/%lu", (unsigned long)nextItemIndex, (unsigned long)strongSelf.sendMessageArray.count];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [strongSelf.sendMailTopIndicator setProgressLabel:str];
                    });
                    [strongSelf sendMessage:builder];
                }
            }
            
            //消息从发件箱移除
            [strongSelf removeMailMessageFromUserDefaultForFolder:MailFolderTypeSending messageID:builder.header.messageID];
            MCOIMAPAppendMessageOperation *op = [strongSelf.imapSession appendMessageOperationWithFolder:MailFolderTypeSent messageData:rfc822Data flags:MCOMessageFlagSeen];
            [op start:^(NSError * _Nullable error, uint32_t createdUID) {
                if (error) {
                    NSLog(@"%@", error);
                }
            }];
            
            //发送通知，刷新发件箱
            [[NSNotificationCenter defaultCenter] postNotificationName:MailSendingFolderReloadNotification object:nil];
        }
    }];
}

/**
 *  发起本地消息推送
 */
- (void)postLocalNotificaiton {
    UIApplicationState state = [UIApplication sharedApplication].applicationState;
    if (state == UIApplicationStateBackground) {//发起本地消息推送
        UILocalNotification *noti = [[UILocalNotification alloc] init];
        if (noti) {
            //            设置推送时间
            //            noti.fireDate = [NSDate date];//=now
            //设置时区
            noti.timeZone = [NSTimeZone defaultTimeZone];
            //设置重复间隔
            noti.repeatInterval = 0;
            //推送声音
            noti.soundName = UILocalNotificationDefaultSoundName;
            //内容
            noti.alertBody = @"您有新邮件";
//            //显示在icon上的红色圈中的数字
//            NSInteger count = [[HikConversationModule sharedInstance] getAllUnreadMessageCount];
//            if (count == 0) {
//                count = 1;
//            }
            noti.applicationIconBadgeNumber = 1;
            
            //            //设置userinfo 方便在之后需要撤销的时候使用
            //            NSDictionary *infoDic = [NSDictionary dictionaryWithObject:@"name" forKey:@"key"];
            //            noti.userInfo = infoDic;
            
            //添加推送到uiapplication
            UIApplication *app = [UIApplication sharedApplication];
            [app presentLocalNotificationNow:noti];
        }
    }
}

- (void)handleWithImapError:(NSError *)error {
    NSLog(@"handleWithImapError: %@", error);
    if (error.code == 1) {//Error Domain=MCOErrorDomain Code=1 "A stable connection to the server could not be established." UserInfo={NSLocalizedDescription=A stable connection to the server could not be established.}
        if (self.internetConnectionReach.isReachable) {//网络可达
            
        } else {//断网
            
        }
    } else if (error.code == 5) {//Error Domain=MCOErrorDomain Code=5 "Unable to authenticate with the current session's credentials." UserInfo={NSLocalizedDescription=Unable to authenticate with the current session's credentials.}
        
    } else {
        
    }
}

/**
 *  网络监测
 */
- (void)networkReachability {
    NSString *host = @"";
    self.internetConnectionReach = [TMReachability reachabilityWithHostName:host];
    
    self.internetConnectionReach.reachableBlock = ^(TMReachability * reachability) {

    };
    
    self.internetConnectionReach.unreachableBlock = ^(TMReachability * reachability) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
        });
    };
    
    [self.internetConnectionReach startNotifier];
}

#pragma mark - setter and getter

- (MCOIMAPSession *)imapSession {
    if (_imapSession == nil) {
        _imapSession = [[MCOIMAPSession alloc] init];
        _imapSession.username = self.mailAddress;
        _imapSession.password = self.password;
        _imapSession.hostname = self.imapHost;
        _imapSession.port = self.imapPort;
        _imapSession.timeout = 15;
        _imapSession.checkCertificateEnabled = NO;
        _imapSession.connectionType = MCOConnectionTypeTLS;
        _imapSession.allowsFolderConcurrentAccessEnabled = YES;
        _imapSession.dispatchQueue = dispatch_queue_create("com.mailModule.imapSession", DISPATCH_QUEUE_SERIAL);//串行队列
    }
    
    return _imapSession;
}

- (MCOSMTPSession *)smtpSession {
    if (_smtpSession == nil) {
        _smtpSession = [[MCOSMTPSession alloc] init];
        _smtpSession.hostname = self.smtpHost;
        _smtpSession.port = self.smtpPort;
        _smtpSession.username = self.mailAddress;
        _smtpSession.password = self.password;
        _smtpSession.checkCertificateEnabled = NO;
        _smtpSession.connectionType = MCOConnectionTypeTLS;
        _smtpSession.dispatchQueue = dispatch_queue_create("com.mailModule.smtpSession", DISPATCH_QUEUE_SERIAL);//串行队列
    }
    
    return _smtpSession;
}

- (NSMutableDictionary *)totalNumberOfMessagesDic {
    if (_totalNumberOfMessagesDic == nil) {
        _totalNumberOfMessagesDic = [[NSMutableDictionary alloc] init];
    }
    
    return _totalNumberOfMessagesDic;
}

- (NSMutableDictionary *)mailMessageListDic {
    if (_mailMessageListDic == nil) {
        _mailMessageListDic = [[NSMutableDictionary alloc] init];
    }
    
    return _mailMessageListDic;
}

- (NSMutableArray *)sendMessageArray {
    if (_sendMessageArray == nil) {
        _sendMessageArray = [[NSMutableArray alloc] init];
    }
    
    return _sendMessageArray;
}

- (ZGSendMailTopIndicator *)sendMailTopIndicator {
    if (_sendMailTopIndicator == nil) {
        _sendMailTopIndicator = [[ZGSendMailTopIndicator alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    }
    
    return _sendMailTopIndicator;
}

@end
