//
//  HeatMap.swift
//  NNPlayground
//
//  Created by 杨培文 on 16/4/21.
//  Copyright © 2016年 杨培文. All rights reserved.
//

import UIKit
class HeatMapView: UIView {
    let NUM_SHADES = 256
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initLayer()
    }
    
    var backgroundLayer = CALayer()
    var dataLayer = CALayer()
    
    func initLayer(){
        backgroundLayer.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)
        self.layer.insertSublayer(backgroundLayer, at: 0)
        dataLayer.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)
        self.layer.insertSublayer(dataLayer, at: 1)
        
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(HeatMapView.longpress))
        recognizer.minimumPressDuration = 1;
        self.addGestureRecognizer(recognizer)
    }
    
    func longpress(_ rec:UILongPressGestureRecognizer){
        if(rec.state == UIGestureRecognizerState.began){
//            print("long press")
        }
    }
    
    func setBackground(_ image:UIImage){
        backgroundLayer.contents = image.cgImage
        self.setNeedsDisplay()
    }
    
    var trainx:[[Double]] = []
    var trainy:[Double] = []
    var testx:[[Double]] = []
    var testy:[Double] = []
    
    func setData(_ x1:UnsafeMutablePointer<Double>, x2:UnsafeMutablePointer<Double>, y:UnsafeMutablePointer<Double>, size:Int){
        self.trainx = []
        self.trainy = []
        for i in 0..<size{
            self.trainx.append([x1[i], x2[i]])
            self.trainy.append(y[i])
        }
        dataLayer.sublayers = nil
        
        let halfWidth = Double(dataLayer.frame.size.width / 2)
        let halfHeight = Double(dataLayer.frame.size.height / 2)
        for i in 0..<trainx.count{
            if abs(trainx[i][0]) > 1 || abs(trainx[i][1]) > 1{
                continue;
            }
            //先添加白底圆，再添加颜色圆
            var pathLayer = CAShapeLayer()
            var path = UIBezierPath(ovalIn: CGRect(x: Double(halfWidth * trainx[i][0] + halfWidth)-1, y: Double(halfHeight - halfHeight * trainx[i][1])-1, width: 6.0, height: 6.0))  //减1是为了圆心和半径5的圆匹配
            pathLayer.path = path.cgPath
            pathLayer.fillColor = white.cgColor
            dataLayer.addSublayer(pathLayer)
            
            pathLayer = CAShapeLayer()
            path = UIBezierPath(ovalIn: CGRect(x: Double(halfWidth * trainx[i][0] + halfWidth), y: Double(halfHeight - halfHeight * trainx[i][1]), width: 4.0, height: 4.0))
            pathLayer.path = path.cgPath
            if trainy[i] > 0{
                pathLayer.fillColor = blue.cgColor
            }else{
                pathLayer.fillColor = orange.cgColor
            }
            dataLayer.addSublayer(pathLayer)
            
        }
        self.setNeedsDisplay()
    }
    
    func setTestData(_ x1:UnsafeMutablePointer<Double>, x2:UnsafeMutablePointer<Double>, y:UnsafeMutablePointer<Double>, size:Int){
        self.testx = []
        self.testy = []
        for i in 0..<size{
            self.testx.append([x1[i], x2[i]])
            self.testy.append(y[i])
        }
        
        let halfWidth = Double(dataLayer.frame.size.width / 2)
        let halfHeight = Double(dataLayer.frame.size.height / 2)
        for i in 0..<testx.count{
            if abs(testx[i][0]) > 1 || abs(testx[i][1]) > 1{
                continue;
            }
            //先添加黑底圆，再添加颜色圆
            var pathLayer = CAShapeLayer()
            var path = UIBezierPath(ovalIn: CGRect(x: Double(halfWidth * testx[i][0] + halfWidth)-1, y: Double(halfHeight - halfHeight * testx[i][1])-1, width: 6.0, height: 6.0))  //减1是为了圆心和半径5的圆匹配
            pathLayer.path = path.cgPath
            pathLayer.fillColor = black.cgColor
            dataLayer.addSublayer(pathLayer)
            
            pathLayer = CAShapeLayer()
            path = UIBezierPath(ovalIn: CGRect(x: Double(halfWidth * testx[i][0] + halfWidth), y: Double(halfHeight - halfHeight * testx[i][1]), width: 4.0, height: 4.0))
            pathLayer.path = path.cgPath
            if testy[i] > 0{
                pathLayer.fillColor = blue.cgColor
            }else{
                pathLayer.fillColor = orange.cgColor
            }
            dataLayer.addSublayer(pathLayer)
        }
        self.setNeedsDisplay()
        
    }
    
    let orange = UIColor(red: 245/256.0, green: 147/256.0, blue: 34/256.0, alpha: 1)
    let blue = UIColor(red: 8/256.0, green: 119/256.0, blue: 189/256.0, alpha: 1)
    let white = UIColor(red: 232/256.0, green: 234/256.0, blue: 235/256.0, alpha: 1)
    let black = UIColor(white: 0, alpha: 0.87)
    
}
