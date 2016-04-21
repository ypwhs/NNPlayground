//
//  Util.h
//  NN
//
//  Created by 杨培文 on 16/4/19.
//  Copyright © 2016年 杨培文. All rights reserved.
//

#ifndef Util_h
#define Util_h

#import <iostream>
#import <cstdio>
#import <vector>
#import <cmath>
using namespace std;

#define ARC4RANDOM_MAX      0x100000000

double drand();

enum ActivationFunction{aReLU, aTanh, aSigmoid, aLinear};
enum RegularizationFunction{rNone, rL1, rL2};

auto None =     [](double w){return w;};
auto L1 =       [](double w){return abs(w);};
auto derL1 =    [](double w){return w < 0 ? -1.0 : 1.0;};
auto L2 =       [](double w){return 0.5 * w * w;};
auto derL2 =    [](double w){return w;};

auto ReLU =       [](double x){return x < 0 ? 0.0 : x;};
auto derReLU =    [](double x){return x < 0 ? 0.0 : 1.0;};
auto Tanh =       [](double x){return tanh(x);};
auto derTanh =    [](double x){return 1-tanh(x)*tanh(x);};
auto Sigmoid =    [](double x){return 1/(1+exp(-x));};
auto derSigmoid = [](double x){return Sigmoid(x)*(1-Sigmoid(x));};
auto Linear =     [](double x){return x;};
auto derLinear =  [](double x){return 1.0;};

class Regularization {
public:
    double (*output)(double w) = None;
    double (*der)(double w) = None;
};

class Activation {
public:
    double (*output)(double x) = Tanh;
    double (*der)(double x) = derTanh;
};


#endif