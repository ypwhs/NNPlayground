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
int * networkShape = new int[3]{2, 4, 1};
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
    
    vector<Node*> &inputLayer = *network->network[0];
    for(int i = 0; i < 100; i++){
        for(int j = 0; j < 100; j++){
            for(int k = 0; k < inputLayer.size(); k++){
                inputLayer[0]->updateBitmapPixel(i, j, (j - 50.0)/50*6);
                inputLayer[1]->updateBitmapPixel(i, j, (i - 50.0)/50*6);
            }
        }
    }
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
    _myswitch.on = false;
    always = false;
    [self resetNetwork];
}

- (IBAction)updateHeatmap:(id)sender {
    dataset_circle();
    _myswitch.on = false;
    always = false;
    [self resetNetwork];
}

//*************************** Heatmap ***************************

UIImage * image;
- (void) getHeatData{
    [networkLock lock];
    
    //用100*100网络获取每个节点的输出
    for(int i = 0; i < 100; i++){
        for(int j = 0; j < 100; j++){
            inputs[0] = (i - 50.0)/50;
            inputs[1] = (j - 50.0)/50;
            network->forwardProp(inputs, 2, i, j);
        }
    }
    
    //获取大图
    image = (*network->network[layers-1])[0]->getImage();
    
    //获取每个节点的小图

    
    //更新大图，小图
    [self ui:^{
        [_heatMap setBackground:image];
        for(int i = 0; i < layers - 1; i++){
            for(int j = 0; j < networkShape[i]; j++){
                Node * node = (*network->network[i])[j];
                [node->nodeLayer setContents:(id)node->getImage().CGImage];
            }
        }
    }];
    
    [networkLock unlock];
}

void outputNetwork(double x, double y){
    [networkLock lock];
    
    inputs[0] = x;
    inputs[1] = y;
    network->forwardProp(inputs, 2);
    for(int i = 0; i < network->networkShape.size(); i++){
        auto currentLayer = network->network[i];
        for(int j = 0; j < currentLayer->size(); j++){
            auto node = (*currentLayer)[j];
            printf("%d-%d=%lf\n", node->layer, node->id, node->output);
        }
        printf("\n");
    }
    
    [networkLock unlock];
}

- (void) initNodeLayer{
    [networkLock lock];
    
    //add layers
    CGRect frame = _heatMap.frame;
    CGFloat margin = _heatMap.frame.origin.y;
    CGFloat x = margin;
    CGFloat y = margin;
    
    CGFloat width = _heatMap.frame.origin.x;
    width -= margin;
    if(layers - 2!= 0)width /= layers - 1;
    
    CGFloat height = self.view.frame.size.height;
    height -= margin;
    height /= 8;
    
    CGFloat iwidth = height-5*scale;
    frame.size = CGSizeMake(iwidth, iwidth);
    
    for(int i = 0; i < layers - 1; i++){
        for(int j = 0; j < networkShape[i]; j++){
            frame.origin = CGPointMake(x + width*i, y + height*j);
            Node * node = (*network->network[i])[j];
            node->initNodeLayer(frame);
            [self.view.layer addSublayer:node->nodeLayer];
            [self.view.layer addSublayer:node->triangleLayer];
        }
    }
    
    [networkLock unlock];
}

//**************************** Train ****************************
bool always = false;
NSString * toShow;
int batch = 1;
int epoch = 0;
int last = 0;
int speed = 0;
int lasttime = (int)[NSDate date].timeIntervalSince1970;
- (void)onestep{
    [networkLock lock];
    
    epoch += batch;
    double loss = 0;
    for(int n = 0; n < batch; n++)
    for (int i = 0; i < DATA_NUM; i++) {
        inputs[0] = x1[i];
        inputs[1] = x2[i];
        double output = network->forwardProp(inputs, 2);
        network->backProp(y[i]);
        loss += 0.5 * pow(output - y[i], 2);
        network->updateWeights(learningRate, 0);
    }
    
    if((int)[NSDate date].timeIntervalSince1970 != lasttime){
        lasttime = (int)[NSDate date].timeIntervalSince1970;
        speed = epoch - last;
        last = epoch;
    }
    
    toShow = [NSString stringWithFormat:@"loss:%.3f\nEpoch:%d.speed:%d", loss/DATA_NUM/batch, epoch, speed];
    
    [networkLock unlock];
    
    [self getHeatData];
    [self ui:^{
        _outputLabel.text = toShow;
    }];
}

- (void)train{
    while(always){
        [self onestep];
//        [NSThread sleepForTimeInterval:0.008];
    }
}

- (IBAction)changeSwitch:(UISwitch *)sender {
    always = sender.on;
    [self xiancheng:^{[self train];}];
}

- (IBAction)changeStepper:(UIStepper *)sender {
    _myswitch.on = false;
    always = false;
    [NSThread sleepForTimeInterval:0.008];
    [networkLock lock];
    
    printf("%d\n", int(sender.value + 2));
    delete[] networkShape;
    networkShape = new int[int(sender.value + 2)];
    networkShape[0] = 2;
    for(int i = 1; i < int(sender.value + 1); i++){
        networkShape[i] = 8;
    }
    networkShape[int(sender.value + 1)] = 1;
    layers = int(sender.value + 2);
    
    [networkLock unlock];
    [self resetNetwork];
}

CGFloat scale = [UIScreen mainScreen].scale;

- (void)viewDidLoad {
    [super viewDidLoad];
    printf("scale:%f\n", scale);
    initColor();
    dataset_circle();
    [self resetNetwork];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
