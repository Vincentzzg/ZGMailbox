//
//  ZGMessageHeaderDetailAddressTableViewCell.h
//  ZGMailbox
//
//  Created by zzg on 2017/4/10.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZGAddressShadowButton;
@class MCOAddress;
@protocol ZGMessageHeaderDetailAddressTableViewCellDelegate;

@interface ZGMessageHeaderDetailAddressTableViewCell : UITableViewCell

@property (nonatomic, weak) id<ZGMessageHeaderDetailAddressTableViewCellDelegate> delegate;
@property (nonatomic, strong) MCOAddress *address;

@property (nonatomic, strong) UILabel *titleLabel;

@end

@protocol ZGMessageHeaderDetailAddressTableViewCellDelegate <NSObject>

- (void)headerDetailAddressCell:(ZGMessageHeaderDetailAddressTableViewCell *)tableViewCell addressButtonPressed:(ZGAddressShadowButton *)button;

@end
