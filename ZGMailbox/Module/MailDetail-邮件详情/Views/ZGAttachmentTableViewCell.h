//
//  ZGAttachmentTableViewCell.h
//  ZGMailbox
//
//  Created by zzg on 2017/4/13.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MCOIMAPPart;

@interface ZGAttachmentTableViewCell : UITableViewCell

@property (nonatomic, strong) MCOIMAPPart *part;

@end
