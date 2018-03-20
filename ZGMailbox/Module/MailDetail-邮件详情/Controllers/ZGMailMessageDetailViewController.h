//
//  ZGMailMessageDetailViewController.h
//  ZGMailbox
//
//  Created by zzg on 2017/3/27.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MCOIMAPSession;
@class MCOIMAPMessage;
@protocol ZGMailMessageDetailViewControllerDelegate;

///邮件详情页面
@interface ZGMailMessageDetailViewController : UIViewController

@property (nonatomic, weak) id<ZGMailMessageDetailViewControllerDelegate> delegate;

@property (nonatomic, copy) NSString *folder;
@property (nonatomic, strong) MCOIMAPSession *session;
@property (nonatomic, strong) MCOIMAPMessage *imapMessage;
@property (nonatomic, strong) NSIndexPath *indexPath;

@end

@protocol ZGMailMessageDetailViewControllerDelegate <NSObject>

- (void)messageDetailVC:(ZGMailMessageDetailViewController *)messageDetailVC deleteMessageAtIndexPath:(NSIndexPath *)indexPath;

@end
