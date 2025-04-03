//
//  GrogCounterViewController.swift
//  RetainCycleDetector
//
//  Created by Chris Mays on 3/25/25.
//

import SwiftUI

class GrogCounterViewController: UIViewController {
    lazy var hostingView = UIHostingConfiguration {
        GrogCounterView {
            self.dismiss(animated: true)
        }
    }
        .margins(.all, 0)
        .makeContentView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        self.title = "Grog Counter"
        self.hostingView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(hostingView)
        tether(hostingView)
        self.hostingView.pin(to: self.view)
    }
}

struct GrogCounterView: View {
    @State var grogsDrank: [String] = []
    
    let drinkOptions: [String] = [
        "🍺",
        "🍻",
        "🍷",
        "🥂",
        "🥃",
        "🍸",
        "🍹",
        "🍾",
        "🧃",
        "🧉",
        "☕️",
        "🥤",
        "🧋"
    ]
    
    let callItQuitsAction: ()->Void
    @State var startDate: Date = Date()
    
    var body: some View {
        VStack {
            let intensity = 0.03 * CGFloat(grogsDrank.count)
            if grogsDrank.isEmpty {
                Spacer()
                Text("🏝️")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 125))
                    .minimumScaleFactor(0.5)
                Spacer()
            } else {
                ScrollView {
                    Text(grogsDrank.joined(separator: ""))
                        .frame(maxHeight: .infinity)
                        .font(.system(size: 50))
                        .blur(radius: 6 * intensity)
                        .grogDistortion(intensity: intensity)
                }
                .frame(maxHeight: .infinity)
                .scrollClipDisabled()
                Spacer()
            }
            Button {
                grogsDrank.append(drinkOptions.randomElement() ?? "")
            } label: {
                Text(grogsDrank.isEmpty ? "Have a drink" : "Another One For Me")
                    .blur(radius: 6 * intensity)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity)
                    .background(.yellow)
                    .foregroundColor(.black)
                    .font(.headline)
                    .clipShape(Capsule())
            }
            .grogDistortion(intensity: intensity)
            
            Button {
                callItQuitsAction()
            } label: {
                Text("Call it quits (for now)")
                    .blur(radius: 6 * intensity)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(.red)
                    .foregroundColor(.black)
                    .font(.headline)
                    .clipShape(Capsule())
            }
            .grogDistortion(intensity: intensity)
        }
        .padding(.horizontal, 24)
    }
}
