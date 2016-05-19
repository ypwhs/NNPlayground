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
double learningRate = 0.03;
double regularizationRate = 0;
auto activation = Tanh;
auto regularization = None;

Network * network = new Network(networkShape, layers, activation, regularization);
NSLock * networkLock = [[NSLock alloc] init];

bool discretize = false;
- (void)buildInputImage{
    //创建input图像
    vector<Node*> &inputLayer = *network->network[0];
    for(int j = 0; j < 100; j++){
        for(int i = 0; i < 100; i++){
            for(int k = 0; k < inputLayer.size(); k++){
                inputLayer[0]->updateBitmapPixel(i, j, (i - 50.0)/50*6, discretize);
                inputLayer[1]->updateBitmapPixel(i, j, (j - 50.0)/50*6, discretize);
            }
        }
    }
}

//初始化神经网络
- (void)resetNetwork{
    [networkLock lock];
    epoch = 0;
    lastEpoch = 0;
    Network * oldNetwork = network;
    network = new Network(networkShape, layers, activation, None);
    [self buildInputImage];
    [networkLock unlock];
    
    [self initNodeLayer];
    
    [networkLock lock];
    //计算loss
    double loss = 0;
    for (int i = 0; i < testNum; i++) {
        inputs[0] = testx1[i];
        inputs[1] = testx2[i];
        double output = network->forwardProp(inputs, 2);
        loss += 0.5 * pow(output - testy[i], 2);
    }
    testLoss = loss/testNum;
    
    loss = 0;
    for (int i = 0; i < trainNum; i++) {
        inputs[0] = trainx1[i];
        inputs[1] = trainx2[i];
        double output = network->forwardProp(inputs, 2);
        loss += 0.5 * pow(output - trainy[i], 2);
    }
    trainLoss = loss/testNum;
    
    delete oldNetwork;
    [networkLock unlock];
    
    [_heatMap setData:trainx1 x2:trainx2 y:trainy size:trainNum];
    if(isShowTestData)[_heatMap setTestData:testx1 x2:testx2 y:testy size:testNum];
    
    [self updateLabel];
    
}


//**************************** Inputs ***************************
const int DATA_NUM = 500;
double inputs[] = {1, 1};
double * rawx1 = new double[DATA_NUM];
double * rawx2 = new double[DATA_NUM];
double * rawy = new double[DATA_NUM];
double noise = 0;

#define π 3.1415926

double normalRandom(double mean, double variance){
    double v1, v2, s;
    do {
        v1 = drand(-1, 1);
        v2 = drand(-1, 1);
        s = v1 * v1 + v2 * v2;
    } while (s > 1);
    
    double result = sqrt(-2 * log(s) / s) * v1;
    return mean + variance * result;
}

void dataset_circle(){
    for(int i = 0; i < DATA_NUM; i++){
        double r;
        if(i < DATA_NUM/2)r = drand(0.7, 0.9);
        else r = drand(0, 0.5);
        double dir = drand(0, 2*π);
        rawx1[i] = r*cos(dir);
        rawx2[i] = r*sin(dir);
        double noisex1 = drand(-1, 1) * noise + rawx1[i];
        double noisex2 = drand(-1, 1) * noise + rawx2[i];
        rawy[i] = (noisex1*noisex1 + noisex2*noisex2)<0.25? 1 : -1;
    }
}

void dataset_twoGaussData(){
    for(int i = 0; i < DATA_NUM; i++){
        rawy[i] = i > DATA_NUM/2 ? 1 : -1;
        double variance = 0.14 + noise*0.5;
        rawx1[i] = normalRandom(rawy[i] * 0.4, variance);
        rawx2[i] = normalRandom(rawy[i] * 0.4, variance);
    }
}

void dataset_xor(){
    double padding = 0.05;
    for(int i = 0; i < DATA_NUM; i++){
        rawx1[i] = drand(-0.8, 0.8);
        rawx2[i] = drand(-0.8, 0.8);
        rawx1[i] += rawx1[i]>0 ? padding : -padding;
        rawx2[i] += rawx2[i]>0 ? padding : -padding;
        double noisex1 = drand(-1, 1) * noise + rawx1[i];
        double noisex2 = drand(-1, 1) * noise + rawx2[i];
        rawy[i] = noisex1*noisex2 > 0 ? 1 : -1;
    }
}

void dataset_spiral(){
    double deltaT = 0;
    for (int i = 0; i < DATA_NUM/2; i++) {
        double n = DATA_NUM/2;
        double r = (double)i / n * 0.8;
        double t = 1.75 * i / n * 2 * π + deltaT;
        rawx1[i] = r * sin(t) + drand(-1, 1)/6 * noise;
        rawx2[i] = r * cos(t) + drand(-1, 1)/6 * noise;
        rawy[i] = 1;
    }
    deltaT = π;
    for (int i = 0; i < DATA_NUM/2; i++) {
        double n = DATA_NUM/2;
        double r = (double)i / n * 0.8;
        double t = 1.75 * i / n * 2 * π + deltaT;
        rawx1[i+DATA_NUM/2] = r * sin(t) + drand(-1, 1)/6 * noise;
        rawx2[i+DATA_NUM/2] = r * cos(t) + drand(-1, 1)/6 * noise;
        rawy[i+DATA_NUM/2] = -1;
    }
}

double * trainx1 = new double[DATA_NUM];
double * trainx2 = new double[DATA_NUM];
double * trainy = new double[DATA_NUM];
double * testx1 = new double[DATA_NUM];
double * testx2 = new double[DATA_NUM];
double * testy = new double[DATA_NUM];
double ratioOfTrainingData = 0.5;

int trainNum = 0;
int testNum = 0;
double lastRatio = 0.5, lastNoise = 0;
enum Dataset{Circle, Xor, TwoGaussian, Spiral};
Dataset dataset = Circle;

- (void)updateDataset{
    switch (dataset) {
        case Circle: {
            dataset_circle();
            break;
        }
        case Xor: {
            dataset_xor();
            break;
        }
        case TwoGaussian: {
            dataset_twoGaussData();
            break;
        }
        case Spiral: {
            dataset_spiral();
            break;
        }
    }
    
    //Fisher-Yates algorithm
    for(int i = 0; i < DATA_NUM; i++){
        int r = floor(drand(0, DATA_NUM));
        double t1 = rawx1[i];
        double t2 = rawx2[i];
        double t3 = rawy[i];
        rawx1[i] = rawx1[r];
        rawx2[i] = rawx2[r];
        rawy[i] = rawy[r];
        rawx1[r] = t1;
        rawx2[r] = t2;
        rawy[r] = t3;
    }
    
    trainNum = ratioOfTrainingData * DATA_NUM;
    testNum = DATA_NUM - trainNum;
    for(int i = 0; i < trainNum; i++){
        trainx1[i] = rawx1[i];
        trainx2[i] = rawx2[i];
        trainy[i] = rawy[i];
    }
    
    for(int i = 0; i < testNum; i++){
        testx1[i] = rawx1[trainNum + i];
        testx2[i] = rawx2[trainNum + i];
        testy[i] = rawy[trainNum + i];
    }
    
    [self reset];
}

-(void) reset{
    _runButton.isRunButton = true;
    always = false;
    [networkLock lock];
    [networkLock unlock];
    [self ui:^{
        [_lossView clearData];
    }];
    [self resetNetwork];
}

bool isSpeedUp = false;
- (IBAction)speedUp:(AccelerateButton *)sender {
    [networkLock lock];
    if(isSpeedUp){
        _speedUpLabel.hidden = true;
        trainBatch = 1;
    }else{
        _speedUpLabel.hidden = false;
        trainBatch = 10;
    }
    isSpeedUp = !isSpeedUp;
    [networkLock unlock];
}

//*************************** Heatmap ***************************

UIImage * image;
- (void) getHeatData{
    [networkLock lock];
    
    //用100*100网络获取每个结点的输出
    for(int j = 0; j < 100; j++){
        for(int i = 0; i < 100; i++){
            inputs[0] = (i - 50.0)/50;
            inputs[1] = (j - 50.0)/50;
            network->forwardProp(inputs, 2, i, j, discretize);
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
- (IBAction)resetClick:(ResetButton *)sender {
    [self updateDataset];
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
        //最后一个Node的 frame
        if (i > 0) {
            AddButton *addButton = [_spreadView.addNodeButton objectAtIndex:(i - 1)];
            addButton.frame = CGRectMake(frame.origin.x, _spreadView.subNodeButtonY + 2 * _spreadView.buttonWidth, frame.size.width, frame.size.height);
            AddButton *subButton = [_spreadView.subNodeButton objectAtIndex:(i - 1)];
            subButton.frame = CGRectMake(frame.origin.x, _spreadView.subNodeButtonY, frame.size.width, frame.size.height);
        }
    }
    
    int viewHeight = self.view.frame.size.height;
    if (viewHeight == 320) {
        _spreadView.buttonWidth = 29;
    }
    else {
        _spreadView.buttonWidth = 36;
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
int trainBatch = 1;
int batch = 10;
int epoch = 0;
int lastEpoch = 0;
int speed = 0;
double lastEpochTime = [NSDate date].timeIntervalSince1970;
double trainLoss = 0, testLoss = 0;
- (void)onestep{
    [networkLock lock];
    
    double loss = 0;
    for (int i = 0; i < testNum; i++) {
        inputs[0] = testx1[i];
        inputs[1] = testx2[i];
        double output = network->forwardProp(inputs, 2);
        loss += 0.5 * pow(output - testy[i], 2);
    }
    testLoss = loss/testNum;
    
    loss = 0;
    int trainEpoch = 0;
    //进行trainBatch轮训练
    for(int n = 0; n < trainBatch; n++){
        for (int i = 0; i < trainNum; i++) {
            inputs[0] = trainx1[i];
            inputs[1] = trainx2[i];
            double output = network->forwardProp(inputs, 2);
            network->backProp(trainy[i]);
            loss += 0.5 * pow(output - trainy[i], 2);
            trainEpoch++;
            if((trainEpoch+1)%batch==0){
                network->updateWeights(learningRate, regularizationRate);
            }
        }
    }
    epoch += trainBatch;
    trainLoss = loss/trainNum/trainBatch;
    
    double tmp1 = trainLoss, tmp2 = testLoss;
    [self ui:^{
        [_lossView addLoss:tmp1 b:tmp2];
    }];
    
    [networkLock unlock];
    double now = [NSDate date].timeIntervalSince1970;
    speed = 1.0/(now - lastEpochTime);
    lastEpochTime = now;

    [self getHeatData];
    [self updateLabel];
}

- (void)updateLabel{
    [self ui:^{
        [_outputLabel setText:[NSString stringWithFormat:@"训练误差\n%.3f\n测试误差\n%.3f\n训练次数\n%d", trainLoss, testLoss, epoch]];
        [_fpsLabel setText:[NSString stringWithFormat:@"fps:%d", speed]];
    }];
}

double lastTrainTime = 0;
int maxfps = 120;
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

- (IBAction)runNN:(RunButton *)sender {
    always = sender.isRunButton;
    sender.isRunButton = !sender.isRunButton;
    lastEpochTime = (int)[NSDate date].timeIntervalSince1970;
    [self xiancheng:^{[self train];}];
}

-(void)initSpreadView{
    NSArray *nib = [[NSBundle mainBundle]loadNibNamed:@"SpreadView" owner:self options:nil];
    _spreadView = [nib objectAtIndex:0];
    ViewController *strongSelf = self;
//    _spreadView.addLayerButtons.frame.size = CGSizeMake(_heatMap.frame.size.height, _heatMap.frame.size.height);
    
    //增加节点 layerNum:范围为[1,6]的第n隐藏层
    _spreadView.addNode = ^(NSInteger layerNum,BOOL isAdd){
        int value = isAdd? 1 : -1;
        networkShape[layerNum] += value;
        if(networkShape[layerNum] < 1)networkShape[layerNum] = 1;
        if(networkShape[layerNum] > 8)networkShape[layerNum] = 8;
        [strongSelf reset];
        return NSInteger(networkShape[layerNum]);
    };
    
    //滑条 [0,8];[0,10];[0,29]
    _spreadView.setRatio = ^(NSInteger current){
        ratioOfTrainingData = (current+1.0)/10.0;   // 0.1~0.9
        if(ratioOfTrainingData != lastRatio){
            lastRatio = ratioOfTrainingData;
            [strongSelf updateDataset];
        }
    };
    _spreadView.setNoise = ^(NSInteger current){
        noise = current / 20.0;    //0~50%
        if(noise != lastNoise){
            lastNoise = noise;
            [strongSelf updateDataset];
        }
    };
    _spreadView.setBatchSize = ^(NSInteger current){
        batch = (int)current + 1;
    };
    
    //选择数据
    _spreadView.setCircleData = ^{
        dataset = Circle;
        [strongSelf updateDataset];
    };
    _spreadView.setExclusiveOrData = ^{
        dataset = Xor;
        [strongSelf updateDataset];
    };
    _spreadView.setGaussianData = ^{
        dataset = TwoGaussian;
        [strongSelf updateDataset];
    };
    _spreadView.setSpiralData = ^{
        dataset = Spiral;
        [strongSelf updateDataset];
    };
    
    //下拉菜单
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

    //增加层数
    _spreadView.addLayer = ^{
        strongSelf.runButton.isRunButton = true;
        always = false;
        [NSThread sleepForTimeInterval:0.008];
        
        [networkLock lock];
        int newLayers = (int)strongSelf.spreadView.layers;
        always = false;
        int * oldNetworkShape = networkShape;
        
        networkShape = new int[newLayers];
        networkShape[0] = 2;
        int i = 1;
        for(; i < layers - 1; i++){
            networkShape[i] = oldNetworkShape[i];
        }
        int repeatValue = oldNetworkShape[layers - 2];
        layers = newLayers;
        for(;i < layers - 1; i++){
            networkShape[i] = repeatValue;
        }
        networkShape[layers - 1] = 1;
        
        delete[] oldNetworkShape;
        
        [networkLock unlock];
        [strongSelf reset];
    };
}

CGFloat screenScale = [UIScreen mainScreen].scale;

- (void)viewDidLoad {
    [super viewDidLoad];
    initColor();
    dataset = Circle;
    [self updateDataset];
    [self initSpreadView];
    
    //左侧约束
    int height = self.view.frame.size.height;
    NSLayoutConstraint * runButtonWidth;
    if (height == 320) {
        runButtonWidth = [NSLayoutConstraint constraintWithItem:_runButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:39];
    }
    else {
        runButtonWidth = [NSLayoutConstraint constraintWithItem:_runButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:46];
    }
    [NSLayoutConstraint activateConstraints:[NSArray arrayWithObjects:runButtonWidth, nil]];
    [self.view layoutIfNeeded];
    NSLog(@"%f",_runButton.frame.size.height);
    

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
- (IBAction)oneStep:(id)sender {
    [self onestep];
}

bool isShowTestData = false;
- (IBAction)showTestData:(CheckButton *)sender {
    sender.checked = !sender.checked;
    isShowTestData = !isShowTestData;
    if(isShowTestData){
        [_heatMap setTestData:testx1 x2:testx2 y:testy size:testNum];
    }else{
        [_heatMap setData:trainx1 x2:trainx2 y:trainy size:trainNum];
    }
}
- (IBAction)changeDiscretize:(CheckButton *)sender {
    sender.checked = !sender.checked;
    [networkLock lock];
    discretize = !discretize;
    [self buildInputImage];
    [networkLock unlock];
    [self getHeatData];
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
