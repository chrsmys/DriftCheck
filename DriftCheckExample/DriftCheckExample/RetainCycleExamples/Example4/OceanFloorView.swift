//
//  OceanFloorView.swift
//  DriftCheckExample
//
//  Created by Chris Mays on 3/30/25.
//

import SwiftUI

struct OceanFloorView: View {
    @State var startDate: Date = Date()
    var body: some View {
        ZStack(alignment: .center) {
            Color.blue
            TimelineView(.animation) { context in
                Image(systemName: "sailboat")
                    .font(.system(size: 300))
                    .visualEffect { content, proxy in
                        content
                            .distortionEffect(ShaderLibrary.complexWave(
                                .float(startDate.timeIntervalSinceNow),
                                .float2(proxy.size),
                                .float(0.5),
                                .float(8),
                                .float(10)
                            ), maxSampleOffset: .init(width: 50, height: 50))
                    }
            }
        }
    }
}
