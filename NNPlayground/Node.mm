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
    [shadowLayer removeFromSuperlayer];
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
    nodeLayer.borderWidth = 2;
    nodeLayer.borderColor = [UIColor blackColor].CGColor;
    nodeLayer.frame = frame;
    
    //阴影
    shadowLayer = [[CALayer alloc] init];
    shadowLayer.frame = frame;
    shadowLayer.cornerRadius = 5;
    shadowLayer.shadowOffset = CGSizeMake(0, 3);
    shadowLayer.shadowColor = [UIColor blackColor].CGColor;
    shadowLayer.shadowRadius = 5.0;
    shadowLayer.shadowOpacity = 0.3;
    shadowLayer.backgroundColor = [UIColor grayColor].CGColor;
    
    //三角形
    UIBezierPath * triangle = [UIBezierPath bezierPath];
    CGPoint p1 = CGPointMake(frame.origin.x + iwidth - 1, frame.origin.y + iwidth/2-triangleWidth);
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
    Node * node1 = source;
    Node * node2 = dest;
    CGRect frame1 = node1->nodeLayer.frame;
    CGRect frame2 = node2->nodeLayer.frame;
    
    //贝塞尔曲线
    CGPoint point1 = CGPointMake(frame1.origin.x + frame1.size.width, frame1.origin.y + frame1.size.height/2);
    CGFloat width = frame2.size.height/15;
    width = width > 2 ? 2 : width;
    CGPoint point2 = CGPointMake(frame2.origin.x, frame2.origin.y + frame2.size.height/2 - 5*width + node1->id * width);
    CGPoint controlPoint1 = CGPointMake(point1.x + (point2.x-point1.x)/2, point1.y);
    CGPoint controlPoint2 = CGPointMake(point1.x + (point2.x-point1.x)/2, point2.y);
    
    UIBezierPath * curve = [UIBezierPath bezierPath];
    [curve moveToPoint:point1];
    [curve addCurveToPoint:point2 controlPoint1:controlPoint1 controlPoint2:controlPoint2];
    [curve addCurveToPoint:point1 controlPoint1:controlPoint2 controlPoint2:controlPoint1];
    [curve closePath];
    
    curveLayer = [CAShapeLayer layer];
    [curveLayer setPath:curve.CGPath];
    curveLayer.lineWidth = 1;
    unsigned int color = getColor(-weight);
    CGColorRef color2 = [UIColor colorWithRed:(color&0xFF)/256.0 green:((color>>8)&0xFF)/256.0 blue:((color>>16)&0xFF)/256.0 alpha:1].CGColor;
    [curveLayer setStrokeColor:color2];
}

Link::~Link(){
    [curveLayer removeFromSuperlayer];
}

void Link::updateCurve(){
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    
    CGFloat width = abs(weight);
    width = width < 0.5 ? 0.5 : width;
    curveLayer.lineWidth = width;
    
    unsigned int color = getColor(-weight);
    CGColorRef color2 = [UIColor colorWithRed:(color&0xFF)/256.0 green:((color>>8)&0xFF)/256.0 blue:((color>>16)&0xFF)/256.0 alpha:1].CGColor;
    [curveLayer setStrokeColor:color2];
    
    [CATransaction commit];
}