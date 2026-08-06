import SwiftUI
import MetalKit

struct MetalGlassView: UIViewRepresentable {
    let drink: Drink
    let fill: Double
    let carbonation: Double
    let tilt: Double
    let isPouring: Bool

    func makeCoordinator() -> Renderer { Renderer() }
    func makeUIView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        view.delegate = context.coordinator
        view.preferredFramesPerSecond = 60
        view.isOpaque = false
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        context.coordinator.configure(view: view)
        return view
    }
    func updateUIView(_ view: MTKView, context: Context) {
        context.coordinator.drink = drink
        context.coordinator.fill = Float(fill)
        context.coordinator.carbonation = Float(carbonation)
        context.coordinator.tilt = Float(tilt * .pi / 180)
        context.coordinator.isPouring = isPouring
    }

    final class Renderer: NSObject, MTKViewDelegate {
        var drink: Drink = .beer; var fill: Float = 0.76; var carbonation: Float = 0.68; var tilt: Float = 0; var isPouring = true
        private var device: MTLDevice!; private var queue: MTLCommandQueue!; private var compute: MTLComputePipelineState!; private var render: MTLRenderPipelineState!; private var buffer: MTLBuffer!; private var uniform: MTLBuffer!; private var time: Float = 0

        func configure(view: MTKView) {
            guard let device = view.device, let library = device.makeDefaultLibrary() else { return }
            self.device = device; queue = device.makeCommandQueue()
            compute = try? device.makeComputePipelineState(function: library.makeFunction(name: "updateParticles")!)
            render = try? device.makeRenderPipelineState(descriptor: Self.renderDescriptor(library: library, pixelFormat: view.colorPixelFormat))
            buffer = device.makeBuffer(length: MemoryLayout<Particle>.stride * 380, options: .storageModeShared)
            uniform = device.makeBuffer(length: MemoryLayout<Uniforms>.stride, options: .storageModeShared)
            seedParticles()
        }

        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable, let pass = view.currentRenderPassDescriptor, let command = queue.makeCommandBuffer() else { return }
            time += 1 / 60
            let u = uniform.contents().bindMemory(to: Uniforms.self, capacity: 1); u.time = time; u.fill = fill; u.carbonation = carbonation; u.tilt = tilt; u.pouring = isPouring ? 1 : 0
            let color = drink == .beer ? SIMD4<Float>(0.98, 0.46, 0.06, 1) : SIMD4<Float>(0.16, 0.035, 0.018, 1); u.color = color
            if let encoder = command.makeComputeCommandEncoder() { encoder.setComputePipelineState(compute); encoder.setBuffer(buffer, offset: 0, index: 0); encoder.setBuffer(uniform, offset: 0, index: 1); encoder.dispatchThreads(MTLSize(width: 380, height: 1, depth: 1), threadsPerThreadgroup: MTLSize(width: min(380, compute.maxTotalThreadsPerThreadgroup), height: 1, depth: 1)); encoder.endEncoding() }
            let encoder = command.makeRenderCommandEncoder(descriptor: pass)!; encoder.setRenderPipelineState(render); encoder.setVertexBuffer(buffer, offset: 0, index: 0); encoder.setVertexBuffer(uniform, offset: 0, index: 1); encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6, instanceCount: 380); encoder.endEncoding(); command.present(drawable); command.commit()
        }
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

        private func seedParticles() { let p = buffer.contents().bindMemory(to: Particle.self, capacity: 380); for i in 0..<380 { let isBubble = i % 3 == 0; p[i] = Particle(x: Float.random(in: -0.28...0.28), y: Float.random(in: -0.68...0.65), vx: 0, vy: Float.random(in: 0.05...0.22), size: isBubble ? Float.random(in: 0.012...0.035) : Float.random(in: 0.025...0.07), kind: isBubble ? 1 : 0, phase: Float.random(in: 0...6.28)) } }
        private static func renderDescriptor(library: MTLLibrary, pixelFormat: MTLPixelFormat) -> MTLRenderPipelineDescriptor { let d = MTLRenderPipelineDescriptor(); d.vertexFunction = library.makeFunction(name: "particleVertex"); d.fragmentFunction = library.makeFunction(name: "particleFragment"); d.colorAttachments[0].pixelFormat = pixelFormat; d.colorAttachments[0].isBlendingEnabled = true; d.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha; d.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha; return d }
    }
}

private struct Particle { var x: Float; var y: Float; var vx: Float; var vy: Float; var size: Float; var kind: Float; var phase: Float }
private struct Uniforms { var time: Float = 0; var fill: Float = 0.76; var carbonation: Float = 0.68; var tilt: Float = 0; var pouring: Float = 1; var color = SIMD4<Float>(1, 0.5, 0.1, 1) }

