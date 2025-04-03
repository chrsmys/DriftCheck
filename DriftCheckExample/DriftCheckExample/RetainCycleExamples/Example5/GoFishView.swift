//
//  GoFishView.swift
//  RetainCycleDetector
//
//  Created by Chris Mays on 3/25/25.
//

import SwiftUI

struct GoFishView: View {
    @State var viewModel: GoFishViewModel = .init()
    @State var isPresented: Bool = false
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            Button {
                isPresented = true
            } label: {
                Text("🎣 View Catch")
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(.yellow)
                    .foregroundColor(.black)
                    .font(.headline)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 12)
        .background {
            ZStack {
                OceanFloorView()
                SwimmingFishView(fishes: viewModel.fish) {
                    viewModel.catchFish($0)
                }
                Color.blue.opacity(0.3)
                    .allowsHitTesting(false)
                WaterView(renderer: viewModel.waterRenderer)
                    .allowsHitTesting(false)
                
            }
            
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged({ value in
                        viewModel.makeRipple(value.location)
                    })
            )
            .ignoresSafeArea(.all)
            
        }
        .tint(.white)
        .sheet(isPresented: $isPresented) {
            VStack(alignment: .leading) {
                Text("🪝 Caught Fish: \(viewModel.caughtFish.count)")
                    .frame(maxWidth: .infinity)
                    .font(.title2)
                
                Text(viewModel.caughtFish.joined(separator: ""))
                    .font(.title)
                Spacer()
            }
            .padding(20)
            .presentationDetents([.medium, .large])
        }
        .navigationTitle(Text("🪝 Caught Fish: \(viewModel.caughtFish.count)"))
        .tether(viewModel)
    }
}
