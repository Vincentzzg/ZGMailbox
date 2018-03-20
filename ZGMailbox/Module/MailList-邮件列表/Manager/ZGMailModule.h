//
//  ZGMailModule.h
//  ZGMailbox
//
//  Created by zzg on 2017/3/21.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MailCore/MCOConstants.h>

@class MCOIMAPMessageRenderingOperation;
@class MCOIMAPMessage;
@class MCOIMAPSession;
@class MCOMessageBuilder;
@class MCOAbstractPart;
@class MCOMessageHeader;
@class MCOSMTPSendOperation;
@class ZGMailMessage;

#define NUMBER_OF_MESSAGES_TO_LOAD		20

typedef NS_ENUM(NSUInteger, ImageSizeType) {
    ImageSizeTypeSmall,//小的51
    ImageSizeTypeLarge,//大的105
};

@interface ZGMailModule : NSObject

@property (nonatomic, strong) MCOIMAPSession *imapSession;
@property (nonatomic, copy, readonly) NSString *mailAddress;

+ (instancetype)sharedInstance;

///设置邮箱地址和密码
- (void)setMailAddress:(NSString *)mailAddress password:(NSString *)password;
    
/**
 *  根据文件夹类型获取邮件列表数据
 *
 *  @param folder   文件夹类型
 *
 *  @return 返回对应文件夹下的邮件数组
 */
- (NSArray *)showingMailListWithFolder:(NSString *)folder;

/**
 *  保存收件箱未读邮件数
 *
 *  @param unseenNumber 未读邮件数
 */
- (void)saveUnseenMessageNumberOfINBOX:(NSUInteger)unseenNumber;

/**
 *  获取收件箱未读邮件数
 *
 *  @return 返回收件箱
 */
- (NSUInteger)unseenMessageNumberOfINBOX;

/**
 *  获取正在发送的邮件的发送操作对象
 *
 *  @return 操作对象
 */
- (MCOSMTPSendOperation *)sendingOperation;

/**
 *  取消邮件的发送
 *
 *  @param messageID 邮件消息id
 */
- (void)stopSendOperationOfMessage:(NSString *)messageID;

/**
 *  设置发送中的消息为失败（客户端被强制关闭时使用）
 */
- (void)setSendingMailMessageFailure;

/**
 *  关闭邮件检查时间程
 */
- (void)stopMailCheckTimer;


////////////////////////////////////////////////*******邮件相关请求******////////////////////////////////////////////////

///**
// *  获取邮箱配置信息
// */
//- (void)getMailConfigInformation;

///**
// *  检查账户是否正确
// *
// *  @param completionBlock
// */
//- (void)checkAccount:(void (^)(NSError *error))completionBlock;

/**
 *  检查收件箱新邮件
 *
 */
- (void)checkInboxNewMessage;

/**
 *  检查收件箱新邮件
 *
 */
- (void)checkInboxNewMessage:(void (^)(BOOL hasNewMail))completionBlock;

/**
 *  加载更多邮件
 */
- (void)loadMoreHistoryMessagesInFolder:(NSString *)folder completion:(void (^)(NSError *error, NSArray *mailListArray))completion;

/**
 *  更新邮件列表
 *
 *  @param folder     文件夹
 *  @param completion 成功block
 */
- (void)updateMailListWithFolder:(NSString *)folder completion:(void (^)(NSError *error, NSArray *mailListArray))completion;

/**
 *  修改消息的标志
 *
 *  @param folder   目录
 *  @param messages 消息数组
 *  @param kind     请求类型
 *  @param flags    标志
 */
- (void)storeFlagsWithFolder:(NSString *)folder messages:(NSArray *)messages kind:(MCOIMAPStoreFlagsRequestKind)kind flags:(MCOMessageFlag)flags;

/**
 *  修改所有当前展示消息的标志
 *
 *  @param folder 文件夹
 *  @param kind   请求类型
 *  @param flags  标志
 */
- (void)storeAllShowingMessagesFlagsWithFolder:(NSString *)folder kind:(MCOIMAPStoreFlagsRequestKind)kind flags:(MCOMessageFlag)flags;

/**
 *  对应文件夹消息全部已读
 *
 *  @param folder folder
 */
- (void)storeAllFlagSeenWithFolder:(NSString *)folder;

/**
 *  获取未读消息个数
 *
 *  @param folder          文件夹
 *  @param completionBlock 成功block回调
 */
- (void)getUnseenNumberWithFolder:(NSString *)folder  completionBlock:(void (^)(NSError *error, NSInteger unseenNumber))completionBlock;


////////////////////////////////////////////////*******本地操作******////////////////////////////////////////////////

/**
 *  删除对应文件夹的邮件数据
 *
 *  @param index  下标
 *  @param folder 文件夹
 */
- (void)removeMessageAtIndex:(NSUInteger)index withFolder:(NSString *)folder;

/**
 *  删除对应文件夹的邮件数据
 *
 *  @param indexSet  下标集合
 *  @param folder    文件夹
 */
- (void)removeMessageAtIndexes:(NSIndexSet *)indexSet withFolder:(NSString *)folder;

/**
 *  替换对应文件夹下的对应下标的邮件数据
 *
 *  @param array      新的数据
 *  @param indexPaths 要替换的下标
 *  @param folder     文件夹
 */
- (void)replaceMessagesInFolder:(NSString *)folder withNewMessages:(NSArray *)array atIndexPaths:(NSArray *)indexPaths;

- (void)replaceMessagesWithArray:(NSMutableArray *)array folder:(NSString *)folder;

/**
 *  修改邮件
 *
 *  @param folder  目录
 *  @param index   下标
 *  @param message 新的消息实例
 */
- (void)setMessageWithFolder:(NSString *)folder index:(NSUInteger)index newMessage:(MCOIMAPMessage *)message;

- (MCOIMAPMessageRenderingOperation *)messageRenderingOperationWithMessage:(MCOIMAPMessage *)message folder:(NSString *)folder;



////////////////////////////////////////////////*******发送邮件******////////////////////////////////////////////////

- (void)sendMessageWithHeader:(MCOMessageHeader *)header textBody:(NSString *)textBody attachments:(NSArray *)attachments;

- (void)sendMessageWithHeader:(MCOMessageHeader *)header textBody:(NSString *)textBody attachments:(NSArray *)attachments originMessage:(MCOIMAPMessage *)originMessage originMessageAttachments:(NSArray *)originMessageAttachments originMessageHtmlString:(NSString *)originMessageHtmlString originMessageFolder:(NSString *)originMessageFolder;


////////////////////////////////////////////////*******接收的邮件附件操作******////////////////////////////////////////////////

/**
 *  根据part生成附件存储地址
 *
 *  @param part 附件组件
 *
 *  @return     邮件消息id
 */
- (NSString *)cachePathForPart:(MCOAbstractPart *)part withMessageID:(NSString *)messageID;

/**
 *  保存数据到本地
 *
 */
- (void)cacheData:(NSData *)data forPart:(MCOAbstractPart *)part  withMessageID:(NSString *)messageID;


////////////////////////////////////////////////*******草稿箱和发件箱本地数据操作******////////////////////////////////////////////////

- (void)removeMailMessageFromUserDefaultForFolder:(NSString *)folder messageID:(NSString *)messageID;

- (void)insertOrUpdateMailMessageInUserDefaultForFolder:(NSString *)folder message:(ZGMailMessage *)message;

- (NSArray *)localMailArrayForFolder:(NSString *)folder;

- (void)saveMailListForFolder:(NSString *)folder;


////////////////////////////////////////////////*******邮件发送指示器操作******////////////////////////////////////////////////

/**
 *  展示邮件发送指示器
 */
- (void)showSendMailTopIndicator;

/**
 *  隐藏邮件发送指示器
 */
- (void)hideSendMailTopIndicator;



////////////////////////////////////////////////*******待发送邮件附件本地操作******////////////////////////////////////////////////

/**
 *  根据邮件消息ID和图片名称，保存图片到磁盘
 *
 *  @param imageData 图片数据
 *  @param messageID 邮件消息ID
 *  @param imageName 图片名称
 */
- (void)storeImageDataToDisk:(NSData *)imageData messageID:(NSString *)messageID imageName:(NSString *)imageName;

/**
 *  根据邮件消息ID和图片名称删除图片
 *
 *  @param messageID 邮件消息ID
 *  @param imageName 图片名称
 */
- (void)removeImageFromDiskWithMessageID:(NSString *)messageID imageName:(NSString *)imageName;

/**
 *  删除对应邮件消息ID的图片存储目录
 *
 *  @param messageID 邮件消息ID
 */
- (void)removeImageStoreDirectoryFromDiskForMessageID:(NSString *)messageID;

/**
 *  根据邮件消息ID和图片名称生成图片保存的地址
 *
 *  @param messageID 邮件消息ID
 *  @param imageName 图片名称
 *
 *  @return 地址
 */
- (NSString *)pathOfImageDataStoreWithMessageID:(NSString *)messageID imageName:(NSString *)imageName;

/**
 *  根据文件名返回相应的文件Icon名称
 */
- (NSString *)imageNameWithFileName:(NSString *)fileName imageSizeType:(ImageSizeType)sizeType;

@end
