//
//  SwimmingFishView.swift
//  DriftCheckExample
//
//  Created by Chris Mays on 3/30/25.
//

import SwiftUI

struct SwimmingFishView: View {
    let fishes: [Fish]
    
    var onCatch: (Fish) -> Void
    @State var startDate = Date()
    
    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                ZStack {
                    ForEach(fishes) { fish in
                        let currentTime = timeline.date.timeIntervalSince1970
                        let time = currentTime - fish.appearTime
                        
                        let normalized = time >= 0 ? (time * fish.speed * 0.2).truncatingRemainder(dividingBy: 1.0) : 0
                        let progress = -0.2 + (normalized * 1.4)
                        let x = fish.flip
                        ? geo.size.width * (1.0 - progress)
                        : geo.size.width * progress
                        
                        let y = (fish.startY * geo.size.height) + sin(progress * 2 * .pi * fish.waveFreq) * fish.waveAmp
                        
                        Text(fish.emoji)
                            .font(.system(size: fish.size))
                            .scaleEffect(x: !fish.flip ? -1 : 1, y: 1)
                            .position(x: x, y: y)
                            .simultaneousGesture(
                                TapGesture()
                                    .onEnded({ _ in
                                        onCatch(fish)
                                    })
                            )
                            .visualEffect { content, proxy in
                                content
                                    .distortionEffect(ShaderLibrary.complexWave(
                                        .float(startDate.timeIntervalSinceNow),
                                        .float2(proxy.size),
                                        .float(0.5),
                                        .float(8),
                                        .float(8)
                                    ), maxSampleOffset: CGSize(width: 20, height: 20))
                            }
                    }
                }
            }
        }
    }
}
