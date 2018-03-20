//
//  ZGMailAttachmetPhoto.m
//  ZGMailbox
//
//  Created by zzg on 2017/5/22.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import "ZGMailAttachmetPhoto.h"
#import "MWPhotoBrowser.h"
#import <SDWebImage/SDWebImageManager.h>
#import <SDWebImage/SDWebImageOperation.h>
#import <SDWebImage/UIImage+ForceDecode.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import <MailCore/MCOIMAPPart.h>
#import <MailCore/MailCore.h>

//邮件模块管理工具类
#import "ZGMailModule.h"

@interface ZGMailAttachmetPhoto () {
    BOOL _loadingInProgress;
    MCOIMAPFetchContentOperation *operation;
}

@end

@implementation ZGMailAttachmetPhoto

@synthesize underlyingImage = _underlyingImage; // synth property from protocol

+ (ZGMailAttachmetPhoto *)photoWithImagePart:(MCOIMAPPart *)imagePart folder:(NSString *)folder message:(MCOIMAPMessage *)message {
    return [[ZGMailAttachmetPhoto alloc] initWithImagePart:imagePart folder:folder message:message];
}

#pragma mark - Init

- (id)initWithImagePart:(MCOIMAPPart *)imagePart folder:(NSString *)folder message:(MCOIMAPMessage *)message {
    if ((self = [super init])) {
        _imagePart = imagePart;
        _folder = folder;
        _message = message;
        
        NSString *path = [[ZGMailModule sharedInstance] cachePathForPart:imagePart withMessageID:self.message.header.messageID];
        NSData *data = [NSData dataWithContentsOfFile:path];
        if (data) {//@"text/plain"，txt文件
            UIImage *image = [UIImage imageWithContentsOfFile:path];
            _image = image;
        }
    }
    
    return self;
}

#pragma mark - MWPhoto Protocol Methods

- (UIImage *)underlyingImage {
    return _underlyingImage;
}

- (void)loadUnderlyingImageAndNotify {
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    if (_loadingInProgress) return;
    _loadingInProgress = YES;
    @try {
        if (self.underlyingImage) {
            [self imageLoadingComplete];
        } else {
            [self performLoadUnderlyingImageAndNotify];
        }
    }
    @catch (NSException *exception) {
        self.underlyingImage = nil;
        _loadingInProgress = NO;
        [self imageLoadingComplete];
    }
    @finally {
    }
}

// Set the underlyingImage and call decompressImageAndFinishLoading on the main thread when complete.
// On error, set underlyingImage to nil and then call decompressImageAndFinishLoading on the main thread.
- (void)performLoadUnderlyingImageAndNotify {
    // Get underlying image
    if (_image) {
        
        // We have UIImage so decompress
        self.underlyingImage = _image;
        [self decompressImageAndFinishLoading];
        
    } else if (_imagePart) {
        
            __weak typeof(self) weakSelf = self;
            operation = [[ZGMailModule sharedInstance].imapSession fetchMessageAttachmentOperationWithFolder:self.folder uid:self.message.uid partID:[self.imagePart partID] encoding:[self.imagePart encoding]];
            [operation setProgress:^(unsigned int current, unsigned int maximum) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (maximum != 0) {
                        float progress = (float)current / maximum;
                        NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                              [NSNumber numberWithFloat:progress], @"progress",
                                              strongSelf, @"photo", nil];
                        [[NSNotificationCenter defaultCenter] postNotificationName:MWPHOTO_PROGRESS_NOTIFICATION object:dict];
                    }
                });
            }];
            
            [operation start:^(NSError *error, NSData *data) {
                __strong typeof(weakSelf) strongSelf = weakSelf;

                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([error code] != MCOErrorNone) {
                        return;
                    }
                    NSAssert(data != NULL, @"data != nil");
                    //保存数据到本地
                    [[ZGMailModule sharedInstance] cacheData:data forPart:strongSelf.imagePart withMessageID:strongSelf.message.header.messageID];
                    
                    NSString *path = [[ZGMailModule sharedInstance] cachePathForPart:strongSelf.imagePart withMessageID:strongSelf.message.header.messageID];
                    if (!IsEmptyString(path)) {//地址为空不加载
                        UIImage *image = [UIImage imageWithContentsOfFile:path];
                        strongSelf.underlyingImage = image;
                        [strongSelf decompressImageAndFinishLoading];
                    }
                });
            }];
    } else {
        
        // Failed - no source
        @throw [NSException exceptionWithName:@"" reason:nil userInfo:nil];
        
    }
}

// Release if we can get it again from path or url
- (void)unloadUnderlyingImage {
    _loadingInProgress = NO;
    if (self.underlyingImage) {
        self.underlyingImage = nil;
    }
}

- (void)decompressImageAndFinishLoading {
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    if (self.underlyingImage) {
        // Decode image async to avoid lagging when UIKit lazy loads
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self.underlyingImage = [UIImage decodedImageWithImage:self.underlyingImage];
            dispatch_async(dispatch_get_main_queue(), ^{
                // Finish on main thread
                [self imageLoadingComplete];
            });
        });
    } else {
        // Failed
        [self imageLoadingComplete];
    }
}

- (void)imageLoadingComplete {
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    // Complete so notify
    _loadingInProgress = NO;
    // Notify on next run loop
    [self performSelector:@selector(postCompleteNotification) withObject:nil afterDelay:0];
}

- (void)postCompleteNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:MWPHOTO_LOADING_DID_END_NOTIFICATION
                                                        object:self];
}

- (void)cancelAnyLoading {
    if (operation) {
        [operation cancel];
        _loadingInProgress = NO;
    }
}

@end
