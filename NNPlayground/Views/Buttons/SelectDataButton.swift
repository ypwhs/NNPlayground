//
//  SelectDataButton.swift
//  NNPlayground
//
//  Created by 陈禹志 on 16/5/6.
//  Copyright © 2016年 杨培文. All rights reserved.
//

import UIKit

class SelectDataButton: UIButton {
    
    var isChosen: Bool = false
    {
        didSet{
            if isChosen {
                alpha = 1
            }
            else {
                alpha = 0.4
            }
        }
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        layer.masksToBounds = true
        layer.cornerRadius = 5
        layer.borderWidth = 2
        layer.borderColor = UIColor.blackColor().CGColor
        alpha = 0.4
    }
    
}
