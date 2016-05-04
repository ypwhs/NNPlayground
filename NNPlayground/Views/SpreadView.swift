//
//  SpreadView.swift
//  UIPlayground
//
//  Created by 陈禹志 on 16/4/26.
//  Copyright © 2016年 com.insta. All rights reserved.
//

import UIKit

class SpreadView: UIView {
    
    var layers = 3
    var buttonWidth:CGFloat = 30
    
    lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clearColor()
        return view
    }()
    
    lazy var addNodeButton: [AddButton] = {
        let view = AddButton()
        view.frame = CGRect(x: 50, y: 100, width: 30, height: 30)
        var views = [view]
        for i in 2...6 {
            let view = AddButton()
            view.frame = CGRect(x: i*50, y: 100, width: 30, height: 30)
            views.append(view)
        }
        return views
    }()
    
    lazy var subNodeButton: [AddButton] = {
        let view = AddButton()
        view.frame = CGRect(x: 50, y: 150, width: 30, height: 30)
        view.isAddButton = false
        var views = [view]
        for i in 2...6 {
            let view = AddButton()
            view.isAddButton = false
            view.frame = CGRect(x: i*50, y: 150, width: 30, height: 30)
            views.append(view)
        }
        return views
    }()
    
    // MARK: - AddLayer
    var addLayer: (() -> Void)?
    func addLayerButtons(sender:AddButton) {
        if sender.isAddButton && layers < 8 {
            layers += 1
            addNodeButton[layers - 3].hidden = false
            subNodeButton[layers - 3].hidden = false
        }
        if !sender.isAddButton && layers > 2 {
            layers -= 1
            addNodeButton[layers - 2].hidden = true
            subNodeButton[layers - 2].hidden = true
        }
        print("\(layers)")
        addLayer?()
    }
    
    lazy var addLayerButton: AddButton = {
        let view = AddButton()
        view.frame = CGRect(x: 50, y: 20, width: 30, height: 30)
        view.addTarget(self, action: #selector(addLayerButtons), forControlEvents: .TouchUpInside)
        return view
    }()
    
    lazy var subLayerButton: AddButton = {
        let view = AddButton()
        view.isAddButton = false
        view.frame = CGRect(x: 100, y: 20, width: 30, height: 30)
        view.addTarget(self, action: #selector(addLayerButtons), forControlEvents: .TouchUpInside)
        return view
    }()
    
    // MARK: - DropDown
    private lazy var dropDownView: DropDownView = {
        let view = DropDownView()
        view.labelName = ["ReLU","Tanh","Sigmoid","Linear"]
        return view
    }()
    
    @objc private func dropDown() {
        if let window = self.window {
            dropDownView.showInView(window,button: dropDownButton)
        }
    }
    
    lazy var dropDownButton: DropDownButton = {
        let view = DropDownButton()
        view.frame = CGRect(x: 200, y: 100, width: 96, height: 24)
        view.addTarget(self, action: #selector(dropDown), forControlEvents: .TouchUpInside)
        return view
    }()
    
    func showInView(view:UIView) {
        frame = view.bounds
        view.addSubview(self)
        
        layoutIfNeeded()
        
        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseIn, animations: {[weak self]  _ in
            self?.containerView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.3)
            
            }, completion: { _ in
        })
        
        //        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        //
        //        rotateAnimation.fromValue = 0.0
        //        rotateAnimation.toValue = π/2
        //        rotateAnimation.duration = 0.2
        //        addLayerButton.layer.addAnimation(rotateAnimation, forKey: "addLayerButtonGra")
    }
    
    func hide() {
        UIView.animateWithDuration(0.2, delay: 0.1, options: .CurveEaseOut, animations: {[weak self]  _ in
            self?.containerView.backgroundColor = UIColor.clearColor()
            
            }, completion: {[weak self]  _ in
                self?.removeFromSuperview()
            })
    }
    
    var isFirstTimeBeenAddAsSubview = true
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if isFirstTimeBeenAddAsSubview {
            isFirstTimeBeenAddAsSubview = false
            
            makeUI()
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(SpreadView.hide))
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
            "addLayerButton":addLayerButton,
            "subLayerButton":subLayerButton
            ,"dropDownButton":dropDownButton
        ]
        
        let containerViewConstraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[containerView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)
        let containerViewConstraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[containerView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)
        
        NSLayoutConstraint.activateConstraints(containerViewConstraintsH)
        NSLayoutConstraint.activateConstraints(containerViewConstraintsV)
        
        addLayerButton.frame.size = CGSize(width: buttonWidth, height: buttonWidth)
        //        addLayerButton.frame = CGRect(x: <#T##CGFloat#>, y: <#T##CGFloat#>, width: buttonWidth, height: buttonWidth)
        containerView.addSubview(addLayerButton)
        containerView.addSubview(subLayerButton)
        for i in 0...5 {
            containerView.addSubview(addNodeButton[i])
            containerView.addSubview(subNodeButton[i])
            if i != 0 {
                addNodeButton[i].hidden = true
                subNodeButton[i].hidden = true
            }
        }
                containerView.addSubview(dropDownButton)
        
    }
    
}

extension SpreadView: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        
        if touch.view != containerView {
            return false
        }
        return true
    }
    
}
