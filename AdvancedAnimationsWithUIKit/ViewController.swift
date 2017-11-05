//
//  ViewController.swift
//  AdvancedAnimationsWithUIKit
//
//  Created by Leaf on 2017/11/4.
//  Copyright © 2017年 leaf. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let animationView = UIView()
    let blurEffectView = UIVisualEffectView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        blurEffectView.frame = view.bounds
        view.addSubview(blurEffectView)
        
        animationView.backgroundColor = UIColor.red
        view.addSubview(animationView)
        animationView.frame = CGRect(x: 0, y: view.frame.height-44, width: view.frame.width, height: view.frame.height)
        
        animationView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
        animationView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan)))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    enum State {
        case Expanded
        case Collapsed
    }
    
    var state = State.Expanded
    
    
    var runningAnimators = [UIViewPropertyAnimator]()
    
    @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
        
        animateOrReverseRunningTransition(state: state, duration: 1)
    }
    
    @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
        
        switch recognizer.state {
        case .began:
            startInteractiveTransition(state: state, duration: 1)
            
        case .changed:
            var translation = recognizer.translation(in: animationView)
            if state == .Expanded {
                translation.y = -translation.y
            }
            updateInteractiveTransition(fractionComplete: translation.y/(self.view.frame.height-44))
            
        case .ended:
            
            continueInteractiveTransition(cancel: false)
            
        default : break
            
        }
    }
    //开始动画
    func animateTransitionIfNeeded(state: State, duration: TimeInterval) {
        if runningAnimators.isEmpty {
            let frameAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1, animations: {

                switch state {
                case .Collapsed:
                    self.animationView.frame = CGRect(x: 0, y: self.view.frame.height-44, width: self.view.frame.width, height: self.view.frame.height)
                case .Expanded:
                    self.animationView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
                }
            })
            frameAnimator.addCompletion({ (UIViewAnimatingPosition) in
                self.runningAnimators.removeAll()
                if UIViewAnimatingPosition == .end {
                    switch state {
                    case .Expanded:
                        self.state = .Collapsed
                    case .Collapsed:
                        self.state = .Expanded
                    }
                }
            })
            frameAnimator.startAnimation()
            runningAnimators.append(frameAnimator)
            
            let timing : UITimingCurveProvider
            switch state {
            case .Expanded:
                timing = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.75, y: 0.1),
                                                 controlPoint2: CGPoint(x: 0.9, y: 0.25))
            case .Collapsed:
                timing = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.1, y: 0.75),
                                                 controlPoint2: CGPoint(x: 0.25, y: 0.9))
            }
            let blurAnimator = UIViewPropertyAnimator(duration: duration, timingParameters: timing)
            blurAnimator.scrubsLinearly = false
            blurAnimator.addAnimations {
                switch state {
                case .Expanded:
                    self.blurEffectView.effect = UIBlurEffect(style: .dark)
                case .Collapsed:
                    self.blurEffectView.effect = nil
                }
            }
            blurAnimator.startAnimation()
            runningAnimators.append(blurAnimator)
        }
    }
    //转变动画方向
    func animateOrReverseRunningTransition(state: State, duration: TimeInterval) {
        if runningAnimators.isEmpty {
            animateTransitionIfNeeded(state: state, duration: duration)
        } else {
            for animator in runningAnimators {
                animator.isReversed = !animator.isReversed
            }
        }
    }
    
    var progressWhenInterrupted: CGFloat = 0
    
    //开始交互变化
    func startInteractiveTransition(state: State, duration: TimeInterval) {
        if runningAnimators.isEmpty {
            animateTransitionIfNeeded(state: state, duration: duration)
        }
        for animator in runningAnimators {
            animator.pauseAnimation()
            progressWhenInterrupted = animator.fractionComplete
        }
    }
    //更新交互变化
    func updateInteractiveTransition(fractionComplete: CGFloat) {
        for animator in runningAnimators {
            animator.fractionComplete = fractionComplete + progressWhenInterrupted
        }
    }
    //继续动画
    func continueInteractiveTransition(cancel: Bool) {
        for animator in runningAnimators {
            animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
            if animator.fractionComplete < 0.2 {
                animator.isReversed = !animator.isReversed
            }
        }
    }
}

