//
//  LifecycleDetector.swift
//  RetainDetector
//
//  Created by Chris Mays on 3/24/25.
//

import UIKit

class DeinitDetector {
    var onDeinit: () -> Void
    init(onDeinit: @escaping () -> Void) {
        self.onDeinit = onDeinit
    }
    
    func decommission() {
        onDeinit = {}
    }
    
    deinit {
        onDeinit()
    }
}

