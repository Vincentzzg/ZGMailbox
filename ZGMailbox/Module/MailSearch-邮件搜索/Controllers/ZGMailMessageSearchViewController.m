//
//  ZGMailMessageSearchViewController.m
//  ZGMailbox
//
//  Created by zzg on 2017/5/18.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import "ZGMailMessageSearchViewController.h"
#import "ZGMailMessageDetailViewController.h"//邮件详情页面

//cell
#import "ZGMailListTableViewCell.h"

//邮件协议
#import <MailCore/MailCore.h>

//record
#import "ZGMailRecord.h"

//邮件模块
#import "ZGMailModule.h"

//view
#import "ZGRoundSearchBar.h"


//常量
static CGFloat const cellHeight = 86.0f;
static NSString *const MailListTableViewCellIdentifier = @"MailListTableViewCellIdentifier";

@interface ZGMailMessageSearchViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, ZGMailMessageDetailViewControllerDelegate>

@property (nonatomic, strong) ZGRoundSearchBar *searchBar;
@property (nonatomic, strong) UITableView *myTableView;

@property (nonatomic, copy) NSArray *mailList;

@end

@implementation ZGMailMessageSearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithHexString:@"f2f2f2" alpha:1.0f];
    self.navigationItem.hidesBackButton = YES;
    
    [self.view addSubview:self.myTableView];
    [self layoutPageSubviews];
    [self setupNavigationBar];
    [self.searchBar becomeFirstResponder];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.myTableView deselectRowAtIndexPath:[self.myTableView indexPathForSelectedRow] animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.searchBar resignFirstResponder];
    
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MCOIMAPMessage *msg = self.mailList[indexPath.row];
    
    ZGMailMessageDetailViewController *vc = [[ZGMailMessageDetailViewController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    vc.delegate = self;
    vc.folder = @"INBOX";
    vc.imapMessage = msg;
    vc.session = [ZGMailModule sharedInstance].imapSession;
    vc.indexPath = indexPath;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.mailList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZGMailListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MailListTableViewCellIdentifier];
    cell.indexPath = indexPath;
    
    MCOIMAPMessage *message = self.mailList[indexPath.row];
    ZGMailRecord *mailRecord = [[ZGMailRecord alloc] initWithImapMessage:message];
    cell.mailRecord = mailRecord;
    cell.progressView.hidden = YES;
    cell.contentLabel.text = @"";
    cell.failureLabel.text = @"";

    return cell;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.searchBar resignFirstResponder];
}

#pragma mark - UISearchBarDelegate

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
//    NSString *toBeString = [searchBar.text stringByReplacingCharactersInRange:range withString:text]; //得到输入框的内容
//    //输入框数据清空的时候 从新刷新列表
//    if (IsEmptyString(toBeString)) {
//        [self setupSearchHistoryTable];
//        [self.myTableView reloadData];
//    }
    return YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self searchContacts];
}

#pragma mark - ZGMailMessageDetailViewControllerDelegate

- (void)messageDetailVC:(ZGMailMessageDetailViewController *)messageDetailVC deleteMessageAtIndexPath:(NSIndexPath *)indexPath {
    [self.myTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - IBAction

/**
 *  取消按钮点击事件
 */
- (IBAction)cancelButtonClicked:(id)sender {
    [self.searchBar resignFirstResponder];
    [self.navigationController popViewControllerAnimated:NO];
}

/**
 *  设置按钮点击事件
 */
- (IBAction)settingButtonClicked:(id)sender {
    
}

#pragma mark - private method

/**
 *  设置navbar上的视图
 */
- (void)setupNavigationBar {
    self.navigationItem.titleView = self.searchBar;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonClicked:)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"设置" style:UIBarButtonItemStylePlain target:self action:@selector(settingButtonClicked:)];
}

/**
 *  设置约束
 */
- (void)layoutPageSubviews {
    [self.myTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.equalTo(self.view);
        make.center.equalTo(self.view);
    }];
}

/**
 *  搜索联系人
 */
- (void)searchContacts {
    if (IsEmptyString(self.searchBar.text)) {
        [self showTipText:@"请输入查询条件"];
    } else {
        [self showHUDCoverNavbar:YES];
        [self.searchBar resignFirstResponder];
         MCOIMAPSearchOperation *op = [[ZGMailModule sharedInstance].imapSession searchOperationWithFolder:@"INBOX" kind:MCOIMAPSearchKindContent searchString:self.searchBar.text];
        [op start:^(NSError * _Nullable error, MCOIndexSet * _Nullable searchResult) {
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self hideHUD];
                });
            } else {
                MCOIMAPMessagesRequestKind requestKind = (MCOIMAPMessagesRequestKind)(MCOIMAPMessagesRequestKindHeaders | MCOIMAPMessagesRequestKindStructure | MCOIMAPMessagesRequestKindInternalDate | MCOIMAPMessagesRequestKindHeaderSubject | MCOIMAPMessagesRequestKindFlags);

                MCOIMAPFetchMessagesOperation *imapMessagesFetchOp = [[ZGMailModule sharedInstance].imapSession fetchMessagesOperationWithFolder:@"INBOX" requestKind:requestKind uids:searchResult];
                [imapMessagesFetchOp start:^(NSError * _Nullable error, NSArray * _Nullable messages, MCOIndexSet * _Nullable vanishedMessages) {
                    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"header.date" ascending:NO];
                    NSMutableArray *combinedMessages = [NSMutableArray arrayWithArray:messages];
                    
                    //根据邮件头里面的时间排序
                    self.mailList = [combinedMessages sortedArrayUsingDescriptors:@[sort]];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self hideHUD];
                        [self.myTableView reloadData];
                    });
                }];
            }
        }];
    }
}

#pragma mark - setter and getter

- (UITableView *)myTableView {
    if (_myTableView == nil) {
        _myTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        //        _myTableView.backgroundColor = [UIColor clearColor];
        _myTableView.delegate = self;
        _myTableView.dataSource = self;
        _myTableView.tableFooterView = [UIView new];
        _myTableView.rowHeight = cellHeight;
        //inset
        _myTableView.separatorInset = UIEdgeInsetsMake(0, 10, 0, 0);
        _myTableView.layoutMargins = UIEdgeInsetsZero;
        [_myTableView registerClass:[ZGMailListTableViewCell class] forCellReuseIdentifier:MailListTableViewCellIdentifier];
    }
    
    return _myTableView;
}

- (ZGRoundSearchBar *)searchBar {
    if (_searchBar == nil) {
        _searchBar = [[ZGRoundSearchBar alloc] init];
        _searchBar.delegate = self;
        _searchBar.placeholder = @"搜索";
    }
    
    return _searchBar;
}

- (NSArray *)mailList {
    if (_mailList == nil) {
        _mailList = [[NSArray alloc] init];
    }
    
    return _mailList;
}

@end
