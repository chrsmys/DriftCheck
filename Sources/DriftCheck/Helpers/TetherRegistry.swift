//
//  TetherRegistry.swift
//  DriftCheck
//
//  Created by Chris Mays on 3/25/25.
//

import Foundation

class TetherRegistry {
    private(set) var registry: [String: Set<WeakContainer>] = [:]
    private(set) var reverseRegistry: [String: Set<String>] = [:]
    
    func register(_ item: AnyObject, anchor: AnchorPoint) {
        let anchorId = hexAddress(anchor)
        let itemID = hexAddress(item)
        
        var content = registry[anchorId] ?? []
        content.insert(.init(item: item))
        registry[anchorId] = content
        
        var set = reverseRegistry[itemID, default: []]
        set.insert(anchorId)
        reverseRegistry[itemID] = set
    }
    
    func unregister(_ item: AnyObject, anchor: AnchorPoint) {
        let anchorId = hexAddress(anchor)
        let itemID = hexAddress(item)
        
        var content = registry[anchorId] ?? []
        content = content.filter {
            $0.id != itemID
        }
        registry[anchorId] = content
        
        var set = reverseRegistry[itemID, default: []]
        set.remove(anchorId)
        reverseRegistry[itemID] = set
    }
    
    func hasTethers(_ anchor: AnchorPoint) -> Bool {
        tethers(anchor).isEmpty == false
    }
    
    func tethers(_ anchor: AnchorPoint) -> Set<WeakContainer> {
        registry[hexAddress(anchor), default: .init()]
    }
    
    func isAnchored(_ item: AnyObject) -> Bool {
        anchors(item).isEmpty == false
    }
    
    func anchors(_ item: AnyObject) -> Set<String> {
        reverseRegistry[hexAddress(item), default: .init()]
    }
    
    func popFrom(anchorId: String) -> WeakContainer? {
        guard let weakObject = registry[anchorId]?.first else { return nil }
        
        registry[anchorId] = registry[anchorId, default: []].filter({
            $0.id != weakObject.id
        })
        
        var newSet = reverseRegistry[weakObject.id, default: []]
        newSet.remove(anchorId)
        if newSet.isEmpty {
            reverseRegistry.removeValue(forKey: weakObject.id)
        } else {
            reverseRegistry[weakObject.id] = newSet
        }
        
        return weakObject
    }
}
