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
    
    @IBAction func Regenerate(sender: UIButton) {
        //setData
        setCircleData?()
        resetAlpha(setCircleButton)
        
        //slider
        setRatioSlider.setValue(0.5, animated: true)
        setNoiseSlider.setValue(0, animated: true)
        setBatchSizeSlider.setValue(0.333333333, animated: true)
        
        //addLayer
        layers = 3
        addLayer?()
        addNodeButton[0].hidden = false
        subNodeButton[0].hidden = false
        for i in 1...5 {
            addNodeButton[i].hidden = true
            subNodeButton[i].hidden = true
        }
        
        //addNode
        
        //dropDown
        learningRateDropView.showSelectedLabel?(name: "0.03", num: 5)
        learningRateDropView.labelIsSelected = 5
        activationDropView.showSelectedLabel?(name: "Tanh", num: 1)
        activationDropView.labelIsSelected = 1
        regularizationDropView.showSelectedLabel?(name: "None", num: 0)
        regularizationDropView.labelIsSelected = 0
        regularizationRateDropView.showSelectedLabel?(name: "0", num: 0)
        regularizationRateDropView.labelIsSelected = 0
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
    func resetAlpha(sender: SelectDataButton) {
        let setDataButtons = [setCircleButton,setExclusiveOrButton,setGaussianButton,setSpiralButton]
        for i in setDataButtons {
            if i == sender {
                i.isChosen = true
            }
            else {
                i.isChosen = false
            }
        }
    }
    
    @IBAction func setCircle(sender: SelectDataButton) {
        setCircleData?()
        resetAlpha(sender)
    }
    @IBAction func setExclusiveOr(sender: SelectDataButton) {
        setExclusiveOrData?()
        resetAlpha(sender)
    }
    @IBAction func setGaussian(sender: SelectDataButton) {
        setGaussianData?()
        resetAlpha(sender)
    }
    @IBAction func setSpiral(sender: SelectDataButton) {
        setSpiralData?()
        resetAlpha(sender)
    }
    
    // MARK: - UISlider
    var setRatio: ((current: Int) -> Void)?
    var setNoise: ((current: Int) -> Void)?
    var setBatchSize: ((current: Int) -> Void)?
    
    @IBOutlet weak var setRatioSlider: EasySlider!
    @IBOutlet weak var setNoiseSlider: EasySlider!
    @IBOutlet weak var setBatchSizeSlider: EasySlider!
    
    func setSpacing(sender: EasySlider, total: Float) -> Int {
        let spacing = (sender.maximumValue - sender.minimumValue)/total
        let num = Int(sender.value/spacing)
        sender.setValue(Float(num)*spacing, animated: true)
        return num
    }
    
    @IBAction func setRatioAction(sender: EasySlider) {
        setRatio?(current: setSpacing(sender, total: 10))
    }
    @IBAction func setNoiseAction(sender: EasySlider) {
        setNoise?(current: setSpacing(sender, total: 10))
    }
    @IBAction func setBatchSizeAction(sender: EasySlider) {
        setBatchSize?(current: setSpacing(sender, total: 30))
    }
    
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
        addLayer?()
    }
    
    @IBOutlet weak var addLayerButtons: AddButton!
    @IBAction func addLayerButton(sender: AddButton) {
        addLayerButtons(sender)
    }
    @IBAction func subLayerButton(sender: AddButton) {
        addLayerButtons(sender)
    }
    
    // MARK: - AddNode
    var addNode: ((layer: Int, isAdd: Bool) -> Void)?
    func addNodeAction(sender:AddButton) {
        var num = 1
        for i in addNodeButton {
            if i == sender {
                addNode?(layer: num, isAdd: true)
            }
            num += 1
        }
    }
    func subNodeAction(sender:AddButton) {
        var num = 1
        for i in subNodeButton {
            if i == sender {
                addNode?(layer: num, isAdd: false)
            }
            num += 1
        }
    }
    lazy var addNodeButton: [AddButton] = {
        let view = AddButton()
        view.frame = CGRect(x: 50, y: 100, width: 30, height: 30)
        view.addTarget(self, action: #selector(addNodeAction), forControlEvents: .TouchUpInside)
        var views = [view]
        for i in 2...6 {
            let view = AddButton()
            view.frame = CGRect(x: i*50, y: 100, width: 30, height: 30)
            view.addTarget(self, action: #selector(addNodeAction), forControlEvents: .TouchUpInside)
            views.append(view)
        }
        return views
    }()
    
    lazy var subNodeButton: [AddButton] = {
        let view = AddButton()
        view.frame = CGRect(x: 50, y: 150, width: 30, height: 30)
        view.isAddButton = false
        view.addTarget(self, action: #selector(subNodeAction), forControlEvents: .TouchUpInside)
        var views = [view]
        for i in 2...6 {
            let view = AddButton()
            view.isAddButton = false
            view.frame = CGRect(x: i*50, y: 150, width: 30, height: 30)
            view.addTarget(self, action: #selector(subNodeAction), forControlEvents: .TouchUpInside)
            views.append(view)
        }
        return views
    }()

    // MARK: - DropDown
    @IBOutlet weak var learningRateButton: DropDownButton!
    var setLearningRate: ((num: Int) -> Void)?
    private lazy var learningRateDropView: DropDownView = {
        let view = DropDownView()
        view.labelName = ["0.00001","0.0001","0.001","0.003","0.01","0.03","0.1","0.3","1","3","10"]
        view.showSelectedLabel = {(name: String, num: Int) in
            self.learningRateButton.setTitle(name, forState: .Normal)
            view.hide()
            self.setLearningRate?(num: num)
        }
        view.labelIsSelected = 5
        return view
    }()
    @IBAction func learningRateDrop(sender: DropDownButton) {
        if let window = self.window {
            learningRateDropView.showInView(window,button: sender)
        }
    }
    
    
    @IBOutlet weak var activationButton: DropDownButton!
    var setActivation: ((num: Int) -> Void)?
    private lazy var activationDropView: DropDownView = {
        let view = DropDownView()
        view.labelName = ["ReLU","Tanh","Sigmoid","Linear"]
        view.showSelectedLabel = {(name: String, num: Int) in
            self.activationButton.setTitle(name, forState: .Normal)
            view.hide()
            self.setActivation?(num: num)
        }
        view.labelIsSelected = 1
        return view
    }()
    @IBAction func activationDrop(sender: DropDownButton) {
        if let window = self.window {
            activationDropView.showInView(window,button: sender)
        }
    }
    
    
    @IBOutlet weak var regularizationButton: DropDownButton!
    var setRegularization: ((num: Int) -> Void)?
    private lazy var regularizationDropView: DropDownView = {
        let view = DropDownView()
        view.labelName = ["None","L1","L2"]
        view.showSelectedLabel = {(name: String, num: Int) in
            self.regularizationButton.setTitle(name, forState: .Normal)
            view.hide()
            self.setRegularization?(num: num)
        }
        view.labelIsSelected = 0
        return view
    }()
    @IBAction func regularizationDrop(sender: DropDownButton) {
        if let window = self.window {
            regularizationDropView.showInView(window,button: sender)
        }
    }
    
    
    @IBOutlet weak var regularizationRateButton: DropDownButton!
    var setRegularizationRate: ((num: Int) -> Void)?
    private lazy var regularizationRateDropView: DropDownView = {
        let view = DropDownView()
        view.labelName = ["0","0.001","0.003","0.01","0.03","0.1","0.3","1","3","10"]
        view.showSelectedLabel = {(name: String, num: Int) in
            self.regularizationRateButton.setTitle(name, forState: .Normal)
            view.hide()
            self.setRegularizationRate?(num: num)
        }
        view.labelIsSelected = 0
        return view
    }()
    @IBAction func regularizationRateDrop(sender: DropDownButton) {
        if let window = self.window {
            regularizationRateDropView.showInView(window,button: sender)
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
        setCircleButton.isChosen = true
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
