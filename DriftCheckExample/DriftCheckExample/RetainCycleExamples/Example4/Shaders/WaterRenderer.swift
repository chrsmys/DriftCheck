//
//  WaterRenderer.swift
//  DriftCheckExample
//
//  Created by Chris Mays on 3/29/25.
//

import SwiftUI
import MetalKit

class WaterRenderer: NSObject, MTKViewDelegate {
    let mtkView: MTKView
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var pipelineState: MTLRenderPipelineState!
    private var rippleTexture: MTLTexture!
    private var rippleData: [Float]
    private let width = 256
    private let height = 256
    private var time: Float = 0.0
    
    private var touchPoints: [(x: Int, y: Int)] = []

    override init() {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.framebufferOnly = false
        mtkView.isPaused = false
        mtkView.enableSetNeedsDisplay = false
        mtkView.preferredFramesPerSecond = 60
        
//        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
//                pan.maximumNumberOfTouches = 1
//                pan.minimumNumberOfTouches = 1
//                mtkView.addGestureRecognizer(pan)
        
//        mtkView.addGestureRecognizer(tap)
        mtkView.isOpaque = false
        mtkView.backgroundColor = .clear
        mtkView.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0)
        
        self.mtkView = mtkView
        self.device = mtkView.device!
        self.commandQueue = device.makeCommandQueue()
        self.rippleData = Array(repeating: 0.0, count: width * height)
        
        super.init()
        mtkView.delegate = self
        setupPipeline(mtkView: mtkView)
        createRippleTexture()
    }

    private func setupPipeline(mtkView: MTKView) {
        let library = device.makeDefaultLibrary()
        let vertexFunc = library?.makeFunction(name: "vertex_main")
        let fragFunc = library?.makeFunction(name: "fragment_main")
        
        let pipelineDesc = MTLRenderPipelineDescriptor()
        pipelineDesc.vertexFunction = vertexFunc
        pipelineDesc.fragmentFunction = fragFunc
        pipelineDesc.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        
        let attachment = pipelineDesc.colorAttachments[0]
        attachment?.isBlendingEnabled = true
        attachment?.rgbBlendOperation = .add
        attachment?.alphaBlendOperation = .add
        attachment?.sourceRGBBlendFactor = .sourceAlpha
        attachment?.sourceAlphaBlendFactor = .sourceAlpha
        attachment?.destinationRGBBlendFactor = .oneMinusSourceAlpha
        attachment?.destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDesc)
    }

    private func createRippleTexture() {
        let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r32Float,
                                                            width: width,
                                                            height: height,
                                                            mipmapped: false)
        desc.usage = [.shaderRead, .shaderWrite]
        rippleTexture = device.makeTexture(descriptor: desc)
    }

    private func updateRipples() {
        // Simple ripple simulation (wave propagation)
        for y in 1..<height-1 {
            for x in 1..<width-1 {
                let idx = y * width + x
                let sum = rippleData[idx - 1] +
                          rippleData[idx + 1] +
                          rippleData[idx - width] +
                          rippleData[idx + width]
                let newHeight = (sum / 2) - rippleData[idx]
                rippleData[idx] = newHeight * 0.985 // damping
            }
        }

        for point in touchPoints {
            let idx = point.y * width + point.x
            if idx >= 0 && idx < rippleData.count {
                rippleData[idx] = 0.5
            }
        }
        touchPoints.removeAll()

        rippleTexture.replace(region: MTLRegionMake2D(0, 0, width, height),
                              mipmapLevel: 0,
                              withBytes: rippleData,
                              bytesPerRow: MemoryLayout<Float>.size * width)
    }

    func injectRipple(at point: CGPoint) {
        let size = mtkView.bounds.size
        let x = Int(point.x / size.width * CGFloat(width))
        let y = Int((1.0 - (point.y / size.height)) * CGFloat(height))
        touchPoints.append((x: x, y: y))
    }

    func draw(in view: MTKView) {
        updateRipples()
        time += 1.0 / 60.0 // or use actual deltaTime for smoothness

        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }

        encoder.setRenderPipelineState(pipelineState)
        encoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 0)
        encoder.setFragmentTexture(rippleTexture, index: 0)
        encoder.setFragmentSamplerState(view.device?.makeSamplerState(descriptor: MTLSamplerDescriptor()), index: 0)
        
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}

struct WaterView: UIViewRepresentable {
    let renderer: WaterRenderer

    func makeUIView(context: Context) -> MTKView {
        return renderer.mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {}
}
