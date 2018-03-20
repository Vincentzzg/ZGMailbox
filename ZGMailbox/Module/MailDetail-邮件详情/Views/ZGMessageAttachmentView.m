//
//  ZGMessageAttachmentView.m
//  ZGMailbox
//
//  Created by zzg on 2017/4/13.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import "ZGMessageAttachmentView.h"

//cell
#import "ZGAttachmentTableViewCell.h"

#import <MailCore/MCOIMAPPart.h>

//常量
static NSString *const AttachmentTableViewCellIdentifier = @"AttachmentTableViewCellIdentifier";

@interface ZGMessageAttachmentView () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation ZGMessageAttachmentView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        [self addSubview:self.myTableView];
        [self layoutViewSubviews];
    }
    
    return self;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.delegate && [self.delegate respondsToSelector:@selector(messageAttachmentView:selectAttachment:)]) {
        [self.delegate messageAttachmentView:self selectAttachment:[self.attachments objectAtIndex:indexPath.row]];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.01;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.attachments count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZGAttachmentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:AttachmentTableViewCellIdentifier];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.part = [self.attachments objectAtIndex:indexPath.row];
    
    return cell;
}

#pragma mark - public method 

- (float)heightOfAttachmentView {
    return [self.attachments count] * 62 + 20;
}

- (void)reloadTableView {
    [self.myTableView reloadData];
}

#pragma mark - private method 

- (void)layoutViewSubviews {
    [self.myTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(self);
        make.center.mas_equalTo(self);
    }];
}

#pragma mark - setter and getter 

- (UITableView *)myTableView {
    if (_myTableView == nil) {
        _myTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _myTableView.backgroundColor = [UIColor whiteColor];
        _myTableView.contentOffset = CGPointZero;
        _myTableView.layoutMargins = UIEdgeInsetsZero;
        _myTableView.separatorInset = UIEdgeInsetsMake(0, 10, 0, 0);
        _myTableView.delegate = self;
        _myTableView.dataSource = self;
        _myTableView.rowHeight = 62;
        _myTableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, CGFLOAT_MIN)];

        [_myTableView registerClass:[ZGAttachmentTableViewCell class] forCellReuseIdentifier:AttachmentTableViewCellIdentifier];
    }
    
    return _myTableView;
}

@end
