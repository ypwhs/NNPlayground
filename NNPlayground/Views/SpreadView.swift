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
    
    @IBAction func addLayerButton(sender: AddButton) {
        addLayerButtons(sender)
    }
    @IBAction func subLayerButton(sender: AddButton) {
        addLayerButtons(sender)
    }

    // MARK: - DropDown
    private lazy var learningRateDropView: DropDownView = {
        let view = DropDownView()
        view.labelName = ["0.00001","0.0001","0.001","0.003","0.01","0.03","0.1","0.3","1","3","10"]
        view.labelIsSelected = 5
        return view
    }()
    
    @IBAction func learningRateDrop(sender: DropDownButton) {
        if let window = self.window {
            learningRateDropView.showInView(window,button: sender)
        }
    }
    
    private lazy var activationDropView: DropDownView = {
        let view = DropDownView()
        view.labelName = ["ReLU","Tanh","Sigmoid","Linear"]
        view.labelIsSelected = 1
        return view
    }()
    
    @IBAction func activationDrop(sender: DropDownButton) {
        if let window = self.window {
            activationDropView.showInView(window,button: sender)
        }
    }
    
    private lazy var regularizationDropView: DropDownView = {
        let view = DropDownView()
        view.labelName = ["None","L1","L2"]
        view.labelIsSelected = 0
        return view
    }()
    
    @IBAction func regularizationDrop(sender: DropDownButton) {
        if let window = self.window {
            regularizationDropView.showInView(window,button: sender)
        }
    }
    
    private lazy var regularizationRateDropView: DropDownView = {
        let view = DropDownView()
        view.labelName = ["0","0.001","0.003","0.01","0.03","0.1","0.3","1","3","10"]
        view.labelIsSelected = 0
        return view
    }()
    
    @IBAction func regularizationRateDrop(sender: DropDownButton) {
        if let window = self.window {
            regularizationRateDropView.showInView(window,button: sender)
        }
    }
    
    private lazy var problemTypeDropView: DropDownView = {
        let view = DropDownView()
        view.labelName = ["Classification","Regression"]
        view.labelIsSelected = 0
        return view
    }()
    
    @IBAction func problemTypeDrop(sender: DropDownButton) {
        if let window = self.window {
            problemTypeDropView.showInView(window,button: sender)
        }
    }
    
    //MARK: - View
    func showInView(view:UIView) {
        frame = view.bounds
        view.addSubview(self)
        
        layoutIfNeeded()
        
        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseIn, animations: {[weak self]  _ in
            self?.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.3)
            }, completion: { _ in
        })
        
    }
    
    func hide() {
        UIView.animateWithDuration(0.2, delay: 0.1, options: .CurveEaseOut, animations: {[weak self]  _ in
            self?.backgroundColor = UIColor.clearColor()
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
            self.addGestureRecognizer(tap)
            
            tap.cancelsTouchesInView = true
            tap.delegate = self
        }
    }
    
    func makeUI() {
                
        for i in 0...5 {
            self.addSubview(addNodeButton[i])
            self.addSubview(subNodeButton[i])
            if i != 0 {
                addNodeButton[i].hidden = true
                subNodeButton[i].hidden = true
            }
        }
        
    }
    
}

extension SpreadView: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        
        if touch.view != self {
            return false
        }
        return true
    }
    
}
