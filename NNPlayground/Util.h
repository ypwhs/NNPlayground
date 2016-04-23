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

enum ActivationFunction{ReLU, Tanh, Sigmoid, Linear};
enum RegularizationFunction{None, L1, L2};

auto rNone =     [](double w){return w;};
auto rL1 =       [](double w){return abs(w);};
auto rderL1 =    [](double w){return w < 0 ? -1.0 : 1.0;};
auto rL2 =       [](double w){return 0.5 * w * w;};
auto rderL2 =    [](double w){return w;};

auto aReLU =       [](double x){return x < 0 ? 0.0 : x;};
auto aderReLU =    [](double x){return x < 0 ? 0.0 : 1.0;};
auto aTanh =       [](double x){return tanh(x);};
auto aderTanh =    [](double x){return 1-tanh(x)*tanh(x);};
auto aSigmoid =    [](double x){return 1/(1+exp(-x));};
auto aderSigmoid = [](double x){return aSigmoid(x)*(1-aSigmoid(x));};
auto aLinear =     [](double x){return x;};
auto aderLinear =  [](double x){return 1.0;};

class Regularization {
public:
    double (*output)(double w) = rNone;
    double (*der)(double w) = rNone;
};

class Activation {
public:
    double (*output)(double x) = aTanh;
    double (*der)(double x) = aderTanh;
};


#endif