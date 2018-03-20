//
//  AppDelegate.m
//  ZGMailbox
//
//  Created by zzg on 2018/1/24.
//  Copyright © 2018年 zzg. All rights reserved.
//

#import "AppDelegate.h"

#import "LoginViewController.h"
#import "ZGMailListViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    //展示邮件列表页
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showMailListViewController:) name:ShowMailListControllerNotification object:nil];
    
    //设置根控制器
    LoginViewController *vc = [[LoginViewController alloc] init];
    self.window.backgroundColor = [UIColor colorWithHexString:@"F2F2F2" alpha:1.0f];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - private method

/**
 *  展示邮件列表页
 */
- (void)showMailListViewController:(NSNotification *)notify {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.window.rootViewController = nil;
        
        // options是动画选项
        [UIView transitionWithView:[UIApplication sharedApplication].keyWindow duration:0.5f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            BOOL oldState = [UIView areAnimationsEnabled];
            [UIView setAnimationsEnabled:NO];
            
            ZGMailListViewController *mailListVC = [[ZGMailListViewController alloc] init];
            UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:mailListVC];
            self.window.rootViewController = navVC;
            [self.window makeKeyAndVisible];
            
            [UIView setAnimationsEnabled:oldState];
        } completion:^(BOOL finished) {
            
        }];
    });
}

@end
