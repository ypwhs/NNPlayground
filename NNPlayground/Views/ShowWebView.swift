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
        label.textColor = UIColor.gray
        label.font = UIFont(name: "Helvetica", size: 15)
        return label
    }()
    
    lazy var waitView:UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        view.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        return view
    }()
    
    var isFirstTimeBeenAddAsSubview = true
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        layer.masksToBounds = true
        layer.cornerRadius = 5
        layer.backgroundColor = UIColor.white.cgColor
        
        delegate = self
        let u = URL(string: myUrl)
        let request = URLRequest(url: u!)
        loadRequest(request)
        let networkReachability = Reachability.forInternetConnection()
        let networkStatus = networkReachability?.currentReachabilityStatus()
        
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
            
            let waitViewConstraintY = NSLayoutConstraint(item: waitView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 8)
            let waitViewConstraintX = NSLayoutConstraint(item: waitView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0)
            
            NSLayoutConstraint.activate([waitViewConstraintX, waitViewConstraintY])
            
            let waitLabelConstraintY = NSLayoutConstraint(item: waitLabel, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: -10)
            let waitLabelConstraintX = NSLayoutConstraint(item: waitLabel, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0)
            let waitLabelConstraintW = NSLayoutConstraint(item: waitLabel, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 60)
            let waitLabelConstraintH = NSLayoutConstraint(item: waitLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 18)
            
            NSLayoutConstraint.activate([waitLabelConstraintX, waitLabelConstraintY, waitLabelConstraintW, waitLabelConstraintH])
            
            layoutIfNeeded()
        }
        
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        waitView.stopAnimating()
        waitLabel.isHidden = true
    }

}
