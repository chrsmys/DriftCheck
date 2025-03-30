//
//  UIView+Layout.swift
//  RetainCycleDetector
//
//  Created by Chris Mays on 3/25/25.
//

import UIKit

extension UIView {
    func pin(to otherView: UIView, insets: UIEdgeInsets = .zero) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: otherView.topAnchor, constant: insets.top),
            leadingAnchor.constraint(equalTo: otherView.leadingAnchor, constant: insets.left),
            bottomAnchor.constraint(equalTo: otherView.bottomAnchor, constant: -insets.bottom),
            trailingAnchor.constraint(equalTo: otherView.trailingAnchor, constant: -insets.right)
        ])
    }
}
