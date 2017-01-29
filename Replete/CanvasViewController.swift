//
//  CanvasViewController.swift
//  Replete
//
//  Created by Ethan Sherbondy on 1/29/17.
//  Copyright © 2017 FikesFarm. All rights reserved.
//

import UIKit

class CanvasViewController: UIViewController, UIGestureRecognizerDelegate {
    
    var canvasView: EJJavaScriptView!
    var lastPoint: CGPoint = CGPoint(x: 0, y: 0)
    var lastScale: CGFloat = 0.0
    var initialSize: CGSize = CGSize(width: 60, height: 80)

    override func loadView() {
        super.loadView()

        // Do any additional setup after loading the view.
        
        let viewFrame = CGRect(
            x: view.bounds.width - 80, y: 20,
            width: initialSize.width, height: initialSize.height
        )
        
        self.view = UIView.init(frame: viewFrame)
        self.view.backgroundColor = UIColor.gray
        
        let canvasFrame = CGRect(x: 0, y: 0, width: initialSize.width, height: initialSize.height)

        canvasView = EJJavaScriptView(frame: canvasFrame, appFolder: "out/")
        // initially disable interaction
        canvasView.isUserInteractionEnabled = false
        canvasView.translatesAutoresizingMaskIntoConstraints = true
        
        let panR = UIPanGestureRecognizer.init(target: self, action: #selector(handlePan))
        panR.cancelsTouchesInView = true
        panR.delegate = self
        
        let tapR = UILongPressGestureRecognizer.init(target: self, action: #selector(handleTap))
        tapR.minimumPressDuration = 0
        tapR.cancelsTouchesInView = true
        tapR.delegate = self
        
        let pinchR = UIPinchGestureRecognizer.init(target: self, action: #selector(handlePinch))
        pinchR.cancelsTouchesInView = true
        pinchR.delegate = self
        
        self.view.addGestureRecognizer(panR)
        self.view.addGestureRecognizer(tapR)
        self.view.addGestureRecognizer(pinchR)
        
        self.view.addSubview(canvasView)
    }
    
    override func viewDidLoad() {
        canvasView.loadScript(atPath: "index.js")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func jsContext() -> JSGlobalContextRef {
        return self.canvasView.jsGlobalContext
    }
    
    
    // Gesture Recognizer Delegate Methods
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive press: UIPress) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }
    
    // gesture handlers and helpers
    
    func showShadow() {
        self.view.layer.shadowColor = UIColor.black.cgColor
        self.view.layer.shadowOpacity = 0.75
        self.view.layer.shadowRadius = 10
    }
    
    func hideShadow() {
        self.view.layer.shadowRadius = 0
    }
    
    func handleShadow(gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == .began {
            showShadow()
        } else if gestureRecognizer.state == .ended {
            hideShadow()
        }
    }
    
    @IBAction func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        handleShadow(gestureRecognizer: gestureRecognizer)
    }
    
    func handleTranslate(gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == .began {
            lastPoint = gestureRecognizer.location(in: self.view)
        }
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            let location = gestureRecognizer.location(in: self.view)
            // note: 'view' is optional and need to be unwrapped
            self.view.transform = self.view.transform.translatedBy(
                x: (location.x - lastPoint.x),
                y: (location.y - lastPoint.y)
            )
            lastPoint = gestureRecognizer.location(in: self.view)
        }
    }

    
    @IBAction func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        handleTranslate(gestureRecognizer: gestureRecognizer)
        handleShadow(gestureRecognizer: gestureRecognizer)
    }
    
    @IBAction func handlePinch(_ gestureRecognizer: UIPinchGestureRecognizer) {
        if gestureRecognizer.state == .began {
            lastScale = gestureRecognizer.scale
        }
        
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            let currentScale = CGFloat((self.view.layer.value(forKeyPath: "transform.scale") as! NSNumber))
            let maxScale = CGFloat(3.0)
            let minScale = CGFloat(1.0)
            
            let initialScale = 1.0 - (lastScale - gestureRecognizer.scale)
            let newScale = max(
                min(initialScale, maxScale/currentScale),
                minScale/currentScale
            )
            
            self.view.transform = self.view.transform.scaledBy(x: newScale, y: newScale)
            
            let newSize = self.view.frame.size.applying(
                CGAffineTransform.init(scaleX: newScale, y: newScale)
            )
            
            if lastScale != newScale {
                let oldFrame = canvasView.frame
                let newFrame = CGRect(
                    origin: oldFrame.origin,
                    size: newSize
                )
                // HMM, this does not actually make the js/window or js/canvas
                // sizes change... not quite sure how this works.
                // maybe we need to trigger a resize event on the js context?
                canvasView.frame = newFrame
                lastScale = newScale
            }
        }
        
        handleTranslate(gestureRecognizer: gestureRecognizer)
        handleShadow(gestureRecognizer: gestureRecognizer)
        
        if gestureRecognizer.state == .ended {
            canvasView.layoutIfNeeded()
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
