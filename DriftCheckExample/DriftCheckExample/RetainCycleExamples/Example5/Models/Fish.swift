//
//  Fish.swift
//  DriftCheckExample
//
//  Created by Chris Mays on 3/30/25.
//

import Foundation

struct Fish: Identifiable, Equatable, Hashable {
    let id = UUID()
    let emoji: String
    let size: CGFloat
    let appearTime: TimeInterval
    let speed: CGFloat
    let startY: CGFloat
    let waveAmp: CGFloat
    let waveFreq: CGFloat
    let flip: Bool
    
    static func == (lhs: Fish, rhs: Fish) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
