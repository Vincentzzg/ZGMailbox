//
//  ZGMailMessageHeaderDetailView.m
//  ZGMailbox
//
//  Created by zzg on 2017/4/6.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import "ZGMailMessageHeaderDetailView.h"

//custom views
#import "ZGAddressShadowButton.h"
#import "ZGMessageHeaderDetailAddressTableViewCell.h"
#import "ZGMessageHeaderDetailTimeTableViewCell.h"
#import "ZGMessageHeaderDetailAttachmentTableViewCell.h"

#import <MailCore/MCOIMAPMessage.h>
#import <MailCore/MCOMessageHeader.h>
#import <MailCore/MCOAddress.h>

//常量
static NSString *const MessageHeaderDetailAddressTableViewCellIdentifier = @"MessageHeaderDetailAddressTableViewCellIdentifier";
static NSString *const MessageHeaderDetailTimeTableViewCellIdentifier = @"MessageHeaderDetailTimeTableViewCellIdentifier";
static NSString *const MessageHeaderDetailAttachmentTableViewCellIdentifier = @"MessageHeaderDetailAttachmentTableViewCellIdentifier";

@interface ZGMailMessageHeaderDetailView () <UITableViewDelegate, UITableViewDataSource, ZGMessageHeaderDetailAddressTableViewCellDelegate, ZGMessageHeaderDetailAttachmentTableViewCellDelegate>

@property (nonatomic, strong) UITableView *myTableView;

@end

@implementation ZGMailMessageHeaderDetailView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.myTableView];
        
        //cell上的按钮快速点击时一样有点击效果
        self.myTableView.delaysContentTouches = NO;
        for (UIView *currentView in self.myTableView.subviews) {
            if([currentView isKindOfClass:[UIScrollView class]]) {
                ((UIScrollView *)currentView).delaysContentTouches = NO;
                break;
            }
        }

        [self layoutViewSubviews];
    }
    
    return self;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger section = indexPath.section;
    if (section == 4 || section == 5) {
        return 24;
    } else {
        return 38;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 6;//发件人、收件人、抄送、密送、时间、附件
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0://发件人
            return 1;
            break;
        case 1://收件人
            return [self.message.header.to count];
            break;
        case 2://抄送
            return [self.message.header.cc count];
            break;
        case 3://密送
            return [self.message.header.bcc count];
            break;
        case 4://时间
            return 1;
            break;
        case 5://附件
            if ([self.message.attachments count] > 0) {
                return 1;
            } else {
                return 0;
            }
            break;
            
        default:
            return 0;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger section = indexPath.section;
    if (section == 0 || section == 1 || section == 2 || section == 3) {
        ZGMessageHeaderDetailAddressTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MessageHeaderDetailAddressTableViewCellIdentifier];
        cell.delegate = self;
        switch (section) {
            case 0://发件人
                if (indexPath.row == 0) {
                    cell.titleLabel.text = @"发件人：";
                } else {
                    cell.titleLabel.text = @"";
                }
                cell.address = self.message.header.sender;
                
                break;
            case 1://收件人
                if (indexPath.row == 0) {
                    cell.titleLabel.text = @"收件人：";
                } else {
                    cell.titleLabel.text = @"";
                }
                cell.address = [self.message.header.to objectAtIndex:indexPath.row];
                
                break;
            case 2://抄送
                if (indexPath.row == 0) {
                    cell.titleLabel.text = @"抄送：";
                } else {
                    cell.titleLabel.text = @"";
                }
                cell.address = [self.message.header.cc objectAtIndex:indexPath.row];
               
                break;
            case 3://密送
                if (indexPath.row == 0) {
                    cell.titleLabel.text = @"抄送：";
                } else {
                    cell.titleLabel.text = @"";
                }
                cell.titleLabel.text = @"密送：";
                cell.address = [self.message.header.bcc objectAtIndex:indexPath.row];
                
                break;
                
            default:
                break;
        }

        return cell;
    } else if (section == 4) {//时间
        ZGMessageHeaderDetailTimeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MessageHeaderDetailTimeTableViewCellIdentifier forIndexPath:indexPath];
        cell.date = self.message.header.receivedDate;
        
        return cell;
    } else if (section == 5) {//附件
        ZGMessageHeaderDetailAttachmentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MessageHeaderDetailAttachmentTableViewCellIdentifier];
        cell.delegate = self;
        cell.attachments = self.message.attachments;
        
        return cell;
    } else {
        //其他
        UITableViewCell *cell = [[UITableViewCell alloc] init];
        return cell;
    }
}

#pragma mark - ZGMessageHeaderDetailAddressTableViewCellDelegate

- (void)headerDetailAddressCell:(ZGMessageHeaderDetailAddressTableViewCell *)tableViewCell addressButtonPressed:(ZGAddressShadowButton *)button {
    if (self.delegate && [self.delegate respondsToSelector:@selector(headerDetailView:addressButtonPressed:)]) {
        [self.delegate headerDetailView:self addressButtonPressed:button];
    }
}

#pragma mark - ZGMessageHeaderDetailAttachmentTableViewCellDelegate

- (void)headerDetailAttachmentCell:(ZGMessageHeaderDetailAttachmentTableViewCell *)cell attacmentButtonPressed:(ZGAddressShadowButton *)button {
    if (self.delegate && [self.delegate respondsToSelector:@selector(headerDetailView:attachmentButtonPressed:)]) {
        [self.delegate headerDetailView:self attachmentButtonPressed:button];
    }
}

//#pragma mark - IBAction 
//
//- (IBAction)addressButtonPressed:(id)sender {
//    if (self.delegate && [self.delegate respondsToSelector:@selector(headerDetailView:addressButtonPressed:)]) {
//        [self.delegate headerDetailView:self addressButtonPressed:sender];
//    }
//}

#pragma mark - public method

- (float)heightOfMailDetailView {
    [self layoutIfNeeded];
    
    return self.myTableView.contentSize.height;
}

- (void)reloadTableView {
    [self.myTableView reloadData];
}

#pragma mark - private method 

- (void)layoutViewSubviews {
    [self.myTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self);
        make.size.mas_equalTo(self);
    }];
}

- (NSMutableAttributedString *)attributedStringAddresWithAddress:(MCOAddress *)address {
    NSMutableAttributedString *addressStr = [[NSMutableAttributedString alloc] init];
    NSString *name = [address displayName];
    NSString *mailbox = [address mailbox];
    if (IsEmptyString(name)) {
        NSArray *array = [mailbox componentsSeparatedByString:@"@"];
        name = [array firstObject];
    } else {
        //都有值，不需要处理
    }
    
    NSAttributedString *attStr = [[NSAttributedString alloc] initWithString:name attributes:@{NSForegroundColorAttributeName : [UIColor blackColor]}];
    NSAttributedString *attMailbox = [[NSAttributedString alloc] initWithString:mailbox attributes:@{NSForegroundColorAttributeName : [UIColor colorWithHexString:@"999999" alpha:1.0f]}];
    [addressStr appendAttributedString:attStr];
    [addressStr appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
    [addressStr appendAttributedString:attMailbox];
    
    [addressStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:12.0f] range:NSMakeRange(0, addressStr.length)];

    return addressStr;
}

#pragma mark - setter and getter 

- (void)setMessage:(MCOIMAPMessage *)message {
    _message = message;
    [self.myTableView reloadData];
}

#pragma mark - setter and getter 

- (UITableView *)myTableView {
    if (_myTableView == nil) {
        _myTableView = [[UITableView alloc] init];
        _myTableView.delegate = self;
        _myTableView.dataSource = self;
        _myTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _myTableView.allowsSelection = NO;
        [_myTableView registerClass:[ZGMessageHeaderDetailAddressTableViewCell class] forCellReuseIdentifier:MessageHeaderDetailAddressTableViewCellIdentifier];
        [_myTableView registerClass:[ZGMessageHeaderDetailTimeTableViewCell class] forCellReuseIdentifier:MessageHeaderDetailTimeTableViewCellIdentifier];
        [_myTableView registerClass:[ZGMessageHeaderDetailAttachmentTableViewCell class] forCellReuseIdentifier:MessageHeaderDetailAttachmentTableViewCellIdentifier];
    }
    
    return _myTableView;
}

@end
