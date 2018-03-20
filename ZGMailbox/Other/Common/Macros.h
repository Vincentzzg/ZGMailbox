//
//  Macros.h
//  ZGMailbox
//
//  Created by zzg on 2018/1/16.
//  Copyright © 2018年 zzg. All rights reserved.
//

#ifndef Macros_h
#define Macros_h

/**
 *  判断一个字符串是否是空的
 */
#define IsEmptyString(str) (![str isKindOfClass:[NSString class]] || (!str || [[str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]))

//屏幕分辨率
#define ScreenSize      [[UIScreen mainScreen] currentMode].size
//设备尺寸
#define ScreenHeight    [[UIScreen mainScreen] bounds].size.height
#define ScreenWidth     [[UIScreen mainScreen] bounds].size.width

/**
 *  邮件发件箱列表刷新通知
 *
 */
#define MailSendingFolderReloadNotification             @"MailSendingFolderReloadNotification"

/**
 *  收件箱未读消息个数
 */
#define Mailaddress_KEY                     @"Mailaddress"
#define Password_KEY                        @"Password"
#define InboxUnseenMailNumber_KEY           @"InboxUnseenMailNumber"
#define InboxUidNext_KEY                    @"InboxUidNext"

/***** NSNotificationCenter通知名称 *****/
/**
 *  展示邮件列表页
 */
#define ShowMailListControllerNotification            @"ShowMailListControllerNotification"

#endif /* Macros_h */
