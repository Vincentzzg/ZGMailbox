//
//  ZGMailListTitleView.h
//  ZGMailbox
//
//  Created by zzg on 2017/3/23.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ZGMailListTitleViewDelegate;

@interface ZGMailListTitleView : UIView

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, weak) id<ZGMailListTitleViewDelegate> delegate;
@property (nonatomic, assign) BOOL isArrowDown;

@end

@protocol ZGMailListTitleViewDelegate <NSObject>

- (void)mailListTitleViewPrssed:(ZGMailListTitleView *)titleView;

@end
