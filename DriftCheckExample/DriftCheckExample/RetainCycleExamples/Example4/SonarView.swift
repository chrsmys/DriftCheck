//
//  SonarView.swift
//  DriftCheckExample
//
//  Created by Chris Mays on 3/29/25.
//

import UIKit

class SonarPingView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        createPing()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createPing() {
        let circlePath = UIBezierPath(ovalIn: bounds)
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = circlePath.cgPath
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor(red:  245.0/255.0, green: 255.0/255.0, blue: 197.0/255.0, alpha: 0.6).cgColor
        shapeLayer.lineWidth = 3
        shapeLayer.frame = bounds
        layer.addSublayer(shapeLayer)

        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)

        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 0.2
        scale.toValue = 4.5

        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 1
        fade.toValue = 0

        let group = CAAnimationGroup()
        group.animations = [scale, fade]
        group.duration = 1.2
        group.timingFunction = CAMediaTimingFunction(name: .easeOut)
        group.isRemovedOnCompletion = false
        group.fillMode = .forwards

        self.layer.add(group, forKey: "sonar")

        DispatchQueue.main.asyncAfter(deadline: .now() + group.duration) {
            self.removeFromSuperview()
        }
    }
}
