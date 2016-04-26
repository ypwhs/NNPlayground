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
    double weight = drand() - 0.5;
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
    ~Link();
    CAShapeLayer * curveLayer = [CAShapeLayer layer];
    void initCurve();
    void updateCurve();
};

enum ProblemType { Classification, Regression };

class Node {
public:
    int layer = 0;
    int id = 0;
    vector<Link*> inputLinks;
    double bias = 0.5;
    
    vector<Link*> outputs;
    double totalInput = 0;
    double output = 0;
    double outputDer = 0;
    double inputDer = 0;
    double accInputDer = 0;
    double numAccumulatedDers = 0;
    Activation activation;
    int imageWidth = 100;
    int imageBytes = 0;
    unsigned int * outputBitmap;
    Node(Activation &act) {
        activation = act;
    }
    Node(){}
    ~Node();
    
    double updateOutput();
    double updateOutput(int x1, int x2);
    void updateBitmapPixel(int x1, int x2, double value);
    UIImage * nodeImage;
    UIImage * getImage();
    
    CALayer * nodeLayer;
    CAShapeLayer * triangleLayer;
    void initNodeLayer(CGRect frame);
};

#endif
