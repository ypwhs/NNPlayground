//
//  NNPlaygroundUITests.m
//  NNPlaygroundUITests
//
//  Created by 杨培文 on 16/4/21.
//  Copyright © 2016年 杨培文. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface NNPlaygroundUITests : XCTestCase

@end

@implementation NNPlaygroundUITests

- (void)setUp {
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    // In UI tests it is usually best to stop immediately when a failure occurs.
    self.continueAfterFailure = NO;
    // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
    [[[XCUIApplication alloc] init] launch];
    
    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // Use recording to get started writing UI tests.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    XCUIApplication *app = [[XCUIApplication alloc] init];
    XCUIElement *button = [[[[app.otherElements containingType:XCUIElementTypeButton identifier:@"Button"] childrenMatchingType:XCUIElementTypeButton] matchingIdentifier:@"Button"] elementBoundByIndex:0];
    [button tap];
    
    XCUIElement *switch2 = app.switches[@"0"];
    [switch2 tap];
    
    for(int i = 0; i < 5; i++)
        [button tap];
    
    XCUIElement *switch3 = app.switches[@"1"];
    [switch3 tap];
}

@end
