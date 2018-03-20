//
//  LoginViewController.m
//  ZGMailbox
//
//  Created by zzg on 2018/1/15.
//  Copyright © 2018年 zzg. All rights reserved.
//

#import "LoginViewController.h"

#import "ZGMailModule.h"

@interface LoginViewController ()

@property (nonatomic, strong) UITextField *mailaddressTextField;
@property (nonatomic, strong) UIImageView *separatorImageView1;
@property (nonatomic, strong) UITextField *passwordTextField;
@property (nonatomic, strong) UIImageView *separatorImageView2;
@property (nonatomic, strong) UIButton *loginButton;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithHexString:@"F2F2F2" alpha:1.0f];

    [self.view addSubview:self.mailaddressTextField];
    [self.view addSubview:self.separatorImageView1];
    [self.view addSubview:self.passwordTextField];
    [self.view addSubview:self.separatorImageView2];
    [self.view addSubview:self.loginButton];
    
    [self layoutPageSubviews];
    
    NSString *mailaddress = [[NSUserDefaults standardUserDefaults] stringForKey:Mailaddress_KEY];
    if (!IsEmptyString(mailaddress)) {
        self.mailaddressTextField.text = mailaddress;
    }
    
    NSString *password = [[NSUserDefaults standardUserDefaults] stringForKey:Password_KEY];
    if (!IsEmptyString(password)) {
        self.passwordTextField.text = password;
    }
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBAction

- (IBAction)loginButtonPressed:(id)sender {
    if (IsEmptyString((self.mailaddressTextField.text))) {
        [self showTipText:@"请输入邮箱地址"];
    } else if (IsEmptyString((self.passwordTextField.text))) {
        [self showTipText:@"请输入邮箱登录密码"];
    } else {
        NSArray *components = [self.mailaddressTextField.text componentsSeparatedByString:@"@"];
        if (components.count > 1) {
            [[NSUserDefaults standardUserDefaults] setValue:self.mailaddressTextField.text forKey:Mailaddress_KEY];
            [[NSUserDefaults standardUserDefaults] setValue:self.passwordTextField.text forKey:Password_KEY];

            [[ZGMailModule sharedInstance] setMailAddress:self.mailaddressTextField.text password:self.passwordTextField.text];
            
            //展示邮件列表页
            [[NSNotificationCenter defaultCenter] postNotificationName:ShowMailListControllerNotification object:nil];
        } else {
            [self showTipText:@"请输入正确的邮箱地址"];
        }
    }
}

#pragma mark - private method

- (void)layoutPageSubviews {
    //设置设备上显示1个像素的线
    float floatsortaPixel = 1.0 / [UIScreen mainScreen].scale;
    
    [self.mailaddressTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.view.mas_leading).offset(15);
        make.trailing.mas_equalTo(self.view.mas_trailing).offset(-15);
        make.height.mas_equalTo(50);
        make.bottom.mas_equalTo(self.separatorImageView1.mas_top);
    }];
    
    [self.separatorImageView1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.view.mas_leading).offset(15);
        make.trailing.mas_equalTo(self.view);
        make.height.mas_equalTo(floatsortaPixel);
        make.bottom.mas_equalTo(self.passwordTextField.mas_top);
    }];
    
    [self.passwordTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.view.mas_leading).offset(15);
        make.trailing.mas_equalTo(self.view.mas_trailing).offset(-15);
        make.height.mas_equalTo(50);
        make.bottom.mas_equalTo(self.separatorImageView2.mas_top);
    }];
    
    [self.separatorImageView2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.view.mas_leading).offset(15);
        make.trailing.mas_equalTo(self.view);
        make.height.mas_equalTo(floatsortaPixel);
        make.bottom.mas_equalTo(self.loginButton.mas_top).offset(-30);
    }];
    
    [self.loginButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.view.mas_leading).offset(15);
        make.trailing.mas_equalTo(self.view.mas_trailing).offset(-15);
        make.height.mas_equalTo(50);
        make.top.mas_equalTo(self.view.mas_centerY);
    }];
}

#pragma mark - setter and getter

- (UITextField *)mailaddressTextField {
    if (_mailaddressTextField == nil) {
        _mailaddressTextField = [[UITextField alloc] init];
        _mailaddressTextField.placeholder = @"QQ邮箱";
    }
    
    return _mailaddressTextField;
}

- (UIImageView *)separatorImageView1 {
    if (_separatorImageView1 == nil) {
        _separatorImageView1 = [[UIImageView alloc] init];
        _separatorImageView1.backgroundColor = [UIColor lightGrayColor];
    }
    
    return _separatorImageView1;
}

- (UITextField *)passwordTextField {
    if (_passwordTextField == nil) {
        _passwordTextField = [[UITextField alloc] init];
        _passwordTextField.secureTextEntry = YES;
        _passwordTextField.placeholder = @"密码";
    }
    
    return _passwordTextField;
}

- (UIImageView *)separatorImageView2 {
    if (_separatorImageView2 == nil) {
        _separatorImageView2 = [[UIImageView alloc] init];
        _separatorImageView2.backgroundColor = [UIColor lightGrayColor];
    }
    
    return _separatorImageView2;
}

- (UIButton *)loginButton {
    if (_loginButton == nil) {
        _loginButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_loginButton setTitle:@"登录" forState:UIControlStateNormal];
        [_loginButton addTarget:self action:@selector(loginButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [_loginButton setBackgroundColor:[UIColor colorWithHexString:@"3B99FC" alpha:1.0f]];
    }
    
    return _loginButton;
}

@end
