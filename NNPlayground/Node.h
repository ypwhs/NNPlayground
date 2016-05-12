//
//  Node.h
//  NNPlayground
//
//  Created by 杨培文 on 16/4/18.
//  Copyright © 2016年 杨培文. All rights reserved.
//

#ifndef Node_h
#define Node_h

#import "Util.h"
#import <UIKit/UIKit.h>

class Node;

class Link{
public:
    Node * source;
    Node * dest;
    double weight = (drand() - 0.5)*4;  //随机权重
    double errorDer = 0;    //误差导数
    double accErrorDer = 0; //累计误差
    double numAccumulatedDers = 0;  //误差累计次数
    Regularization regularization;  //正则化
    Link(Node * s, Node * d, Regularization &r){
        source = s;
        dest = d;
        regularization = r;
    }
    ~Link();
    CAShapeLayer * curveLayer = [CAShapeLayer layer];   //曲线UI
    void initCurve();
    void updateCurve();
};

class Node {
public:
    int layer = 0;  //本结点所在层数（横坐标）
    int id = 0;     //本结点所在位置（纵坐标）
    vector<Link*> inputLinks;   //输入的连接
    double bias = 0;    //阈值，相当于+1偏置结点
    vector<Link*> outputs;  //输出的连接
    double totalInput = 0;  //输入
    double output = 0;      //输出
    double outputDer = 0;   //输出导数
    double inputDer = 0;    //输入导数
    double accInputDer = 0; //累计输入导数
    double numAccumulatedDers = 0;  //累计输入导数数量
    Activation activation;  //激活函数
    int imageWidth = 100;   //图像宽度
    unsigned int * outputBitmap;    //输出图像数据（HeatMap）
    Node(Activation &act) {
        activation = act;
    }
    Node(){}
    ~Node();
    
    double updateOutput();
    void updateOutput(int x, int y, bool discretize);
    void updateBitmapPixel(int x1, int x2, double value, bool discretize);
    UIImage * nodeImage;
    UIImage * getImage();
    void updateVisibility();
    
    CALayer * nodeLayer = [[CALayer alloc] init];   //结点层（HeatMap）
    CALayer * shadowLayer = [[CALayer alloc] init]; //阴影层
    CAShapeLayer * triangleLayer = [CAShapeLayer layer];    //三角形层
    void initNodeLayer(CGRect frame);   //初始化各层
};

#endif
