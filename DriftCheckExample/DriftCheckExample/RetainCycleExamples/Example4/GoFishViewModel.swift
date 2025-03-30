//
//  GoFishViewModel.swift
//  DriftCheckExample
//
//  Created by Chris Mays on 3/30/25.
//

import SwiftUI

@Observable
class GoFishViewModel {
    let waterRenderer = WaterRenderer()
    var fish: [Fish] = []
    var caughtFish: [String] = []
    private let fishTypes = ["🐟", "🐠", "🐡", "🦈", "🦑", "🦐", "🐙", "🪼", "🦞"]

    init() {
        loadFish(count: Int.random(in: 6...15))
    }
    
    private func loadFish(count: Int) {
        (0..<count).forEach { _ in
            self.fish.append(Fish(
                emoji: fishTypes.randomElement()!,
                size: CGFloat.random(in: 24...42),
                appearTime: Date().timeIntervalSince1970 + CGFloat.random(in: 1...9),
                speed: CGFloat.random(in: 0.2...1.0),
                startY: CGFloat.random(in: 0.2...0.8),
                waveAmp: CGFloat.random(in: 10...30),
                waveFreq: CGFloat.random(in: 0.5...1.5),
                flip: Bool.random()
            ))
        }
    }

    @ObservationIgnored lazy var catchFish: ((_ fish: Fish)->Void) = { fish in
        self.fish.removeAll(where: { $0.id == fish.id})
        self.caughtFish.append(fish.emoji)
        
        if self.fish.count < 10 {
            self.loadFish(count: Int.random(in: 2...5))
        }
    }

    @ObservationIgnored lazy var makeRipple: ((_ location: CGPoint)->Void) = { location in
        self.waterRenderer.injectRipple(at: location)
    }
}
