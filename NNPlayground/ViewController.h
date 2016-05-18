//
//  ViewController.h
//  NNPlayground
//
//  Created by 杨培文 on 16/4/21.
//  Copyright © 2016年 杨培文. All rights reserved.
//

#import <UIKit/UIKit.h>
#ifndef VIEW_CONTROLLER_H
#define VIEW_CONTROLLER_H
#include "NNPlayground-Swift.h"
#include "Network.h"
#import "MBProgressHUD.h"

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet HeatMapView *heatMap;
@property (weak, nonatomic) IBOutlet UILabel *outputLabel;
@property (weak, nonatomic) IBOutlet UILabel *fpsLabel;
@property (nonatomic, strong) SpreadView *spreadView;
@property (weak, nonatomic) IBOutlet LossView *lossView;
@property (weak, nonatomic) IBOutlet RunButton *runButton;
@property (weak, nonatomic) IBOutlet UILabel *speedUpLabel;

@end

#endif