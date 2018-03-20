//
//  ZGMailContactsDetailViewController.m
//  ZGMailbox
//
//  Created by zzg on 2017/5/2.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import "ZGMailContactsDetailViewController.h"
#import "ZGNewMailViewController.h"//写邮件页面

#import <TTTAttributedLabel/TTTAttributedLabel.h>

//邮件地址
#import <MailCore/MCOAddress.h>

@interface ZGMailContactsDetailViewController () <TTTAttributedLabelDelegate>

@property (nonatomic, strong) UIImageView *headImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) TTTAttributedLabel *mailAddressLabel;
@property (nonatomic, strong) UIImageView *mailAddressImageView;
@property (nonatomic, strong) UIView *separatorView;

@end

@implementation ZGMailContactsDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.headImageView];
    [self.view addSubview:self.nameLabel];
    [self.view addSubview:self.mailAddressLabel];
    [self.view addSubview:self.mailAddressImageView];
    [self.view addSubview:self.separatorView];
    
    [self layoutPageSubviews];
    
    self.nameLabel.text = self.nameStr;
    self.mailAddressLabel.text = self.mailAddressStr;
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - TTTAttributedLabelDelegate

- (void)attributedLabel:(TTTAttributedLabel *)label
   didSelectLinkWithURL:(NSURL *)url {
    NSString *urlString = url.absoluteString;
    if ([urlString hasPrefix:@"mailto"]) {//邮箱地址
        ZGNewMailViewController *newMailVC = [[ZGNewMailViewController alloc] init];
        MCOAddress *address = [[MCOAddress alloc] init];
        NSArray *array = [urlString componentsSeparatedByString:@":"];
        if ([array count] > 1) {
            address.mailbox = [array lastObject];
        }
        newMailVC.recipientAddress = address;
        newMailVC.newMailType = NewMailTypeDefault;
        UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:newMailVC];
        [self presentViewController:navVC animated:YES completion:nil];
    } else {
        
    }
}

#pragma mark - private method 

- (void)layoutPageSubviews {
    [self.headImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.view);
        make.top.mas_equalTo(self.view.mas_top).offset(50);
    }];
    
    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.view);
        make.top.mas_equalTo(self.headImageView.mas_bottom).offset(12);
    }];
    
    [self.mailAddressImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.mailAddressLabel);
        make.leading.mas_equalTo(self.view.mas_leading).offset(20);
    }];
    
    [self.mailAddressLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.view.mas_leading).offset(56);
        make.top.mas_equalTo(self.nameLabel.mas_bottom).offset(60);
        make.trailing.mas_equalTo(self.view.mas_trailing).offset(-15);
    }];
    
    //设置设备上显示1个像素的线
    float floatsortaPixel = 1.0 / [UIScreen mainScreen].scale;
    [self.separatorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.mailAddressLabel.mas_bottom).offset(15);
        make.height.mas_equalTo(floatsortaPixel);
        make.leading.mas_equalTo(self.mailAddressLabel);
        make.trailing.mas_equalTo(self.view);
    }];
}

#pragma mark - setter and getter 

- (UIImageView *)headImageView {
    if (_headImageView == nil) {
        _headImageView = [[UIImageView alloc] init];
        _headImageView.image = [UIImage imageNamed:@"defultHeadBig"];
    }
    
    return _headImageView;
}

- (UILabel *)nameLabel {
    if (_nameLabel == nil) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [UIFont systemFontOfSize:20.0f];
        _nameLabel.textColor = [UIColor colorWithHexString:@"31353B" alpha:1.0f];
    }
    
    return _nameLabel;
}

- (TTTAttributedLabel *)mailAddressLabel {
    if (_mailAddressLabel == nil) {
        _mailAddressLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
        _mailAddressLabel.enabledTextCheckingTypes = NSTextCheckingAllSystemTypes;
        _mailAddressLabel.font = [UIFont systemFontOfSize:18.0f];
        _mailAddressLabel.delegate = self;
        _mailAddressLabel.numberOfLines = 1;
        
        UIColor *color = [UIColor colorWithHexString:@"007AFF" alpha:1.0f];
        NSMutableDictionary *linkAttributes = [NSMutableDictionary dictionary];
        [linkAttributes setValue:[NSNumber numberWithBool:NO] forKey:(NSString *)kCTUnderlineStyleAttributeName];
        [linkAttributes setValue:(__bridge id)color.CGColor forKey:(NSString *)kCTForegroundColorAttributeName];
        _mailAddressLabel.linkAttributes = linkAttributes;
        
        NSMutableDictionary *activeLinkAttributes = [NSMutableDictionary dictionary];
        [activeLinkAttributes setValue:(__bridge id)[UIColor lightGrayColor].CGColor forKey:(NSString *)kTTTBackgroundFillColorAttributeName];
        _mailAddressLabel.activeLinkAttributes = activeLinkAttributes;
    }
    
    return _mailAddressLabel;
}

- (UIImageView *)mailAddressImageView {
    if (_mailAddressImageView == nil) {
        _mailAddressImageView = [[UIImageView alloc] init];
        _mailAddressImageView.image = [UIImage imageNamed:@"contactWriteMail"];
    }
    
    return _mailAddressImageView;
}

- (UIView *)separatorView {
    if (_separatorView == nil) {
        _separatorView = [[UIView alloc] init];
        _separatorView.backgroundColor = [UIColor colorWithHexString:@"c8c8c8" alpha:1.0f];
    }
    
    return _separatorView;
}

@end
