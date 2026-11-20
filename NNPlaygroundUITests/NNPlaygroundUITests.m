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

// 商店路径与既有布局诊断分开；只操作真实控件，不注入模型或改变生产布局。
- (XCUIApplication *)launchStoreLanguage:(NSString *)language {
    self.continueAfterFailure = NO;
    XCUIDevice.sharedDevice.orientation = UIDeviceOrientationLandscapeRight;
    XCUIApplication *app = [[XCUIApplication alloc] init];
    BOOL chinese = [language isEqualToString:@"zh-Hans"];
    app.launchArguments = @[@"-AppleLanguages", chinese ? @"(zh-Hans)" : @"(en)",
                           @"-AppleLocale", chinese ? @"zh_CN" : @"en_US",
                           @"-NNPReviewOrientation", @"4"];
    [app launch];
    XCTAssertTrue([app.buttons[@"reviewRun"] waitForExistenceWithTimeout:15]);
    [NSThread sleepForTimeInterval:1];
    NSString *loss = chinese ? @"训练误差" : @"Train loss";
    XCUIElement *lossLabel = [app.staticTexts matchingPredicate:[NSPredicate predicateWithFormat:@"label CONTAINS[c] %@", loss]].firstMatch;
    XCTAssertTrue(lossLabel.exists);
    NSLog(@"STORE_LANGUAGE %@", language);
    return app;
}

- (void)captureStoreLanguage:(NSString *)language phase:(NSString *)phase {
    [NSThread sleepForTimeInterval:0.8];
    NSLog(@"STORE_CAPTURE_READY %@ %@", language, phase);
    [NSThread sleepForTimeInterval:5];
}

- (void)tapStoreCheck:(NSString *)kind app:(XCUIApplication *)app language:(NSString *)language {
    BOOL chinese = [language isEqualToString:@"zh-Hans"];
    NSString *title = [kind isEqualToString:@"test_data"]
        ? (chinese ? @"显示测试数据" : @"Show Test Data")
        : (chinese ? @"离散化输出" : @"Binary Output");
    XCUIElement *button = [app.buttons matchingPredicate:[NSPredicate predicateWithFormat:@"label CONTAINS %@", title]].firstMatch;
    XCTAssertTrue([button waitForExistenceWithTimeout:5]);
    XCTAssertTrue(button.isHittable);
    XCTAssertGreaterThan(button.frame.size.width, 0);
    XCTAssertGreaterThan(button.frame.size.height, 0);
    NSLog(@"STORE_CONTROL %@ label=%@ frame=%@", kind, button.label, NSStringFromCGRect(button.frame));
    // 自绘 Swift CheckButton 的复选框位于控件左侧；坐标始终基于本次可见元素的真实 frame。
    [[button coordinateWithNormalizedOffset:CGVectorMake(0.06, 0.5)] tap];
}

- (void)closeStoreSettings:(XCUIApplication *)app {
    XCUIElement *circle = app.buttons[@"reviewCircle"];
    XCTAssertTrue(circle.isHittable);
    [[[circle coordinateWithNormalizedOffset:CGVectorMake(1, 0.5)]
      coordinateWithOffset:CGVectorMake(8, 0)] tap];
    XCTAssertTrue(app.buttons[@"reviewRun"].isHittable);
}

- (void)trainStoreApp:(XCUIApplication *)app seconds:(NSTimeInterval)seconds {
    [app.buttons[@"reviewSpeed"] tap];
    [app.buttons[@"reviewRun"] tap];
    [NSThread sleepForTimeInterval:seconds];
    [app.buttons[@"reviewRun"] tap];
    [app.buttons[@"reviewSpeed"] tap];
}

- (void)exerciseStoreLanguage:(NSString *)language {
    XCUIApplication *app = [self launchStoreLanguage:language];
    [self trainStoreApp:app seconds:6];
    [self captureStoreLanguage:language phase:@"01-circle-trained"];

    [app.buttons[@"reviewConfigure"] tap];
    XCTAssertTrue([app.buttons[@"reviewXor"] waitForExistenceWithTimeout:5]);
    [app.buttons[@"reviewXor"] tap];
    [app.buttons[@"reviewAddLayer"] tap];
    [self captureStoreLanguage:language phase:@"02-network-settings"];
    [self closeStoreSettings:app];

    [self trainStoreApp:app seconds:6];
    [self tapStoreCheck:@"test_data" app:app language:language];
    [self captureStoreLanguage:language phase:@"03-xor-test-data"];
    [self tapStoreCheck:@"binary" app:app language:language];
    [self captureStoreLanguage:language phase:@"04-binary-output"];
}

- (void)testStoreChinese { [self exerciseStoreLanguage:@"zh-Hans"]; }
- (void)testStoreEnglish { [self exerciseStoreLanguage:@"en"]; }

- (void)testStoreVideoChinese {
    XCUIApplication *app = [self launchStoreLanguage:@"zh-Hans"];
    NSLog(@"STORE_VIDEO_BEGIN zh-Hans");
    // 主机收到标记后启动明确显示器录屏；此处保留真正应用静止画面作开场。
    [NSThread sleepForTimeInterval:2];
    [app.buttons[@"reviewRun"] tap];
    [NSThread sleepForTimeInterval:4];
    [app.buttons[@"reviewSpeed"] tap];
    [NSThread sleepForTimeInterval:3];
    [app.buttons[@"reviewRun"] tap];
    [self tapStoreCheck:@"test_data" app:app language:@"zh-Hans"];
    [NSThread sleepForTimeInterval:2];
    [self tapStoreCheck:@"binary" app:app language:@"zh-Hans"];
    [NSThread sleepForTimeInterval:2];
    [app.buttons[@"reviewConfigure"] tap];
    XCTAssertTrue([app.buttons[@"reviewXor"] waitForExistenceWithTimeout:5]);
    [NSThread sleepForTimeInterval:2];
    [app.buttons[@"reviewXor"] tap];
    [app.buttons[@"reviewAddLayer"] tap];
    [NSThread sleepForTimeInterval:2];
    [self closeStoreSettings:app];
    [app.buttons[@"reviewRun"] tap];
    [NSThread sleepForTimeInterval:4];
    [app.buttons[@"reviewRun"] tap];
    [NSThread sleepForTimeInterval:2];
    NSLog(@"STORE_VIDEO_END zh-Hans");
    [NSThread sleepForTimeInterval:2];
}

- (void)testStoreIPadSaveSheetCancel {
    XCUIApplication *app = [self launchStoreLanguage:@"zh-Hans"];
    XCUIElement *testData = [app.buttons matchingPredicate:
        [NSPredicate predicateWithFormat:@"label CONTAINS %@", @"显示测试数据"]].firstMatch;
    XCTAssertTrue(testData.isHittable);
    CGRect frame = testData.frame;
    // 热图与该按钮等宽，紧贴其上方8pt；由真实可见frame推导中心，不硬编码iPad尺寸。
    CGFloat offsetY = -(frame.size.width / 2 + frame.size.height / 2 + 8);
    XCUICoordinate *heatCenter = [[testData coordinateWithNormalizedOffset:CGVectorMake(0.5, 0.5)]
                                 coordinateWithOffset:CGVectorMake(0, offsetY)];
    NSLog(@"STORE_IPAD_SAVE_BEGIN testData=%@ offsetY=%.2f", NSStringFromCGRect(frame), offsetY);
    [heatCenter pressForDuration:1.0];
    XCUIElement *cancel = app.buttons[@"取消"];
    BOOL appeared = [cancel waitForExistenceWithTimeout:8];
    NSLog(@"STORE_IPAD_SAVE_RESULT cancel=%d appState=%lu", appeared, (unsigned long)app.state);
    XCTAssertTrue(appeared, @"长按热图应显示保存菜单取消按钮；若应用已退出，检查原始崩溃日志");
    XCTAssertEqual(app.state, XCUIApplicationStateRunningForeground);
    XCTAttachment *sheet = [XCTAttachment attachmentWithScreenshot:XCUIScreen.mainScreen.screenshot];
    sheet.name = @"iPad-save-sheet";
    sheet.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:sheet];
    NSLog(@"STORE_IPAD_SAVE_HIERARCHY %@", app.debugDescription);
    [cancel tap];
    XCTAssertTrue(app.buttons[@"reviewRun"].isHittable);
    NSLog(@"STORE_IPAD_SAVE_CANCELLED");
}
@end
