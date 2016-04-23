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

//**************************** Thread ***************************
- (void)xiancheng:(dispatch_block_t)code{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), code);
}

- (void)ui:(dispatch_block_t)code{
    dispatch_async(dispatch_get_main_queue(), code);
}

//*************************** Network ***************************
int networkShape[] = {2, 4, 1};
int layers = 3;
Network * network = new Network(networkShape, layers, Tanh, None);
NSLock * networkLock = [[NSLock alloc] init];

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
        
        negativeColor[i] = r1 + (g1<<8) + (b1<<16);
        positiveColor[i] = r2 + (g2<<8) + (b2<<16);
    }
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

//**************************** Inputs ***************************
int DATA_NUM = 150;
double inputs[] = {1, 1};
double * x1 = new double[DATA_NUM];
double * x2 = new double[DATA_NUM];
double * y = new double[DATA_NUM];

- (IBAction)generateInputs:(id)sender {
    [networkLock lock];
    delete network;
    network = new Network(networkShape, layers, Tanh, None);
    [networkLock unlock];
    for(int i = 0; i < DATA_NUM; i++){
        x1[i] = drand()*1.8;
        x2[i] = drand()*1.8;
        y[i] = x1[i]*x2[i];
    }
    [_heatMap setData:x1 x2:x2 y:y size:DATA_NUM];
    [self onestep];
    
//    getHeatData();
//    [_heatMap setBackground:image];
}

//*************************** Heatmap ***************************
unsigned int * heatdata = new unsigned int[100*100];
UIImage * image;
CGContextRef bitmap;
void getHeatData(){
    [networkLock lock];
    for(int i = 0; i < 100; i++){
        for(int j = 0; j < 100; j++){
            inputs[0] = (j - 50.0)/50;
            inputs[1] = (i - 50.0)/50;
            double output = network->forwardProp(inputs, 2);
            output *= 10;
            heatdata[i*100+j] = getColor(output);
        }
    }
    [networkLock unlock];
    if(image == nil){
        bitmap = CGBitmapContextCreate(heatdata, 100, 100, 8, 400, CGColorSpaceCreateDeviceRGB(), kCGBitmapByteOrder32Big | kCGImageAlphaNoneSkipLast);
    }
    CGImageRef imageRef = CGBitmapContextCreateImage(bitmap);
    image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
}

- (IBAction)updateHeatmap:(id)sender {
    [self onestep];
}

//**************************** Train ****************************
bool always = false;
NSString * toShow;
int batch = 1;
- (void)onestep{
    double loss = 0;
    [networkLock lock];
    for(int n = 0; n < batch; n++)
    for (int i = 0; i < DATA_NUM; i++) {
        inputs[0] = x1[i];
        inputs[1] = x2[i];
        double output = network->forwardProp(inputs, 2);
        network->backProp(y[i]);
        loss += 0.5 * pow(output - y[i], 2);
        network->updateWeights(0.3, 0);
    }
    [networkLock unlock];
    toShow = [NSString stringWithFormat:@"%lf",loss/batch];
    getHeatData();
    [self ui:^{
        _outputLabel.text = toShow;
        [_heatMap setBackground:image];
    }];
}
- (void)train{
    while(always){
        [self onestep];
        [NSThread sleepForTimeInterval:0.008];
    }
}

- (IBAction)switch:(UISwitch *)sender {
    always = sender.on;
    [self xiancheng:^{[self train];}];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    initColor();
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
