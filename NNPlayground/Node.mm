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

void Node::updateOutput(int x, int y) {
    totalInput = bias;
    for (int i = 0; i < inputLinks.size(); i++) {
        auto link = inputLinks[i];
        totalInput += link->weight * link->source->output;
    }
    output = activation.output(totalInput);
    int bitmapIndex = (imageWidth-1-y)*imageWidth + x;
    outputBitmap[bitmapIndex] = getColor(-output);
}

void Node::updateBitmapPixel(int x, int y, double value){
    int bitmapIndex = (imageWidth-1-y)*imageWidth + x;
    outputBitmap[bitmapIndex] = getColor(-value);
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

void Node::updateVisibility(){
    double outputWeight = 0, inputWeight = 0;
    for(int i = 0; i < outputs.size(); i++){
        double weight = abs(outputs[i]->weight);
        if(weight > outputWeight){
            outputWeight = weight;
        }
    }
    
    for(int i = 0; i < inputLinks.size(); i++){
        double weight = abs(inputLinks[i]->weight);
        if(weight > inputWeight){
            inputWeight = weight;
        }
    }
    
    if(outputWeight * inputWeight < 1.5){
        shadowLayer.backgroundColor = [UIColor clearColor].CGColor;
        nodeLayer.borderColor = [[UIColor blackColor] colorWithAlphaComponent:0.2].CGColor;
        triangleLayer.fillColor = [[UIColor blackColor] colorWithAlphaComponent:0.2].CGColor;
    }else{
        shadowLayer.backgroundColor = [UIColor blackColor].CGColor;
        nodeLayer.borderColor = [UIColor blackColor].CGColor;
        triangleLayer.fillColor = [UIColor blackColor].CGColor;
    }
}

void Node::initNodeLayer(CGRect frame){
    CGFloat ndoeWidth = frame.size.width;
    CGFloat triangleWidth = ndoeWidth/10;
    //圆角,边框
    nodeLayer.masksToBounds = true;
    nodeLayer.cornerRadius = 5;
    nodeLayer.borderWidth = 2;
    nodeLayer.borderColor = [UIColor blackColor].CGColor;
    nodeLayer.frame = frame;
    
    //阴影
    shadowLayer.frame = frame;
    shadowLayer.cornerRadius = 5;
    shadowLayer.shadowOffset = CGSizeMake(0, 3);
    shadowLayer.shadowColor = [UIColor blackColor].CGColor;
    shadowLayer.shadowRadius = 5.0;
    shadowLayer.shadowOpacity = 0.3;
    shadowLayer.backgroundColor = [UIColor grayColor].CGColor;
    
    //三角形
    UIBezierPath * triangle = [UIBezierPath bezierPath];
    CGPoint p1 = CGPointMake(frame.origin.x + ndoeWidth - 0.1, frame.origin.y + ndoeWidth/2-triangleWidth);
    CGPoint p2 = CGPointMake(p1.x, p1.y + 2*triangleWidth);
    CGPoint p3 = CGPointMake(frame.origin.x + ndoeWidth + sqrt(3)/2*triangleWidth, frame.origin.y + ndoeWidth/2);
    [triangle moveToPoint:p1];
    [triangle addLineToPoint:p2];
    [triangle addLineToPoint:p3];
    [triangle closePath];
    
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
    
    CGFloat width = frame2.size.height/15;//上下两条link的间距
    width = width > 4 ? 4 : width;
    CGPoint point2 = CGPointMake(frame2.origin.x, frame2.origin.y + frame2.size.height/2 - 5*width + node1->id * width);
    CGPoint controlPoint1 = CGPointMake(point1.x + (point2.x-point1.x)/2, point1.y);
    CGPoint controlPoint2 = CGPointMake(point1.x + (point2.x-point1.x)/2, point2.y);
    
    UIBezierPath * curve = [UIBezierPath bezierPath];
    [curve moveToPoint:point1];
    [curve addCurveToPoint:point2 controlPoint1:controlPoint1 controlPoint2:controlPoint2];
    [curve addCurveToPoint:point1 controlPoint1:controlPoint2 controlPoint2:controlPoint1];
    [curve closePath];
    
    [curveLayer setPath:curve.CGPath];
    updateCurve();
}

Link::~Link(){
    [curveLayer removeFromSuperlayer];
}

void Link::updateCurve(){
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    
    CGFloat width = abs(weight);
    
    width = width < 0.5 ? 0.5 : width;
    width = width > 4 ? 4 : width;
    curveLayer.lineWidth = width;
    
    unsigned int color = getColor(-weight);
    CGColorRef color2 = [UIColor colorWithRed:(color&0xFF)/256.0 green:((color>>8)&0xFF)/256.0 blue:((color>>16)&0xFF)/256.0 alpha:1].CGColor;
    [curveLayer setStrokeColor:color2];
    
    [CATransaction commit];
}