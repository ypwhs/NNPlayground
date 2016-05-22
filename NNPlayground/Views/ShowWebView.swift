//
//  ShowWebView.swift
//  NNPlayground
//
//  Created by 陈禹志 on 16/5/20.
//  Copyright © 2016年 杨培文. All rights reserved.
//  

import UIKit

class ShowWebView: UIWebView,UIWebViewDelegate {

    var myUrl:String = ""
    lazy var waitLabel: UILabel = {
        let label = UILabel()
        label.text = "正在载入"
        label.textColor = UIColor.grayColor()
        label.font = UIFont(name: "Helvetica", size: 15)
        return label
    }()
    
    lazy var waitView:UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        view.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
        return view
    }()
    
    var isFirstTimeBeenAddAsSubview = true
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        layer.masksToBounds = true
        layer.cornerRadius = 5
        layer.backgroundColor = UIColor.whiteColor().CGColor
        
        delegate = self
        let u = NSURL(string: myUrl)
        let request = NSURLRequest(URL: u!)
        loadRequest(request)
        let networkReachability = Reachability.reachabilityForInternetConnection()
        let networkStatus = networkReachability.currentReachabilityStatus()
        
        if networkStatus == NotReachable {
            waitLabel.text = "无网络连接"
            waitView.stopAnimating()
        }
        
        if isFirstTimeBeenAddAsSubview {
            isFirstTimeBeenAddAsSubview = false
            
            addSubview(waitView)
            waitView.translatesAutoresizingMaskIntoConstraints = false
            waitView.startAnimating()
            addSubview(waitLabel)
            waitLabel.translatesAutoresizingMaskIntoConstraints = false
            
            let waitViewConstraintY = NSLayoutConstraint(item: waitView, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1, constant: 8)
            let waitViewConstraintX = NSLayoutConstraint(item: waitView, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1, constant: 0)
            
            NSLayoutConstraint.activateConstraints([waitViewConstraintX, waitViewConstraintY])
            
            let waitLabelConstraintY = NSLayoutConstraint(item: waitLabel, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1, constant: -10)
            let waitLabelConstraintX = NSLayoutConstraint(item: waitLabel, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1, constant: 0)
            let waitLabelConstraintW = NSLayoutConstraint(item: waitLabel, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 60)
            let waitLabelConstraintH = NSLayoutConstraint(item: waitLabel, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 18)
            
            NSLayoutConstraint.activateConstraints([waitLabelConstraintX, waitLabelConstraintY, waitLabelConstraintW, waitLabelConstraintH])
            
            layoutIfNeeded()
        }
        
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        waitView.stopAnimating()
        waitLabel.hidden = true
    }

}
