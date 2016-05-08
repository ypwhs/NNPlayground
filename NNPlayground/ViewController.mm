//
//  ViewController.m
//  NNPlayground
//
//  Created by 杨培文 on 16/4/21.
//  Copyright © 2016年 杨培文. All rights reserved.
//

#import "ViewController.h"

using namespace std;

@interface ViewController ()

@end

@implementation ViewController

//**************************** Thread ***************************
- (void)xiancheng:(dispatch_block_t)code{
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), code);
}

- (void)ui:(dispatch_block_t)code{
    dispatch_async(dispatch_get_main_queue(), code);
}

//*************************** Network ***************************
int * networkShape = new int[3]{2, 4, 1};
int layers = 3;
double learningRate = 0.001;
double regularizationRate = 0;
auto activation = Tanh;
auto regularization = None;

Network * network = new Network(networkShape, layers, activation, regularization);
NSLock * networkLock = [[NSLock alloc] init];

//初始化神经网络
- (void)resetNetwork{
    [networkLock lock];
    epoch = 0;
    lastEpoch = 0;
    Network * oldNetwork = network;
    network = new Network(networkShape, layers, activation, None);
    
    //创建input图像
    vector<Node*> &inputLayer = *network->network[0];
    for(int j = 0; j < 100; j++){
        for(int i = 0; i < 100; i++){
            for(int k = 0; k < inputLayer.size(); k++){
                inputLayer[0]->updateBitmapPixel(i, j, (i - 50.0)/50*6);
                inputLayer[1]->updateBitmapPixel(i, j, (j - 50.0)/50*6);
            }
        }
    }
    
    [networkLock unlock];
    
    [self initNodeLayer];
    
    [networkLock lock];
    //计算loss
    double loss = 0;
    for (int i = 0; i < DATA_NUM; i++) {
        inputs[0] = x1[i];
        inputs[1] = x2[i];
        double output = network->forwardProp(inputs, 2);
        loss += 0.5 * pow(output - y[i], 2);
    }
    [networkLock unlock];
    [_heatMap setData:x1 x2:x2 y:y size:DATA_NUM];
    
    //保存数据点截图
//    _fpsLabel.text = @"";
//    UIGraphicsBeginImageContextWithOptions(_heatMap.bounds.size, NO, 0);
//    [_heatMap.dataLayer renderInContext:UIGraphicsGetCurrentContext()];
//    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    
    delete oldNetwork;
    toShow = [NSString stringWithFormat:@"loss:%.3f,Epoch:%d", loss/DATA_NUM, epoch];
    _outputLabel.text = toShow;
    
}

//**************************** Inputs ***************************
int DATA_NUM = 300;
double inputs[] = {1, 1};
double * x1 = new double[DATA_NUM];
double * x2 = new double[DATA_NUM];
double * y = new double[DATA_NUM];
#define π 3.1415926

void dataset_circle(){
    for(int i = 0; i < DATA_NUM/2; i++){
        double r = drand(0.7, 0.9);
        double dir = drand(0, 2*π);
        x1[i] = r*cos(dir);
        x2[i] = r*sin(dir);
        y[i] = -1;
    }
    
    for(int i = DATA_NUM/2; i < DATA_NUM; i++){
        double r = drand(0, 0.5);
        double dir = drand(0, 2*π);
        x1[i] = r*cos(dir);
        x2[i] = r*sin(dir);
        y[i] = 1;
    }
}

double normalRandom(double mean, double variance){
    double v1, v2, s;
    do {
        v1 = 2 * drand() - 1;
        v2 = 2 * drand() - 1;
        s = v1 * v1 + v2 * v2;
    } while (s > 1);
    
    double result = sqrt(-2 * log(s) / s) * v1;
    return mean + variance * result;
}

void dataset_twoGaussData(){
    for(int i = 0; i < DATA_NUM; i++){
        y[i] = i > DATA_NUM/2 ? 1 : -1;
        x1[i] = normalRandom(y[i] * 0.4, 0.15);
        x2[i] = normalRandom(y[i] * 0.4, 0.15);
    }
}

void dataset_xor(){
    for(int i = 0; i < DATA_NUM; i++){
        x1[i] = drand(-0.8, 0.8);
        x2[i] = drand(-0.8, 0.8);
        y[i] = x1[i]*x2[i]>0 ? 1 : -1;
        x1[i] += x1[i]>0 ? 0.1 : -0.1;
        x2[i] += x2[i]>0 ? 0.1 : -0.1;
    }
}

void dataset_spiral(){
    int n = DATA_NUM/2;
    double deltaT = 0;
    for (int i = 0; i < n; i++) {
        double r = (double)i/n*0.8;
        double t = 1.75 * i / n * 2 * π + deltaT;
        x1[i] = r * sin(t);
        x2[i] = r * cos(t);
        y[i] = 1;
    }
    deltaT = π;
    for (int i = 0; i < n; i++) {
        double r = (double)i/n*0.8;
        double t = 1.75 * i / n * 2 * π + deltaT;
        x1[i+n] = r * sin(t);
        x2[i+n] = r * cos(t);
        y[i+n] = -1;
    }
}

-(void) reset{
    _myswitch.on = false;
    always = false;
    learningRate = 0.01;
    maxfps = 120;
    [self resetNetwork];
}

- (IBAction)speedup:(UISwitch *)sender {
    if(sender.on){
        batch = 120;
    }else{
        batch = 9;
    }
}

int maxfps = 120;

//*************************** Heatmap ***************************

UIImage * image;
- (void) getHeatData{
    [networkLock lock];
    
    //用100*100网络获取每个结点的输出
    for(int j = 0; j < 100; j++){
        for(int i = 0; i < 100; i++){
            inputs[0] = (i - 50.0)/50;
            inputs[1] = (j - 50.0)/50;
            network->forwardProp(inputs, 2, i, j);
        }
    }
    
    [self ui:^{
        //更新大图
        Node * outputNode = (*network->network[layers-1])[0];
        [_heatMap.backgroundLayer setContents:(id)outputNode->getImage().CGImage];
        
        //更新小图
        for(int i = 0; i < layers - 1; i++){
            for(int j = 0; j < networkShape[i]; j++){
                Node * node = (*network->network[i])[j];
                [CATransaction begin];
                [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
                if(layers < 5 && i > 0){
                    node->updateVisibility();
                }
                [node->nodeLayer setContents:(id)node->getImage().CGImage];
                [CATransaction commit];
            }
        }
        
        //更新线宽，颜色
        for(int i = 0; i < layers - 1; i++){
            for(int j = 0; j < networkShape[i]; j++){
                Node * node = (*network->network[i])[j];
                for(int k = 0; k < node->outputs.size(); k++){
                    [CATransaction begin];
                    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
                    node->outputs[k]->updateCurve();
                    [CATransaction commit];
                }
            }
        }
        
    }];
    
    [networkLock unlock];
}


//获取大图
UIImage * bigOutputImage;
int bigOutputImageWidth = 512;
unsigned int * outputBitmap = new unsigned int[bigOutputImageWidth*bigOutputImageWidth];

- (void)generateBigOutputImage{
    bigOutputImage = nil;
    double halfWidth = bigOutputImageWidth/2;
    for(int y = 0; y < bigOutputImageWidth; y++){
        for(int x = 0; x < bigOutputImageWidth; x++){
            inputs[0] = (x - halfWidth)/halfWidth;
            inputs[1] = (y - halfWidth)/halfWidth;
            double output = network->forwardProp(inputs, 2);
            outputBitmap[(bigOutputImageWidth-1-y)*bigOutputImageWidth + x] = getColor(-output);
        }
        [self ui:^{
            hud.progress = (double)y/bigOutputImageWidth;
        }];
    }
    CGContextRef bitmapContext = CGBitmapContextCreate(outputBitmap, bigOutputImageWidth, bigOutputImageWidth, 8, 4*bigOutputImageWidth, CGColorSpaceCreateDeviceRGB(), kCGBitmapByteOrder32Big | kCGImageAlphaNoneSkipLast);
    CGImageRef imageRef = CGBitmapContextCreateImage(bitmapContext);
    bigOutputImage = [UIImage imageWithCGImage:imageRef];
    CGContextRelease(bitmapContext);
    CGImageRelease(imageRef);
}

//初始化每个结点的图像层（CALayer）
- (void) initNodeLayer{
    [networkLock lock];
    
    CGRect frame = _heatMap.frame;
    (*network->network[layers - 1])[0]->initNodeLayer(frame);   //将heatmap的frame设置到网络的输出结点
    
    //计算各个坐标
    CGFloat margin = _heatMap.frame.origin.y;   //将heatmap的y坐标用于第一个结点的x,y坐标
    CGFloat x = margin;
    CGFloat y = margin;
    
    CGFloat width = frame.origin.x - margin;
    width /= layers - 1;    //两个结点的x坐标差
    
    CGFloat height = self.view.frame.size.height - margin;
    height /= 8;
    
    CGFloat ndoeWidth = height - 5*screenScale;
    ndoeWidth = ndoeWidth > 50 ? 50 : ndoeWidth;
    frame.size = CGSizeMake(ndoeWidth, ndoeWidth);

    for(int i = 0; i < layers - 1; i++){
        for(int j = 0; j < networkShape[i]; j++){
            frame.origin = CGPointMake(x + width*i, y + height*j);
            Node * node = (*network->network[i])[j];
            node->initNodeLayer(frame);
        }
    }
    
    [networkLock unlock];
    
    [self getHeatData];
    
    [networkLock lock];
    
    //将每个结点的layer，每个连接线的layer都插入到view中
    for(int i = 0; i < layers - 1; i++){
        for(int j = 0; j < networkShape[i]; j++){
            Node * node = (*network->network[i])[j];
            [self.view.layer addSublayer:node->nodeLayer];
            [self.view.layer addSublayer:node->triangleLayer];
            if(layers < 5 && i > 0){
                node->updateVisibility();
            }
            [CATransaction begin];
            [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
            [node->nodeLayer setContents:(id)node->getImage().CGImage];
            [self.view.layer insertSublayer:node->shadowLayer atIndex:0];
            
            for(int k = 0; k < node->outputs.size(); k++){
                Link * link = node->outputs[k];
                link->initCurve();
                [self.view.layer insertSublayer:link->curveLayer atIndex:0];
            }
            [CATransaction commit];
        }
    }
    
    [networkLock unlock];
}

//**************************** Train ****************************
bool always = false;
NSString * toShow;
NSString * fpsString;
int batch = 9;
int epoch = 0;
int lastEpoch = 0;
int speed = 0;
double lastEpochTime = [NSDate date].timeIntervalSince1970;

- (void)onestep{
    [networkLock lock];
    
    //进行batch轮训练
    double loss = 0;
    for(int n = 0; n < batch; n++){
        for (int i = 0; i < DATA_NUM; i++) {
            inputs[0] = x1[i];
            inputs[1] = x2[i];
            double output = network->forwardProp(inputs, 2);
            network->backProp(y[i]);
            loss += 0.5 * pow(output - y[i], 2);
        }
        network->updateWeights(learningRate, regularizationRate);
    }
    epoch += batch;
    [networkLock unlock];
    
    double now = [NSDate date].timeIntervalSince1970;
    speed = 1.0/(now - lastEpochTime);
    lastEpochTime = now;
    
    toShow = [NSString stringWithFormat:@"loss:%.3f,Epoch:%d", loss/DATA_NUM/batch, epoch];
    fpsString = [NSString stringWithFormat:@"fps:%d", speed];
    
    [self getHeatData];
    [self ui:^{
        _outputLabel.text = toShow;
        _fpsLabel.text = fpsString;
    }];
}

double lastTrainTime = 0;
- (void)train{
    while(always){
        //帧数控制
        if([NSDate date].timeIntervalSince1970 - lastTrainTime > 1.0/maxfps){
            lastTrainTime = [NSDate date].timeIntervalSince1970;
            [self onestep];
        }
        [NSThread sleepForTimeInterval:0.01/120];
//        [NSThread sleepForTimeInterval:0.008];
    }
}

- (IBAction)changeSwitch:(UISwitch *)sender {
    always = sender.on;
    lastEpochTime = (int)[NSDate date].timeIntervalSince1970;
    [self xiancheng:^{[self train];}];
}

-(void)initSpreadView{
    NSArray *nib = [[NSBundle mainBundle]loadNibNamed:@"SpreadView" owner:self options:nil];
    _spreadView = [nib objectAtIndex:0];
    ViewController *strongSelf = self;
//    _spreadView.addLayerButtons.frame.size = CGSizeMake(_heatMap.frame.size.height, _heatMap.frame.size.height);
    
    _spreadView.setCircleData = ^{
        dataset_circle();
        [strongSelf reset];
    };
    _spreadView.setExclusiveOrData = ^{
        dataset_xor();
        [strongSelf reset];
    };
    _spreadView.setGaussianData = ^{
        dataset_twoGaussData();
        [strongSelf reset];
    };
    _spreadView.setSpiralData = ^{
        dataset_spiral();
        [strongSelf reset];
    };
    
    _spreadView.setLearningRate = ^(NSInteger num){
        double learnForm[] = {0.00001,0.0001,0.001,0.003,0.01,0.03,0.1,0.3,1,3,10};
        learningRate = learnForm[num];
    };
    _spreadView.setActivation = ^(NSInteger num){
        activation = (ActivationFunction)num;
        [strongSelf reset];
    };
    _spreadView.setRegularization = ^(NSInteger num){
        regularization = (RegularizationFunction)num;
        [strongSelf reset];
    };
    _spreadView.setRegularizationRate = ^(NSInteger num){
        double form[] = {0,0.001,0.003,0.01,0.03,0.1,0.3,1,3,10};
        regularizationRate = form[num];
    };
    _spreadView.setProblemType = ^(NSInteger num){
        
    };
    
    _spreadView.addLayer = ^{
        strongSelf.myswitch.on = false;
        always = false;
        [NSThread sleepForTimeInterval:0.008];
        
        [networkLock lock];
        
        delete[] networkShape;
        networkShape = new int[int(_spreadView.layers)];
        networkShape[0] = 2;
        for(int i = 1; i < int(_spreadView.layers - 1); i++){
            networkShape[i] = 8;
        }
        networkShape[int(_spreadView.layers - 1)] = 1;
        layers = int(_spreadView.layers);
        
        [networkLock unlock];
        [strongSelf resetNetwork];
    };
}

CGFloat screenScale = [UIScreen mainScreen].scale;

- (void)viewDidLoad {
    [super viewDidLoad];
    initColor();
    dataset_circle();
    [self reset];
    [self initSpreadView];

    UILongPressGestureRecognizer *longpress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpressAction:)];
    longpress.minimumPressDuration = 0.5;
    [_heatMap addGestureRecognizer:longpress];
}

MBProgressHUD *hud;

- (void)imageSavedToPhotosAlbum:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    NSString *message = @"";
    if (!error) {
        message = @"成功保存到相册";
        UIImage *image = [[UIImage imageNamed:@"Checkmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        hud.mode = MBProgressHUDModeCustomView;
        hud.customView = imageView;
    }else {
        message = [error description];
    }
    hud.label.text = message;
    printf("%s\n", [message UTF8String]);
    [hud hideAnimated:YES afterDelay:1];
}

- (void)longpressAction:(UILongPressGestureRecognizer *)longpress{
    if(longpress.state == UIGestureRecognizerStateBegan){
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"保存到相册" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction * cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            printf("cancel\n");
        }];
        UIAlertAction * ok = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeAnnularDeterminate;
            hud.label.text = @"生成图像中";
            [self xiancheng:^{
                [self generateBigOutputImage];
                UIImageWriteToSavedPhotosAlbum(bigOutputImage, self, @selector(imageSavedToPhotosAlbum:didFinishSavingWithError:contextInfo:), nil);
            }];
        }];
        [alert addAction:cancel];
        [alert addAction:ok];
        [self presentViewController:alert animated:YES completion:^(){
            printf("alert\n");
        }];
    }
}


- (void)viewDidAppear:(BOOL)animated{
    [self resetNetwork];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)createSpread:(ConfigureButton *)sender {
    if (UIWindow *window = self.view.window) {
        [_spreadView showInView:window];
    }
}


@end
