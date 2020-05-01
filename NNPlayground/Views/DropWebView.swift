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
        view.backgroundColor = UIColor.clear
        return view
    }()
    
    lazy var webView: ShowWebView = {
        let view = ShowWebView()
        return view
    }()
    
    func showInView(_ view: UIView, button: UIButton, url: String) {
        frame = view.bounds
        dropDownButton = button
        webView.myUrl = url
        
        view.addSubview(self)
        
        layoutIfNeeded()
        
        containerView.alpha = 1
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .transitionCurlUp, animations: {
            
            self.layoutIfNeeded()
            
            }, completion: { _ in
        })
    }
    
    @objc func hide() {
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .transitionCurlDown, animations: {
            
            self.layoutIfNeeded()
            
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
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(hide))
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
        
        let containerViewConstraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[containerView]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)
        let containerViewConstraintsV = NSLayoutConstraint.constraints(withVisualFormat: "V:|[containerView]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)
        
        NSLayoutConstraint.activate(containerViewConstraintsH)
        NSLayoutConstraint.activate(containerViewConstraintsV)
        
        // layout for webView
        containerView.addSubview(webView)
        if (dropDownButton) != nil {
            webView.frame = CGRect(x: 10, y: (dropDownButton?.frame.maxY)! + 10, width: self.frame.width - 20, height: self.frame.height - (dropDownButton?.frame.maxY)! - 20)
        }
        
    }

}

extension DropWebView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        if touch.view != containerView {
            return false
        }
        
        return true
    }
    
}
