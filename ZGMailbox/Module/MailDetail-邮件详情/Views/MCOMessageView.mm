//
//  MCOMessageView.m
//  testUI
//
//  Created by DINH Viêt Hoà on 1/19/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCOMessageView.h"
#import "MCOCIDURLProtocol.h"

#import "ZGMailModule.h"

//image操作
#import <ImageIO/ImageIO.h>

#import <MailCore/MCOIMAPMessage.h>


static NSString *mainJavascript = @"\
var imageElements = function() {\
	var imageNodes = document.getElementsByTagName('img');\
	return [].slice.call(imageNodes);\
};\
\
var findCIDImageURL = function() {\
	var images = imageElements();\
	var imgLinks = [];\
	for (var i = 0; i < images.length; i++) {\
        var url = images[i].getAttribute('src');\
        if (url.indexOf('cid:') > -1 || url.indexOf('x-mailcore-image:') == 0)\
            imgLinks.push(url);\
    }\
	return JSON.stringify(imgLinks);\
};\
\
var replaceImageSrc = function(info) {\
	var images = imageElements();\
    var screenWidth = parseInt(window.screen.availWidth*0.8);\
	for (var i = 0; i < images.length; i++) {\
        var url = images[i].getAttribute('src');\
		if (url.indexOf(info.URLKey) == 0) {\
			images[i].setAttribute('src', info.LocalPathKey);\
            var width = images[i].getAttribute('width');\
            if (!width) {\
                images[i].style.display = 'none';\
                images[i].onload = function (e) {\
                    var _width = e.target.width;\
                    if (_width > screenWidth) _width = screenWidth;\
                    e.target.style.width = _width + 'px';\
                    e.target.style.display = '';\
                };\
            } else {\
                width = width.replace('px', '');\
                if (width != '') {\
                    width = parseInt(width);\
                    if(width>screenWidth){width = screenWidth;}\
                    images[i].style.width = width+'px';\
                }\
            }\
            images[i].removeAttribute('width');\
            images[i].removeAttribute('height');\
            \
			break;\
		}\
	}\
};\
";

static NSString *mainStyle = @"\
        body {\
            font-family: Helvetica;\
            font-size: 14px;\
            word-wrap: break-word;\
            -webkit-text-size-adjust:none;\
            -webkit-nbsp-mode: space;\
            word-break:break-all;\
        }\
        \
        pre {\
          white-space: pre-wrap;\
        }\
        ";


typedef void (^DownloadCallback)(NSError * error, NSData *data);
#define IMAGE_PREVIEW_HEIGHT 300
#define IMAGE_PREVIEW_WIDTH 500


@interface MCOMessageView () <MCOHTMLRendererIMAPDelegate> {
    NSMutableDictionary *storage;
    NSMutableSet *pending;
    NSMutableArray *ops;
    NSMutableDictionary *callbacks;
}

@property (nonatomic, strong) UIWebView *myWebView;

@end

@implementation MCOMessageView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.myWebView];
        self.webScrollView = self.myWebView.scrollView;

        storage = [[NSMutableDictionary alloc] init];
        ops = [[NSMutableArray alloc] init];
        pending = [[NSMutableSet alloc] init];
        callbacks = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc {
    self.myWebView.delegate = nil;
    self.myWebView = nil;
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (self.delegate && [self.delegate respondsToSelector:@selector(MCOMessageView:webViewShouldStartLoadWithRequest:navigationType:)]) {
        BOOL shouldContrinue = [self.delegate MCOMessageView:self webViewShouldStartLoadWithRequest:request navigationType:navigationType];
        if (shouldContrinue) {
            NSURLRequest *responseRequest = [self webView:webView resource:nil willSendRequest:request redirectResponse:nil fromDataSource:nil];
            if (responseRequest == request) {
                return YES;
            } else {
                [webView loadRequest:responseRequest];
                return NO;
            }
        } else {
            return NO;
        }
    } else {
        NSURLRequest *responseRequest = [self webView:webView resource:nil willSendRequest:request redirectResponse:nil fromDataSource:nil];
        if (responseRequest == request) {
            return YES;
        } else {
            [webView loadRequest:responseRequest];
            return NO;
        }
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(MCOMessageView:webViewDidFinishLoad:)]) {
        [self.delegate MCOMessageView:self webViewDidFinishLoad:webView];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if (self.delegate && [self.delegate respondsToSelector:@selector(MCOMessageView:webViewDidFailLoad:)]) {
        [self.delegate MCOMessageView:self webViewDidFailLoad:webView];
    }
}

#pragma mark - MCOHTMLRendererDelegate

// This delegate method should return YES if it can render a preview of the attachment as an image.
- (BOOL)MCOAbstractMessage:(MCOAbstractMessage *)msg canPreviewPart:(MCOAbstractPart *)part {
    static NSMutableSet *supportedImageMimeTypes = NULL;
    if (supportedImageMimeTypes == NULL) {
        supportedImageMimeTypes = [[NSMutableSet alloc] init];
        [supportedImageMimeTypes addObject:@"image/png"];
        [supportedImageMimeTypes addObject:@"image/gif"];
        [supportedImageMimeTypes addObject:@"image/jpg"];
        [supportedImageMimeTypes addObject:@"image/jpeg"];
    }
    static NSMutableSet *supportedImageExtension = NULL;
    if (supportedImageExtension == NULL) {
        supportedImageExtension = [[NSMutableSet alloc] init];
        [supportedImageExtension addObject:@"png"];
        [supportedImageExtension addObject:@"gif"];
        [supportedImageExtension addObject:@"jpg"];
        [supportedImageExtension addObject:@"jpeg"];
    }
    if (part.isAttachment) {//附件不加载
        return NO;
    }
    if ([supportedImageMimeTypes containsObject:[[part mimeType] lowercaseString]]) {
        return YES;
    }
    
    NSString *ext = nil;
    if ([part filename] != nil) {
        if ([[part filename] pathExtension] != nil) {
            ext = [[[part filename] pathExtension] lowercaseString];
        }
    }
    if (ext != nil) {
        if ([supportedImageExtension containsObject:ext])
            return YES;
    }
    
    // tiff, tif, pdf
    NSString *mimeType = [[part mimeType] lowercaseString];
    if ([mimeType isEqualToString:@"image/tiff"]) {
        return YES;
    } else if ([mimeType isEqualToString:@"image/tif"]) {
        return YES;
    } else if ([mimeType isEqualToString:@"application/pdf"]) {
        return YES;
    }
    
    if ([part filename] != nil) {
        if ([[part filename] pathExtension] != nil) {
            ext = [[[part filename] pathExtension] lowercaseString];
        }
    }
    
    if (ext != nil) {
        if ([ext isEqualToString:@"tiff"]) {
            return YES;
        } else if ([ext isEqualToString:@"tif"]) {
            return YES;
        } else if ([ext isEqualToString:@"pdf"]) {
            return YES;
        }
    }
    
    return NO;
}

- (NSDictionary *)MCOAbstractMessage:(MCOAbstractMessage *)msg templateValuesForHeader:(MCOMessageHeader *)header {
    return nil;
}

- (NSDictionary *)MCOAbstractMessage:(MCOAbstractMessage *)msg templateValuesForPart:(MCOAbstractPart *)part {
    return nil;
}

- (NSString *)MCOAbstractMessage:(MCOAbstractMessage *)msg templateForMainHeader:(MCOMessageHeader *)header {
    //常规消息类型隐藏header
    if (self.messageType == MessageTypeNormal) {
        return @"";
    }
    return nil;
}

- (NSString *)MCOAbstractMessage:(MCOAbstractMessage *)msg templateForImage:(MCOAbstractPart *)header {
    NSString *templateString = @"<img src=\"{{URL}}\"/>";
    templateString = [NSString stringWithFormat:@"<div id=\"{{CONTENTID}}\">%@</div>", templateString];
    return templateString;
}

- (NSString *)MCOAbstractMessage_templateForMessage:(MCOAbstractMessage *)msg {
    return @"<div style=\"padding-bottom: 10px; font-family: Helvetica; font-size: 13px;\">{{HEADER}}</div><div>{{BODY}}</div>";
}

- (NSString *)MCOAbstractMessage:(MCOAbstractMessage *)msg templateForEmbeddedMessage:(MCOAbstractMessagePart *)part {
    return NULL;
}

- (NSString *)MCOAbstractMessage:(MCOAbstractMessage *)msg templateForEmbeddedMessageHeader:(MCOMessageHeader *)header {
    return NULL;
}

/**
 *  附件展示模板
 */
- (NSString *)MCOAbstractMessage:(MCOAbstractMessage *)msg templateForAttachment:(MCOAbstractPart *)part {
    return @"";//不在webview中展示附件
}

/**
 *  附件分隔区域展示模板
 */
- (NSString *)MCOAbstractMessage_templateForAttachmentSeparator:(MCOAbstractMessage *)msg {
    return @"";//隐藏附件分隔区域
}

- (NSString *)MCOAbstractMessage:(MCOAbstractMessage *)msg filterHTMLForPart:(NSString *)html {
    return html;
}

- (NSString *)MCOAbstractMessage:(MCOAbstractMessage *)msg filterHTMLForMessage:(NSString *)html {
    return html;
}

#pragma mark - MCOHTMLRendererIMAPDelegate

- (NSData *)MCOAbstractMessage:(MCOAbstractMessage *)msg dataForIMAPPart:(MCOIMAPPart *)part folder:(NSString *)folder {
    return [self dataForIMAPPart:part folder:folder];
}

- (void)MCOAbstractMessage:(MCOAbstractMessage *)msg prefetchAttachmentIMAPPart:(MCOIMAPPart *)part folder:(NSString *)folder {
    if (!self.prefetchIMAPAttachmentsEnabled)
        return;
    
    NSString *partUniqueID = [part uniqueID];
    [self fetchDataForPartWithUniqueID:partUniqueID downloadedFinished:^(NSError * error, NSData *data) {
        // do nothing
    }];
}

- (void)MCOAbstractMessage:(MCOAbstractMessage *)msg prefetchImageIMAPPart:(MCOIMAPPart *)part folder:(NSString *)folder {
    if (!self.prefetchIMAPImagesEnabled)
        return;
    
    NSString *partUniqueID = [part uniqueID];
    [self fetchDataForPartWithUniqueID:partUniqueID downloadedFinished:^(NSError * error, NSData *data) {
        // do nothing
    }];
}

#pragma mark - public method 

- (BOOL)isLoading {
    return [self.myWebView isLoading];
}

#pragma mark - private method

/**
 *  刷新视图
 */
- (void)reloadMessageView {
    NSString *content;
    if (self.imapMessage == nil) {
        content = nil;
    } else {
//        if ([self.message isKindOfClass:[MCOIMAPMessage class]]) {
            content = [self.imapMessage htmlRenderingWithFolder:self.folder delegate:self];
//        } else if ([self.message isKindOfClass:[MCOMessageBuilder class]]) {
//            content = [(MCOMessageBuilder *)self.message htmlRenderingWithDelegate:self];
//        } else if ([self.message isKindOfClass:[MCOMessageParser class]]) {
//            content = [(MCOMessageParser *)self.message htmlRenderingWithDelegate:self];
//        } else {
//            content = nil;
//            MCAssert(0);
//        }
    }
    
    if (content == nil) {
        [self.myWebView loadHTMLString:@"" baseURL:nil];
        return;
    }

    NSString *scalable = @"";
    switch (self.messageType) {
        case MessageTypeNormal:
        {
            scalable = @"yes";
        }
            break;
            
        case MessageTypeOriginal:
        {
            scalable = @"no";
        }
            break;
        default:
            break;
    }
    NSMutableString *html = [NSMutableString string];
    [html appendFormat:@"<html><head>"
     @"<meta name=\"viewport\"\
     content=\"width=device-width,initial-scale=1,maximum-scale=2.0,minimum-scale=1,user-scalable=%@\"/>\
     <meta name=\"apple-mobile-web-app-capable\" content=\"yes\"/>"
     @"<style>%@</style></head>"
     @"<body>%@<script>%@</script></body><iframe src='x-mailcore-msgviewloaded:' style='width: 0px; height: 0px; border: none;'>"
     @"</iframe></html>", scalable, mainStyle, content, mainJavascript];
    
    self.messageHtmlString = content;
    [self.myWebView loadHTMLString:html baseURL:nil];
}

/**
 *  加载邮件正文图片
 */
- (void)loadImages {
    NSString *result = [self.myWebView stringByEvaluatingJavaScriptFromString:@"findCIDImageURL()"];
    NSData *data = [result dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSArray *imagesURLStrings = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    
    for (NSString *urlString in imagesURLStrings) {
        //取出相应的部件对象
        MCOAbstractPart *part = nil;
        NSURL *url = [NSURL URLWithString:urlString];
        if ([MCOCIDURLProtocol isCID:url]) {
            part = [self partForCIDURL:url];
        } else if ([MCOCIDURLProtocol isXMailcoreImage:url]) {
            NSString *specifier = [url resourceSpecifier];
            NSString *partUniqueID = specifier;
            part = [self partForUniqueID:partUniqueID];
        }
        
        if (part == nil) {
            continue;
        }

        //内部block函数
        void (^replaceImages)(NSError *error, NSData *data) = ^(NSError *error, NSData *data) {
            if (data) {
//                //数据转换
//                NSData *previewData = nil;
//                BOOL isHTMLInlineImage = [MCOCIDURLProtocol isCID:url];
//                if (isHTMLInlineImage) {
//                    previewData = data;
//                } else {
//                    previewData = [self convertToJPEGData:data];
//                }
                
                //获取图片地址
                NSString *path = [[ZGMailModule sharedInstance] cachePathForPart:part withMessageID:self.imapMessage.header.messageID];
                NSURL *cacheURL = [NSURL fileURLWithPath:path];
                NSDictionary *args = @{@"URLKey": urlString, @"LocalPathKey": cacheURL.absoluteString};
                NSString *jsonString = [self jsonStringFromDictionary:args];
                
                NSString *replaceScript = [NSString stringWithFormat:@"replaceImageSrc(%@)", jsonString];
                [self.myWebView stringByEvaluatingJavaScriptFromString:replaceScript];
            } else {
                
            }
        };
        
        NSData *data = [self dataForPart:part];
        if (!part.attachment) {//附件文件不加载，只加载正文里的图片
            if (data == nil) {
                NSString *partUniqueID = [part uniqueID];
                [self fetchDataForPartWithUniqueID:partUniqueID downloadedFinished:^(NSError *error, NSData *data) {
                    replaceImages(error, data);
                }];
            } else {
                replaceImages(nil, data);
            }
        }
    }
}

/**
 *  字典转jsonString
 */
- (NSString *)jsonStringFromDictionary:(NSDictionary *)dictionary {
    NSData *json = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
    return jsonString;
}

/**
 *  根据cidUrl取出相应的部件对象
 */
- (MCOAbstractPart *)partForCIDURL:(NSURL *)url {
    return [self.imapMessage partForContentID:[url resourceSpecifier]];
}

/**
 *  根据uniaueID取出相应的部件对象
 */
- (MCOAbstractPart *)partForUniqueID:(NSString *)partUniqueID {
    return [self.imapMessage partForUniqueID:partUniqueID];
}

- (NSData *)dataForIMAPPart:(MCOIMAPPart *)part folder:(NSString *)folder {
    //获取缓存数据
    NSData *data = [self dataForPart:part];
    if (data == NULL) {//缓存数据为空
        NSString *partUniqueID = [part uniqueID];
        //抓取数据
        [self fetchDataForPartWithUniqueID:partUniqueID downloadedFinished:^(NSError * error, NSData *data) {
            [self reloadMessageView];
        }];
        
        return nil;
    } else {
        return data;
    }
}

- (NSURLRequest *)webView:(UIWebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(id)dataSource {
    if ([[[request URL] scheme] isEqualToString:@"x-mailcore-msgviewloaded"]) {
        [self loadImages];
    }
    
    return request;
}

/**
 *  数据转换
 */
- (NSData *)convertToJPEGData:(NSData *)data {
    CGImageSourceRef imageSource;
    CGImageRef thumbnail;
    NSMutableDictionary *info;
    int width;
    int height;
    float quality;
    
    width = IMAGE_PREVIEW_WIDTH;
    height = IMAGE_PREVIEW_HEIGHT;
    quality = 1.0;
    
    imageSource = CGImageSourceCreateWithData((__bridge CFDataRef) data, NULL);
    if (imageSource == NULL) {
        return nil;
    }
    
    info = [[NSMutableDictionary alloc] init];
    [info setObject:(id) kCFBooleanTrue forKey:(__bridge id) kCGImageSourceCreateThumbnailWithTransform];
    [info setObject:(id) kCFBooleanTrue forKey:(__bridge id) kCGImageSourceCreateThumbnailFromImageAlways];
    [info setObject:(id) [NSNumber numberWithFloat:(float) IMAGE_PREVIEW_WIDTH] forKey:(__bridge id) kCGImageSourceThumbnailMaxPixelSize];
    thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (__bridge CFDictionaryRef) info);
    
    if (thumbnail != nil) {
        CGImageDestinationRef destination;
        NSMutableData *destData = [NSMutableData data];
        destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)destData, (CFStringRef)@"public.jpeg", 1, NULL);
        
        CGImageDestinationAddImage(destination, thumbnail, NULL);
        CGImageDestinationFinalize(destination);
        
        CFRelease(destination);
        CFRelease(thumbnail);
        CFRelease(imageSource);
        return destData;
    } else {
        return nil;
    }
}

/**
 *  根据partUniqueID下载消息附件
 */
- (void)fetchDataForPartWithUniqueID:(NSString *)partUniqueID downloadedFinished:(void (^)(NSError *error, NSData *data))downloadFinished {
    MCOIMAPFetchContentOperation *op = [self fetchIMAPPartWithUniqueID:partUniqueID folder:self.folder];
    [op setProgress:^(unsigned int current, unsigned int maximum) {
        MCLog("progress content: %u/%u", current, maximum);
    }];
    
    if (op != nil) {
        [ops addObject:op];
    }
    
    if (downloadFinished != NULL) {
        NSMutableArray *blocks;
        blocks = [callbacks objectForKey:partUniqueID];
        if (blocks == nil) {
            blocks = [NSMutableArray array];
            [callbacks setObject:blocks forKey:partUniqueID];
        }
        [blocks addObject:[downloadFinished copy]];
    }
}

/**
 *  根据partUniqueID下载消息附件
 */
- (MCOIMAPFetchContentOperation *)fetchIMAPPartWithUniqueID:(NSString *)partUniqueID folder:(NSString *)folder {
    if ([pending containsObject:partUniqueID]) {
        return nil;
    }
    
    MCOIMAPPart *part = (MCOIMAPPart *)[self.imapMessage partForUniqueID:partUniqueID];
    NSAssert(part != nil, @"part != nil");
    [pending addObject:partUniqueID];
    
    MCOIMAPFetchContentOperation *op = [self.session fetchMessageAttachmentOperationWithFolder:folder uid:[self.imapMessage uid] partID:[part partID] encoding:[part encoding]];
    [ops addObject:op];
    [op start:^(NSError *error, NSData *data) {
        if ([error code] != MCOErrorNone) {
            [self callbackForPartUniqueID:partUniqueID error:error data:data];
            return;
        }
        
        NSAssert(data != NULL, @"data != nil");
        [ops removeObject:op];
        [storage setObject:data forKey:partUniqueID];
        [pending removeObject:partUniqueID];
        
        //存储图片
        [[ZGMailModule sharedInstance] cacheData:data forPart:part withMessageID:self.imapMessage.header.messageID];
        [self callbackForPartUniqueID:partUniqueID error:nil data:data];
    }];
    
    return op;
}

/**
 *  回调
 */
- (void)callbackForPartUniqueID:(NSString *)partUniqueID error:(NSError *)error data:(NSData *)data {
    NSArray *blocks;
    blocks = [callbacks objectForKey:partUniqueID];
    for (DownloadCallback block in blocks) {
        dispatch_async(dispatch_get_main_queue(), ^{
            block(error, data);
        });
    }
}

- (NSData *)dataForPart:(MCOAbstractPart *)part {
    NSString *partUniqueID = [part uniqueID];
    //取出本地缓存的数据
    NSString *path = [[ZGMailModule sharedInstance] cachePathForPart:part withMessageID:self.imapMessage.header.messageID];
    if (IsEmptyString(path)) {
        NSData *data = [storage objectForKey:partUniqueID];
        return data;
    } else {
        NSData *cachedData = [NSData dataWithContentsOfFile:path];
        if (!cachedData) {
            NSData *data = [storage objectForKey:partUniqueID];
            return data;
        } else {
            return cachedData;
        }
    }
}

#pragma mark - setter and getter

- (void)setImapMessage:(MCOIMAPMessage *)imapMessage {
    _imapMessage = imapMessage;
    
    [storage removeAllObjects];
    [ops removeAllObjects];
    [pending removeAllObjects];
    [callbacks removeAllObjects];
    
    [self.myWebView stopLoading];
    [self reloadMessageView];
}

- (UIWebView *)myWebView {
    if (_myWebView == nil) {
        _myWebView = [[UIWebView alloc] initWithFrame:[self bounds]];
        [_myWebView setAutoresizingMask:(UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth)];
        _myWebView.scalesPageToFit = YES;
        [_myWebView setDelegate:self];
        _myWebView.backgroundColor = [UIColor whiteColor];
        _myWebView.scrollView.backgroundColor = [UIColor whiteColor];
        _myWebView.opaque = NO;
    }
    
    return _myWebView;
}

@end
