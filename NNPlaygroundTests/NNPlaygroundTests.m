//
//  NNPlaygroundTests.m
//  NNPlaygroundTests
//
//  Created by 杨培文 on 16/4/21.
//  Copyright © 2016年 杨培文. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>

// 通过 Objective-C 接口测试 Swift 视图的纯几何计算，不依赖模拟器机型。
@protocol LossPlotGeometry <NSObject>
+ (CGRect)plotBoundsForBounds:(CGRect)bounds
              safeAreaInsets:(UIEdgeInsets)safeAreaInsets
        windowSafeAreaInsets:(UIEdgeInsets)windowSafeAreaInsets;
@end

@interface NNPlaygroundTests : XCTestCase

@end

@implementation NNPlaygroundTests

- (UIViewController *)layoutController {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) continue;
        for (UIWindow *window in ((UIWindowScene *)scene).windows) {
            if (window.isKeyWindow) return window.rootViewController;
        }
    }
    XCTFail(@"未找到测试宿主窗口");
    return nil;
}

- (void)assertSafeHorizontalLayout:(UIViewController *)controller {
    [controller.view layoutIfNeeded];
    UIView *heatMap = [controller valueForKey:@"heatMap"];
    UIView *stack = [controller valueForKey:@"controlStack"];
    XCTAssertNotNil(heatMap);
    XCTAssertNotNil(stack);
    UIEdgeInsets safe = controller.view.safeAreaInsets;
    XCTAssertEqualWithAccuracy(CGRectGetMaxX(heatMap.frame),
                              controller.view.bounds.size.width - MAX(28, safe.right), 0.5);
    XCTAssertEqualWithAccuracy(stack.frame.origin.x, MAX(24, safe.left), 0.5);
    NSNumber *nodeX = [controller valueForKey:@"nodeStartX"];
    XCTAssertEqualWithAccuracy(nodeX.doubleValue, MAX(25, safe.left), 0.5);
}

- (void)testHorizontalContentRespectsActualSafeArea {
    [self assertSafeHorizontalLayout:[self layoutController]];
}

- (void)testSameSizeSafeAreaChangeRelayoutsContent {
    UIViewController *controller = [self layoutController];
    UIEdgeInsets original = controller.additionalSafeAreaInsets;
    CGSize size = controller.view.bounds.size;
    @try {
        controller.additionalSafeAreaInsets = UIEdgeInsetsMake(0, 90, 0, 120);
        [self assertSafeHorizontalLayout:controller];
        XCTAssertTrue(CGSizeEqualToSize(size, controller.view.bounds.size));
        controller.additionalSafeAreaInsets = UIEdgeInsetsMake(0, 120, 0, 90);
        [self assertSafeHorizontalLayout:controller];
        XCTAssertTrue(CGSizeEqualToSize(size, controller.view.bounds.size));
    } @finally {
        controller.additionalSafeAreaInsets = original;
        [controller.view layoutIfNeeded];
    }
    [self assertSafeHorizontalLayout:controller];
}

- (CGRect)plotForWindow:(UIEdgeInsets)windowInsets localRight:(CGFloat)localRight {
    Class<LossPlotGeometry> lossView = (Class<LossPlotGeometry>)NSClassFromString(@"NNPlayground.LossView");
    XCTAssertNotNil(lossView);
    return [lossView plotBoundsForBounds:CGRectMake(0, 0, 160, 80)
                         safeAreaInsets:UIEdgeInsetsMake(0, 0, 0, localRight)
                   windowSafeAreaInsets:windowInsets];
}

- (void)testLossPlotAvoidsRightCamera {
    CGRect plot = [self plotForWindow:UIEdgeInsetsMake(0, 0, 34, 84) localRight:56];
    XCTAssertTrue(CGRectEqualToRect(plot, CGRectMake(0, 0, 104, 80)));
}

- (void)testLossPlotKeepsOppositeOrientation {
    for (NSNumber *localRight in @[@0, @20]) {
        CGRect plot = [self plotForWindow:UIEdgeInsetsMake(0, 84, 34, 0) localRight:localRight.doubleValue];
        XCTAssertTrue(CGRectEqualToRect(plot, CGRectMake(0, 0, 160, 80)));
    }
}

- (void)testLossPlotKeepsSymmetricPhoneInsets {
    for (NSNumber *inset in @[@44, @59, @62]) {
        CGFloat side = inset.doubleValue;
        CGRect plot = [self plotForWindow:UIEdgeInsetsMake(0, side, 21, side) localRight:side - 28];
        XCTAssertTrue(CGRectEqualToRect(plot, CGRectMake(0, 0, 160, 80)));
    }
}

- (void)testLossPlotKeepsUnobstructedScreens {
    for (NSNumber *bottom in @[@0, @20, @34]) {
        CGRect plot = [self plotForWindow:UIEdgeInsetsMake(0, 0, bottom.doubleValue, 0) localRight:0];
        XCTAssertTrue(CGRectEqualToRect(plot, CGRectMake(0, 0, 160, 80)));
    }
    CGRect nonoverlapping = [self plotForWindow:UIEdgeInsetsMake(0, 0, 34, 84) localRight:0];
    XCTAssertTrue(CGRectEqualToRect(nonoverlapping, CGRectMake(0, 0, 160, 80)));
}

- (void)testLossPlotClampsFullyObstructedWidth {
    CGRect plot = [self plotForWindow:UIEdgeInsetsMake(0, 0, 34, 200) localRight:200];
    XCTAssertEqual(plot.size.width, 0);
    XCTAssertEqual(plot.size.height, 80);
}

- (void)testLossPlotRestoresWidthAfterRotation {
    CGRect folded = [self plotForWindow:UIEdgeInsetsMake(0, 0, 34, 84) localRight:56];
    CGRect rotated = [self plotForWindow:UIEdgeInsetsMake(0, 84, 34, 0) localRight:0];
    CGRect unfolded = [self plotForWindow:UIEdgeInsetsZero localRight:0];
    XCTAssertEqual(folded.size.width, 104);
    XCTAssertEqual(rotated.size.width, 160);
    XCTAssertEqual(unfolded.size.width, 160);
}

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
