//
//  ZGMailListBottomToolBar.m
//  ZGMailbox
//
//  Created by zzg on 2018/1/15.
//  Copyright © 2018年 zzg. All rights reserved.
//

#import "ZGMailListBottomToolBar.h"

@interface ZGMailListBottomToolBar ()

@property (nonatomic, strong) UIToolbar *toolbar;

@property (nonatomic, strong) UIBarButtonItem *flexItem;
@property (nonatomic, strong) UIBarButtonItem *allFlagBarButton;//全部已读
@property (nonatomic, strong) UIBarButtonItem *flagBarButton;//标记邮件
@property (nonatomic, strong) UIBarButtonItem *deleteBarButton;//删除

@end

@implementation ZGMailListBottomToolBar

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.toolbar];
        
        [self layoutViewSubviews];
        
        self.toolbar.items = @[self.allFlagBarButton, self.flexItem, self.deleteBarButton];
    }
    
    return self;
}

#pragma mark - public method

- (void)setDeleteButtonEnable:(BOOL)enable {
    self.deleteBarButton.enabled = enable;
}

- (void)setFlagButtonType:(FlaButtonType)type {
    switch (type) {
        case FlaButtonType_Delete:
        {
            self.toolbar.items = @[self.deleteBarButton];
        }
            break;
            
        case FlaButtonType_FlagAndDelete:
        {
            self.toolbar.items = @[self.flagBarButton, self.flexItem, self.deleteBarButton];
        }
            break;
            
        case FlaButtonType_AllFlagSeenAndDelete:
        {
            self.toolbar.items = @[self.allFlagBarButton, self.flexItem, self.deleteBarButton];
        }
            break;
            
        default:
            break;
    }
}

#pragma mark - IBAction

- (IBAction)allFlagButtonPressed:(id)sender {
    if (self.toolBarDelegate && [self.toolBarDelegate respondsToSelector:@selector(mailListBottomToolBarAllFlagButtonPressed:)]) {
        [self.toolBarDelegate mailListBottomToolBarAllFlagButtonPressed:self];
    }
}

- (IBAction)flagButtonPressed:(id)sender {
    if (self.toolBarDelegate && [self.toolBarDelegate respondsToSelector:@selector(mailListBottomToolBarFlagButtonPressed:)]) {
        [self.toolBarDelegate mailListBottomToolBarFlagButtonPressed:self];
    }
}

- (IBAction)deleteButtonPressed:(id)sender {
    if (self.toolBarDelegate && [self.toolBarDelegate respondsToSelector:@selector(mailListBottomToolBarDeleteButtonPressed:)]) {
        [self.toolBarDelegate mailListBottomToolBarDeleteButtonPressed:self];
    }
}

#pragma mark - private method

- (void)layoutViewSubviews {
    [self.toolbar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(self);
        make.center.mas_equalTo(self);
    }];
}

#pragma mark - setter and getter

- (UIToolbar *)toolbar {
    if (_toolbar == nil) {
        _toolbar = [[UIToolbar alloc] init];
        _toolbar.barStyle = UIBarStyleDefault;
    }
    
    return _toolbar;
}

- (UIBarButtonItem *)flexItem {
    if (_flexItem == nil) {
        _flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    }
    
    return _flexItem;
}

- (UIBarButtonItem *)allFlagBarButton {
    if (_allFlagBarButton == nil) {
        _allFlagBarButton = [[UIBarButtonItem alloc] initWithTitle:@"全部已读" style:UIBarButtonItemStylePlain target:self action:@selector(allFlagButtonPressed:)];
    }
    
    return _allFlagBarButton;
}

- (UIBarButtonItem *)flagBarButton {
    if (_flagBarButton == nil) {
        _flagBarButton = [[UIBarButtonItem alloc] initWithTitle:@"标记邮件" style:UIBarButtonItemStylePlain target:self action:@selector(flagButtonPressed:)];
    }
    
    return _flagBarButton;
}

- (UIBarButtonItem *)deleteBarButton {
    if (_deleteBarButton == nil) {
        _deleteBarButton = [[UIBarButtonItem alloc] initWithTitle:@"删除" style:UIBarButtonItemStylePlain target:self action:@selector(deleteButtonPressed:)];
        _deleteBarButton.enabled = NO;
        _deleteBarButton.tintColor = [UIColor redColor];
    }
    
    return _deleteBarButton;
}

@end
