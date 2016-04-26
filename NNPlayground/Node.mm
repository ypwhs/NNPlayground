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

void Node::updateBitmapPixel(int x1, int x2, double value){
    int bitmapIndex = x1*imageWidth + (imageWidth-1-x2);
    outputBitmap[bitmapIndex] = getColor(value);
}

Node::~Node(){
    //remove layers
    [nodeLayer removeFromSuperlayer];
    [triangleLayer removeFromSuperlayer];
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

void Node::initNodeLayer(CGRect frame){
    nodeLayer = [[CALayer alloc] init];
    CGFloat iwidth = frame.size.width;
    CGFloat triangleWidth = iwidth/10;
    //圆角,边框
    nodeLayer.masksToBounds = true;
    nodeLayer.cornerRadius = 5;
    nodeLayer.borderWidth = 1.5f;
    nodeLayer.borderColor = [UIColor blackColor].CGColor;
    
    nodeLayer.frame = frame;
    
    UIBezierPath * triangle = [UIBezierPath bezierPath];
    CGPoint p1 = CGPointMake(frame.origin.x + iwidth, frame.origin.y + iwidth/2-triangleWidth);
    CGPoint p2 = CGPointMake(p1.x, p1.y + 2*triangleWidth);
    CGPoint p3 = CGPointMake(frame.origin.x + iwidth + sqrt(3)/2*triangleWidth, frame.origin.y + iwidth/2);
    [triangle moveToPoint:p1];
    [triangle addLineToPoint:p2];
    [triangle addLineToPoint:p3];
    [triangle closePath];
    
    triangleLayer = [CAShapeLayer layer];
    [triangleLayer setPath:triangle.CGPath];
    [triangleLayer setFillColor:[UIColor blackColor].CGColor];
}

void Link::initCurve(){
    //add curve line
    Node * node = source;
    Node * node2 = dest;
    CGRect frame1 = node->nodeLayer.frame;
    CGRect frame2 = node2->nodeLayer.frame;
    CGPoint p1 = CGPointMake(frame1.origin.x + frame1.size.width*1.08, frame1.origin.y + frame1.size.height/2);
    CGPoint p2 = CGPointMake(frame2.origin.x, frame2.origin.y + frame2.size.height/2);
    CGPoint c1 = CGPointMake(p1.x + (p2.x-p1.x)/2, p1.y);
    CGPoint c2 = CGPointMake(p1.x + (p2.x-p1.x)/2, p2.y);
    UIBezierPath * curve = [UIBezierPath bezierPath];
    [curve moveToPoint:p1];
    [curve addCurveToPoint:p2 controlPoint1:c1 controlPoint2:c2];
    [curve addCurveToPoint:p1 controlPoint1:c2 controlPoint2:c1];
    [curve closePath];
    
    curveLayer = [CAShapeLayer layer];
    [curveLayer setPath:curve.CGPath];
    curveLayer.lineWidth = 1;
    unsigned int color = getColor(weight);
    CGColorRef color2 = [UIColor colorWithRed:(color&0xFF)/256.0 green:((color>>8)&0xFF)/256.0 blue:((color>>16)&0xFF)/256.0 alpha:1].CGColor;
    [curveLayer setStrokeColor:color2];
}

Link::~Link(){
    [curveLayer removeFromSuperlayer];
}

void Link::updateCurve(){
    curveLayer.lineWidth = abs(weight);
    unsigned int color = getColor(weight);
    CGColorRef color2 = [UIColor colorWithRed:(color&0xFF)/256.0 green:((color>>8)&0xFF)/256.0 blue:((color>>16)&0xFF)/256.0 alpha:1].CGColor;
    [curveLayer setStrokeColor:color2];
}