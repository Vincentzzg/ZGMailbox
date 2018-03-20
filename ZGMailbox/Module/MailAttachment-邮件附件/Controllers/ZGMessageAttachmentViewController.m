//
//  ZGMessageAttachmentViewController.m
//  ZGMailbox
//
//  Created by zzg on 2017/4/13.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import "ZGMessageAttachmentViewController.h"

#import <MailCore/MailCore.h>
#import <MailCore/MCOIMAPPart.h>

//邮件模块管理工具类
#import "ZGMailModule.h"

//view
#import "ZGAttachmentDownloadView.h"

#import "NSString+Mail.h"

@interface ZGMessageAttachmentViewController () <UIWebViewDelegate> {
    MCOIMAPFetchContentOperation *operation;
}

@property (nonatomic, strong) UIWebView *myWebview;
@property (nonatomic, strong) ZGAttachmentDownloadView *attachmentDownloadView;

@end

@implementation ZGMessageAttachmentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithHexString:@"F0F0F0" alpha:1.0f];
    self.title = self.part.filename;
    
    [self.view addSubview:self.myWebview];
    [self layoutPageViews];
    
    NSString *path = [[ZGMailModule sharedInstance] cachePathForPart:self.part withMessageID:self.message.header.messageID];
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (data) {//@"text/plain"，txt文件
        NSURL *url = [NSURL fileURLWithPath:path];
        NSString *mimeType = [self mimeType:url];
        if ([mimeType isEqualToString:@"text/plain"]) {
            [self.myWebview loadData:data MIMEType:mimeType textEncodingName:@"GBK" baseURL:[NSURL new]];
        } else {
            [self.myWebview loadData:data MIMEType:mimeType textEncodingName:@"utf-8" baseURL:[NSURL new]];
        }
    } else {
        [self fetchAttachment];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [operation cancel];
    [self.myWebview stopLoading];
    self.myWebview = nil;
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"%@", error.description);
}

#pragma mark - private method

- (void)layoutPageViews {
    [self.myWebview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self.view);
        make.size.mas_equalTo(self.view);
    }];
}

- (void)fetchAttachment {
    [self.view addSubview:self.attachmentDownloadView];
    [self.attachmentDownloadView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self.view);
        make.size.mas_equalTo(self.view);
    }];
    
    __weak typeof(self) weakSelf = self;
    operation = [self.session fetchMessageAttachmentOperationWithFolder:self.folder uid:[self.message uid] partID:[self.part partID] encoding:[self.part encoding]];
    [operation setProgress:^(unsigned int current, unsigned int maximum) {
        __strong typeof(weakSelf) strongSelf = weakSelf;

        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *currentStr = [NSString formatStringOfSize:current];
            NSString *maximumStr = [NSString formatStringOfSize:maximum];
            
            if (maximum != 0) {
                float progress = (float)current / maximum;
                strongSelf.attachmentDownloadView.progressView.progress = progress;
                strongSelf.attachmentDownloadView.progressLabel.text = [NSString stringWithFormat:@"%@ / %@", currentStr, maximumStr];
            }
        });
    }];

    [operation start:^(NSError *error, NSData *data) {
        __strong typeof(weakSelf) strongSelf = weakSelf;

        dispatch_async(dispatch_get_main_queue(), ^{
            strongSelf.attachmentDownloadView.hidden = YES;
            [strongSelf.attachmentDownloadView removeFromSuperview];
            
            if ([error code] != MCOErrorNone) {
                return;
            }
            NSAssert(data != NULL, @"data != nil");
            //保存数据到本地
            [[ZGMailModule sharedInstance] cacheData:data forPart:strongSelf.part withMessageID:self.message.header.messageID];
            
            NSString *path = [[ZGMailModule sharedInstance] cachePathForPart:strongSelf.part withMessageID:self.message.header.messageID];
            if (!IsEmptyString(path)) {//地址为空不加载
                NSURL *url = [NSURL fileURLWithPath:path];
                NSString *mimeType = [strongSelf mimeType:url];
                [strongSelf.myWebview loadData:data MIMEType:mimeType textEncodingName:@"utf-8" baseURL:[NSURL new]];
            }
        });
    }];
}

#pragma mark 获取指定URL的MIMEType类型
- (NSString *)mimeType:(NSURL *)url {
    //1NSURLRequest
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    //3 在NSURLResponse里，服务器告诉浏览器用什么方式打开文件。
    
    //使用同步方法后去MIMEType
    NSURLResponse *response = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
    
    return response.MIMEType;
}

#pragma mark - setter and getter

- (UIWebView *)myWebview {
    if (_myWebview == nil) {
        _myWebview = [[UIWebView alloc] init];
        _myWebview.delegate = self;
        _myWebview.scalesPageToFit = YES;
    }
    
    return _myWebview;
}

- (ZGAttachmentDownloadView *)attachmentDownloadView {
    if (_attachmentDownloadView == nil) {
        _attachmentDownloadView = [[ZGAttachmentDownloadView alloc] init];
        _attachmentDownloadView.mimeType = self.part.mimeType;
        _attachmentDownloadView.progressLabel.text = [NSString stringWithFormat:@"0B / %@", [NSString formatStringOfSize:self.part.size]];
        _attachmentDownloadView.fileNameLabel.text = self.part.filename;
        _attachmentDownloadView.filename = self.part.filename;
    }
    
    return _attachmentDownloadView;
}

@end
