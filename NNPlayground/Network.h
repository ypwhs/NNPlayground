//
//  Network.h
//  NN
//
//  Created by 杨培文 on 16/4/19.
//  Copyright © 2016年 杨培文. All rights reserved.
//

#ifndef Network_h
#define Network_h

#include "Util.h"
#include "Node.h"

class Network{
public:
    vector<vector<Node*>*> network; //Node二维数组
    vector<int> networkShape;   //网络形状
    int numLayers;  //层数
    ActivationFunction activation;  //激活函数
    RegularizationFunction regularzation;   //正则函数
    Network(int ns[], int ls, ActivationFunction activation, RegularizationFunction regularzation);
    ~Network();
    double forwardProp(double inputs[], int inputSize);
    void forwardProp(double inputs[], int inputSize, int x1, int x2, bool discretize);
    void backProp(double target);
    void updateWeights(double learningRate, double regularizationRate);
    void forEachNode(bool ignoreInputs, void (*accessor)(Node*));
    Node* getOutputNode();
};

#endif
