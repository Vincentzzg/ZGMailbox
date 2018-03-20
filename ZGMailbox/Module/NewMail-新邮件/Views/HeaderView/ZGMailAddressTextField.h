//
//  ZGMailAddressTextField.h
//  ZGMailbox
//
//  Created by zzg on 2017/4/21.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ZGMailAddressTextFieldDelegate;

/**
 *  邮件地址输入textField，可以隐藏光标，但不放弃第一响应
 */
@interface ZGMailAddressTextField : UITextField

@property (nonatomic, weak) id<ZGMailAddressTextFieldDelegate> addressTextFieldDelegate;

/**
 *  展示光标（同时移除遮罩）
 */
- (void)showCursor;

/**
 *  隐藏光标（同时添加遮罩），并没有放弃第一响应
 */
- (void)hideCuresor;

@end

@protocol ZGMailAddressTextFieldDelegate <NSObject>

/**
 *  键盘删除按钮点击
 */
- (void)textFieldDidDelete;

/**
 *  单击手势
 */
- (void)mailAddressTextField:(ZGMailAddressTextField *)textField didRecognizeTapGesture:(UITapGestureRecognizer *)gesture;

@end
