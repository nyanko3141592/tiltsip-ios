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
        view.enableSetNeedsDisplay = false
        view.isOpaque = false
        view.contentMode = .scaleToFill
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.framebufferOnly = false
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
        var drink: Drink = .beer
        var fill: Float = 0.73
        var carbonation: Float = 0.82
        var tilt: Float = 0
        var isPouring = false

        private var device: MTLDevice!
        private var queue: MTLCommandQueue!
        private var compute: MTLComputePipelineState!
        private var surface: MTLRenderPipelineState!
        private var particles: MTLRenderPipelineState!
        private var particleBuffer: MTLBuffer!
        private var uniform: MTLBuffer!
        private var time: Float = 0

        func configure(view: MTKView) {
            guard let device = view.device, let library = device.makeDefaultLibrary() else { return }
            self.device = device
            queue = device.makeCommandQueue()
            compute = try? device.makeComputePipelineState(function: library.makeFunction(name: "updateParticles")!)
            surface = try? device.makeRenderPipelineState(descriptor: Self.pipeline(library: library, vertex: "surfaceVertex", fragment: "surfaceFragment", pixelFormat: view.colorPixelFormat))
            particles = try? device.makeRenderPipelineState(descriptor: Self.pipeline(library: library, vertex: "particleVertex", fragment: "particleFragment", pixelFormat: view.colorPixelFormat))
            particleBuffer = device.makeBuffer(length: MemoryLayout<Particle>.stride * 720, options: .storageModeShared)
            uniform = device.makeBuffer(length: MemoryLayout<Uniforms>.stride, options: .storageModeShared)
            seedParticles()
        }

        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let pass = view.currentRenderPassDescriptor,
                  let command = queue.makeCommandBuffer() else { return }

            time += 1.0 / 60.0
            let u = uniform.contents().bindMemory(to: Uniforms.self, capacity: 1)
            u.pointee.time = time
            u.pointee.fill = fill
            u.pointee.carbonation = carbonation
            u.pointee.tilt = tilt
            u.pointee.pouring = isPouring ? 1 : 0
            u.pointee.color = drink == .beer ? SIMD4<Float>(0.99, 0.62, 0.08, 1) : SIMD4<Float>(0.12, 0.018, 0.010, 1)

            if let encoder = command.makeComputeCommandEncoder() {
                encoder.setComputePipelineState(compute)
                encoder.setBuffer(particleBuffer, offset: 0, index: 0)
                encoder.setBuffer(uniform, offset: 0, index: 1)
                encoder.dispatchThreads(MTLSize(width: 720, height: 1, depth: 1), threadsPerThreadgroup: MTLSize(width: min(720, compute.maxTotalThreadsPerThreadgroup), height: 1, depth: 1))
                encoder.endEncoding()
            }

            if let encoder = command.makeRenderCommandEncoder(descriptor: pass) {
                encoder.setRenderPipelineState(surface)
                encoder.setVertexBuffer(uniform, offset: 0, index: 0)
                encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
                encoder.endEncoding()
            }
            command.present(drawable)
            command.commit()
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

        private func seedParticles() {
            let p = particleBuffer.contents().bindMemory(to: Particle.self, capacity: 720)
            for i in 0..<720 {
                let bubble = i % 3 == 0
                p[i] = Particle(x: Float.random(in: -0.94...0.94), y: Float.random(in: -0.88...0.18), vx: 0, vy: Float.random(in: 0.04...0.20), size: bubble ? Float.random(in: 0.006...0.018) : Float.random(in: 0.012...0.035), kind: bubble ? 1 : 0, phase: Float.random(in: 0...6.28))
            }
        }

        private static func pipeline(library: MTLLibrary, vertex: String, fragment: String, pixelFormat: MTLPixelFormat) -> MTLRenderPipelineDescriptor {
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = library.makeFunction(name: vertex)
            descriptor.fragmentFunction = library.makeFunction(name: fragment)
            descriptor.colorAttachments[0].pixelFormat = pixelFormat
            descriptor.colorAttachments[0].isBlendingEnabled = true
            descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            return descriptor
        }
    }
}

private struct Particle { var x: Float; var y: Float; var vx: Float; var vy: Float; var size: Float; var kind: Float; var phase: Float }
private struct Uniforms { var time: Float = 0; var fill: Float = 0.94; var carbonation: Float = 0.82; var tilt: Float = 0; var pouring: Float = 0; var color = SIMD4<Float>(0.99, 0.62, 0.08, 1) }
