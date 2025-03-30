//
//  UIView+AnchorPoint.swift
//  RetainDetector
//
//  Created by Chris Mays on 3/23/25.
//

import UIKit

extension UIView: PrivateAnchorPoint {
    
    static func startRetainCycleDetector() {
        swizzleViewDidDisappearImplementation
    }
    
    static let swizzleViewDidDisappearImplementation: Void = {
        let originalSelector = #selector(didMoveToWindow)
        let swizzledSelector = #selector(swizzled_didMoveToWindow)

        guard
            let originalMethod = class_getInstanceMethod(UIView.self, originalSelector),
            let swizzledMethod = class_getInstanceMethod(UIView.self, swizzledSelector)
        else {
            return
        }

        method_exchangeImplementations(originalMethod, swizzledMethod)
    }()

    @objc func swizzled_didMoveToWindow() {
        self.swizzled_didMoveToWindow()
        if self.window == nil {
            self.prepareToCheckStatus()
        }
    }
    
    @MainActor func prepareToCheckStatus() -> Void {
        self.updateStatus(retentionMode: retentionMode)
    }

    @MainActor func children() -> [PrivateAnchorPoint] {
        self.subviews
    }
}
