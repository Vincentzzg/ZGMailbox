//
//  ZGRoundSearchBar.m
//  ZGMailbox
//
//  Created by zzg on 2017/6/6.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import "ZGRoundSearchBar.h"

@implementation ZGRoundSearchBar

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundImage = [UIImage new];
        self.searchTextPositionAdjustment = UIOffsetMake(4, 0);
        
        UIImage *image = [UIImage imageNamed:@"searchBarBg"];
        image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(6, 6, 6, 6) resizingMode:UIImageResizingModeStretch];
        [self setSearchFieldBackgroundImage:image forState:UIControlStateNormal];
        
        UITextField *searchField = [self valueForKey:@"searchField"];
        if (searchField) {
            searchField.tintColor = [UIColor colorWithHexString:@"C4261D" alpha:1.0f];
            searchField.clearButtonMode = UITextFieldViewModeNever;
            searchField.font = [UIFont systemFontOfSize:15];
        }
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
