//
//  Helper.swift
//  NNPlayground
//
//  Created by 陈禹志 on 16/5/30.
//  Copyright © 2016年 杨培文. All rights reserved.
//

import Foundation
import UIKit

typealias CancelableTask = (_ cancel: Bool) -> Void

func delay(_ time: TimeInterval, work: @escaping ()->()) -> CancelableTask? {
    
    var finalTask: CancelableTask?
    
    let cancelableTask: CancelableTask = { cancel in
        if cancel {
            finalTask = nil
            
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }
    
    finalTask = cancelableTask
    
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(time * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
        if let task = finalTask {
            task(false)
        }
    }
    
    return finalTask
}

func cancel(_ cancelableTask: CancelableTask?) {
    cancelableTask?(true)
}

func hideAddButton(_ sender: AddButton, hide: Bool) {
    
    let graduallyAnimation = CABasicAnimation(keyPath: "transform.scale")
    graduallyAnimation.duration = 0.2
    graduallyAnimation.fillMode = kCAFillModeForwards
    
    if hide {
        graduallyAnimation.fromValue = 1
        graduallyAnimation.toValue = 0.01
        sender.layer.add(graduallyAnimation, forKey: "graduallyAnimation")
        delay(0.1){
            sender.isHidden = true
        }
    }
    else {
        graduallyAnimation.fromValue = 0.01
        graduallyAnimation.toValue = 1
        sender.layer.add(graduallyAnimation, forKey: "graduallyAnimation")
        sender.isHidden = false
    }

}

func transitionSender(_ sender:UIView, hide: Bool) {
    
    let transition = CATransition()
    transition.duration = 0.2
    
    sender.layer.add(transition, forKey: "transition")
    
    if hide {
        sender.isHidden = true
    }
    else {
        sender.isHidden = false
    }

}

func stretchTransition(_ sender:UIView, toLeft: Bool, changeHidden: Bool) {
    let transition = CATransition()
    transition.duration = 0.2
    if changeHidden&&(!sender.isHidden) {
        transition.type = kCATransitionReveal
    }
    else{
        transition.type = kCATransitionMoveIn
    }
    
    if toLeft {
        transition.subtype = kCATransitionFromRight
    }
    else {
        transition.subtype = kCATransitionFromLeft
    }
    
    sender.layer.add(transition, forKey: "transition")
    
    if changeHidden {
        sender.isHidden = !sender.isHidden
    }
}
