//
//  SpreadView.swift
//  UIPlayground
//
//  Created by 陈禹志 on 16/4/26.
//  Copyright © 2016年 com.insta. All rights reserved.
//

import UIKit

@objcMembers class SpreadView: UIView {
    
    var layers = 3
    var buttonWidth:CGFloat = 30
    var subNodeButtonY:CGFloat = 114
    
    var regenerate: (() -> Void)?
    @IBAction func Regenerate(_ sender: UIButton) {
        regenerate?()
        //setData
        setCircleData?()
        resetAlpha(setCircleButton)
        
        //slider
        setRatioSlider.setValue(0.5, animated: true)
        setRatioLabel.text = "训练数据百分比：50%"
        setRatio?(4)
        setNoiseSlider.setValue(0, animated: true)
        setNoiseLabel.text = "噪声：0"
        setNoise?(0)
        setBatchSizeSlider.setValue(0.333333333, animated: true)
        setBatchSizeLabel.text = "批量大小：10"
        setBatchSize?(9)
        
        //addLayer
        layers = 3
        addNodeButton[0].isHidden = false
        subNodeButton[0].isHidden = false
        for i in 1...5 {
            addNodeButton[i].isHidden = true
            subNodeButton[i].isHidden = true
        }
        addLayerLabel.text = "隐藏层数：\(layers-2)"
        addLayerButton.isEnabled = true
        subLayerButton.isEnabled = true
        
        //addNode
        addNodeButton[0].isEnabled = true
        subNodeButton[0].isEnabled = true
        
        //dropDown
        learningRateDropView.showSelectedLabel?("0.03", 5)
        learningRateDropView.labelIsSelected = 5
        activationDropView.showSelectedLabel?("Tanh", 1)
        activationDropView.labelIsSelected = 1
        regularizationDropView.showSelectedLabel?("None", 0)
        regularizationDropView.labelIsSelected = 0
        regularizationRateDropView.showSelectedLabel?("0", 0)
        regularizationRateDropView.labelIsSelected = 0
    }
    
    // MARK: - Introduce
//    private lazy var introduceDropWebView: DropWebView = {
//        let view = DropWebView()
//        return view
//    }()
    var introduce: ((_ url: URL) -> Void)?
    @IBAction func IntroduceAction(_ sender: UIButton) {
//        if let window = self.window {
//            introduceDropWebView.showInView(window, button: sender, url: "https://ypwhs.gitbooks.io/nnplayground/content/")
//        }
        //        openURL(NSURL(string: "https://ypwhs.gitbooks.io/nnplayground/content/"))
        
        self.hide()
        introduce?(URL(string: "https://ypwhs.gitbooks.io/nnplayground/content/")!)
    }
    // MARK: - SetData
    var setCircleData: (() -> Void)?
    var setExclusiveOrData: (() -> Void)?
    var setGaussianData: (() -> Void)?
    var setSpiralData: (() -> Void)?
    
    @IBOutlet weak var setCircleButton: SelectDataButton!
    @IBOutlet weak var setExclusiveOrButton: SelectDataButton!
    @IBOutlet weak var setGaussianButton: SelectDataButton!
    @IBOutlet weak var setSpiralButton: SelectDataButton!
    func resetAlpha(_ sender: SelectDataButton) {
        let setDataButtons = [setCircleButton,setExclusiveOrButton,setGaussianButton,setSpiralButton]
        for i in setDataButtons {
            if i == sender {
                i?.isChosen = true
            }
            else {
                i?.isChosen = false
            }
        }
    }
    
    @IBAction func setCircle(_ sender: SelectDataButton) {
        setCircleData?()
        resetAlpha(sender)
    }
    @IBAction func setExclusiveOr(_ sender: SelectDataButton) {
        setExclusiveOrData?()
        resetAlpha(sender)
    }
    @IBAction func setGaussian(_ sender: SelectDataButton) {
        setGaussianData?()
        resetAlpha(sender)
    }
    @IBAction func setSpiral(_ sender: SelectDataButton) {
        setSpiralData?()
        resetAlpha(sender)
    }
    
    // MARK: - UISlider
    var setRatio: ((_ current: Int) -> Void)?
    var setNoise: ((_ current: Int) -> Void)?
    var setBatchSize: ((_ current: Int) -> Void)?
    
    @IBOutlet weak var setRatioSlider: EasySlider!
    @IBOutlet weak var setNoiseSlider: EasySlider!
    @IBOutlet weak var setBatchSizeSlider: EasySlider!
    @IBOutlet weak var setRatioLabel: UILabel!
    @IBOutlet weak var setNoiseLabel: UILabel!
    @IBOutlet weak var setBatchSizeLabel: UILabel!
    
    func setSpacing(_ sender: EasySlider, total: Float) -> Int {
        let spacing = (sender.maximumValue - sender.minimumValue)/total
        let num = Int(sender.value/spacing)
        sender.setValue(Float(num)*spacing, animated: true)
        return num
    }
    
    @IBAction func setRatioAction(_ sender: EasySlider) {
        let num = setSpacing(sender, total: 8)
        setRatio?(num)
        setRatioLabel.text = "训练数据百分比：\(num + 1)0%"
    }
    @IBAction func setNoiseAction(_ sender: EasySlider) {
        let num = setSpacing(sender, total: 10)
        setNoise?(num)
        setNoiseLabel.text = "噪声：\(num*5)"
    }
    @IBAction func setBatchSizeAction(_ sender: EasySlider) {
        let num = setSpacing(sender, total: 29)
        setBatchSize?(num)
        setBatchSizeLabel.text = "批量大小：\(num + 1)"
    }
    
    // MARK: - AddLayer
    var addLayer: (() -> Void)?
    @IBOutlet weak var addLayerLabel: UILabel!
    
    func addLayerButtons(_ sender:AddButton) {
        if sender.isAddButton && layers < 8 {
            layers += 1
            addLayer?()
            
//            hideAddButton(addNodeButton[layers - 3], hide: false)
//            hideAddButton(subNodeButton[layers - 3], hide: false)
            
//            transitionSender(addNodeButton[layers - 3], hide: false)
//            transitionSender(subNodeButton[layers - 3], hide: false)
            // duang
            for i in 0..<layers-3 {
                stretchTransition(addNodeButton[i], toLeft: true, changeHidden: false)
                stretchTransition(subNodeButton[i], toLeft: true, changeHidden: false)
            }
            
            if layers - 3 > 0 {
                stretchTransition(addNodeButton[layers - 3], toLeft: false, changeHidden: true)
                stretchTransition(subNodeButton[layers - 3], toLeft: false, changeHidden: true)
            }
            else {
                transitionSender(addNodeButton[layers - 3], hide: false)
                transitionSender(subNodeButton[layers - 3], hide: false)
            }
            
            // 锁死
            if layers != 3 {
                if !addNodeButton[layers - 4].isEnabled {
                    addNodeButton[layers - 3].isEnabled = false
                }
                else {
                    addNodeButton[layers - 3].isEnabled = true
                }
                if !subNodeButton[layers - 4].isEnabled {
                    subNodeButton[layers - 3].isEnabled = false
                }
                else {
                    subNodeButton[layers - 3].isEnabled = true
                }
            }
            else {
                addNodeButton[0].isEnabled = true
                subNodeButton[0].isEnabled = true
            }
        }
        if !sender.isAddButton && layers > 2 {
            layers -= 1
            addLayer?()
            
//            hideAddButton(addNodeButton[layers - 2], hide: true)
//            hideAddButton(subNodeButton[layers - 2], hide: true)
            
            // duang
            for i in 0..<layers-2 {
                stretchTransition(addNodeButton[i], toLeft: false, changeHidden: false)
                stretchTransition(subNodeButton[i], toLeft: false, changeHidden: false)
            }
            
            if layers - 2 > 0 {
                stretchTransition(addNodeButton[layers - 2], toLeft: true, changeHidden: true)
                stretchTransition(subNodeButton[layers - 2], toLeft: true, changeHidden: true)
            }
            else {
                hideAddButton(addNodeButton[layers - 2], hide: true)
                hideAddButton(subNodeButton[layers - 2], hide: true)
            }
        }
        
        if layers == 8 {
            addLayerButton.isEnabled = false
        }
        else {
            addLayerButton.isEnabled = true
        }
        if layers == 2 {
            subLayerButton.isEnabled = false
        }
        else {
            subLayerButton.isEnabled = true
        }
        addLayerLabel.text = "隐藏层数：\(layers-2)"
    }
    
    @IBOutlet weak var addLayerButton: AddButton!
    @IBOutlet weak var subLayerButton: AddButton!
    @IBAction func addLayerAction(_ sender: AddButton) {
        addLayerButtons(sender)
    }
    @IBAction func subLayerAction(_ sender: AddButton) {
        addLayerButtons(sender)
    }
    
    // MARK: - AddNode
    var addNode: ((_ layer: Int, _ num: Int) -> Int)?
    @objc func addNodeAction(_ sender:AddButton) {
        var num = 1
        var nodes = 4
        if sender.isAddButton {
            for i in addNodeButton {
                if i == sender {
                    nodes = addNode!(num, 1)
                    break
                }
                num += 1
            }
        }
        else {
            for i in subNodeButton {
                if i == sender {
                    nodes = addNode!(num, -1)
                    break
                }
                num += 1
            }
        }
        if nodes == 8 || nodes == 1 {
            sender.isEnabled = false
        }
        else{
            if sender.isAddButton {
                subNodeButton[num - 1].isEnabled = true
            }
            else {
                addNodeButton[num - 1].isEnabled = true
            }
        }
        
    }
    
    var addNodeButton: [AddButton] = {
        let view = AddButton()
        view.frame = CGRect(x: 50, y: 100, width: 30, height: 30)
        view.addTarget(self, action: #selector(addNodeAction), for: .touchUpInside)
        var views = [view]
        for i in 2...6 {
            let view = AddButton()
            view.frame = CGRect(x: i*50, y: 100, width: 30, height: 30)
            view.addTarget(self, action: #selector(addNodeAction), for: .touchUpInside)
            views.append(view)
        }
        
        return views
    }()
    
    var subNodeButton: [AddButton] = {
        let view = AddButton()
        view.frame = CGRect(x: 50, y: 150, width: 30, height: 30)
        view.isAddButton = false
        view.addTarget(self, action: #selector(addNodeAction), for: .touchUpInside)
        var views = [view]
        for i in 2...6 {
            let view = AddButton()
            view.isAddButton = false
            view.frame = CGRect(x: i*50, y: 150, width: 30, height: 30)
            view.addTarget(self, action: #selector(addNodeAction), for: .touchUpInside)
            views.append(view)
        }
        return views
    }()

    // MARK: - DropDown
    @IBOutlet weak var learningRateButton: DropDownButton!
    var setLearningRate: ((_ num: Int) -> Void)?
    fileprivate lazy var learningRateDropView: DropDownView = {
        let view = DropDownView()
        view.labelName = ["0.00001","0.0001","0.001","0.003","0.01","0.03","0.1","0.3","1","3","10"]
        view.showSelectedLabel = {(name: String, num: Int) in
            self.learningRateButton.setTitle(name, for: UIControl.State())
            view.hide()
            self.setLearningRate?(num)
        }
        view.labelIsSelected = 5
        return view
    }()
    @IBAction func learningRateDrop(_ sender: DropDownButton) {
        if let window = self.window {
            learningRateDropView.showInView(window,button: sender)
        }
    }
    
    
    @IBOutlet weak var activationButton: DropDownButton!
    var setActivation: ((_ num: Int) -> Void)?
    fileprivate lazy var activationDropView: DropDownView = {
        let view = DropDownView()
        view.labelName = ["ReLU","Tanh","Sigmoid","Linear"]
        view.showSelectedLabel = {(name: String, num: Int) in
            self.activationButton.setTitle(name, for: UIControl.State())
            view.hide()
            self.setActivation?(num)
        }
        view.labelIsSelected = 1
        return view
    }()
    @IBAction func activationDrop(_ sender: DropDownButton) {
        if let window = self.window {
            activationDropView.showInView(window,button: sender)
        }
    }
    
    
    @IBOutlet weak var regularizationButton: DropDownButton!
    var setRegularization: ((_ num: Int) -> Void)?
    fileprivate lazy var regularizationDropView: DropDownView = {
        let view = DropDownView()
        view.labelName = ["None","L1","L2"]
        view.showSelectedLabel = {(name: String, num: Int) in
            self.regularizationButton.setTitle(name, for: UIControl.State())
            view.hide()
            self.setRegularization?(num)
        }
        view.labelIsSelected = 0
        return view
    }()
    @IBAction func regularizationDrop(_ sender: DropDownButton) {
        if let window = self.window {
            regularizationDropView.showInView(window,button: sender)
        }
    }
    
    
    @IBOutlet weak var regularizationRateButton: DropDownButton!
    var setRegularizationRate: ((_ num: Int) -> Void)?
    fileprivate lazy var regularizationRateDropView: DropDownView = {
        let view = DropDownView()
        view.labelName = ["0","0.001","0.003","0.01","0.03","0.1","0.3","1","3","10"]
        view.showSelectedLabel = {(name: String, num: Int) in
            self.regularizationRateButton.setTitle(name, for: UIControl.State())
            view.hide()
            self.setRegularizationRate?(num)
        }
        view.labelIsSelected = 0
        return view
    }()
    @IBAction func regularizationRateDrop(_ sender: DropDownButton) {
        if let window = self.window {
            regularizationRateDropView.showInView(window,button: sender)
        }
    }
        
    //MARK: - View
    func showInView(_ view:UIView) {
        frame = view.bounds
        view.addSubview(self)
        
        layoutIfNeeded()
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseIn, animations: { 
            self.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        }, completion: { _ in
        })
        
    }
    
    @objc func hide() {
        UIView.animate(withDuration: 0.2, delay: 0.1, options: .curveEaseOut, animations: { 
            self.backgroundColor = UIColor.clear
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
        
        setCircleButton.isChosen = true
        
        let setDataButtonWidth = NSLayoutConstraint(item: setCircleButton!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: buttonWidth + 10)
        let addLayerButtonWidth = NSLayoutConstraint(item: addLayerButton!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: buttonWidth)
        NSLayoutConstraint.activate([setDataButtonWidth,addLayerButtonWidth])
        
        self.layoutIfNeeded()
        
        subNodeButtonY = setRatioSlider.frame.minY
        for i in 0...5 {
            self.addSubview(addNodeButton[i])
            (addNodeButton[i] as AddButton).frame.origin = CGPoint(x: (addNodeButton[i] as AddButton).frame.minX, y: subNodeButtonY + 2 * buttonWidth)
            self.addSubview(subNodeButton[i])
            (subNodeButton[i] as AddButton).frame.origin = CGPoint(x: (subNodeButton[i] as AddButton).frame.minX, y: subNodeButtonY)
            if i != 0 {
                addNodeButton[i].isHidden = true
                subNodeButton[i].isHidden = true
            }
        }
        
    }
    
}

extension SpreadView: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view != self {
            return false
        }
        return true
    }
    
}
