//
//  GrogViewModifier.swift
//  DriftCheckExample
//
//  Created by Chris Mays on 3/30/25.
//

import SwiftUI

struct GrogDistortion: ViewModifier {
    let intensity: CGFloat

    @State var startTime: Date = .init()

    func body(content: Content) -> some View {
        TimelineView(.animation) { context in
            content
                .visualEffect { content, proxy in
                    content.distortionEffect(
                        ShaderLibrary.default.grogDistortion(
                            .float(startTime.timeIntervalSinceNow),
                            .float2(proxy.size),
                            .float(Float(intensity * 0.4))
                        ),
                        maxSampleOffset: CGSize(width: 200, height: 200)
                    )
                }
        }
    }
}

extension View {
    func grogDistortion(intensity: CGFloat) -> some View {
        self.modifier(GrogDistortion(intensity: intensity))
    }
}
