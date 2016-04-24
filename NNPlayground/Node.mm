//
//  Node.mm
//  NNPlayground
//
//  Created by 杨培文 on 16/4/18.
//  Copyright © 2016年 杨培文. All rights reserved.
//

#include "Node.h"

double Node::updateOutput() {
    // Stores total input into the node.
    totalInput = bias;
    for (int i = 0; i < inputLinks.size(); i++) {
        auto link = inputLinks[i];
        totalInput += link->weight * link->source->output;
    }
    output = activation.output(totalInput);
    return output;
}

double Node::updateOutput(int x1, int x2) {
    // Stores total input into the node.
    updateOutput();
    int bitmapIndex = x1*imageWidth + x2;
    outputBitmap[bitmapIndex] = getColor(output);
//    printf("%d-%d outputBitmap[%d]=%X\n", layer, id, bitmapIndex, getColor(output));
    return output;
}

Node::~Node(){
    //delete every link
    for (int i = 0; i < inputLinks.size(); i++) {
        delete inputLinks[i];
    }
    delete outputBitmap;
}

UIImage * Node::getImage(){
    CGContextRef nodeBitmapContext = CGBitmapContextCreate(outputBitmap, imageWidth, imageWidth, 8, 4*imageWidth, CGColorSpaceCreateDeviceRGB(), kCGBitmapByteOrder32Big | kCGImageAlphaNoneSkipLast);
    CGImageRef nodeImageRef = CGBitmapContextCreateImage(nodeBitmapContext);
    CGContextRelease(nodeBitmapContext);
    nodeImage = [UIImage imageWithCGImage:nodeImageRef];
    CGImageRelease(nodeImageRef);
    return nodeImage;
}