//
//  DropWebView.swift
//  NNPlayground
//
//  Created by 陈禹志 on 16/5/20.
//  Copyright © 2016年 杨培文. All rights reserved.
//

import UIKit

class DropWebView: UIView {
    
    var dropDownButton:UIButton?
    
    lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clearColor()
        return view
    }()
    
    lazy var webView: ShowWebView = {
        let view = ShowWebView()
        return view
    }()
    
    func showInView(view: UIView, button: UIButton, url: String) {
        frame = view.bounds
        dropDownButton = button
        webView.myUrl = url
        
        view.addSubview(self)
        
        layoutIfNeeded()
        
        containerView.alpha = 1
        
        UIView.animateWithDuration(0.2, delay: 0.0, options: .TransitionCurlUp, animations: {[weak self]  _ in
            
            self?.layoutIfNeeded()
            
            }, completion: { _ in
        })
    }
    
    func hide() {
        
        UIView.animateWithDuration(0.2, delay: 0.0, options: .TransitionCurlDown, animations: {[weak self]  _ in
            
            
            self?.layoutIfNeeded()
            
            }, completion: {[weak self] _ in
                self?.removeFromSuperview()
            })
    }
    
    var isFirstTimeBeenAddAsSubview = true
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if isFirstTimeBeenAddAsSubview {
            isFirstTimeBeenAddAsSubview = false
            
            makeUI()
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(DropDownView.hide))
            containerView.addGestureRecognizer(tap)
            
            tap.cancelsTouchesInView = true
            tap.delegate = self
        }
    }
    
    func makeUI() {
        
        addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let viewsDictionary = [
            "containerView": containerView,
            ]
        
        // layout for containerView
        
        let containerViewConstraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[containerView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)
        let containerViewConstraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[containerView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)
        
        NSLayoutConstraint.activateConstraints(containerViewConstraintsH)
        NSLayoutConstraint.activateConstraints(containerViewConstraintsV)
        
        // layout for webView
        containerView.addSubview(webView)
        if (dropDownButton) != nil {
            webView.frame = CGRect(x: 10, y: (dropDownButton?.frame.maxY)! + 10, width: self.frame.width - 20, height: self.frame.height - (dropDownButton?.frame.maxY)! - 20)
        }
        
    }

}

extension DropWebView: UIGestureRecognizerDelegate {
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        
        if touch.view != containerView {
            return false
        }
        
        return true
    }
    
}
