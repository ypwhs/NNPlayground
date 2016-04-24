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
double learningRate = 0.01;
auto activation = Tanh;
auto regularization = None;

Network * network = new Network(networkShape, layers, activation, regularization);
NSLock * networkLock = [[NSLock alloc] init];

- (void)resetNetwork{
    [networkLock lock];
    
    epoch = 0;
    delete network;
    network = new Network(networkShape, layers, activation, None);
    [_heatMap setData:x1 x2:x2 y:y size:DATA_NUM];
    
    [networkLock unlock];
    [self initNodeLayer];
    [self onestep];
}

//**************************** Inputs ***************************
int DATA_NUM = 300;
double inputs[] = {1, 1};
double * x1 = new double[DATA_NUM];
double * x2 = new double[DATA_NUM];
double * y = new double[DATA_NUM];

void dataset_circle(){
    for(int i = 0; i < DATA_NUM/2; i++){
        double r = drand()*0.2+0.7;
        double dir = arc4random()%360/180.0*3.14;
        x1[i] = r*sin(dir);
        x2[i] = r*cos(dir);
        y[i] = 1;
    }
    
    for(int i = DATA_NUM/2; i < DATA_NUM; i++){
        double r = drand()*0.5;
        double dir = arc4random()%360/180.0*3.14;
        x1[i] = r*sin(dir);
        x2[i] = r*cos(dir);
        y[i] = -1;
    }
}

void dataset_xor(){
    for(int i = 0; i < DATA_NUM; i++){
        x1[i] = (drand()-0.5)*1.6;
        x2[i] = (drand()-0.5)*1.6;
        y[i] = x1[i]*x2[i]>0 ? 1 : -1;
        x1[i] += x1[i]>0 ? 0.1 : -0.1;
        x2[i] += x2[i]>0 ? 0.1 : -0.1;
    }

}

- (IBAction)generateInputs:(id)sender {
    dataset_xor();
    [self resetNetwork];
}

- (IBAction)updateHeatmap:(id)sender {
    dataset_circle();
    [self resetNetwork];
}

//*************************** Heatmap ***************************

UIImage * image;
vector<UIImage * > nodeImages;

bool first = true;
- (void) getHeatData{
    [networkLock lock];
    
    for(int i = 0; i < 100; i++){
        for(int j = 0; j < 100; j++){
            inputs[0] = (i - 50.0)/50;
            inputs[1] = (j - 50.0)/50;
            network->forwardProp(inputs, 2, i, j);
        }
    }
    
    image = (*network->network[layers-1])[0]->getImage();
    
    int n = 0;
    for(int i = 1; i < layers; i++){
        for(int j = 0; j < networkShape[i]; j++){
            if(first)
                nodeImages.push_back((*network->network[i])[j]->getImage());
            else
                nodeImages[n] = (*network->network[i])[j]->getImage();
            n++;
        }
    }
    first = false;
    
    [self ui:^{
        [_heatMap setBackground:image];
        for (int i = 0; i < nodeImages.size(); i++) {
            [nodeLayers[i] setContents:(id)nodeImages[i].CGImage];
        }
    }];
    
    [networkLock unlock];
}

void outputNetwork(double x, double y){
    [networkLock lock];
    inputs[0] = x;
    inputs[1] = y;
    network->forwardProp(inputs, 2);
    [networkLock unlock];
    for(int i = 0; i < network->networkShape.size(); i++){
        auto currentLayer = network->network[i];
        for(int j = 0; j < currentLayer->size(); j++){
            auto node = (*currentLayer)[j];
            printf("%d-%d=%lf\n", node->layer, node->id, node->output);
        }
        printf("\n");
    }
}

vector<CALayer*> nodeLayers;
- (void) initNodeLayer{
    //remove all old layer
    while(nodeLayers.size() != 0){
        CALayer * nodeLayer = nodeLayers.back();
        [nodeLayer removeFromSuperlayer];
        nodeLayers.pop_back();
    }
    
    //add layers
    CGRect frame = _heatMap.frame;
    CGFloat x = frame.origin.x + frame.size.width + 10;
    CGFloat y = frame.origin.y;
    frame.size = CGSizeMake(30, 30);
    for(int i = 1; i < layers; i++){
        for(int j = 0; j < networkShape[i]; j++){
            frame.origin = CGPointMake(x + 40*i, y + 40*j);
            CALayer * nodeLayer = [[CALayer alloc] init];
            nodeLayer.frame = frame;
            [self.view.layer insertSublayer:nodeLayer atIndex:99];
            nodeLayers.push_back(nodeLayer);
        }
    }
    
}

//**************************** Train ****************************
bool always = false;
NSString * toShow;
int batch = 1;
int epoch = 0;
- (void)onestep{
    epoch += 1;
    double loss = 0;
    [networkLock lock];
    for(int n = 0; n < batch; n++)
    for (int i = 0; i < DATA_NUM; i++) {
        inputs[0] = x1[i];
        inputs[1] = x2[i];
        double output = network->forwardProp(inputs, 2);
        network->backProp(y[i]);
        loss += 0.5 * pow(output - y[i], 2);
        network->updateWeights(learningRate, 0);
    }
    [networkLock unlock];
    toShow = [NSString stringWithFormat:@"Epoch:%d,loss:%.3f", epoch, loss/DATA_NUM/batch];
    [self getHeatData];
    [self ui:^{
        _outputLabel.text = toShow;
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
    dataset_circle();
    [self initNodeLayer];
    [self resetNetwork];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
