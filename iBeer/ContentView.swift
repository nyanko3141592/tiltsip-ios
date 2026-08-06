import SwiftUI
import CoreMotion

enum Drink: String, CaseIterable, Identifiable {
    case beer = "BEER"
    case cola = "COLA"
    var id: Self { self }
}

struct ContentView: View {
    @State private var drink: Drink = .beer
    @StateObject private var motion = MotionManager()

    var body: some View {
        ZStack {
            FluidBackdrop(drink: drink, fill: motion.level, tilt: motion.tilt, energy: motion.sloshEnergy, flow: motion.flow)
            MetalGlassView(drink: drink, fill: motion.level, carbonation: 0.82, tilt: motion.tilt * 180 / .pi, isPouring: false)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            HStack(spacing: 8) {
                Circle().fill(drink == .beer ? Color.yellow : Color.red.opacity(0.7)).frame(width: 7, height: 7)
                Text(drink.rawValue).font(.system(size: 11, weight: .bold, design: .rounded)).tracking(2.2)
            }
            .foregroundStyle(.white.opacity(0.42))
            .padding(.top, 12)
            .frame(maxHeight: .infinity, alignment: .top)
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture { drink = drink == .beer ? .cola : .beer }
        .accessibilityLabel("液体シミュレーション。タップでビールとコーラを切り替え")
        .preferredColorScheme(.dark)
        .task { motion.start() }
    }
}

private struct FluidBackdrop: View {
    let drink: Drink
    let fill: Double
    let tilt: Double
    let energy: Double
    let flow: Double

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            FluidCanvas(drink: drink, time: timeline.date.timeIntervalSinceReferenceDate, fill: fill, tilt: tilt, energy: energy, flow: flow)
        }
    }
}

private struct FluidCanvas: View {
    let drink: Drink
    let time: TimeInterval
    let fill: Double
    let tilt: Double
    let energy: Double
    let flow: Double

    var body: some View {
        Canvas { context, size in
                let t = time
                // The top edge of the phone is the cup rim. Drinking moves the surface downward.
                let surface = size.height * (0.08 + CGFloat(1.0 - fill) * 0.80)
                let slope = CGFloat(max(-0.55, min(0.55, tilt))) * 0.28
                let waveAmplitude = 4.0 + CGFloat(energy) * 18.0
                let foamHeight = 18.0 + CGFloat(fill) * 42.0
                var liquid = Path()
                liquid.move(to: CGPoint(x: 0, y: surface))
                for x in stride(from: 0, through: size.width, by: 8) {
                    let normalizedX = Double(x / size.width)
                    let wave1 = sin(normalizedX * 15.0 + t * 0.9) * waveAmplitude
                    let wave2 = sin(normalizedX * 31.0 - t * 0.5) * waveAmplitude * 0.28
                    let wake = sin(normalizedX * 44.0 - t * 2.4 + flow * 3.0) * Double(energy) * 7.0 * exp(-abs(normalizedX - 0.5) * 2.8)
                    let y = surface + CGFloat(wave1 + wave2 + wake) + slope * (x - size.width / 2)
                    liquid.addLine(to: CGPoint(x: x, y: y))
                }
                liquid.addLine(to: CGPoint(x: size.width, y: size.height))
                liquid.addLine(to: CGPoint(x: 0, y: size.height))
                liquid.closeSubpath()

                let beer = drink == .beer
                let liquidColors: [Color] = beer ? [Color(red: 1.0, green: 0.72, blue: 0.14), Color(red: 0.90, green: 0.40, blue: 0.025), Color(red: 0.46, green: 0.10, blue: 0.004)] : [Color(red: 0.25, green: 0.035, blue: 0.02), Color(red: 0.035, green: 0.004, blue: 0.003)]
                context.fill(liquid, with: .linearGradient(Gradient(colors: liquidColors), startPoint: CGPoint(x: 0, y: surface), endPoint: CGPoint(x: 0, y: size.height)))
                context.fill(liquid, with: .radialGradient(Gradient(colors: [.white.opacity(beer ? 0.15 : 0.05), .clear]), center: CGPoint(x: size.width * 0.42, y: surface + size.height * 0.30), startRadius: 0, endRadius: size.width * 0.78))
                context.fill(liquid, with: .linearGradient(Gradient(colors: [.black.opacity(0.18), .clear, .black.opacity(0.24)]), startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: size.width, y: 0)))

                let foam = beer ? Color(red: 1.0, green: 0.90, blue: 0.66) : Color(red: 0.28, green: 0.08, blue: 0.06)
                var foamBand = Path()
                foamBand.move(to: CGPoint(x: 0, y: surface - foamHeight - slope * size.width / 2))
                for x in stride(from: 0, through: size.width, by: 8) {
                    let y = surface - foamHeight + sin(Double(x / size.width) * 17.0 + t * 0.55) * (3 + CGFloat(energy) * 8) + slope * (x - size.width / 2)
                    foamBand.addLine(to: CGPoint(x: x, y: y))
                }
                foamBand.addLine(to: CGPoint(x: size.width, y: surface + 27))
                foamBand.addLine(to: CGPoint(x: 0, y: surface + 27))
                foamBand.closeSubpath()
                context.fill(foamBand, with: .linearGradient(Gradient(colors: [foam.opacity(0.98), foam.opacity(0.70)]), startPoint: CGPoint(x: 0, y: surface - foamHeight), endPoint: CGPoint(x: 0, y: surface + 27)))

                var foamShadow = Path()
                foamShadow.move(to: CGPoint(x: -10, y: surface + 5))
                foamShadow.addCurve(to: CGPoint(x: size.width + 10, y: surface + 7), control1: CGPoint(x: size.width * 0.28, y: surface - 1), control2: CGPoint(x: size.width * 0.70, y: surface + 14))
                context.drawLayer { layer in
                    layer.addFilter(.blur(radius: 7))
                    layer.stroke(foamShadow, with: .color(.black.opacity(beer ? 0.24 : 0.16)), lineWidth: 10)
                }

                for i in 0..<42 {
                    let seed = Double(i) * 9.173
                    let x = CGFloat((sin(seed) * 43758.5).truncatingRemainder(dividingBy: 1.0).magnitude) * size.width
                    let y = surface - foamHeight + CGFloat((sin(seed * 1.7 + t * 0.3) * 0.5 + 0.5)) * (foamHeight + 20)
                    let radius = CGFloat(2 + (i % 4) * 2)
                    context.fill(Path(ellipseIn: CGRect(x: x - radius, y: y - radius * 0.6, width: radius * 2, height: radius * 1.2)), with: .color(foam.opacity(0.22)))
                }

                for i in 0..<24 {
                    let seed = Double(i) * 6.417
                    let x = CGFloat((sin(seed * 2.1) * 43758.5).truncatingRemainder(dividingBy: 1.0).magnitude) * size.width
                    let y = surface - 8 + CGFloat((sin(seed * 1.3) * 0.5 + 0.5)) * 28
                    let radius = CGFloat(2 + (i % 3))
                    context.fill(Path(ellipseIn: CGRect(x: x - radius, y: y - radius * 0.55, width: radius * 2, height: radius * 1.1)), with: .color(.black.opacity(0.065)))
                }

                // Foam cells catch a narrow highlight and keep a soft shadow on their lower rim.
                for i in 0..<30 {
                    let seed = Double(i) * 4.271
                    let x = CGFloat((sin(seed * 2.7) * 43758.5).truncatingRemainder(dividingBy: 1.0).magnitude) * size.width
                    let y = surface - foamHeight * 0.72 + CGFloat((sin(seed * 1.9 + t * 0.22) * 0.5 + 0.5)) * (foamHeight * 1.35)
                    let radius = CGFloat(3 + (i % 4) * 2)
                    let cell = Path(ellipseIn: CGRect(x: x - radius, y: y - radius * 0.62, width: radius * 2, height: radius * 1.24))
                    context.stroke(cell, with: .color(.white.opacity(beer ? 0.34 : 0.16)), lineWidth: 0.9)
                    context.fill(Path(ellipseIn: CGRect(x: x - radius * 0.48, y: y - radius * 0.28, width: radius * 0.38, height: radius * 0.22)), with: .color(.white.opacity(beer ? 0.56 : 0.24)))
                    context.fill(Path(ellipseIn: CGRect(x: x + radius * 0.18, y: y + radius * 0.18, width: radius * 0.52, height: radius * 0.24)), with: .color(.black.opacity(0.15)))
                }

                var foamReflection = Path()
                foamReflection.move(to: CGPoint(x: -20, y: surface + 5))
                foamReflection.addCurve(to: CGPoint(x: size.width + 20, y: surface + 8), control1: CGPoint(x: size.width * 0.25, y: surface - 2), control2: CGPoint(x: size.width * 0.72, y: surface + 16))
                context.drawLayer { layer in
                    layer.addFilter(.blur(radius: 5))
                    layer.stroke(foamReflection, with: .color(.white.opacity(beer ? 0.36 : 0.12)), lineWidth: 3.5)
                }

                var sheen = Path()
                sheen.move(to: CGPoint(x: size.width * 0.18, y: surface + 35))
                sheen.addLine(to: CGPoint(x: size.width * 0.28, y: size.height))
                context.drawLayer { layer in
                    layer.addFilter(.blur(radius: 13))
                    layer.stroke(sheen, with: .color(.white.opacity(beer ? 0.16 : 0.07)), lineWidth: 22)
                }

                for i in 0..<95 {
                    let seed = Double(i) * 12.9898
                    let x = CGFloat((sin(seed) * 43758.5).truncatingRemainder(dividingBy: 1.0).magnitude) * size.width
                    let speed = 0.015 + Double(i % 5) * 0.004
                    let progress = (t * speed + Double(i) * 0.071).truncatingRemainder(dividingBy: 1.0)
                    let drift = CGFloat(flow) * progress * 16.0
                    let y = size.height - progress * (size.height - surface + 30) + drift
                    let r = CGFloat(1.0 + Double(i % 3))
                    let bubble = Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
                    context.fill(Path(ellipseIn: CGRect(x: x - r * 1.25, y: y - r * 1.25, width: r * 2.5, height: r * 2.5)), with: .color(.white.opacity(beer ? 0.045 : 0.025)))
                    context.stroke(bubble, with: .color(.white.opacity(beer ? 0.35 : 0.20)), lineWidth: 0.8)
                    context.fill(Path(ellipseIn: CGRect(x: x - r * 0.35, y: y - r * 0.45, width: r * 0.45, height: r * 0.45)), with: .color(.white.opacity(beer ? 0.45 : 0.25)))
                }

                // Carbonation rises in loose trails rather than as a uniform random field.
                for lane in 0..<18 {
                    let seed = Double(lane) * 17.31
                    let originX = CGFloat((sin(seed) * 43758.5).truncatingRemainder(dividingBy: 1.0).magnitude) * size.width
                    for bead in 0..<7 {
                        let beadPhase = (t * (0.018 + Double(lane % 4) * 0.002) + Double(bead) * 0.11 + seed).truncatingRemainder(dividingBy: 1.0)
                        let y = size.height - beadPhase * (size.height - surface + 24)
                        let x = originX + CGFloat(sin(beadPhase * 13.0 + seed) * (4.0 + beadPhase * 16.0)) + CGFloat(flow) * beadPhase * 10
                        let r = CGFloat(0.8 + Double((lane + bead) % 3) * 0.65)
                        let beadPath = Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
                        context.stroke(beadPath, with: .color(.white.opacity(beer ? 0.22 : 0.12)), lineWidth: 0.65)
                        context.fill(Path(ellipseIn: CGRect(x: x - r * 0.25, y: y - r * 0.35, width: r * 0.32, height: r * 0.32)), with: .color(.white.opacity(beer ? 0.34 : 0.18)))
                    }
                }

                context.drawLayer { layer in
                    layer.addFilter(.blur(radius: 8))
                    for band in 0..<5 {
                        var caustic = Path()
                        let y = surface + 90 + CGFloat(band) * size.height * 0.13
                        caustic.move(to: CGPoint(x: -20, y: y))
                        caustic.addCurve(to: CGPoint(x: size.width + 20, y: y + 10), control1: CGPoint(x: size.width * 0.28, y: y - 12), control2: CGPoint(x: size.width * 0.72, y: y + 18))
                        layer.stroke(caustic, with: .color(.white.opacity(beer ? 0.035 : 0.018)), lineWidth: 7)
                    }
                }
            }
        }
}

private final class MotionManager: ObservableObject {
    @Published var tilt: Double = 0
    @Published var level: Double = 0.94
    @Published var sloshEnergy: Double = 0
    @Published var flow: Double = 0
    private let manager = CMMotionManager()
    private var tiltVelocity: Double = 0

    func start() {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        manager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            let roll = motion.attitude.roll
            let pitch = abs(motion.attitude.pitch)
            // Roll handles side-to-side slosh; pitch makes the phone behave like a glass while drinking.
            let forwardTilt = sin(motion.attitude.pitch) * 0.62
            let targetTilt = max(-0.55, min(0.55, roll + forwardTilt))
            let springForce = (targetTilt - self.tilt) * 13.0 - self.tiltVelocity * 3.8
            self.tiltVelocity += springForce / 30.0
            self.tilt += self.tiltVelocity / 30.0
            self.tilt = max(-0.55, min(0.55, self.tilt))
            self.sloshEnergy = min(1.0, max(abs(self.tiltVelocity) * 1.8, self.sloshEnergy * 0.94))
            self.flow = max(-1.0, min(1.0, self.tiltVelocity * 4.0))
            if pitch > 0.92 {
                let sip = min(0.0035, 0.00035 + (pitch - 0.92) * 0.0022)
                self.level = max(0.06, self.level - sip)
            }
        }
    }

    deinit { manager.stopDeviceMotionUpdates() }
}

#Preview { ContentView() }
