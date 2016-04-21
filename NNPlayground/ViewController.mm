//
//  ViewController.m
//  NNPlayground
//
//  Created by 杨培文 on 16/4/21.
//  Copyright © 2016年 杨培文. All rights reserved.
//

#import "ViewController.h"
#include "Network.h"
using namespace std;

@interface ViewController ()

@end

@implementation ViewController

- (void)xiancheng:(dispatch_block_t)code{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), code);
}

- (void)ui:(dispatch_block_t)code{
    dispatch_async(dispatch_get_main_queue(), code);
}

int networkShape[] = {2, 4, 1};
Network network = Network(networkShape, 3, aTanh, rNone);;

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

double inputs[] = {1, 1};
double * x1 = new double[150];
double * x2 = new double[150];
double * y = new double[150];


- (IBAction)generateInputs:(id)sender {
    for(int i = 0; i < 150; i++){
        x1[i] = drand()*1.8;
        x2[i] = drand()*1.8;
        y[i] = x1[i]*x2[i];
    }
    [_heatMap setData:x1 x2:x2 y:y size:150];
}

int32_t * heatdata = new int32_t[100*100];
#define NUM_SHADES 256
int32_t * color = new int32_t[NUM_SHADES];
- (IBAction)updateHeatmap:(id)sender {
    for(int i = 0; i < 100; i++){
        for(int j = 0; j < 100; j++){
            heatdata[i*100+j] = 0x000000FF;
        }
    }
    [_heatMap setBackground:heatdata];
    
}
bool always = false;
NSString * toShow;

- (void)train{
    while(always){
        double output = network.forwardProp(inputs, 2);
        network.backProp(1);
        network.updateWeights(0.03, 0);
        toShow = [NSString stringWithFormat:@"%f",1-output];
        [self ui:^{
            _outputLabel.text = toShow;
        }];
    }
}

- (IBAction)switch:(UISwitch *)sender {
    always = sender.on;
    [self xiancheng:^{[self train];}];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
