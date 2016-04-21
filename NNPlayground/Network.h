//
//  Network.h
//  NN
//
//  Created by 杨培文 on 16/4/19.
//  Copyright © 2016年 杨培文. All rights reserved.
//

#ifndef Network_h
#define Network_h

#import "Util.h"
#include "Node.h"

class Network{
public:
    vector<vector<Node*>*> network;
    Network(int networkShape[], int numLayers, ActivationFunction activation, RegularizationFunction regularzation);
    double forwardProp(double inputs[], int inputSize);
    void backProp(double target);
    void updateWeights(double learningRate, double regularizationRate);
    void forEachNode(bool ignoreInputs, void (*accessor)(Node*));
    Node* getOutputNode();
};

#endif
