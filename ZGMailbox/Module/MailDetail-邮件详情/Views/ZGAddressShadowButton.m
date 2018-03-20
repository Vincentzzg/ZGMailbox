//
//  ZGAddressShadowButton.m
//  ZGMailbox
//
//  Created by zzg on 2017/4/6.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import "ZGAddressShadowButton.h"

@interface ZGAddressShadowButton ()

@end

@implementation ZGAddressShadowButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.titleLabel.numberOfLines = 2;
        self.titleLabel.textAlignment = NSTextAlignmentLeft;
        self.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;

        UIImage *image = [UIImage imageNamed:@"mail_roundcornerBgHighlight"];
        image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)];
        [self setBackgroundImage:image forState:UIControlStateHighlighted];
        [self setBackgroundImage:image forState:UIControlStateSelected];

        UIImage *normalImage = [UIImage imageNamed:@"mail_roundcornerBgNormal"];
        normalImage = [normalImage resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)];
        [self setBackgroundImage:normalImage forState:UIControlStateNormal];
        
        self.contentEdgeInsets = UIEdgeInsetsMake(4, 4, 4, 4);
    }
    
    return self;
}

- (NSString *)shortName {
    if (IsEmptyString(self.mailbox)) {
        NSString *attTitle = [[self currentAttributedTitle] string];
        if (IsEmptyString(attTitle)) {//发件人只有发件人名字的情况
            NSString *title = [self currentTitle];
            
            return title;
        } else {//两行地址的情况
            return [[attTitle componentsSeparatedByString:@"\n"] firstObject];
        }
    } else {
        NSArray *array = [self.mailbox componentsSeparatedByString:@"@"];
        
        return [array firstObject];
    }
}

- (void)pressesBegan:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event {
    self.highlighted = YES;
}

@end
