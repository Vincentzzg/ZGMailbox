//
//  ZGMailListBottomToolBar.h
//  ZGMailbox
//
//  Created by zzg on 2018/1/15.
//  Copyright © 2018年 zzg. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ZGMailListBottomToolBarDelegate;

/**
 *  修改标记按钮类型
 */
typedef NS_ENUM(NSInteger, FlaButtonType) {
    FlaButtonType_Delete,//只有删除按钮
    FlaButtonType_FlagAndDelete,//标记+删除
    FlaButtonType_AllFlagSeenAndDelete//全部已读+删除
};

///邮件列表底部工具条
@interface ZGMailListBottomToolBar : UIView

@property (nonatomic, weak) id<ZGMailListBottomToolBarDelegate> toolBarDelegate;

- (void)setDeleteButtonEnable:(BOOL)enable;

- (void)setFlagButtonType:(FlaButtonType)type;

@end

@protocol ZGMailListBottomToolBarDelegate <NSObject>

///全部标记按钮点击
- (void)mailListBottomToolBarAllFlagButtonPressed:(ZGMailListBottomToolBar *)bottomToolBar;

///标记按钮点击
- (void)mailListBottomToolBarFlagButtonPressed:(ZGMailListBottomToolBar *)bottomToolBar;

///删除按钮点击
- (void)mailListBottomToolBarDeleteButtonPressed:(ZGMailListBottomToolBar *)bottomToolBar;

@end
