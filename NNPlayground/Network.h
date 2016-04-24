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
    vector<vector<Node*>*> network;
    vector<int> networkShape;
    int numLayers;
    Network(int ns[], int ls, ActivationFunction activation, RegularizationFunction regularzation);
    ~Network();
    double forwardProp(double inputs[], int inputSize);
    double forwardProp(double inputs[], int inputSize, int x1, int x2);
    void backProp(double target);
    void updateWeights(double learningRate, double regularizationRate);
    void forEachNode(bool ignoreInputs, void (*accessor)(Node*));
    Node* getOutputNode();
};

#endif
