//
//  Util.m
//  NN
//
//  Created by 杨培文 on 16/4/19.
//  Copyright © 2016年 杨培文. All rights reserved.
//

#import "Util.h"

double drand(){
    return (double)arc4random()/ARC4RANDOM_MAX;
}

double drand(double a, double b){
    return (double)arc4random()/ARC4RANDOM_MAX * (b - a) + a;;
}

void initColor(){
    for(int i = 0; i < NUM_SHADES; i++){
        double factor = (double)i/NUM_SHADES;
        unsigned char r1 = 234 + ( 97 - 234)*factor;
        unsigned char g1 = 234 + (167 - 234)*factor;
        unsigned char b1 = 234 + (213 - 234)*factor;
        
        unsigned char r2 = 234 + (246 - 234)*factor;
        unsigned char g2 = 234 + (184 - 234)*factor;
        unsigned char b2 = 234 + (113 - 234)*factor;
        
        negativeColor[i] = r1 + (g1<<8) + (b1<<16);
        positiveColor[i] = r2 + (g2<<8) + (b2<<16);
    }
}

unsigned int getColor(double x){
    if(x > 0){
        x = x > 1 ? 1 : x;
        int index = x*(NUM_SHADES-1);
        return positiveColor[index];
    }else{
        x = -x;
        x = x > 1 ? 1 : x;
        int index = x*(NUM_SHADES-1);
        return negativeColor[index];
    }
}