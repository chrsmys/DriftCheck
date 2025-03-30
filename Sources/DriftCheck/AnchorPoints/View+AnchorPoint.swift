//
//  RetainAnchor+View.swift
//  RetainDetector
//
//  Created by Chris Mays on 3/23/25.
//

import SwiftUI

extension View {
    /// View modifier to tether an object to a SwiftUIView.
    public func tether(_ object: AnyObject) -> some View {
        self.modifier(
            AnchorPointViewModifier(object: object)
        )
    }
}

struct AnchorPointViewModifier: ViewModifier {
    let object: AnyObject
    func body(content: Content) -> some View {
        content.background(
            AnchorPointView(obj: object)
        )
    }
}

struct AnchorPointView: UIViewRepresentable {
    let obj: AnyObject
    
    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator()
        return coordinator
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.tether(obj)
        context.coordinator.lastPin = obj
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if context.coordinator.lastPin !== obj{
            if let lastPin = context.coordinator.lastPin {
                uiView.untether(lastPin)
            }
            uiView.tether(obj)
        }
    }
    
    class Coordinator {
        weak var lastPin: AnyObject?
    }
}
