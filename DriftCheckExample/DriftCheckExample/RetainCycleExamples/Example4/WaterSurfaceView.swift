//
//  WaterSurfaceView.swift
//  DriftCheckExample
//
//  Created by Chris Mays on 3/28/25.
//

import UIKit

class WaterSurfaceView: UIView {
    private var waveLayers: [CAShapeLayer] = []
    private var displayLink: CADisplayLink?
    private var phase: CGFloat = 0

    var beachHeightRatio: CGFloat = 0.2
    
    private let waveCount = 8
    private let baseAlpha: CGFloat = 0.08
    private let waveSpeeds: [CGFloat] = [0.5, 0.45, 0.4, 0.35, 0.3, 0.25, 0.2, 0.15]
    private let waveAmplitudes: [CGFloat] = [12, 10, 10, 8, 8, 7, 6, 6]
    private let waveFrequencies: [CGFloat] = [0.6, 0.55, 0.5, 0.45, 0.4, 0.35, 0.3, 0.25]

    private var beachDrawn = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBlue
        setupWaves()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupWaves() {
        for _ in 0..<waveCount {
            let layer = CAShapeLayer()
            layer.fillColor = UIColor.white.withAlphaComponent(baseAlpha).cgColor
            self.layer.addSublayer(layer)
            waveLayers.append(layer)
        }

        displayLink = CADisplayLink(target: self, selector: #selector(updateWaves))
        displayLink?.add(to: .main, forMode: .common)
    }

    @objc private func updateWaves() {
        phase += 0.03

        for (index, waveLayer) in waveLayers.enumerated() {
            let path = UIBezierPath()
            let amplitude = waveAmplitudes[index]
            let frequency = waveFrequencies[index]
            let speed = waveSpeeds[index]
            
            let spacing = bounds.height / CGFloat(waveCount + 2)
            let yOffset = spacing * CGFloat(index + 1)

            path.move(to: CGPoint(x: 0, y: yOffset))

            for x in stride(from: 0, to: bounds.width, by: 1) {
                let relativeX = CGFloat(x) / bounds.width
                let sine = sin((relativeX * frequency * .pi * 2) + (phase * speed))
                let y = yOffset + sine * amplitude
                path.addLine(to: CGPoint(x: CGFloat(x), y: y))
            }

            path.addLine(to: CGPoint(x: bounds.width, y: bounds.height))
            path.addLine(to: CGPoint(x: 0, y: bounds.height))
            path.close()

            waveLayer.path = path.cgPath
        }
    }

    private func drawBeach() {
        let beachHeight = bounds.height * beachHeightRatio
        let beachLayer = CAShapeLayer()
        beachLayer.fillColor = UIColor(red: 1.0, green: 0.92, blue: 0.72, alpha: 1.0).cgColor

        let width = bounds.width
        let height = bounds.height
        let beachTopY = height - beachHeight

        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: height))
        path.addQuadCurve(to: CGPoint(x: width, y: height),
                          controlPoint: CGPoint(x: width / 2, y: beachTopY))
        path.addLine(to: CGPoint(x: width, y: height + 100))
        path.addLine(to: CGPoint(x: 0, y: height + 100))
        path.close()

        beachLayer.path = path.cgPath
        layer.insertSublayer(beachLayer, at: 0)
    }

    private func addSwimmers() {
        let swimmers = ["🏊‍♂️", "🏊‍♀️"]
        let beachHeight = bounds.height * beachHeightRatio
        let height = bounds.height
        let width = bounds.width
        let beachTopY = height - beachHeight
        let controlPoint = CGPoint(x: width / 2, y: beachTopY)

        for emoji in swimmers {
            var attempts = 0
            while attempts < 20 {
                attempts += 1
                let x = CGFloat.random(in: 0...(width - 40))
                let y = CGFloat.random(in: beachTopY - 100...(beachTopY - 20))
                let t = x / width
                let oneMinusT = 1 - t
                let curveY =
                    oneMinusT * oneMinusT * height +
                    2 * oneMinusT * t * controlPoint.y +
                    t * t * height

                if y < curveY {
                    let label = UILabel()
                    label.text = emoji
                    label.font = .systemFont(ofSize: 36)
                    label.frame = CGRect(x: x, y: y, width: 40, height: 40)
                    addSubview(label)
                    break
                }
            }
        }
    }
    
    private func addBeachItems() {
        let beachEmojis = ["🧍‍♀️", "🧍‍♂️", "⛱️", "🌴", "🧘‍♂️", "🧘‍♀️"]
        let beachHeight = bounds.height * beachHeightRatio
        let height = bounds.height
        let width = bounds.width
        let beachTopY = height - beachHeight
        let controlPoint = CGPoint(x: width / 2, y: beachTopY)

        let emojiCount = 5
        var placed = 0
        var attempts = 0

        while placed < emojiCount && attempts < emojiCount * 10 {
            attempts += 1

            let x = CGFloat.random(in: 0...(width - 40))
            let y = CGFloat.random(in: beachTopY...(height - 40))
            let t = x / width
            let oneMinusT = 1 - t
            let curveY =
                oneMinusT * oneMinusT * height +
                2 * oneMinusT * t * controlPoint.y +
                t * t * height

            if y >= curveY {
                let label = UILabel()
                label.text = beachEmojis.randomElement()
                label.font = .systemFont(ofSize: 30)
                label.frame = CGRect(x: x, y: y, width: 40, height: 40)
                addSubview(label)
                placed += 1
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        for layer in waveLayers {
            layer.frame = bounds
        }

        if !beachDrawn {
            drawBeach()
            addBeachItems()
            addSwimmers()
            beachDrawn = true
        }
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(updateWaves))
        displayLink?.add(to: .main, forMode: .common)
    }
}
