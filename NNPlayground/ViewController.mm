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

//*************************** Network ***************************
int networkShape[] = {2, 4, 1};
Network network = Network(networkShape, 3, aTanh, rNone);

//**************************** Color ****************************
#define NUM_SHADES 256
unsigned int * positiveColor = new unsigned int[NUM_SHADES];
unsigned int * negativeColor = new unsigned int[NUM_SHADES];
void initColor(){
    for(int i = 0; i < NUM_SHADES; i++){
        double factor = (double)i/NUM_SHADES;
        unsigned char r1 = 234 + ( 97 - 234)*factor;
        unsigned char g1 = 234 + (167 - 234)*factor;
        unsigned char b1 = 234 + (213 - 234)*factor;
        
        unsigned char r2 = 234 + (246 - 234)*factor;
        unsigned char g2 = 234 + (184 - 234)*factor;
        unsigned char b2 = 234 + (113 - 234)*factor;
        negativeColor[i] = (b1<<24) + (g1<<16) + (r1<<8) + 0xFF;
        positiveColor[i] = (b2<<24) + (g2<<16) + (r2<<8) + 0xFF;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    initColor();
}

int DATA_NUM = 150;
double inputs[] = {1, 1};
double * x1 = new double[DATA_NUM];
double * x2 = new double[DATA_NUM];
double * y = new double[DATA_NUM];


- (IBAction)generateInputs:(id)sender {
    network = Network(networkShape, 3, aTanh, rNone);
    for(int i = 0; i < DATA_NUM; i++){
        x1[i] = drand()*1.8;
        x2[i] = drand()*1.8;
        y[i] = x1[i]*x2[i];
    }
    [_heatMap setData:x1 x2:x2 y:y size:DATA_NUM];
    getHeatData();
    [_heatMap setBackground:heatdata];
}

unsigned int getColor(double x){
    if(x > 0){
        if(x > 1)x = 1;
        int index = x*(NUM_SHADES-1);
        return positiveColor[index];
    }else{
        x = -x;
        if(x > 1)x = 1;
        int index = x*(NUM_SHADES-1);
        return negativeColor[index];
    }
}

unsigned int * heatdata = new unsigned int[100*100];
void getHeatData(){
    for(int i = 0; i < 100; i++){
        for(int j = 0; j < 100; j++){
            inputs[0] = (j - 50.0)/50;
            inputs[1] = (i - 50.0)/50;
            double output = network.forwardProp(inputs, 2);
            output *= 2;
            heatdata[i*100+j] = getColor(output);
        }
    }
}

- (IBAction)updateHeatmap:(id)sender {
    network = Network(networkShape, 3, aTanh, rNone);
    getHeatData();
    [_heatMap setBackground:heatdata];
}

bool always = false;
NSString * toShow;

- (void)train{
    while(always){
        double loss = 0;
        for (int i = 0; i < DATA_NUM; i++) {
            inputs[0] = x1[i];
            inputs[1] = x2[i];
            double output = network.forwardProp(inputs, 2);
            network.backProp(y[i]);
            loss += abs(output - y[i]);
            network.updateWeights(0.03, 0);
        }
        toShow = [NSString stringWithFormat:@"%lf",loss];
        getHeatData();
        [self ui:^{
            _outputLabel.text = toShow;
            [_heatMap setBackground:heatdata];
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
