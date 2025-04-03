//
//  Example1.swift
//  DriftCheckExample
//
//  Created by Chris Mays on 4/3/25.
//

import SwiftUI

class Example1: UIViewController {
    lazy var hostingView: UIView = UIHostingConfiguration {
        VStack {
            Button {
                self.dismiss(animated: true)
                // ↑ Strong capture of self inside the action block
            } label: {
                Text("Walk the plank")
            }
        }
    }
        .margins(.all, 0)
        .makeContentView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        
        self.hostingView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(hostingView)
        
        self.hostingView.pin(to: self.view)
    }
}
