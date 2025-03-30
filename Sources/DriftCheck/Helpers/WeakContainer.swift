//
//  WeakContainer.swift
//  RetainDetector
//
//  Created by Chris Mays on 3/25/25.
//

import Foundation

struct WeakContainer: Equatable, Hashable {
    weak var item: AnyObject?
    var id: String
    
    init(item: AnyObject) {
        self.item = item
        self.id = hexAddress(item)
    }
    
    static func == (lhs: WeakContainer, rhs: WeakContainer) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
