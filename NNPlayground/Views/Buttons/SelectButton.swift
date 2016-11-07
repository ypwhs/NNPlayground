//
//  SelectButton.swift
//  NNPlayground
//
//  Created by 陈禹志 on 16/5/14.
//  Copyright © 2016年 杨培文. All rights reserved.
//

import UIKit

@IBDesignable
class SelectButton: UIButton {
    
    @IBInspectable var isChosen:Bool = false
//    @IBInspectable var fillColor: UIColor = UIColor(red: 24/255.0, green: 61/255.0, blue: 78/255.0, alpha: 1)
    @IBInspectable var fillColor: UIColor = UIColor.white.withAlphaComponent(1)

    override func draw(_ rect: CGRect) {
     
        if isChosen {
            let path = UIBezierPath(rect: rect)
            fillColor.setFill()
            path.fill()
        }
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        layer.masksToBounds = true
        layer.cornerRadius = 5
//        layer.borderWidth = 2
//        layer.borderColor = fillColor.CGColor
        layer.backgroundColor = fillColor.cgColor
        titleLabel?.textColor = fillColor
    }

}
