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

class Node;

class Link{
public:
    Node * source;
    Node * dest;
    double weight = drand();
    double errorDer = 0;
    /** Accumulated error derivative since the last update. */
    double accErrorDer = 0;
    /** Number of accumulated derivatives since the last update. */
    double numAccumulatedDers = 0;
    Regularization regularization;
    Link(Node * s, Node * d, Regularization &r){
        source = s;
        dest = d;
        regularization = r;
    }
};

enum ProblemType { Classification, Regression };

class Node {
public:
    int layer = 0;
    int id = 0;
    vector<Link*> inputLinks = vector<Link*>();
    double bias = 0.1;
    
    vector<Link*> outputs = vector<Link*>();
    double totalInput;
    double output;
    double outputDer = 0;
    double inputDer = 0;
    double accInputDer = 0;
    double numAccumulatedDers = 0;
    Activation activation;
    Node(Activation &act) {
        activation = act;
    }
    Node(){}
    
    double updateOutput();
};

#endif
