//
//  ZGMailMessageDetailViewController.m
//  ZGMailbox
//
//  Created by zzg on 2017/3/27.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import "ZGMailMessageDetailViewController.h"
#import "ZGNewMailViewController.h"//写邮件页面
#import "ZGMailContactsDetailViewController.h"//邮件联系人详情页面
#import "ZGMessageAttachmentViewController.h"//附件页面

#import "MCOMessageView.h"
#import "ZGMailMessageHeaderView.h"//头部视图
#import "ZGAddressShadowButton.h"
#import "ZGMessageAttachmentView.h"//插件视图

//邮件模块管理工具类
#import "ZGMailModule.h"
#import "ZGMailAttachmetPhoto.h"

//动画
#import <pop/POP.h>

//图片浏览
#import "MWPhotoBrowser.h"

//网络监测
#import "TMReachability.h"

typedef void (^DownloadCallback)(NSError * error);
#define IMAGE_PREVIEW_HEIGHT 300
#define IMAGE_PREVIEW_WIDTH 500


@interface ZGMailMessageDetailViewController () <MCOMessageViewDelegate, ZGMailMessageHeaderViewDelegate, ZGMessageAttachmentViewDelegate, MWPhotoBrowserDelegate>

@property (nonatomic, strong) UIBarButtonItem *prevMailItem;
@property (nonatomic, strong) UIBarButtonItem *nextMailItem;

@property (nonatomic, strong) MCOMessageView *messageView;
@property (nonatomic, strong) ZGMailMessageHeaderView *messageHeaderView;
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;
@property (nonatomic, strong) ZGMessageAttachmentView *attachmentView;

@property (nonatomic, strong) UIToolbar *bottomToolbar;
@property (nonatomic, strong) UIBarButtonItem *starItem;
@property (nonatomic, strong) UIBarButtonItem *replyItem;

@property (nonatomic, strong) UIImageView *screenshotImageView;

@property (nonatomic, copy) NSMutableSet *supportedImageTypes;
@property (nonatomic, copy) NSMutableSet *supportedDocumentTypes;

@property (nonatomic, copy) NSMutableArray *photoAttachmentArray;//图片附件数组

@end

@implementation ZGMailMessageDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithHexString:@"F2F2F2" alpha:1.0f];
    self.automaticallyAdjustsScrollViewInsets = NO;

    [self.view addSubview:self.messageView];
    [self.view addSubview:self.bottomToolbar];
    
    [self setupNavigationBarItem];
    
    //添加约束
    [self layoutPageViews];

    //加载messageView
    self.messageView.imapMessage = self.imapMessage;
    
    //headerView
    self.messageHeaderView.message = self.imapMessage;
    float headerHeight = [self.messageHeaderView heightOfMessageHeaderView];
    self.messageHeaderView.frame = CGRectMake(0, -headerHeight, ScreenWidth, headerHeight);
    
    
    //webview设置
    self.messageView.webScrollView.contentInset = UIEdgeInsetsMake(headerHeight, 0, 44, 0);
    self.messageView.webScrollView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 44, 0);
    [self.messageView.webScrollView addSubview:self.messageHeaderView];
    [self.messageView.webScrollView sendSubviewToBack:self.messageHeaderView];
    self.messageView.webScrollView.delaysContentTouches = NO;//scrollView上的按钮快速点击时一样有点击效果
    
    //风火轮
    [self.messageView addSubview:self.indicatorView];
    [self.indicatorView startAnimating];
    [self.indicatorView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self.messageView);
    }];

    //更新前后按钮
    [self updatePrevAndNextButtonWithIndex:self.indexPath.row];
    
    //监听webview
    [self.messageView.webScrollView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
    [self.messageView.webScrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
    
    if (self.imapMessage.attachments.count > 0) {
        [self.imapMessage.attachments enumerateObjectsUsingBlock:^(MCOIMAPPart *part, NSUInteger idx, BOOL * _Nonnull stop) {
            //判断是否是支持的图片类型
            NSString *pathExtension = [part.filename pathExtension];
            if ([self supportImageType:pathExtension]) {
                [self.photoAttachmentArray addObject:part];
            }
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [self.messageView.webScrollView removeObserver:self forKeyPath:@"contentSize" context:nil];
    [self.messageView.webScrollView removeObserver:self forKeyPath:@"contentOffset" context:nil];
    self.messageView.delegate = nil;
    self.messageView = nil;
}

#pragma mark - MCOMessageViewDelegate

- (BOOL)MCOMessageView:(MCOMessageView *)view webViewShouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    //判断是否是单击
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        NSURL *url = [request URL];
        NSString *curUrl= [url absoluteString];
        
        if ([curUrl hasPrefix:@"http:"] || [curUrl hasPrefix:@"https:"]) {//点击的是链接地址，webview打开
            [[UIApplication sharedApplication] openURL:url];
            
            return NO;
        } else if([curUrl hasPrefix:@"mailto:"]) {//点击的是邮件地址，打开写邮件页面
            NSArray *array = [curUrl componentsSeparatedByString:@":"];
            NSString *mailbox = @"";
            if (array.count > 1) {
                mailbox = [array objectAtIndex:1];
            }
            
            MCOAddress *address = [MCOAddress addressWithDisplayName:@"" mailbox:mailbox];
            [self presentNewMailVCWithRecipientAddress:address];
            
            return NO;
        } else {
            return YES;
        }
    } else {
        return YES;
    }
}

- (void)MCOMessageView:(MCOMessageView *)view webViewDidFinishLoad:(UIWebView *)webView {
    //消息内容加载之后设置消息为已读
    if (self.imapMessage.flags & MCOMessageFlagSeen) {//已读消息不做操作
    } else {//未读消息，增加已读标志
        if ([self.folder isEqualToString:MailFolderTypeINBOX]) {//收件箱的消息才需要做已读操作
//            [[ZGMailModule sharedInstance] storeFlagsWithFolder:self.folder messages:@[self.imapMessage] kind:MCOIMAPStoreFlagsRequestKindAdd flags:MCOMessageFlagSeen];
//            //更新消息数据
//            self.imapMessage.flags = self.imapMessage.flags | MCOMessageFlagSeen;
//            [[ZGMailModule sharedInstance] setMessageWithFolder:self.folder index:self.indexPath.row newMessage:self.imapMessage];
//            
//            //修改未读消息数
//            NSUInteger unseenNumber = [[ZGMailModule sharedInstance] unseenMessageNumberOfINBOX];
//            unseenNumber -= 1;
//            [[ZGMailModule sharedInstance] saveUnseenMessageNumberOfINBOX:unseenNumber];
            
            //添加星标
            [self storeFlagsForIndexPath:self.indexPath kind:MCOIMAPStoreFlagsRequestKindAdd flags:MCOMessageFlagSeen];
        }
    }
    
    //风火轮
    [self.indicatorView stopAnimating];
    [self.indicatorView removeFromSuperview];
    
    //更新附件视图
    [self updateAttachmentView];
    
    self.starItem.enabled = YES;
    self.replyItem.enabled = YES;
}

- (void)MCOMessageView:(MCOMessageView *)view webViewDidFailLoad:(UIWebView *)webView {
//    //消息内容加载之后设置消息为已读
//    if (self.imapMessage.flags & MCOMessageFlagSeen) {//已读消息不做操作
//    } else {//未读消息，增加已读标志
//        [[ZGMailModule sharedInstance] storeFlagsWithFolder:self.folder messages:@[self.imapMessage] kind:MCOIMAPStoreFlagsRequestKindAdd flags:MCOMessageFlagSeen];
//        //更新消息数据
//        self.imapMessage.flags = self.imapMessage.flags | MCOMessageFlagSeen;
//        [[ZGMailModule sharedInstance] setMessageWithFolder:self.folder index:self.indexPath.row newMessage:self.imapMessage];
//        
//        if ([self.folder isEqualToString:MailFolderTypeINBOX]) {
//            //修改未读消息数
//            NSUInteger unseenNumber = [[ZGMailModule sharedInstance] unseenMessageNumberOfINBOX];
//            unseenNumber -= 1;
//            [[ZGMailModule sharedInstance] saveUnseenMessageNumberOfINBOX:unseenNumber];
//        }
//    }
    
//    //风火轮
//    [self.indicatorView stopAnimating];
//    [self.indicatorView removeFromSuperview];
}

#pragma mark - ZGMailMessageHeaderViewDelegate

- (void)headerView:(ZGMailMessageHeaderView *)headerView detailButtonPressed:(id)sender {
    float height = [self.messageHeaderView heightOfMessageHeaderView];
    self.messageView.webScrollView.contentOffset = CGPointMake(0, -height);
    //更新headerView的高度和scrollView的缩进值
    [self setupFrameOfHeaderView];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //更新attachmentView的位置
        [self setupFrameOfAttachmentView];
    });
}

- (void)headerView:(ZGMailMessageHeaderView *)headerView hideButtonPressed:(id)sender {
    //还原Y轴偏移量
    float height = [self.messageHeaderView heightOfMessageHeaderView];
    self.messageView.webScrollView.contentOffset = CGPointMake(0, -height);
    
    //更新headerView的高度和scrollView的缩进值
    [self setupFrameOfHeaderView];

    //更新attachmentView的位置
    [self setupFrameOfAttachmentView];
}

- (void)headerView:(ZGMailMessageHeaderView *)headerView addressButtonPressed:(ZGAddressShadowButton *)button {
//    [[HikContactsModule sharedInstance] getContactsInfoRecordWithShortName:button.shortName completion:^(HikContactsInfoRecord *contactsInfoRecord, BOOL networkData) {
//        if (contactsInfoRecord) {
//            HikContactDetailViewController *contactDetailVC = [[HikContactDetailViewController alloc] init];
//            contactDetailVC.contactInfoRecord = contactsInfoRecord;
//            [self.navigationController pushViewController:contactDetailVC animated:YES];
//        } else {
            ZGMailContactsDetailViewController *mailContactsDetailVC = [[ZGMailContactsDetailViewController alloc] init];
            mailContactsDetailVC.nameStr = button.shortName;
            mailContactsDetailVC.mailAddressStr = button.mailbox;
            [self.navigationController pushViewController:mailContactsDetailVC animated:YES];
//        }
//    }];
}

- (void)headerView:(ZGMailMessageHeaderView *)headerView attachmentButtonPressed:(ZGAddressShadowButton *)button {
    [self scrollToBottom];
}

#pragma mark - ZGMessageAttachmentViewDelegate

- (void)messageAttachmentView:(ZGMessageAttachmentView *)attachmentView selectAttachment:(MCOIMAPPart *)part {
//    if ([self.supportedImageMimeTypes containsObject:[[part mimeType] lowercaseString]]) {//图片附件展示
    //判断是否是支持的图片类型
    NSString *pathExtension = [part.filename pathExtension];
    if ([self supportImageType:pathExtension]) {//图片附件展示
        __block NSUInteger index = 0;
        [self.photoAttachmentArray enumerateObjectsUsingBlock:^(MCOIMAPPart *photoPart, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([photoPart.partID isEqualToString:part.partID]) {
                index = idx;
                *stop = YES;
                return;
            }
        }];
        
        [self showAttachmentImagesWithCurrentIndex:index];
    } else if ([self supportDocumentType:pathExtension]) {
        TMReachability *reachability = [TMReachability reachabilityForInternetConnection];
        if (reachability.isReachableViaWiFi) {
            [self pushToMessageAttachmentVC:part];
        } else {
            if (part.size > 10 * 1024.0 * 1024.0) {//大于10M的提示是否下载
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"附件过大" message:@"附件大于10M，是否使用流量下载？" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消下载" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    
                }];
                UIAlertAction *settingAction = [UIAlertAction actionWithTitle:@"继续下载" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self pushToMessageAttachmentVC:part];
                }];
                
                [alertController addAction:cancelAction];
                [alertController addAction:settingAction];
                
                [self presentViewController:alertController animated:YES completion:nil];
            } else {
                [self pushToMessageAttachmentVC:part];
            }
        }
    } else {
        [self showTipText:@"不支持的文件类型"];
    }
}

#pragma mark - MWPhotoBrowserDelegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return [self.photoAttachmentArray count];
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    MCOIMAPPart *part = [self.photoAttachmentArray objectAtIndex:index];
    ZGMailAttachmetPhoto *photo = [ZGMailAttachmetPhoto photoWithImagePart:part folder:self.folder message:self.imapMessage];
   
    return photo;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index {
    MCOIMAPPart *part = [self.photoAttachmentArray objectAtIndex:index];
    ZGMailAttachmetPhoto *photo = [ZGMailAttachmetPhoto photoWithImagePart:part folder:self.folder message:self.imapMessage];
    
    return photo;
}

#pragma mark - IBAction

- (IBAction)prevMailButtonPressed:(id)sender {
    self.indexPath = [NSIndexPath indexPathForRow:self.indexPath.row - 1 inSection:0];
    
    [self updateMailDetail];
}

- (IBAction)nextMailButtonPressed:(id)sender {
    self.indexPath = [NSIndexPath indexPathForRow:self.indexPath.row + 1 inSection:0];

    [self updateMailDetail];
}

- (IBAction)starButtonPressed:(id)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *starAction = [UIAlertAction actionWithTitle:@"添加星标" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//        //添加星标
//        [[ZGMailModule sharedInstance] storeFlagsWithFolder:self.folder messages:@[self.imapMessage] kind:MCOIMAPStoreFlagsRequestKindAdd flags:MCOMessageFlagFlagged];
//        //更新消息数据
//        self.imapMessage.flags = self.imapMessage.flags | MCOMessageFlagFlagged;
//        [[ZGMailModule sharedInstance] setMessageWithFolder:self.folder index:self.indexPath.row newMessage:self.imapMessage];
        
        //添加星标
        [self storeFlagsForIndexPath:self.indexPath kind:MCOIMAPStoreFlagsRequestKindAdd flags:MCOMessageFlagFlagged];
        
        [self showSuccessTipText:@"标记成功"];
        [self.messageHeaderView showStarImageView];
    }];
    UIAlertAction *unstarAction = [UIAlertAction actionWithTitle:@"取消星标" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//        //取消星标（移除星标标志）
//        [[ZGMailModule sharedInstance] storeFlagsWithFolder:self.folder messages:@[self.imapMessage] kind:MCOIMAPStoreFlagsRequestKindRemove flags:MCOMessageFlagFlagged];
//        //更新消息数据
//        self.imapMessage.flags = self.imapMessage.flags & ~MCOMessageFlagFlagged;
//        [[ZGMailModule sharedInstance] setMessageWithFolder:self.folder index:self.indexPath.row newMessage:self.imapMessage];
        
        //取消星标
        [self storeFlagsForIndexPath:self.indexPath kind:MCOIMAPStoreFlagsRequestKindRemove flags:MCOMessageFlagFlagged];
        
        [self showSuccessTipText:@"标记成功"];
        [self.messageHeaderView hideStarImageView];
    }];
    
    UIAlertAction *unseenAction = [UIAlertAction actionWithTitle:@"标为未读" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//        //标为未读（移除已读标志）
//        [[ZGMailModule sharedInstance] storeFlagsWithFolder:self.folder messages:@[self.imapMessage] kind:MCOIMAPStoreFlagsRequestKindRemove flags:MCOMessageFlagSeen];
//        //更新消息数据
//        self.imapMessage.flags = self.imapMessage.flags & ~MCOMessageFlagSeen;
//        [[ZGMailModule sharedInstance] setMessageWithFolder:self.folder index:self.indexPath.row newMessage:self.imapMessage];
//        
//        if ([self.folder isEqualToString:MailFolderTypeINBOX]) {
//            //修改未读消息数
//            NSUInteger unseenNumber = [[ZGMailModule sharedInstance] unseenMessageNumberOfINBOX];
//            unseenNumber += 1;
//            [[ZGMailModule sharedInstance] saveUnseenMessageNumberOfINBOX:unseenNumber];
//        }
        //标为未读
        [self storeFlagsForIndexPath:self.indexPath kind:MCOIMAPStoreFlagsRequestKindRemove flags:MCOMessageFlagSeen];
        
        [self showSuccessTipText:@"标记成功"];
        [self.messageHeaderView showUnseenImageView];
    }];
    
    UIAlertAction *seenAction = [UIAlertAction actionWithTitle:@"标为已读" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//        [[HikMailModule sharedInstance] storeFlagsWithFolder:self.folder messages:@[self.imapMessage] kind:MCOIMAPStoreFlagsRequestKindAdd flags:MCOMessageFlagSeen];
//        //更新消息数据
//        self.imapMessage.flags = self.imapMessage.flags | MCOMessageFlagSeen;
//        [[HikMailModule sharedInstance] setMessageWithFolder:self.folder index:self.indexPath.row newMessage:self.imapMessage];
//        
//        if ([self.folder isEqualToString:MailFolderTypeINBOX]) {
//            //修改未读消息数
//            NSUInteger unseenNumber = [[HikMailModule sharedInstance] unseenMessageNumberOfINBOX];
//            unseenNumber -= 1;
//            [[HikMailModule sharedInstance] saveUnseenMessageNumberOfINBOX:unseenNumber];
//        }
        
        //标为未读
        [self storeFlagsForIndexPath:self.indexPath kind:MCOIMAPStoreFlagsRequestKindAdd flags:MCOMessageFlagSeen];
        
        [self showSuccessTipText:@"标记成功"];
        [self.messageHeaderView hideUnseenImageView];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    if (self.imapMessage.flags & MCOMessageFlagFlagged) {//星标
        [alertController addAction:unstarAction];
    } else {
        [alertController addAction:starAction];
    }
    
    if (self.imapMessage.flags & MCOMessageFlagSeen) {//已读
        [alertController addAction:unseenAction];
    } else {//未读
        [alertController addAction:seenAction];
    }
    
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)deleteButtonPressed:(id)sender {
    //修改消息的标志为删除
    [[ZGMailModule sharedInstance] storeFlagsWithFolder:self.folder messages:@[self.imapMessage] kind:MCOIMAPStoreFlagsRequestKindAdd flags:MCOMessageFlagDeleted];
    
    //修改model
    [[ZGMailModule sharedInstance] removeMessageAtIndex:self.indexPath.row withFolder:self.folder];
    if (self.delegate && [self.delegate respondsToSelector:@selector(messageDetailVC:deleteMessageAtIndexPath:)]) {
        [self.delegate messageDetailVC:self deleteMessageAtIndexPath:self.indexPath];
    }
    
    ///屏幕截图
    UIImage *image = [self getMessageDetailImage];
    self.screenshotImageView.image = image;
    [self.view insertSubview:self.screenshotImageView belowSubview:self.bottomToolbar];
    
    //切换下一封邮件，中间删掉了一封邮件，后面的下标会前移一位，所以现有的index取出的就是下一封邮件
    NSUInteger maxIndex = [[[ZGMailModule sharedInstance] showingMailListWithFolder:self.folder] count] - 1;
    if (self.indexPath.row > maxIndex) {//当前删除的是最后一条数据，下面展示最后一条数据
        self.indexPath = [NSIndexPath indexPathForRow:maxIndex inSection:0];
    } else {
        //不是最后一条数据，不处理
    }
    
    ///更新邮件内容
    [self updateMailDetail];

    //动画
    {
        __block MASConstraint *screenshotWidthConstraint;
        [self.screenshotImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            screenshotWidthConstraint = make.width.mas_equalTo(CGRectGetWidth(self.view.frame));
            make.height.mas_equalTo(self.screenshotImageView.mas_width).multipliedBy(CGRectGetHeight(self.view.frame) / CGRectGetWidth(self.view.frame));
            make.bottom.mas_equalTo(self.view);
            make.centerX.mas_equalTo(self.bottomToolbar);
        }];
        
        [self.view layoutIfNeeded];
        
        screenshotWidthConstraint.offset = 0;
        [UIView animateWithDuration:0.25 animations:^{
            self.screenshotImageView.alpha = 0;
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            [self.screenshotImageView removeFromSuperview];
            self.screenshotImageView.alpha = 1;
        }];
    }
}

- (IBAction)replyButtonPressed:(id)sender {
    UIAlertAction *replyAction = [UIAlertAction actionWithTitle:@"回复" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self presentNewMailVCWithNewMailType:NewMailTypeReply];
    }];
    
    UIAlertAction *replyAllAction = [UIAlertAction actionWithTitle:@"回复全部" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self presentNewMailVCWithNewMailType:NewMailTypeReplyAll];
    }];

    UIAlertAction *forwardAction = [UIAlertAction actionWithTitle:@"转发" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self presentNewMailVCWithNewMailType:NewMailTypeForward];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:replyAction];
    
    //根据条件展示“回复全部”按钮
    if (self.imapMessage.header.to.count == 1 && self.imapMessage.header.cc.count == 0) {//如果收件人只有一个，且没有抄送人员
        NSString *mailAddress = [ZGMailModule sharedInstance].mailAddress;
        MCOAddress *address = [self.imapMessage.header.to firstObject];
        if (![address.mailbox isEqualToString:mailAddress]) {//唯一的收件人地址不是自己的地址，说明发送的是邮件组，需要回复全部
            [alertController addAction:replyAllAction];
        } else {
            //唯一的收件人是自己，不需要展示“回复全部”按钮
        }
    } else {
        [alertController addAction:replyAllAction];
    }
    
    [alertController addAction:forwardAction];
    [alertController addAction:cancelAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)newMailButtonPressed:(id)sender {
    ZGNewMailViewController *newMailVC = [[ZGNewMailViewController alloc] init];
    newMailVC.newMailType = NewMailTypeDefault;
    
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:newMailVC];
    [self presentViewController:navVC animated:YES completion:nil];
}

#pragma mark - private method

/**
 *  加约束
 */
- (void)layoutPageViews {
    [self.messageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.view);
        make.width.mas_equalTo(self.view);
        make.top.mas_equalTo(self.view);
        make.bottom.mas_equalTo(self.view.mas_bottom).offset(0);
    }];
    
    [self.bottomToolbar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(self.view);
        make.height.mas_equalTo(44);
        make.bottom.mas_equalTo(self.view.mas_bottom);
        make.centerX.mas_equalTo(self.view);
    }];
}

- (void)setupNavigationBarItem {
    self.navigationItem.rightBarButtonItems = @[self.nextMailItem, self.prevMailItem];
}

///更新邮件详情
- (void)updateMailDetail {
    [self updatePrevAndNextButtonWithIndex:self.indexPath.row];
    
    NSArray *messageArray = [[ZGMailModule sharedInstance] showingMailListWithFolder:self.folder];
    self.imapMessage = [messageArray objectAtIndex:self.indexPath.row];
    self.messageView.imapMessage = self.imapMessage;
    
    //风火轮
    [self.indicatorView startAnimating];
    [self.messageView addSubview:self.indicatorView];
    [self.indicatorView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self.messageView);
    }];
    
    //更新头部
    [self updateHeaderView];
    
    self.starItem.enabled = NO;
    self.replyItem.enabled = NO;
    
    [self.photoAttachmentArray removeAllObjects];
    if (self.imapMessage.attachments.count > 0) {
        [self.imapMessage.attachments enumerateObjectsUsingBlock:^(MCOIMAPPart *part, NSUInteger idx, BOOL * _Nonnull stop) {
            //判断是否是支持的图片类型
            NSString *pathExtension = [part.filename pathExtension];
            if ([self supportImageType:pathExtension]) {
                [self.photoAttachmentArray addObject:part];
            }
        }];
    }
}

///更新前后按钮
- (void)updatePrevAndNextButtonWithIndex:(NSUInteger)index {
    if (index == 0) {
        self.prevMailItem.enabled = NO;
        self.nextMailItem.enabled = YES;
    } else if (index == [[[ZGMailModule sharedInstance] showingMailListWithFolder:self.folder] count] - 1) {
        self.nextMailItem.enabled = NO;
        self.prevMailItem.enabled = YES;
    } else {
        //中间邮件，上下箭头都可用
        self.prevMailItem.enabled = YES;
        self.nextMailItem.enabled = YES;
    }
}

//更新headerview
- (void)updateHeaderView {
    //headerView
    if (![self.messageHeaderView isDescendantOfView:self.messageView.webScrollView]) {
        [self.messageView.webScrollView addSubview:self.messageHeaderView];
    }
    //更新数据
    self.messageHeaderView.message = self.imapMessage;
    [self.messageHeaderView hideMailDetailView];
    
    [self.messageView.webScrollView sendSubviewToBack:self.messageHeaderView];
    
    [self setupFrameOfHeaderView];
}

//更新附件视图
- (void)updateAttachmentView {
    //附件视图
    if ([self.attachmentView isDescendantOfView:self.messageView.webScrollView]) {
        [self.attachmentView removeFromSuperview];
    }
    
    if ([self.imapMessage.attachments count] > 0) {
        //刷新数据
        self.attachmentView.attachments = self.imapMessage.attachments;
        [self.attachmentView reloadTableView];

        [self.messageView.webScrollView addSubview:self.attachmentView];
        [self.messageView.webScrollView sendSubviewToBack:self.attachmentView];
        
        //设置附件视图的位置
        [self setupFrameOfAttachmentView];
    } else {
        //还原底部缩进值
        UIEdgeInsets insets = self.messageView.webScrollView.contentInset;
        insets.bottom = 44;
        self.messageView.webScrollView.contentInset = insets;
    }
}

//设置headerView的frame
- (void)setupFrameOfHeaderView {
    float heaerViewHeight = [self.messageHeaderView heightOfMessageHeaderView];
    
    //X轴的内容偏移
    float contentOffsetX = [self.messageView.webScrollView contentOffset].x;
    self.messageHeaderView.frame = CGRectMake(contentOffsetX, -heaerViewHeight, ScreenWidth, heaerViewHeight);
    
    UIEdgeInsets insets = self.messageView.webScrollView.contentInset;
    insets.top = heaerViewHeight;
    self.messageView.webScrollView.contentInset = insets;
}

/**
 *  更新附件视图的位置
 */
- (void)setupFrameOfAttachmentView {
    float attachmentHeight = [self.attachmentView heightOfAttachmentView];
    
    //通过JS代码获取webview的内容高度
    //    float attachmentViewY = [[self.messageView.myWebView stringByEvaluatingJavaScriptFromString:@"document.body.scrollHeight"] floatValue];
    //通过webview的contentSize获取内容高度
    float attachmentViewY = [self.messageView.webScrollView contentSize].height;
    float headerHeight = [self.messageHeaderView heightOfSummaryMessageHeaderView];
    
    //browserView的最小高度
    float contentMinHeight = self.view.height - headerHeight - attachmentHeight - 44;
    if (attachmentViewY < contentMinHeight) {
        attachmentViewY = contentMinHeight;
        CGSize contentSize = [self.messageView.webScrollView contentSize];
        contentSize.height = contentMinHeight;
        self.messageView.webScrollView.contentSize = contentSize;
    }
    
    //X轴的内容偏移，保证附件视图始始终显示在屏幕中
    float contentOffsetX = [self.messageView.webScrollView contentOffset].x;
    self.attachmentView.frame = CGRectMake(contentOffsetX, attachmentViewY, ScreenWidth, attachmentHeight);
    
    //设置scrollView的缩进
    if ([self.attachmentView isDescendantOfView:self.messageView.webScrollView]) {
        UIEdgeInsets insets = self.messageView.webScrollView.contentInset;
        insets.bottom = attachmentHeight + 44;
        self.messageView.webScrollView.contentInset = insets;
    }
}

///获取邮件详情截图
- (UIImage *)getMessageDetailImage {
    UIGraphicsBeginImageContextWithOptions(self.messageView.bounds.size, NO, [UIScreen mainScreen].scale * 2);
    [self.messageView.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)scrollToBottom {
    //判断附件是否已经完全展示出来
//    float headerViewHeight = [self.messageHeaderView heightOfMessageHeaderView];
//    CGRect frame = self.attachmentView.frame;
//    float offsetY = headerViewHeight + frame.origin.y + frame.size.height - self.view.height;
    
    CGRect rect = [self.view convertRect:self.attachmentView.frame fromView:self.messageView.webScrollView];
    float offsetY = rect.origin.y + [self.attachmentView heightOfAttachmentView] - self.view.height;

    if (offsetY < 0) {//附件已经完全展示出来
        POPSpringAnimation *scaleAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewScaleXY];
        scaleAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(1, 1)];
        scaleAnimation.velocity = [NSValue valueWithCGPoint:CGPointMake(2, 2)];
        scaleAnimation.springBounciness = 20.f;
        [self.attachmentView.myTableView pop_addAnimation:scaleAnimation forKey:@"scaleAnimation"];
    } else {
        [UIView animateWithDuration:0.25 animations:^{
            float offsetY = self.messageView.webScrollView.contentSize.height + self.messageView.webScrollView.contentInset.bottom - self.view.height;
            self.messageView.webScrollView.contentOffset = CGPointMake(0, offsetY);
        }];
    }
}

//监听触发
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"contentSize"]) {
        if ([self.messageView isLoading]) {
            //加载过程中不更新
        } else {//加载完成才更新
            //更新附件视图
            [self setupFrameOfAttachmentView];
        }
    } else if ([keyPath isEqualToString:@"contentOffset"]) {
        if ([self.messageView isLoading]) {
           //加载过程中不更新
        } else {//加载完成才更新
            //更新附件视图
            [self setupFrameOfAttachmentView];
            //更新headerView
            [self setupFrameOfHeaderView];
        }
    }
}

- (void)showAttachmentImagesWithCurrentIndex:(NSInteger)index {
    // Create browser
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    browser.displayActionButton = NO;
    browser.displayNavArrows = YES;
    browser.displaySelectionButtons = NO;
    browser.alwaysShowControls = NO;
    browser.zoomPhotosToFill = NO;
    browser.enableGrid = NO;
    browser.startOnGrid = NO;
    [browser setCurrentPhotoIndex:index];
    
    // Modal
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:browser];
    nc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:nc animated:YES completion:nil];
}

- (void)storeFlagsForIndexPath:(NSIndexPath *)indexPath kind:(MCOIMAPStoreFlagsRequestKind)kind flags:(MCOMessageFlag)flags {
    //标记请求
    [[ZGMailModule sharedInstance] storeFlagsWithFolder:self.folder messages:@[self.imapMessage] kind:kind flags:flags];
    //更新消息数据
//    self.imapMessage.flags = self.imapMessage.flags | MCOMessageFlagFlagged;
    //修改缓存数据
    if (kind == MCOIMAPStoreFlagsRequestKindRemove) {
        self.imapMessage.flags = self.imapMessage.flags & ~flags;
    } else {
        self.imapMessage.flags = self.imapMessage.flags | flags;
    }

    [[ZGMailModule sharedInstance] setMessageWithFolder:self.folder index:self.indexPath.row newMessage:self.imapMessage];
    
    if ([self.folder isEqualToString:MailFolderTypeINBOX] && (flags == MCOMessageFlagSeen || flags == MCOMessageFlagDeleted)) {
        if (flags == MCOMessageFlagSeen) {
            //修改未读消息数
            NSUInteger unseenNumber = [[ZGMailModule sharedInstance] unseenMessageNumberOfINBOX];
            if (kind == MCOIMAPStoreFlagsRequestKindRemove) {
                unseenNumber += 1;
            } else {
                unseenNumber -= 1;
            }
            
            [[ZGMailModule sharedInstance] saveUnseenMessageNumberOfINBOX:unseenNumber];
        } else {
            //更新未读邮件数
            [[ZGMailModule sharedInstance] getUnseenNumberWithFolder:MailFolderTypeINBOX completionBlock:nil];
        }
    }
}

///打开新邮件页面：带邮件类型参数
- (void)presentNewMailVCWithNewMailType:(NewMailType)newMailType {
    ZGNewMailViewController *newMailVC = [[ZGNewMailViewController alloc] init];
    newMailVC.originImapMessage = self.imapMessage;
    newMailVC.newMailType = newMailType;
    newMailVC.session = self.session;
    newMailVC.originMessageFolder = self.folder;
    
    UINavigationController *navVc = [[UINavigationController alloc] initWithRootViewController:newMailVC];
    [self presentViewController:navVc animated:YES completion:nil];
}

///打开新邮件页面：NewMailTypeDefault + 带收件人地址
- (void)presentNewMailVCWithRecipientAddress:(MCOAddress *)recipientAddress {
    ZGNewMailViewController *newMailVC = [[ZGNewMailViewController alloc] init];
    newMailVC.recipientAddress = recipientAddress;
    newMailVC.newMailType = NewMailTypeDefault;
    
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:newMailVC];
    [self presentViewController:navVC animated:YES completion:nil];
}

- (void)pushToMessageAttachmentVC:(MCOIMAPPart *)part {
    ZGMessageAttachmentViewController *attachmentVC = [[ZGMessageAttachmentViewController alloc] init];
    attachmentVC.message = self.imapMessage;
    attachmentVC.folder = self.folder;
    attachmentVC.session = self.session;
    attachmentVC.part = part;
    [self.navigationController pushViewController:attachmentVC animated:YES];
}

///检测是否是支持的图片类型
- (BOOL)supportImageType:(NSString *)type {
    if ([self.supportedImageTypes containsObject:[type lowercaseString]]) {
        return YES;
    } else {
        return NO;
    }
}

///检测是否是支持的文档类型
- (BOOL)supportDocumentType:(NSString *)type {
    if ([self.supportedDocumentTypes containsObject:[type lowercaseString]]) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - setter and getter

- (UIBarButtonItem *)prevMailItem {
    if (_prevMailItem == nil) {
        _prevMailItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"btn_nav_prev"] style:UIBarButtonItemStylePlain target:self action:@selector(prevMailButtonPressed:)];
    }
    
    return _prevMailItem;
}

- (UIBarButtonItem *)nextMailItem {
    if (_nextMailItem == nil) {
        _nextMailItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"btn_nav_next"] style:UIBarButtonItemStylePlain target:self action:@selector(nextMailButtonPressed:)];
    }
    
    return _nextMailItem;
}

- (MCOMessageView *)messageView {
    if (_messageView == nil) {
        _messageView = [[MCOMessageView alloc] init];
        _messageView.delegate = self;
        _messageView.messageType = MessageTypeNormal;
        _messageView.session = self.session;
        _messageView.folder = self.folder;
    }
    
    return _messageView;
}

- (ZGMailMessageHeaderView *)messageHeaderView {
    if (_messageHeaderView == nil) {
        _messageHeaderView = [[ZGMailMessageHeaderView alloc] init];
        _messageHeaderView.backgroundColor = [UIColor whiteColor];
        _messageHeaderView.delegate = self;
    }
    
    return _messageHeaderView;
}

- (UIActivityIndicatorView *)indicatorView {
    if (_indicatorView == nil) {
        _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _indicatorView.hidesWhenStopped = YES;
    }
    
    return _indicatorView;
}

- (ZGMessageAttachmentView *)attachmentView {
    if (_attachmentView == nil) {
        _attachmentView = [[ZGMessageAttachmentView alloc] init];
        _attachmentView.delegate = self;
    }
    
    return _attachmentView;
}

- (UIToolbar *)bottomToolbar {
    if (_bottomToolbar == nil) {
        _bottomToolbar = [[UIToolbar alloc] init];
        _bottomToolbar.barStyle = UIBarStyleDefault;
        _bottomToolbar.translucent = NO;
        
        UIBarButtonItem *deleteItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deleteButtonPressed:)];
        UIBarButtonItem *newItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(newMailButtonPressed:)];
        UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

        _bottomToolbar.items = @[self.starItem, flexItem, deleteItem, flexItem, self.replyItem, flexItem, newItem];
    }
    
    return _bottomToolbar;
}

- (UIBarButtonItem *)starItem {
    if (_starItem == nil) {
        _starItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_star"] style:UIBarButtonItemStylePlain target:self action:@selector(starButtonPressed:)];
        _starItem.enabled = NO;
    }
    
    return _starItem;
}

- (UIBarButtonItem *)replyItem {
    if (_replyItem == nil) {
        _replyItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemReply target:self action:@selector(replyButtonPressed:)];
        _replyItem.enabled = NO;
    }
    
    return _replyItem;
}

- (MCOIMAPMessage *)imapMessage {
    if (_imapMessage == nil) {
        _imapMessage = [[MCOIMAPMessage alloc] init];
    }
    
    return _imapMessage;
}

- (UIImageView *)screenshotImageView {
    if (_screenshotImageView == nil) {
        _screenshotImageView = [[UIImageView alloc] init];
    }
    
    return _screenshotImageView;
}

- (NSMutableArray *)photoAttachmentArray {
    if (_photoAttachmentArray == nil) {
        _photoAttachmentArray = [[NSMutableArray alloc] init];
    }
    
    return _photoAttachmentArray;
}

- (NSMutableSet *)supportedImageTypes {
    if (_supportedImageTypes == nil) {
        _supportedImageTypes = [[NSMutableSet alloc] init];
        [_supportedImageTypes addObject:@"bmp"];
        [_supportedImageTypes addObject:@"gif"];
        [_supportedImageTypes addObject:@"png"];
        
        [_supportedImageTypes addObject:@"png"];
        [_supportedImageTypes addObject:@"jpg"];
        [_supportedImageTypes addObject:@"jpeg"];
        
        [_supportedImageTypes addObject:@"tif"];
        [_supportedImageTypes addObject:@"tiff"];
    }
    
    return _supportedImageTypes;
}

- (NSMutableSet *)supportedDocumentTypes {
    if (_supportedDocumentTypes == nil) {
        _supportedDocumentTypes = [[NSMutableSet alloc] init];
        
        //Office
        [_supportedDocumentTypes addObject:@"pptx"];
        [_supportedDocumentTypes addObject:@"ppt"];
        
        [_supportedDocumentTypes addObject:@"docx"];
        [_supportedDocumentTypes addObject:@"doc"];
        [_supportedDocumentTypes addObject:@"dot"];
        [_supportedDocumentTypes addObject:@"dotx"];
        
        [_supportedDocumentTypes addObject:@"xlsx"];
        [_supportedDocumentTypes addObject:@"xls"];
        
        //pdf
        [_supportedDocumentTypes addObject:@"pdf"];
        [_supportedDocumentTypes addObject:@"ppdf"];
        
        //HTML网页
        [_supportedDocumentTypes addObject:@"html"];
        [_supportedDocumentTypes addObject:@"htm"];
        
        //文本文件
        [_supportedDocumentTypes addObject:@"txt"];
        [_supportedDocumentTypes addObject:@"ptxt"];
        [_supportedDocumentTypes addObject:@"rtf"];
    }
    
    return _supportedDocumentTypes;
}

@end

