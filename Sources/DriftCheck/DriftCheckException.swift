//
//  DriftCheckException.swift
//  DriftCheck
//
//  Created by Chris Mays on 3/26/25.
//

import Foundation

/// An exception that is fired when an item is left past it's retentionMode
public struct DriftCheckException {
    
    /// The anchor that triggered the warning
    public let anchorItem: Item
    
    /// The tethered items that were still in memory at the time the exception was triggered.
    public let tetheredItems: [Item]
    
    /// Metadata about an Object.
    public struct Item {
        /// The hex address for the item
        public let id: String
        
        /// The human readable type for the item
        public let type: String
        
        /// Whether the item was in memory at the time of exception
        public let retained: Bool
        
        /// A weak reference to the item.
        /// Note: Since this is a weak reference it is not guaranteed to have a value even if retained is true.
        public weak var item: AnyObject?
        
        /// A string representation of the item. Type<Hex Address>
        public var message: String {
            return "\(type)<\(id)>"
        }
    }
    
    /// A human readable explantion for the exception.
    public var message: String {
        var message = ""
        if anchorItem.retained {
            message = "⚓️ \(anchorItem.message) still exists past it's retention plan."
            if !tetheredItems.isEmpty {
                message += "\nSome tethered objects still remain:"
                message += "\n\(tetheredItems.map{"🛟 " + $0.message}.joined(separator: "\n"))"
            }
        } else {
            tetheredItems.forEach {
                message += "🛟 DriftCheck: Detected lingering object \($0.type)<\($0.id)> that exists past anchor's (\(anchorItem.type)<\(anchorItem.id)>) retention plan."
            }
        }
        return message
    }
}
