//
//  RetainAnchor+UIViewController.swift
//  RetainDetector
//
//  Created by Chris Mays on 3/23/25.
//

import UIKit

class Controller: UIViewController {
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        print("Controller didMove(toParent:)")
    }
}

extension UIViewController: PrivateAnchorPoint {
    
    static func startRetainCycleDetector() {
        swizzleViewDidDisappearImplementation
    }
    
    static let swizzleViewDidDisappearImplementation: Void = {
        let originalSelector = #selector(viewDidDisappear(_:))
        let swizzledSelector = #selector(swizzled_viewDidDisappear(_:))
        
        guard
            let originalMethod = class_getInstanceMethod(UIViewController.self, originalSelector),
            let swizzledMethod = class_getInstanceMethod(UIViewController.self, swizzledSelector)
        else {
            return
        }

        method_exchangeImplementations(originalMethod, swizzledMethod)
    }()

    @objc func swizzled_viewDidDisappear(_ animated: Bool) {
        swizzled_viewDidDisappear(animated)
        prepareToCheckStatus()
    }
    
    func prepareToCheckStatus() {
        let retentionMode = retentionMode
        if retentionMode != .optOut {
            self.tether(self.view)
        }
        self.updateStatus(retentionMode: retentionMode)
    }

    @MainActor func children() -> [PrivateAnchorPoint] {
        self.children + [self.view]
    }
}
