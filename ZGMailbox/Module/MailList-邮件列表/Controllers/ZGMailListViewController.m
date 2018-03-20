//
//  ZGMailListViewController.m
//  ZGMailbox
//
//  Created by zzg on 2017/3/20.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import "ZGMailListViewController.h"
#import "ZGMailMessageDetailViewController.h"//邮件详情页面
#import "ZGNewMailViewController.h"//写邮件页面
#import "ZGMailMessageSearchViewController.h"//邮件搜索

//邮件协议
#import <MailCore/MailCore.h>
#import <MailCore/MCOSMTPSendOperation.h>

//邮件模块管理工具类
#import "ZGMailModule.h"

//record
#import "ZGMailRecord.h"
#import "ZGMailMessage.h"

//custom views
#import "ZGMailListTableViewCell.h"//cell
#import "ZGMailListBottomToolBar.h"
#import "ZGMailListTitleView.h"//titleView

//下拉刷新、上拉加载更多
#import <MJRefresh/MJRefresh.h>

//弹出菜单
#import "FTPopOverMenu.h"

//空白页面
#import "UIScrollView+EmptyDataSet.h"

//常量
static CGFloat const cellHeight = 86.0f;
static NSString *const MailListTableViewCellIdentifier = @"MailListTableViewCellIdentifier";


@interface ZGMailListViewController () <UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, ZGMailListTitleViewDelegate, ZGMailMessageDetailViewControllerDelegate, ZGMailListTableViewCellDelegate, ZGMailListBottomToolBarDelegate> {
    BOOL isFistLoad;
}

@property (nonatomic, strong) ZGMailListTitleView *titleView;

//顶部导航栏按钮
@property (nonatomic, strong) UIBarButtonItem *editBarButton;//编辑
@property (nonatomic, strong) UIBarButtonItem *selectAllBarButton;//全选
@property (nonatomic, strong) UIBarButtonItem *unSelectAllBarButton;//取消全选
@property (nonatomic, strong) UIBarButtonItem *doneBarButton;//完成
@property (nonatomic, strong) UIBarButtonItem *searchBarButton;//搜索
@property (nonatomic, strong) UIBarButtonItem *newmailBarButton;//新邮件

@property (nonatomic, strong) UITableView *myTableView;
@property (nonatomic, strong) ZGMailListBottomToolBar *bottomToolbar;

@property (nonatomic, strong) NSArray *messageArrayForShow;//列表数据源

@property (nonatomic, strong) NSMutableDictionary *mailPreviews;
@property (nonatomic, strong) NSString *folderType;//文件夹
@property (nonatomic, copy) NSMutableDictionary *selectedCellDic;//被选中的cell对应的messageId ：1对
@property (nonatomic, assign) BOOL selectAll;

@property (nonatomic, copy) NSMutableDictionary *mjRefreshFooterHiddenDic;//各个文件夹下上拉加载更多的配置信息

@property (nonatomic, strong) MASConstraint *bottomToolbarBottomConstraint;

@end

@implementation ZGMailListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.titleView.titleLabel.text = @"收件箱";
    self.navigationItem.titleView = self.titleView;
    self.view.backgroundColor = [UIColor colorWithHexString:@"f2f2f2" alpha:1.0f];
    
    [self.view addSubview:self.myTableView];
    [self.view addSubview:self.bottomToolbar];
    [self layoutPageSubviews];

    self.myTableView.emptyDataSetSource = self;
    self.myTableView.emptyDataSetDelegate = self;
    
    [self setupNavigationBar];
    [self setUpMJRefresh];
    
    isFistLoad = YES;
    
    self.selectAll = NO;
    self.folderType = MailFolderTypeINBOX;
    
    //先展示本地数据
    NSArray *array = [[ZGMailModule sharedInstance] localMailArrayForFolder:MailFolderTypeINBOX];
    self.messageArrayForShow = array;
    
    //加载第一页数据
    [self loadFirstPageData];
    
    //修改下个页面的返回按钮标题
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    //发件箱消息列表刷新通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendingFolderReloadNotification:) name:MailSendingFolderReloadNotification object:nil];
    //收到新邮件通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedNewMailNotification:) name:ZGNotificationReceivedNewMail object:nil];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!isFistLoad) {
        //刷新列表
        //更新展示数据
        self.messageArrayForShow = [[ZGMailModule sharedInstance] showingMailListWithFolder:self.folderType];
        [self.myTableView reloadData];
        
        //更新收件箱和已发送的本地数据
        [[ZGMailModule sharedInstance] saveMailListForFolder:self.folderType];
    } else {
        isFistLoad = NO;
    }

    //当前展示的是发件箱，隐藏右上角的发件进度
    if ([self.folderType isEqualToString:MailFolderTypeSending]) {
        [[ZGMailModule sharedInstance] hideSendMailTopIndicator];
    }
    
    //更新标题和底部红点
    [self updateTitleAndBadge];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[ZGMailModule sharedInstance] showSendMailTopIndicator];

    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //编辑模式
    if (tableView.isEditing) {
        ZGMailListTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        NSString *selected = [self.selectedCellDic valueForKey:[NSString stringWithFormat:@"%ld", (long)indexPath.row]];
        if (IsEmptyString(selected)) {//无值，做选中操作，存储下标
            [cell.multipleSelectImageView setImage:[UIImage imageNamed:@"checkmark_selected"]];
            [self.selectedCellDic setValue:@"selected" forKey:[NSString stringWithFormat:@"%ld", (long)indexPath.row]];
        } else {//有值，做反选操作，删除下标
            [self.selectedCellDic removeObjectForKey:[NSString stringWithFormat:@"%ld", (long)indexPath.row]];
            [cell.multipleSelectImageView setImage:[UIImage imageNamed:@"checkmark_unselected"]];
        }
        
        NSUInteger selectCount = [self.selectedCellDic count];
        if (selectCount == 0) {
            self.navigationItem.title = [self navigationItemTitle];
            
            [self.bottomToolbar setDeleteButtonEnable:NO];
            [self.bottomToolbar setFlagButtonType:FlaButtonType_AllFlagSeenAndDelete];
        } else {
            self.navigationItem.title = [NSString stringWithFormat:@"已选定%lu封", (unsigned long)selectCount];
            
            [self.bottomToolbar setDeleteButtonEnable:YES];
            [self.bottomToolbar setFlagButtonType:FlaButtonType_FlagAndDelete];
        }
    } else {//正常状态
        if ([self.folderType isEqualToString:MailFolderTypeDraft]) {//草稿
            ZGMailMessage *message = self.messageArrayForShow[indexPath.row];

            [self presentNewMailVCWithMessage:message newMailType:NewMailTypeDraft];
        } else if ([self.folderType isEqualToString:MailFolderTypeSending]) {//发件箱
            ZGMailMessage *message = self.messageArrayForShow[indexPath.row];
            //发件箱中，只有失败状态的邮件才能点击跳转到写邮件页面
            if (message.messageStatus == MailMessageStatus_Failure) {
                [self presentNewMailVCWithMessage:message newMailType:NewMailTypeSending];
            } else {
                [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];
            }
        } else {//邮件详情页面
            MCOIMAPMessage *message = self.messageArrayForShow[indexPath.row];
            
            [self pushToMailMessageDetailVCWithMessage:message indexPath:indexPath];
        }
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZGMailListTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [cell.multipleSelectImageView setImage:[UIImage imageNamed:@"checkmark_unselected"]];
    
    if (tableView.isEditing) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        return UITableViewCellEditingStyleDelete & UITableViewCellEditingStyleInsert;
    } else {
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        
        return UITableViewCellEditingStyleDelete;
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    
}

- (nullable NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZGMailListTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];

    UITableViewRowAction *likeAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"标记" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *starAction = [UIAlertAction actionWithTitle:@"添加星标" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            //添加星标
            [self storeFlagsForIndexPath:indexPath kind:MCOIMAPStoreFlagsRequestKindAdd flags:MCOMessageFlagFlagged];
            
            cell.mailRecord.isStarred = YES;
            [cell showStar:YES];
        }];
        
        UIAlertAction *unstarAction = [UIAlertAction actionWithTitle:@"取消星标" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            //取消星标
            [self storeFlagsForIndexPath:indexPath kind:MCOIMAPStoreFlagsRequestKindRemove flags:MCOMessageFlagFlagged];
            
            cell.mailRecord.isStarred = NO;
            [cell showStar:NO];
        }];
        
        UIAlertAction *unseenAction = [UIAlertAction actionWithTitle:@"标为未读" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            //标为未读
            [self storeFlagsForIndexPath:indexPath kind:MCOIMAPStoreFlagsRequestKindRemove flags:MCOMessageFlagSeen];
            
            cell.mailRecord.isUnread = YES;
            [cell showUnseen:YES];
        }];
        
        UIAlertAction *seenAction = [UIAlertAction actionWithTitle:@"标为已读" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            //标为已读
            [self storeFlagsForIndexPath:indexPath kind:MCOIMAPStoreFlagsRequestKindAdd flags:MCOMessageFlagSeen];
            
            cell.mailRecord.isUnread = NO;
            [cell showUnseen:NO];
        }];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        
        MCOIMAPMessage *msg = self.messageArrayForShow[indexPath.row];
        if (msg.flags & MCOMessageFlagFlagged) {
            [alertController addAction:unstarAction];
        } else {
            [alertController addAction:starAction];
        }
        
        if (msg.flags & MCOMessageFlagSeen) {
            [alertController addAction:unseenAction];
        } else {
            [alertController addAction:seenAction];
        }
        
        [alertController addAction:cancelAction];
        
        [self presentViewController:alertController animated:YES completion:nil];
        
        // 在最后希望cell可以自动回到默认状态，所以需要退出编辑模式
        tableView.editing = NO;
    }];
    
    //删除
    UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"删除" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        if ([self.folderType isEqualToString:MailFolderTypeINBOX] || [self.folderType isEqualToString:MailFolderTypeSent]) {//收件箱、已发送
            //删除
            [self storeFlagsForIndexPath:indexPath kind:MCOIMAPStoreFlagsRequestKindAdd flags:MCOMessageFlagDeleted];
        } else if ([self.folderType isEqualToString:MailFolderTypeDraft] || [self.folderType isEqualToString:MailFolderTypeSending]) {//草稿箱
            //修改model
            [[ZGMailModule sharedInstance] removeMessageAtIndex:indexPath.row withFolder:self.folderType];
            //更新展示数据
            self.messageArrayForShow = [[ZGMailModule sharedInstance] showingMailListWithFolder:self.folderType];
            //接着刷新view
            [self.myTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        } else {
            
        }
    }];
    
    if ([self.folderType isEqualToString:MailFolderTypeINBOX]) {
        return @[deleteAction, likeAction];
    } else {
        return @[deleteAction];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.messageArrayForShow count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZGMailListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MailListTableViewCellIdentifier];
    cell.indexPath = indexPath;
    cell.folderType = self.folderType;
    if (tableView.isEditing) {
        if (self.selectAll) {//全选
            [cell.multipleSelectImageView setImage:[UIImage imageNamed:@"checkmark_selected"]];
        } else {
            NSString *selected = [self.selectedCellDic valueForKey:[NSString stringWithFormat:@"%ld", (long)indexPath.row]];
            if (!IsEmptyString(selected)) {
                [cell.multipleSelectImageView setImage:[UIImage imageNamed:@"checkmark_selected"]];
            } else {
                [cell.multipleSelectImageView setImage:[UIImage imageNamed:@"checkmark_unselected"]];
            }
        }
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else {
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    
    if ([self.folderType isEqualToString:MailFolderTypeDraft]) {//草稿
        ZGMailMessage *message = self.messageArrayForShow[indexPath.row];
        ZGMailRecord *mailRecord = [[ZGMailRecord alloc] initWithMailMessage:message];
        cell.mailRecord = mailRecord;
        cell.contentLabel.text = [message.bodyText stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        cell.failureLabel.text = @"";
        cell.progressView.hidden = YES;
    } else if ([self.folderType isEqualToString:MailFolderTypeSending]) {//发件箱
        cell.delegate = self;
        ZGMailMessage *message = self.messageArrayForShow[indexPath.row];
        ZGMailRecord *mailRecord = [[ZGMailRecord alloc] initWithMailMessage:message];
        cell.mailRecord = mailRecord;
        if (message.messageStatus == MailMessageStatus_Sending) {
            [cell showProgressView];
            //        cell.contentLabel.text = message.bodyText;
            MCOSMTPSendOperation *sendOperation = [[ZGMailModule sharedInstance] sendingOperation];
            [sendOperation setProgress:^(unsigned int current, unsigned int maximum) {
                float progress = (float)current / maximum;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [cell.progressView setProgress:progress];
                });
            }];
        } else if (message.messageStatus == MailMessageStatus_Wait) {
            [cell showProgressView];
            [cell.progressView setProgress:0.01];
        } else {
            cell.progressView.hidden = YES;
            cell.contentLabel.text = @"";
            cell.failureLabel.text = message.failureString;
        }
    } else {//收件箱、已发送
        MCOIMAPMessage *message = self.messageArrayForShow[indexPath.row];
        ZGMailRecord *mailRecord = [[ZGMailRecord alloc] initWithImapMessage:message];
        cell.mailRecord = mailRecord;
        cell.progressView.hidden = YES;
        cell.failureLabel.text = @"";
        NSString *uidKey = message.header.messageID;
        NSString *cachedPreview = self.mailPreviews[uidKey];
        if (cachedPreview) {
            cell.contentLabel.text = [cachedPreview stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        } else {
            //防止block中循环引用，导致无法释放
            __weak __block typeof(self) weakSelf = self;
            
            cell.contentLabel.text = @"";
            cell.messageRenderingOperation = [[ZGMailModule sharedInstance] messageRenderingOperationWithMessage:message folder:self.folderType];
            [cell.messageRenderingOperation start:^(NSString *plainTextBodyString, NSError * error) {
                __strong typeof(weakSelf) strongSelf = weakSelf;

                dispatch_async(dispatch_get_main_queue(), ^{
                    strongSelf.mailPreviews[uidKey] = plainTextBodyString;
                    cell.contentLabel.text = [strongSelf.mailPreviews[cell.mailRecord.messageID] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                    cell.messageRenderingOperation = nil;
                });
            }];
        }
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.folderType isEqualToString:MailFolderTypeSending]) {
        ZGMailMessage *msg = self.messageArrayForShow[indexPath.row];
        //发件箱中，只有失败状态的邮件才支持删除
        if (msg.messageStatus == MailMessageStatus_Failure) {
            return YES;
        } else {
            return NO;
        }
    } else {
        return YES;
    }
}

#pragma mark - DZNEmptyDataSetSource

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    return nil;
}

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *text = @"没有邮件";
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Light" size:22.0],
                                 NSForegroundColorAttributeName: [UIColor colorWithHexString:@"c9c9c9" alpha:1.0f]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView {
    return [UIColor clearColor];
}

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView {
    CGFloat offset = CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
    offset += CGRectGetHeight(self.navigationController.navigationBar.frame);
    
    return -offset;
}

- (CGFloat)spaceHeightForEmptyDataSet:(UIScrollView *)scrollView {
    return 16.0f;
}

#pragma mark - DZNEmptyDataSetDelegate

- (BOOL)emptyDataSetShouldDisplay:(UIScrollView *)scrollView {
    
    if ([self.messageArrayForShow count] > 0) {
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)emptyDataSetShouldAllowScroll:(UIScrollView *)scrollView {
    return YES;
}

- (BOOL) emptyDataSetShouldAllowImageViewAnimate:(UIScrollView *)scrollView {
    return YES;
}

- (BOOL)emptyDataSetShouldAnimateImageView:(UIScrollView *)scrollView {
    return YES;
}

- (void)emptyDataSet:(UIScrollView *)scrollView didTapView:(UIView *)view {
    // Do something
}

#pragma mark - ZGMailListTitleViewDelegate

- (void)mailListTitleViewPrssed:(ZGMailListTitleView *)titleView {
    FTPopOverMenuConfiguration *configuration = [FTPopOverMenuConfiguration defaultConfiguration];
    configuration.tintColor = [UIColor whiteColor];
    configuration.textColor = [UIColor colorWithHexString:@"333333" alpha:1.0f];
    configuration.highlightedTextColor = [UIColor colorWithHexString:@"116CCF" alpha:1.0f];
    configuration.menuTextMargin = 15;
    configuration.menuIconMargin = 10;
    configuration.borderColor = [UIColor clearColor];
    configuration.textFont = [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
    
    if ([FTPopOverMenu sharedInstance].isCurrentlyOnScreen) {
        [FTPopOverMenu dismiss];
    } else {
        [FTPopOverMenu showForSender:titleView inView:self.navigationController.view underView:self.navigationController.navigationBar withMenuArray:@[@"收件箱", @"草稿箱", @"发件箱", @"已发送"] imageArray:@[@"mail_inbox", @"mail_draft", @"mail_sending", @"mail_sent"] doneBlock:^(NSInteger selectedIndex) {
            //隐藏弹出框
            [FTPopOverMenu dismiss];
            
            //缓存状态
            [self.mjRefreshFooterHiddenDic setValue:[NSNumber numberWithBool:self.myTableView.mj_footer.hidden] forKey:self.folderType];
            //先隐藏上拉视图
            self.myTableView.mj_footer.hidden = YES;
            
            //切换数据展示
            if (selectedIndex == 0) {
                self.folderType = MailFolderTypeINBOX;
            } else if (selectedIndex == 1) {
                self.folderType = MailFolderTypeDraft;
            } else if (selectedIndex == 2) {
                self.folderType = MailFolderTypeSending;
            } else if (selectedIndex == 3) {
                self.folderType = MailFolderTypeSent;
            } else if (selectedIndex == 4) {
                self.folderType = MailFolderTypeTrash;
            }
            
            //更新展示数据
            NSArray *messagesArray = [[ZGMailModule sharedInstance] showingMailListWithFolder:self.folderType];
            self.messageArrayForShow = messagesArray;
            if ([messagesArray count] == 0) {
                [self.myTableView reloadData];
                //更新标题和底部红点
                [self updateTitleAndBadge];

                //只有收件箱和已发送需要请求数据
                if ([self.folderType isEqualToString:MailFolderTypeINBOX] || [self.folderType isEqualToString:MailFolderTypeSent]) {
                    //防止block中循环引用，导致无法释放
                    __weak __block typeof(self) weakSelf = self;
                    [[ZGMailModule sharedInstance] loadMoreHistoryMessagesInFolder:self.folderType completion:^(NSError *error, NSArray *mailListArray) {
                        if (error) {
                            return;
                        }
                        
                        __strong typeof(weakSelf) strongSelf = weakSelf;
                        strongSelf.messageArrayForShow = [[ZGMailModule sharedInstance] showingMailListWithFolder:strongSelf.folderType];
                        //更新标题和底部红点
                        [strongSelf updateTitleAndBadge];
                        
                        [strongSelf.myTableView reloadData];
                    }];
                }
            } else {
                //更新标题和底部红点
                [self updateTitleAndBadge];

                [self.myTableView reloadData];
            }
            //更新编辑按钮
            [self updateEditBarButton];
            //更新下拉刷新和上拉加载更多
            [self updateMJRefreshHeaderAndFooter];
            //更新底部工具条
            [self updateBottomToolBar];
            
            //发件箱列表，隐藏邮件发送指示器
            if ([self.folderType isEqualToString:MailFolderTypeSending]) {
                [[ZGMailModule sharedInstance] hideSendMailTopIndicator];
            } else {
                [[ZGMailModule sharedInstance] showSendMailTopIndicator];
            }
        } dismissBlock:^{
            self.titleView.isArrowDown = NO;
            
            self.editBarButton.enabled = YES;
            self.searchBarButton.enabled = YES;
            self.newmailBarButton.enabled = YES;
        }];
        
        self.editBarButton.enabled = NO;
        self.searchBarButton.enabled = NO;
        self.newmailBarButton.enabled = NO;
    }
}

#pragma mark - ZGMailMessageDetailViewControllerDelegate

- (void)messageDetailVC:(ZGMailMessageDetailViewController *)messageDetailVC deleteMessageAtIndexPath:(NSIndexPath *)indexPath {
    [self.myTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - ZGMailListTableViewCellDelegate

- (void)mailListTableViewCell:(ZGMailListTableViewCell *)cell cancelButtonPressed:(UIButton *)sender {
    ZGMailMessage *msg = [self.messageArrayForShow objectAtIndex:cell.indexPath.row];
    msg.messageStatus = MailMessageStatus_Failure;
    msg.failureString = @"邮件已取消发送";
    [[ZGMailModule sharedInstance] insertOrUpdateMailMessageInUserDefaultForFolder:MailFolderTypeSending message:msg];
    [[ZGMailModule sharedInstance] stopSendOperationOfMessage:msg.header.messageID];
}

#pragma mark - ZGMailListBottomToolBarDelegate

///全部标记按钮点击
- (void)mailListBottomToolBarAllFlagButtonPressed:(ZGMailListBottomToolBar *)bottomToolBar {
    [self storeAllFlagSeen];
}

///标记按钮点击
- (void)mailListBottomToolBarFlagButtonPressed:(ZGMailListBottomToolBar *)bottomToolBar {
    [self flagButtonPressed:nil];
}

///删除按钮点击
- (void)mailListBottomToolBarDeleteButtonPressed:(ZGMailListBottomToolBar *)bottomToolBar {
    [self deleteButtonPressed:nil];
}

#pragma mark - IBAction

- (IBAction)editButtonPressed:(id)sender {
    //先关闭编辑模式
    if (self.myTableView.isEditing) {
        [self.myTableView setEditing:NO animated:YES];
    }

    //开启TableView编辑模式
    self.myTableView.allowsSelection = YES;
    self.myTableView.allowsSelectionDuringEditing = YES;
    [self.myTableView setEditing:YES animated:YES];
    
    //缓存状态
    [self.mjRefreshFooterHiddenDic setValue:[NSNumber numberWithBool:self.myTableView.mj_footer.hidden] forKey:self.folderType];
    //隐藏下拉刷新
    self.myTableView.mj_header.hidden = YES;
    self.myTableView.mj_footer.hidden = YES;
    
    //TableView底部缩进
    UIEdgeInsets insets = self.myTableView.contentInset;
    insets.bottom = insets.bottom - 5;
    self.myTableView.contentInset = insets;
    
    //调整navigationItem的展示
    self.navigationItem.rightBarButtonItems = nil;
    self.selectAllBarButton.title = @"全选";
    self.navigationItem.leftBarButtonItem = self.selectAllBarButton;
    self.navigationItem.rightBarButtonItem = self.doneBarButton;
    
    //隐藏自定义的titleView
    self.navigationItem.titleView = nil;
    //
    self.navigationItem.title = [self navigationItemTitle];
    
    //显示底部工具条
    self.bottomToolbarBottomConstraint.offset = 0;
    //隐藏tabbar
    self.tabBarController.tabBar.hidden = YES;
   
    [UIView animateWithDuration:0.25 animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (IBAction)selectAllButtonPressed:(id)sender {
    //清空选中项
    [self.selectedCellDic removeAllObjects];
    [self.messageArrayForShow enumerateObjectsUsingBlock:^(MCOIMAPMessage *msg, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.selectedCellDic setValue:@"selected" forKey:[NSString stringWithFormat:@"%ld", (unsigned long)idx]];
    }];
        
    self.selectAll = YES;
    self.navigationItem.title = [NSString stringWithFormat:@"已选定%lu封", (unsigned long)[self.selectedCellDic count]];
    self.navigationItem.leftBarButtonItem = self.unSelectAllBarButton;
    [self.bottomToolbar setDeleteButtonEnable:YES];
    [self.bottomToolbar setFlagButtonType:FlaButtonType_FlagAndDelete];
    
    [self.myTableView reloadData];
}

- (IBAction)unSelectAllButtonPressed:(id)sender {
    self.selectAll = NO;
    self.navigationItem.leftBarButtonItem = self.selectAllBarButton;
    
    //清空选中项
    [self.selectedCellDic removeAllObjects];
    
    self.navigationItem.title = [self navigationItemTitle];
    [self.bottomToolbar setDeleteButtonEnable:NO];
    [self.bottomToolbar setFlagButtonType:FlaButtonType_AllFlagSeenAndDelete];
    
    [self.myTableView reloadData];
}

- (IBAction)doneButtonPressed:(id)sender {
    //状态还原
    self.selectAll = NO;
    //TableView关闭模式
    [self.myTableView setEditing:NO animated:YES];
    
    //恢复上拉、下拉
    [self updateMJRefreshHeaderAndFooter];

    //回复TableView底部缩进
    UIEdgeInsets insets = self.myTableView.contentInset;
    insets.bottom = insets.bottom + 5;
    self.myTableView.contentInset = insets;
    //删除缓存的选中数据
    [self.selectedCellDic removeAllObjects];
    
    //回复titleView
    self.navigationItem.titleView = self.titleView;
    //显示tabbar
    self.tabBarController.tabBar.hidden = NO;

    //隐藏底部工具条
    self.bottomToolbarBottomConstraint.offset = 44;
    [UIView animateWithDuration:0.25 animations:^{
        [self.view layoutIfNeeded];
    }];
    
    //恢复导航栏设置
    [self setupNavigationBar];
    
    //恢复底部工具条
    [self.bottomToolbar setDeleteButtonEnable:NO];
    [self.bottomToolbar setFlagButtonType:FlaButtonType_AllFlagSeenAndDelete];
}

/**
 *  右上角搜索按钮点击
 *
 *  @param sender sender
 */
- (IBAction)searchButtonPressed:(id)sender {
    ZGMailMessageSearchViewController *searchVC = [[ZGMailMessageSearchViewController alloc] init];
    searchVC.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:searchVC animated:NO];
}

/**
 *  右上角新建邮件按钮点击
 *
 *  @param sender sender
 */
- (IBAction)newMailButtonPressed:(id)sender {
    ZGNewMailViewController *newMailVC = [[ZGNewMailViewController alloc] init];
    newMailVC.newMailType = NewMailTypeDefault;
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:newMailVC];
    [self presentViewController:navVC animated:YES completion:nil];
}

#pragma mark - private method

/**
 *  设置约束
 */
- (void)layoutPageSubviews {
    [self.myTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.equalTo(self.view);
        make.center.equalTo(self.view);
    }];
    
    [self.bottomToolbar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(self.view);
        make.height.mas_equalTo(44);
        self.bottomToolbarBottomConstraint = make.bottom.mas_equalTo(self.view.mas_bottom).offset(44);
        make.centerX.mas_equalTo(self.view);
    }];
}

/**
 *  设置navbar上的搜索按钮
 */
- (void)setupNavigationBar {
    self.navigationItem.leftBarButtonItem = self.editBarButton;
    
    self.navigationItem.rightBarButtonItems = @[self.newmailBarButton, self.searchBarButton];
}

/**
 *  设置下拉刷新 上拉加载更多
 */
- (void)setUpMJRefresh {
    // 设置回调（一旦进入刷新状态，就调用target的action，也就是调用self的loadNewData方法）
    MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadNewData)];
    // 设置自动切换透明度(在导航栏下面自动隐藏)
    header.automaticallyChangeAlpha = YES;
    // 隐藏时间
    header.lastUpdatedTimeLabel.hidden = YES;
    // 设置header
    self.myTableView.mj_header = header;
    
    //上拉加载更多
    self.myTableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadNextPageData)];
    self.myTableView.mj_footer.automaticallyChangeAlpha = YES;
    self.myTableView.mj_footer.hidden = YES;
    
    CGRect frame = self.myTableView.mj_footer.frame;
    frame.size.height = cellHeight;
    self.myTableView.mj_footer.frame = frame;
}

//下拉刷新最新的交易记录数据
- (void)loadNewData {
    __weak __block typeof(self) weakSelf = self;
    [[ZGMailModule sharedInstance] updateMailListWithFolder:self.folderType completion:^(NSError *error, NSArray *mailListArray) {
        __strong typeof(weakSelf) strongSelf = weakSelf;

        if (error) {
            [strongSelf.myTableView.mj_header endRefreshing];
            [strongSelf showTipText:@"网络异常，请稍后重试"];
            
            return ;
        }
        
        //更新展示数据
        strongSelf.messageArrayForShow = [[ZGMailModule sharedInstance] showingMailListWithFolder:strongSelf.folderType];
        //保存收件箱和已发送第一页的数据
        [[ZGMailModule sharedInstance] saveMailListForFolder:strongSelf.folderType];
        
        //更新标题和底部红点
        [strongSelf updateTitleAndBadge];
        
        [strongSelf.myTableView.mj_header endRefreshing];
        
        if ([mailListArray count] < NUMBER_OF_MESSAGES_TO_LOAD) {
            strongSelf.myTableView.mj_footer.hidden = YES;
        } else {
            strongSelf.myTableView.mj_footer.hidden = NO;
        }
        
        [strongSelf.myTableView reloadData];
    }];
}

///上拉加载更多的邮件消息
- (void)loadNextPageData {
    __weak __block typeof(self) weakSelf = self;
    [[ZGMailModule sharedInstance] loadMoreHistoryMessagesInFolder:self.folderType completion:^(NSError *error, NSArray *mailListArray) {
        __strong typeof(weakSelf) strongSelf = weakSelf;

        if (error) {
            [strongSelf.myTableView.mj_footer endRefreshing];
            [strongSelf showTipText:@"网络异常，请稍后重试"];
            
            return ;
        }
        
        //更新展示数据
        strongSelf.messageArrayForShow = [[ZGMailModule sharedInstance] showingMailListWithFolder:strongSelf.folderType];

        //更新标题和底部红点
        [strongSelf updateTitleAndBadge];
        
        [strongSelf.myTableView.mj_footer endRefreshing];
        if ([mailListArray count] < NUMBER_OF_MESSAGES_TO_LOAD) {
            strongSelf.myTableView.mj_footer.hidden = YES;
        } else {
            strongSelf.myTableView.mj_footer.hidden = NO;
        }
        
        [strongSelf.myTableView reloadData];
    }];
}

///加载第一页数据
- (void)loadFirstPageData {
    //防止block中循环引用，导致无法释放
    __weak typeof(self) weakSelf = self;
    [[ZGMailModule sharedInstance] loadMoreHistoryMessagesInFolder:self.folderType completion:^(NSError *error, NSArray *mailListArray) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf.myTableView.mj_header endRefreshing];
                [strongSelf showTipText:@"网络异常，请稍后重试"];
            });
            
            return ;
        }
        
        //更新展示数据
        strongSelf.messageArrayForShow = [[ZGMailModule sharedInstance] showingMailListWithFolder:strongSelf.folderType];
        //保存收件箱和已发送第一页的数据
        [[ZGMailModule sharedInstance] saveMailListForFolder:strongSelf.folderType];
        
        //更新标题和底部红点
        [strongSelf updateTitleAndBadge];
        
        //数据不够一页，隐藏上拉加载视图
        if ([mailListArray count] < NUMBER_OF_MESSAGES_TO_LOAD) {
            strongSelf.myTableView.mj_footer.hidden = YES;
        } else {
            strongSelf.myTableView.mj_footer.hidden = NO;
        }
        
        [strongSelf.myTableView reloadData];
    }];
}

//根据未读消息数设置标题
- (void)setTitleWithUnseenCount:(NSInteger)unseenCount {
    NSString *title = [self navigationItemTitle];
    if (unseenCount == 0) {
        self.titleView.titleLabel.text = title;
    } else {
        self.titleView.titleLabel.text = [NSString stringWithFormat:@"%@(%lu)", title, (unsigned long)unseenCount];
    }
}

/**
 *  更新标题和底部红点
 */
- (void)updateTitleAndBadge {
    if ([self.folderType isEqualToString:MailFolderTypeINBOX]) {
        //修改未读消息数
        NSUInteger unseenNumber = [[ZGMailModule sharedInstance] unseenMessageNumberOfINBOX];
        
        [self setTitleWithUnseenCount:unseenNumber];
        [self setTabbarBadge:unseenNumber];
    } else {
        [self setTitleWithUnseenCount:0];
    }
}

/**
 *  设置tabbar上的红点
 *
 *  @param count 红点上展示的数字
 */
- (void)setTabbarBadge:(NSInteger)count {
    if (count > 0) {
        if (count > 99) {
            [self.tabBarItem setBadgeValue:@"99+"];
        } else {
            [self.tabBarItem setBadgeValue:[NSString stringWithFormat:@"%ld", (unsigned long)count]];
        }
    } else {
        [self.tabBarItem setBadgeValue:nil];
    }
}

- (void)updateEditBarButton {
    if ([self.folderType isEqualToString:MailFolderTypeINBOX]) {
        self.navigationItem.leftBarButtonItem = self.editBarButton;
    } else {
        self.navigationItem.leftBarButtonItem = nil;
    }
}

- (void)updateMJRefreshHeaderAndFooter {
    if ([self.folderType isEqualToString:MailFolderTypeDraft] || [self.folderType isEqualToString:MailFolderTypeSending]) {//草稿、发件箱
        self.myTableView.mj_header.hidden = YES;
        self.myTableView.mj_footer.hidden = YES;
    } else {
        self.myTableView.mj_header.hidden = NO;
        NSNumber *number = [self.mjRefreshFooterHiddenDic objectForKey:self.folderType];
        self.myTableView.mj_footer.hidden = number.boolValue;

    }
}

- (void)updateBottomToolBar {
    if ([self.folderType isEqualToString:MailFolderTypeINBOX]) {
        [self.bottomToolbar setFlagButtonType:FlaButtonType_AllFlagSeenAndDelete];
    } else if ([self.folderType isEqualToString:MailFolderTypeDraft]) {//草稿
        [self.bottomToolbar setFlagButtonType:FlaButtonType_Delete];
    } else {
        [self.bottomToolbar setFlagButtonType:FlaButtonType_Delete];
    }
}

- (NSString *)navigationItemTitle {
    NSString *title = @"";
    if ([self.folderType isEqualToString:MailFolderTypeINBOX]) {
        title = @"收件箱";
    } else if ([self.folderType isEqualToString:MailFolderTypeDraft]) {
        title = @"草稿箱";
    } else if ([self.folderType isEqualToString:MailFolderTypeSending]) {
        title = @"发件箱";
    } else if ([self.folderType isEqualToString:MailFolderTypeSent]) {
        title = @"已发送";
    } else if ([self.folderType isEqualToString:MailFolderTypeTrash]) {
        title = @"已删除";
    }
    
    return title;
}

- (void)sendingFolderReloadNotification:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.folderType isEqualToString:MailFolderTypeSending]) {
            //更新展示数据
            self.messageArrayForShow = [[ZGMailModule sharedInstance] showingMailListWithFolder:self.folderType];
            [self.myTableView reloadData];
        }
    });
}

- (void)receivedNewMailNotification:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.folderType isEqualToString:MailFolderTypeINBOX]) {
            //更新展示数据
            self.messageArrayForShow = [[ZGMailModule sharedInstance] showingMailListWithFolder:self.folderType];
            [self.myTableView reloadData];
            //更新标题和底部红点
            [self updateTitleAndBadge];
        }
    });
}

///全部已读
- (void)storeAllFlagSeen {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"将此文件夹中的邮件全部标记为已读？" preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *unseenAction = [UIAlertAction actionWithTitle:@"全部标记为已读" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //全部标记为已读
        [[ZGMailModule sharedInstance] storeAllFlagSeenWithFolder:self.folderType];
        
        NSMutableArray *array = [[NSMutableArray alloc] init];
        NSMutableArray *selectedIndexPath = [[NSMutableArray alloc] init];
        [self.messageArrayForShow enumerateObjectsUsingBlock:^(MCOIMAPMessage *msg, NSUInteger idx, BOOL * _Nonnull stop) {
            msg.flags = msg.flags | MCOMessageFlagSeen;
            [array addObject:msg];
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
            [selectedIndexPath addObject:indexPath];
        }];
        //更新数据
        [[ZGMailModule sharedInstance] replaceMessagesInFolder:self.folderType withNewMessages:array atIndexPaths:selectedIndexPath];
        //刷新页面
        [self.myTableView reloadRowsAtIndexPaths:selectedIndexPath withRowAnimation:UITableViewRowAnimationAutomatic];
        
        //关闭编辑模式
        [self doneButtonPressed:nil];
        //未读消息数为0
        [[ZGMailModule sharedInstance] saveUnseenMessageNumberOfINBOX:0];
        //更新标题和底部红点
        [self updateTitleAndBadge];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    
    [alertController addAction:unseenAction];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)flagButtonPressed:(id)sender {
    __block BOOL haveUnseenMsg = NO;
    __block BOOL haveSeenMsg = NO;
    __block BOOL haveStarredMsg = NO;
    __block BOOL haveUnStarredMsg = NO;
    
    //取出选中的下标数据
    NSArray *array = [self.selectedCellDic allKeys];
    //加工下标数据
    [array enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSInteger index = [obj integerValue];
        MCOIMAPMessage *msg = [self.messageArrayForShow objectAtIndex:index];
        if (msg.flags & MCOMessageFlagFlagged) {//有星标邮件
            haveStarredMsg = YES;
        } else {
            haveUnStarredMsg = YES;
        }
        
        if (msg.flags & MCOMessageFlagSeen) {//有已读邮件
            haveSeenMsg = YES;
        } else {
            haveUnseenMsg = YES;
        }
    }];
    
    UIAlertAction *addStarAction = [UIAlertAction actionWithTitle:@"添加星标" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //添加星标
        [self storeFlagsForSelectedMessagesWithKind:MCOIMAPStoreFlagsRequestKindAdd flags:MCOMessageFlagFlagged];
    }];
    
    UIAlertAction *unstarAction = [UIAlertAction actionWithTitle:@"取消星标" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //取消星标
        [self storeFlagsForSelectedMessagesWithKind:MCOIMAPStoreFlagsRequestKindRemove flags:MCOMessageFlagFlagged];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *starAction = [UIAlertAction actionWithTitle:@"星标" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIAlertController *starAlert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        [starAlert addAction:addStarAction];
        [starAlert addAction:unstarAction];
        [starAlert addAction:cancelAction];
        
        [self presentViewController:starAlert animated:YES completion:nil];
    }];
    
    UIAlertAction *seenAction = [UIAlertAction actionWithTitle:@"标为已读" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //标未已读
        [self storeFlagsForSelectedMessagesWithKind:MCOIMAPStoreFlagsRequestKindAdd flags:MCOMessageFlagSeen];
    }];
    
    UIAlertAction *unseenAction = [UIAlertAction actionWithTitle:@"标为未读" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //标未未读
        [self storeFlagsForSelectedMessagesWithKind:MCOIMAPStoreFlagsRequestKindRemove flags:MCOMessageFlagSeen];
    }];
    
    //选中的有没有星标的邮件+星标邮件
    if (haveUnStarredMsg && haveStarredMsg) {
        [alertController addAction:starAction];
    } else if (haveUnStarredMsg) {//只有没有星标的邮件
        [alertController addAction:addStarAction];
    } else {//只有星标邮件
        [alertController addAction:unstarAction];
    }
    
    //选中的有未读邮件+已读邮件
    if (haveUnseenMsg && haveSeenMsg) {
        [alertController addAction:seenAction];
        [alertController addAction:unseenAction];
    } else if (haveUnseenMsg) {//只有未读邮件
        [alertController addAction:seenAction];
    } else {//只有已读邮件
        [alertController addAction:unseenAction];
    }
    
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)deleteButtonPressed:(id)sender {
    //删除邮件
    [self storeFlagsForSelectedMessagesWithKind:MCOIMAPStoreFlagsRequestKindAdd flags:MCOMessageFlagDeleted];
}

- (void)storeFlagsForIndexPath:(NSIndexPath *)indexPath kind:(MCOIMAPStoreFlagsRequestKind)kind flags:(MCOMessageFlag)flags {
    MCOIMAPMessage *msg = self.messageArrayForShow[indexPath.row];

    //发起标记请求
    [[ZGMailModule sharedInstance] storeFlagsWithFolder:self.folderType messages:@[msg] kind:kind flags:flags];
    
    //修改缓存数据
    if (kind == MCOIMAPStoreFlagsRequestKindRemove) {
        msg.flags = msg.flags & ~flags;
    } else {
        msg.flags = msg.flags | flags;
    }
    
    //删除需要特殊处理
    if (flags == MCOMessageFlagDeleted) {
        //修改model
        [[ZGMailModule sharedInstance] removeMessageAtIndex:indexPath.row withFolder:self.folderType];
        //更新展示数据
        self.messageArrayForShow = [[ZGMailModule sharedInstance] showingMailListWithFolder:self.folderType];
        //接着刷新view
        [self.myTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        //不需要主动退出编辑模式，上面更新view的操作完成后就会自动退出编辑模式
    } else {
        [[ZGMailModule sharedInstance] setMessageWithFolder:self.folderType index:indexPath.row newMessage:msg];
    }
    
    if ([self.folderType isEqualToString:MailFolderTypeINBOX] && (flags == MCOMessageFlagSeen || flags == MCOMessageFlagDeleted)) {
        if (flags == MCOMessageFlagSeen) {
            //修改未读消息数
            NSUInteger unseenNumber = [[ZGMailModule sharedInstance] unseenMessageNumberOfINBOX];
            if (kind == MCOIMAPStoreFlagsRequestKindRemove) {
                unseenNumber += 1;
            } else {
                unseenNumber -= 1;
            }
            
            [[ZGMailModule sharedInstance] saveUnseenMessageNumberOfINBOX:unseenNumber];
            
            //更新标题和底部红点
            [self updateTitleAndBadge];   
        } else {
            //更新未读邮件数
            [[ZGMailModule sharedInstance] getUnseenNumberWithFolder:MailFolderTypeINBOX completionBlock:^(NSError *error, NSInteger unseenNumber) {
                [self updateTitleAndBadge];
            }];
        }
    }
}

///标记选中的邮件消息
- (void)storeFlagsForSelectedMessagesWithKind:(MCOIMAPStoreFlagsRequestKind)kind flags:(MCOMessageFlag)flags {
    //取出选中的下标数据
    NSArray *array = [self.selectedCellDic allKeys];
    NSMutableArray *selectedMessages = [[NSMutableArray alloc] init];
    NSMutableArray *selectedIndexPaths = [[NSMutableArray alloc] init];
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    
    //加工下标数据
    [array enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSInteger index = [obj integerValue];
        MCOIMAPMessage *msg = [self.messageArrayForShow objectAtIndex:index];
        [selectedMessages addObject:msg];
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [selectedIndexPaths addObject:indexPath];
        
        [indexSet addIndex:index];
    }];
    
    //发起标记请求
    [[ZGMailModule sharedInstance] storeFlagsWithFolder:self.folderType messages:selectedMessages kind:kind flags:flags];
    
    if (flags == MCOMessageFlagDeleted) {//删除
        //更新页面、刷新数据
        [[ZGMailModule sharedInstance] removeMessageAtIndexes:indexSet withFolder:self.folderType];
        //更新展示数据
        self.messageArrayForShow = [[ZGMailModule sharedInstance] showingMailListWithFolder:self.folderType];
        [self.myTableView deleteRowsAtIndexPaths:selectedIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {//其他
        //更新缓存数据
        NSMutableArray *array = [[NSMutableArray alloc] init];
        [selectedMessages enumerateObjectsUsingBlock:^(MCOIMAPMessage *msg, NSUInteger idx, BOOL * _Nonnull stop) {
            if (kind == MCOIMAPStoreFlagsRequestKindRemove) {
                msg.flags = msg.flags & ~flags;
            } else {
                msg.flags = msg.flags | flags;
            }
            
            [array addObject:msg];
        }];
        //更新数据
        [[ZGMailModule sharedInstance] replaceMessagesInFolder:self.folderType withNewMessages:selectedMessages atIndexPaths:selectedIndexPaths];
        
        //刷新页面
        [self.myTableView reloadRowsAtIndexPaths:selectedIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
    //关闭编辑模式
    [self doneButtonPressed:nil];
    
    if (flags == MCOMessageFlagSeen) {//修改了已读/未读标记
        //更新未读邮件数
        [self updateUnseenMessageNumber];
    }
}

///更新未读邮件数
- (void)updateUnseenMessageNumber {
    __weak __block typeof(self) weakSelf = self;
    [[ZGMailModule sharedInstance] getUnseenNumberWithFolder:MailFolderTypeINBOX completionBlock:^(NSError *error, NSInteger unseenNumber) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        [strongSelf updateTitleAndBadge];
    }];
}

///打开写邮件页面
- (void)presentNewMailVCWithMessage:(ZGMailMessage *)message newMailType:(NewMailType)newMailType {
    ZGNewMailViewController *newMailVC = [[ZGNewMailViewController alloc] init];
    newMailVC.newMailType = newMailType;
    newMailVC.mailMessage = message;
    newMailVC.originMessageFolder = message.originMessageFolder;
    newMailVC.session = [ZGMailModule sharedInstance].imapSession;
    
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:newMailVC];
    
    [self presentViewController:navVC animated:YES completion:nil];
}

///打开消息详情页面
- (void)pushToMailMessageDetailVCWithMessage:(MCOIMAPMessage *)message indexPath:(NSIndexPath *)indexPath {
    ZGMailMessageDetailViewController *vc = [[ZGMailMessageDetailViewController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    vc.delegate = self;
    vc.folder = self.folderType;
    vc.imapMessage = message;
    vc.session = [ZGMailModule sharedInstance].imapSession;
    vc.indexPath = indexPath;
    
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - setter and getter

- (ZGMailListTitleView *)titleView {
    if (_titleView == nil) {
        _titleView = [[ZGMailListTitleView alloc] initWithFrame:CGRectMake(0, 0, 145, 44)];
        _titleView.delegate = self;
    }
    
    return _titleView;
}

- (UIBarButtonItem *)editBarButton {
    if (_editBarButton == nil) {
        _editBarButton = [[UIBarButtonItem alloc] initWithTitle:@"编辑" style:UIBarButtonItemStylePlain target:self action:@selector(editButtonPressed:)];
    }
    
    return _editBarButton;
}

- (UIBarButtonItem *)selectAllBarButton {
    if (_selectAllBarButton == nil) {
        _selectAllBarButton = [[UIBarButtonItem alloc] initWithTitle:@"全选" style:UIBarButtonItemStylePlain target:self action:@selector(selectAllButtonPressed:)];
    }
    
    return _selectAllBarButton;
}

- (UIBarButtonItem *)unSelectAllBarButton {
    if (_unSelectAllBarButton == nil) {
        _unSelectAllBarButton = [[UIBarButtonItem alloc] initWithTitle:@"取消全选" style:UIBarButtonItemStylePlain target:self action:@selector(unSelectAllButtonPressed:)];
    }
    
    return _unSelectAllBarButton;
}

- (UIBarButtonItem *)doneBarButton {
    if (_doneBarButton == nil) {
        _doneBarButton = [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStylePlain target:self action:@selector(doneButtonPressed:)];
    }
    
    return _doneBarButton;
}

- (UIBarButtonItem *)searchBarButton {
    if (_searchBarButton == nil) {
        _searchBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchButtonPressed:)];
    }
    
    return _searchBarButton;
}

- (UIBarButtonItem *)newmailBarButton {
    if (_newmailBarButton == nil) {
        _newmailBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(newMailButtonPressed:)];
    }
    
    return _newmailBarButton;
}

- (UITableView *)myTableView {
    if (_myTableView == nil) {
        _myTableView = [[UITableView alloc] init];
        
        _myTableView.delegate = self;
        _myTableView.dataSource = self;
        _myTableView.tableFooterView = [UIView new];
        _myTableView.rowHeight = cellHeight;
        //inset
        _myTableView.layoutMargins = UIEdgeInsetsZero;
        [_myTableView registerClass:[ZGMailListTableViewCell class] forCellReuseIdentifier:MailListTableViewCellIdentifier];
    }
    
    return _myTableView;
}

- (ZGMailListBottomToolBar *)bottomToolbar {
    if (_bottomToolbar == nil) {
        _bottomToolbar = [[ZGMailListBottomToolBar alloc] init];
        _bottomToolbar.toolBarDelegate = self;
    }
    
    return _bottomToolbar;
}

- (NSArray *)messageArrayForShow {
    if (_messageArrayForShow == nil) {
        _messageArrayForShow = [[NSArray alloc] init];
    }
    
    return _messageArrayForShow;
}

- (NSMutableDictionary *)mailPreviews {
    if (_mailPreviews == nil) {
        _mailPreviews = [[NSMutableDictionary alloc] init];
    }
    
    return _mailPreviews;
}

- (NSMutableDictionary *)selectedCellDic {
    if (_selectedCellDic == nil) {
        _selectedCellDic = [[NSMutableDictionary alloc] init];
    }
    
    return _selectedCellDic;
}

- (NSMutableDictionary *)mjRefreshFooterHiddenDic {
    if (_mjRefreshFooterHiddenDic == nil) {
        _mjRefreshFooterHiddenDic = [[NSMutableDictionary alloc] init];
    }
    
    return _mjRefreshFooterHiddenDic;
}

@end
