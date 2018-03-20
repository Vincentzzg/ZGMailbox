//
//  MCOMessageView.h
//  testUI
//
//  Created by DINH Viêt Hoà on 1/19/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import <MailCore/MailCore.h>

#import <UIKit/UIKit.h>

@class MCOIMAPSession;

typedef NS_ENUM(NSUInteger, MessageType) {
    MessageTypeNormal,//常规邮件
    MessageTypeOriginal,//原始邮件
};

@protocol MCOMessageViewDelegate;

@interface MCOMessageView : UIView <UIWebViewDelegate>

@property (nonatomic, strong) UIScrollView *webScrollView;

@property (nonatomic, strong) MCOIMAPSession *session;
@property (nonatomic, copy) NSString *folder;
@property (nonatomic, strong) MCOIMAPMessage *imapMessage;
@property (nonatomic, assign) MessageType messageType;

@property (nonatomic, assign) id <MCOMessageViewDelegate> delegate;

@property (nonatomic, assign) BOOL prefetchIMAPImagesEnabled;
@property (nonatomic, assign) BOOL prefetchIMAPAttachmentsEnabled;

@property (nonatomic, copy) NSString *messageHtmlString;

- (BOOL)isLoading;

@end

@protocol MCOMessageViewDelegate <NSObject>

@optional

- (BOOL)MCOMessageView:(MCOMessageView *)view webViewShouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;

- (void)MCOMessageView:(MCOMessageView *)view webViewDidFinishLoad:(UIWebView *)webView;
- (void)MCOMessageView:(MCOMessageView *)view webViewDidFailLoad:(UIWebView *)webView;

@end
