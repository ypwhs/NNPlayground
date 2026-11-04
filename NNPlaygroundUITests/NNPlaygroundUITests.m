#import <XCTest/XCTest.h>

@interface NNPlaygroundUITests : XCTestCase
@end

@implementation NNPlaygroundUITests

- (void)capturePhase:(NSString *)phase {
    // 给 Debug 诊断快照留出刷新时间；宿主脚本在标记后捕获带硬件遮罩的屏幕。
    [NSThread sleepForTimeInterval:0.6];
    NSLog(@"LAYOUT_CAPTURE_READY %@", phase);
    [NSThread sleepForTimeInterval:6];
}

- (void)exerciseOrientation:(NSInteger)orientation name:(NSString *)name {
    self.continueAfterFailure = NO;
    // 界面左右横屏与设备左右朝向相反；同步物理方向，避免 iPad 截图内容倒置。
    UIDeviceOrientation deviceOrientation = UIDeviceOrientationPortrait;
    if (orientation == UIInterfaceOrientationLandscapeLeft) deviceOrientation = UIDeviceOrientationLandscapeRight;
    if (orientation == UIInterfaceOrientationLandscapeRight) deviceOrientation = UIDeviceOrientationLandscapeLeft;
    XCUIDevice.sharedDevice.orientation = deviceOrientation;
    XCUIApplication *app = [[XCUIApplication alloc] init];
    app.launchArguments = @[@"-AppleLanguages", @"(zh-Hans)", @"-AppleLocale", @"zh_CN",
                           @"-NNPReviewOrientation", [@(orientation) stringValue]];
    [app launch];
    XCUIElement *run = app.buttons[@"reviewRun"];
    XCTAssertTrue([run waitForExistenceWithTimeout:10]);

    [app.buttons[@"reviewStep"] tap];
    [app.buttons[@"reviewSpeed"] tap];
    XCTAssertTrue([app.staticTexts[@"reviewSpeedLabel"] waitForExistenceWithTimeout:3]);
    [app.buttons[@"reviewSpeed"] tap];
    XCTAssertFalse(app.staticTexts[@"reviewSpeedLabel"].isHittable);
    [run tap];
    [NSThread sleepForTimeInterval:3];
    [run tap];
    [self capturePhase:[name stringByAppendingString:@"-trained"]];

    [app.buttons[@"reviewConfigure"] tap];
    XCTAssertTrue([app.buttons[@"reviewXor"] waitForExistenceWithTimeout:5]);
    [app.buttons[@"reviewXor"] tap];
    [app.buttons[@"reviewCircle"] tap];
    [app.buttons[@"reviewAddLayer"] tap];
    [app.buttons[@"reviewSubLayer"] tap];
    [self capturePhase:[name stringByAppendingString:@"-settings"]];

    // 以已显示的控件为坐标基准，避免折叠设备 app.frame 仍是旧屏幕范围。
    // 点击数据按钮右侧空白，走原有关闭手势，不新增测试专用关闭操作。
    XCUICoordinate *blank = [[app.buttons[@"reviewCircle"] coordinateWithNormalizedOffset:CGVectorMake(1, 0.5)]
                             coordinateWithOffset:CGVectorMake(8, 0)];
    [blank tap];
    XCTAssertTrue([run waitForExistenceWithTimeout:5]);
    [app.buttons[@"reviewReset"] tap];
    [self capturePhase:[name stringByAppendingString:@"-reset"]];
}

- (void)testLeft { [self exerciseOrientation:UIInterfaceOrientationLandscapeLeft name:@"left"]; }
- (void)testRight { [self exerciseOrientation:UIInterfaceOrientationLandscapeRight name:@"right"]; }
- (void)testPortrait { [self exerciseOrientation:UIInterfaceOrientationPortrait name:@"portrait"]; }
@end
