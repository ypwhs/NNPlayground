//
//  AppDelegate.m
//  NNPlayground
//
//  Created by 杨培文 on 16/4/21.
//  Copyright © 2016年 杨培文. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@interface SceneDelegate : UIResponder <UIWindowSceneDelegate>
@property (strong, nonatomic) UIWindow *window;
@property (nonatomic) UIInterfaceOrientationMask lastSupportedOrientations;
@property (nonatomic) UIInterfaceOrientationMask lastRequestedOrientations;
@property (nonatomic) UIInterfaceOrientation lastRequestedFromOrientation;
@property (nonatomic) BOOL orientationUpdateScheduled;
@end

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) {
        return;
    }
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *rootViewController = [storyboard instantiateInitialViewController];
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.rootViewController = rootViewController;
    [self.window makeKeyAndVisible];

    UIWindowScene *windowScene = (UIWindowScene *)scene;
    [windowScene registerForTraitChanges:@[
        UITraitUserInterfaceIdiom.class,
        UITraitHorizontalSizeClass.class,
        UITraitVerticalSizeClass.class,
    ] withTarget:self action:@selector(windowSceneTraitsDidChange:)];
    [self scheduleOrientationUpdateForWindowScene:windowScene];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientationsForWindowScene:(UIWindowScene *)windowScene {
    return [AppDelegate supportedOrientationsForWindowScene:windowScene];
}

- (void)windowSceneTraitsDidChange:(UIWindowScene *)windowScene {
    [self scheduleOrientationUpdateForWindowScene:windowScene];
}

- (void)scheduleOrientationUpdateForWindowScene:(UIWindowScene *)windowScene {
    if (self.orientationUpdateScheduled) return;
    self.orientationUpdateScheduled = YES;
    __weak typeof(self) weakSelf = self;
    __weak UIWindowScene *weakScene = windowScene;
    // 等待同一轮 traits 传播，避免 scene 与根控制器暂时使用不同方向集合。
    dispatch_async(dispatch_get_main_queue(), ^{
        typeof(self) strongSelf = weakSelf;
        UIWindowScene *scene = weakScene;
        if (!strongSelf) return;
        strongSelf.orientationUpdateScheduled = NO;
        if (!scene || strongSelf.window.windowScene != scene) return;
        [strongSelf updateOrientationsForWindowScene:scene];
    });
}

- (void)updateOrientationsForWindowScene:(UIWindowScene *)windowScene {
    UIInterfaceOrientationMask supported = [AppDelegate supportedOrientationsForWindowScene:windowScene];
    if (self.lastSupportedOrientations != supported) {
        self.lastSupportedOrientations = supported;
        self.lastRequestedOrientations = 0;
        UIViewController *controller = self.window.rootViewController;
        while (controller) {
            [controller setNeedsUpdateOfSupportedInterfaceOrientations];
            controller = controller.presentedViewController;
        }
    }

    UIInterfaceOrientation orientation = windowScene.effectiveGeometry.interfaceOrientation;
    if (orientation == UIInterfaceOrientationUnknown) return;
    if ((supported & (1UL << orientation)) != 0) {
        self.lastRequestedOrientations = 0;
        return;
    }
    if (windowScene.activationState != UISceneActivationStateForegroundActive) return;
    if (self.lastRequestedOrientations == supported &&
        self.lastRequestedFromOrientation == orientation) return;

    // 只修正不再支持的方向；合法竖屏或横屏不主动改变，失败也不循环重试。
    self.lastRequestedOrientations = supported;
    self.lastRequestedFromOrientation = orientation;
    UIWindowSceneGeometryPreferencesIOS *preferences =
        [[UIWindowSceneGeometryPreferencesIOS alloc] initWithInterfaceOrientations:supported];
    [windowScene requestGeometryUpdateWithPreferences:preferences errorHandler:^(NSError *error) {
        NSLog(@"requestGeometryUpdate failed: %@", error);
    }];
}

- (void)sceneDidBecomeActive:(UIScene *)scene {
    if (![scene isKindOfClass:[UIWindowScene class]]) return;
    // 新的激活周期允许重试此前在后台或切换中未能完成的方向请求。
    self.lastRequestedOrientations = 0;
    [self scheduleOrientationUpdateForWindowScene:(UIWindowScene *)scene];
}

- (void)windowScene:(UIWindowScene *)windowScene didUpdateEffectiveGeometry:(UIWindowSceneGeometry *)previousEffectiveGeometry {
    [self scheduleOrientationUpdateForWindowScene:windowScene];
}

- (void)windowScene:(UIWindowScene *)windowScene didUpdateCoordinateSpace:(id<UICoordinateSpace>)previousCoordinateSpace interfaceOrientation:(UIInterfaceOrientation)previousInterfaceOrientation traitCollection:(UITraitCollection *)previousTraitCollection {
    if (@available(iOS 26.0, *)) return;
    [self scheduleOrientationUpdateForWindowScene:windowScene];
}

@end

@implementation AppDelegate

+ (UIInterfaceOrientationMask)supportedOrientationsForWindowScene:(UIWindowScene *)scene {
    if (@available(iOS 27.0, *)) {
        UITraitCollection *traits = scene.traitCollection;
        if (traits.userInterfaceIdiom == UIUserInterfaceIdiomPhone &&
            traits.horizontalSizeClass == UIUserInterfaceSizeClassRegular &&
            traits.verticalSizeClass == UIUserInterfaceSizeClassRegular) {
            return UIInterfaceOrientationMaskLandscape | UIInterfaceOrientationMaskPortrait;
        }
    }
    return UIInterfaceOrientationMaskLandscape;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
