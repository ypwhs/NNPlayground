//
//  AppDelegate.h
//  NNPlayground
//
//  Created by 杨培文 on 16/4/21.
//  Copyright © 2016年 杨培文. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

// 方向策略以 scene 的布局环境为准，供 scene 与控制器共同使用。
+ (UIInterfaceOrientationMask)supportedOrientationsForWindowScene:(UIWindowScene *)scene;


@end

