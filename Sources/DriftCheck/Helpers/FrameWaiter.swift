//
//  FrameWaiter.swift
//  RetainDetector
//
//  Created by Chris Mays on 3/24/25.
//

import UIKit

final class FrameWaiter {
    private var displayLink: CADisplayLink?
    private var remainingFrames: Int = 0
    private var completion: (() -> Void)?

    func wait(frames: Int, completion: @escaping () -> Void) {
        guard frames > 0 else {
            completion()
            return
        }

        self.remainingFrames = frames
        self.completion = completion

        displayLink = CADisplayLink(target: self, selector: #selector(handleFrame))
        displayLink?.add(to: .main, forMode: .common)
    }

    @objc private func handleFrame() {
        remainingFrames -= 1

        if remainingFrames <= 0 {
            displayLink?.invalidate()
            displayLink = nil
            completion?()
            completion = nil
        }
    }

    static func wait(frames: Int) async {
        let frameWaiter = FrameWaiter()
        await withCheckedContinuation { continuation in
            frameWaiter.wait(frames: frames) {
                continuation.resume()
            }
        }
    }
}
