//
//  ZGSendingMailListViewController.m
//  ZGMailbox
//
//  Created by zzg on 2017/5/22.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import "ZGSendingMailListViewController.h"
#import "ZGNewMailViewController.h"//写邮件页面

//cell
#import "ZGMailListTableViewCell.h"

//邮件协议
#import <MailCore/MailCore.h>

//邮件模块管理工具类
#import "ZGMailModule.h"

//record
#import "ZGMailMessage.h"
#import "ZGMailRecord.h"


//常量
static CGFloat const cellHeight = 86.0f;
static NSString *const MailListTableViewCellIdentifier = @"ZGMailListTableViewCellIdentifier";


@interface ZGSendingMailListViewController () <UITableViewDelegate, UITableViewDataSource, ZGMailListTableViewCellDelegate>

@property (nonatomic, strong) UITableView *myTableView;

@property (nonatomic, strong) NSArray *messageArrayForShow;//列表数据源

@end

@implementation ZGSendingMailListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithHexString:@"f2f2f2" alpha:1.0f];
    [self.view addSubview:self.myTableView];
    [self layoutPageSubviews];
    
    //先展示本地数据
    self.messageArrayForShow = [[ZGMailModule sharedInstance] localMailArrayForFolder:MailFolderTypeSending];
    
    //发件箱消息列表刷新通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendingFolderReloadNotification:) name:MailSendingFolderReloadNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[ZGMailModule sharedInstance] hideSendMailTopIndicator];   
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[ZGMailModule sharedInstance] showSendMailTopIndicator];
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
    ZGMailMessage *msg = self.messageArrayForShow[indexPath.row];
    //发件箱中，只有失败状态的邮件才能点击跳转到写邮件页面
    if (msg.messageStatus == MailMessageStatus_Failure) {
        ZGNewMailViewController *newMailVC = [[ZGNewMailViewController alloc] init];
        newMailVC.newMailType = NewMailTypeSending;
        newMailVC.mailMessage = msg;
        newMailVC.originMessageFolder = msg.originMessageFolder;
        newMailVC.session = [ZGMailModule sharedInstance].imapSession;
        UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:newMailVC];
        [self presentViewController:navVC animated:YES completion:nil];
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.messageArrayForShow count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZGMailListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MailListTableViewCellIdentifier];
    cell.indexPath = indexPath;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    
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
    
    return cell;
}

#pragma mark - ZGMailListTableViewCellDelegate

- (void)mailListTableViewCell:(ZGMailListTableViewCell *)cell cancelButtonPressed:(UIButton *)sender {
//    ZGMailMessage *msg = [self.messageArrayForShow objectAtIndex:cell.indexPath.row];
//    msg.messageStatus = MailMessageStatus_Failure;
//    msg.failureString = @"邮件已取消发送";
//    [[ZGMailModule sharedInstance] insertOrUpdateMailMessageInUserDefaultForFolder:MailFolderTypeSending message:msg];
//    [[ZGMailModule sharedInstance] stopSendOperationOfMessage:msg.header.messageID];
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
}

- (void)sendingFolderReloadNotification:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        //更新展示数据
        self.messageArrayForShow = [[ZGMailModule sharedInstance] showingMailListWithFolder:MailFolderTypeSending];
        [self.myTableView reloadData];
    });
}

#pragma mark - setter and getter

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

- (NSArray *)messageArrayForShow {
    if (_messageArrayForShow == nil) {
        _messageArrayForShow = [[NSArray alloc] init];
    }
    
    return _messageArrayForShow;
}

@end
