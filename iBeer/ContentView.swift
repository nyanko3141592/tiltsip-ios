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
            if drink == .beer {
                FoamPhotoTexture(fill: motion.level, tilt: motion.tilt, energy: motion.sloshEnergy)
            }
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

private struct FoamPhotoTexture: View {
    let fill: Double
    let tilt: Double
    let energy: Double

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
            GeometryReader { proxy in
                let surface = proxy.size.height * (0.08 + CGFloat(1.0 - fill) * 0.80)
                let foamHeight = 14.0 + CGFloat(fill) * 46.0
                let shimmer = sin(timeline.date.timeIntervalSinceReferenceDate * 0.72) * 0.018
                let drift = CGFloat(sin(timeline.date.timeIntervalSinceReferenceDate * 0.31) * 1.2)
                Image("FoamTextureV2")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: foamHeight + 28)
                    .clipped()
                    .opacity(0.145 + shimmer + energy * 0.018)
                    .blendMode(.screen)
                    .rotationEffect(.radians(tilt * 0.18), anchor: .center)
                    .offset(x: drift + CGFloat(tilt) * 22.0, y: surface - foamHeight)
            }
        }
        .allowsHitTesting(false)
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
                let foamHeight = 14.0 + CGFloat(fill) * 46.0
                var liquid = Path()
                liquid.move(to: CGPoint(x: 0, y: surface))
                for x in stride(from: 0, through: size.width, by: 8) {
                    let normalizedX = Double(x / size.width)
                    let wave1 = sin(normalizedX * 15.0 + t * 0.9) * waveAmplitude
                    let wave2 = sin(normalizedX * 31.0 - t * 0.5) * waveAmplitude * 0.28
                    let microRipple = sin(normalizedX * 73.0 + t * 1.7 + flow * 4.0) * (0.7 + Double(energy) * 2.0)
                    let crossWave = sin(normalizedX * 9.0 - t * 0.7 + tilt * 5.0) * abs(tilt) * 4.0
                    let wakePhase = normalizedX * 44.0 - t * 2.4 + flow * 3.0
                    let wakeEnvelope = exp(-abs(normalizedX - 0.5) * 2.8)
                    let wake = sin(wakePhase) * 7.0 * Double(energy) * wakeEnvelope
                    let waveOffset = CGFloat(wave1 + wave2 + wake + microRipple + crossWave)
                    let slopeOffset = slope * (x - size.width / 2)
                    let y = surface + waveOffset + slopeOffset
                    liquid.addLine(to: CGPoint(x: x, y: y))
                }
                liquid.addLine(to: CGPoint(x: size.width, y: size.height))
                liquid.addLine(to: CGPoint(x: 0, y: size.height))
                liquid.closeSubpath()

                let beer = drink == .beer
                let liquidColors: [Color] = beer ? [Color(red: 1.0, green: 0.74, blue: 0.15), Color(red: 0.93, green: 0.46, blue: 0.035), Color(red: 0.50, green: 0.12, blue: 0.004)] : [Color(red: 0.25, green: 0.035, blue: 0.02), Color(red: 0.035, green: 0.004, blue: 0.003)]
                context.fill(liquid, with: .linearGradient(Gradient(colors: liquidColors), startPoint: CGPoint(x: 0, y: surface), endPoint: CGPoint(x: 0, y: size.height)))
                let lightCenterX = size.width * (0.42 + CGFloat(tilt) * 0.12)
                context.fill(liquid, with: .radialGradient(Gradient(colors: [.white.opacity(beer ? 0.15 : 0.05), .clear]), center: CGPoint(x: lightCenterX, y: surface + size.height * 0.30), startRadius: 0, endRadius: size.width * 0.78))
                context.fill(liquid, with: .linearGradient(Gradient(colors: [.black.opacity(0.18), .clear, .black.opacity(0.24)]), startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: size.width, y: 0)))
                context.fill(liquid, with: .radialGradient(Gradient(colors: [.clear, .black.opacity(beer ? 0.16 : 0.24)]), center: CGPoint(x: size.width * 0.5, y: size.height * 1.08), startRadius: size.width * 0.08, endRadius: size.width * 0.92))

                // Beer glows just below the head where light scatters through foam,
                // then quickly attenuates as the liquid gets deeper.
                if beer {
                    var surfaceScatter = Path()
                    surfaceScatter.addRect(CGRect(x: -20, y: surface - 2, width: size.width + 40, height: 110))
                    context.drawLayer { layer in
                        layer.clip(to: liquid)
                        layer.fill(surfaceScatter, with: .linearGradient(Gradient(colors: [.white.opacity(0.20), .yellow.opacity(0.065), .clear]), startPoint: CGPoint(x: 0, y: surface), endPoint: CGPoint(x: 0, y: surface + 110)))
                    }
                }

                // Light attenuates through the drink. These broad, moving shafts are
                // deliberately soft so they read as volume, not graphic stripes.
                if beer {
                    context.drawLayer { layer in
                        layer.addFilter(.blur(radius: 18))
                        for beam in 0..<4 {
                            let phase = t * (0.10 + Double(beam) * 0.015) + Double(beam) * 1.8
                            let x = size.width * (0.10 + CGFloat(beam) * 0.25) + CGFloat(sin(phase) * 18) + CGFloat(tilt) * size.width * 0.08
                            var lightShaft = Path()
                            lightShaft.move(to: CGPoint(x: x, y: surface + 28))
                            lightShaft.addLine(to: CGPoint(x: x + size.width * 0.15, y: size.height + 28))
                            layer.stroke(lightShaft, with: .color(.white.opacity(0.045 + energy * 0.035)), lineWidth: 17)
                        }
                    }
                }

                var depthHaze = Path()
                depthHaze.addRect(CGRect(x: -20, y: size.height - 170, width: size.width + 40, height: 190))
                context.drawLayer { layer in
                    layer.clip(to: liquid)
                    layer.addFilter(.blur(radius: 16))
                    layer.fill(depthHaze, with: .linearGradient(Gradient(colors: [.clear, .black.opacity(beer ? 0.10 : 0.17)]), startPoint: CGPoint(x: 0, y: size.height - 170), endPoint: CGPoint(x: 0, y: size.height)))
                }
                var bottomRoll = Path()
                bottomRoll.move(to: CGPoint(x: -20, y: size.height - 86))
                bottomRoll.addCurve(to: CGPoint(x: size.width + 20, y: size.height - 100), control1: CGPoint(x: size.width * 0.24, y: size.height - 126 + CGFloat(flow) * 10), control2: CGPoint(x: size.width * 0.72, y: size.height - 62 - CGFloat(flow) * 8))
                context.drawLayer { layer in
                    layer.clip(to: liquid)
                    layer.addFilter(.blur(radius: 20))
                    layer.stroke(bottomRoll, with: .color(.black.opacity(beer ? 0.07 : 0.12)), lineWidth: 26)
                }

                // The phone edges act like the inside wall of a glass: a faint meniscus
                // and side falloff make the liquid feel curved instead of painted flat.
                var surfaceGleam = Path()
                surfaceGleam.move(to: CGPoint(x: -8, y: surface + 2))
                for x in stride(from: 0, through: size.width, by: 8) {
                    let normalizedX = Double(x / size.width)
                    let wave = sin(normalizedX * 15.0 + t * 0.9) * waveAmplitude
                    let ripple = sin(normalizedX * 31.0 - t * 0.5) * waveAmplitude * 0.28
                    let micro = sin(normalizedX * 73.0 + t * 1.7 + flow * 4.0) * (0.7 + Double(energy) * 2.0)
                    let cross = sin(normalizedX * 9.0 - t * 0.7 + tilt * 5.0) * abs(tilt) * 4.0
                    surfaceGleam.addLine(to: CGPoint(x: x, y: surface + CGFloat(wave + ripple + micro + cross) + slope * (x - size.width / 2) - 1))
                }
                context.drawLayer { layer in
                    layer.addFilter(.blur(radius: 2.5))
                    layer.stroke(surfaceGleam, with: .color(.white.opacity(beer ? 0.22 : 0.08)), lineWidth: 2.2)
                }

                var leftMeniscus = Path()
                leftMeniscus.move(to: CGPoint(x: 1, y: surface - 10))
                leftMeniscus.addCurve(to: CGPoint(x: 10, y: surface + 20), control1: CGPoint(x: 1, y: surface - 2), control2: CGPoint(x: 5, y: surface + 10))
                var rightMeniscus = Path()
                rightMeniscus.move(to: CGPoint(x: size.width - 1, y: surface - 10))
                rightMeniscus.addCurve(to: CGPoint(x: size.width - 10, y: surface + 20), control1: CGPoint(x: size.width - 1, y: surface - 2), control2: CGPoint(x: size.width - 5, y: surface + 10))
                context.drawLayer { layer in
                    layer.addFilter(.blur(radius: 3))
                    layer.stroke(leftMeniscus, with: .color(.black.opacity(beer ? 0.28 : 0.34)), lineWidth: 7)
                    layer.stroke(rightMeniscus, with: .color(.black.opacity(beer ? 0.28 : 0.34)), lineWidth: 7)
                }
                context.stroke(leftMeniscus, with: .color(.white.opacity(beer ? 0.12 : 0.04)), lineWidth: 1.2)
                context.stroke(rightMeniscus, with: .color(.white.opacity(beer ? 0.10 : 0.04)), lineWidth: 1.2)
                context.drawLayer { layer in
                    layer.addFilter(.blur(radius: 9))
                    var leftEdge = Path()
                    leftEdge.move(to: CGPoint(x: 3, y: surface + 18))
                    leftEdge.addLine(to: CGPoint(x: 3, y: size.height))
                    var rightEdge = Path()
                    rightEdge.move(to: CGPoint(x: size.width - 3, y: surface + 18))
                    rightEdge.addLine(to: CGPoint(x: size.width - 3, y: size.height))
                    let edgeLight = beer ? 0.075 + abs(tilt) * 0.035 : 0.03
                    let edgeShade = beer ? 0.17 + abs(tilt) * 0.025 : 0.22
                    layer.stroke(leftEdge, with: .color(.white.opacity(edgeLight)), lineWidth: 10)
                    layer.stroke(rightEdge, with: .color(.black.opacity(edgeShade)), lineWidth: 14)
                }

                let foam = beer ? Color(red: 1.0, green: 0.90, blue: 0.66) : Color(red: 0.52, green: 0.30, blue: 0.18)
                var foamBand = Path()
                foamBand.move(to: CGPoint(x: 0, y: surface - foamHeight - slope * size.width / 2))
                for x in stride(from: 0, through: size.width, by: 8) {
                    let normalizedX = Double(x / size.width)
                    let foamWave = sin(normalizedX * 17.0 + t * 0.55) * (3 + CGFloat(energy) * 8)
                    let foamRipple = sin(normalizedX * 41.0 - t * 0.9 + flow * 2.0) * (1.2 + CGFloat(energy) * 2.8)
                    let y = surface - foamHeight + foamWave + foamRipple + slope * (x - size.width / 2)
                    foamBand.addLine(to: CGPoint(x: x, y: y))
                }
                foamBand.addLine(to: CGPoint(x: size.width, y: surface + 27))
                foamBand.addLine(to: CGPoint(x: 0, y: surface + 27))
                foamBand.closeSubpath()
                context.fill(foamBand, with: .linearGradient(Gradient(colors: [foam.opacity(0.98), foam.opacity(0.70)]), startPoint: CGPoint(x: 0, y: surface - foamHeight), endPoint: CGPoint(x: 0, y: surface + 27)))

                var foamShadow = Path()
                foamShadow.move(to: CGPoint(x: -10, y: surface + 5 + CGFloat(flow) * 2.0))
                foamShadow.addCurve(to: CGPoint(x: size.width + 10, y: surface + 7 - CGFloat(flow) * 2.0), control1: CGPoint(x: size.width * 0.28, y: surface - 1 + CGFloat(flow) * 3.0), control2: CGPoint(x: size.width * 0.70, y: surface + 14 - CGFloat(flow) * 3.0))
                context.drawLayer { layer in
                    layer.addFilter(.blur(radius: 7))
                    layer.stroke(foamShadow, with: .color(.black.opacity(beer ? 0.24 : 0.16)), lineWidth: 10)
                }

                // The head is made of overlapping domes, not a perfectly flat strip.
                // Layered radial gradients create soft foam volume at the liquid line.
                for i in 0..<24 {
                    let seed = Double(i) * 7.931
                    let x = CGFloat((sin(seed * 2.31) * 43758.5).truncatingRemainder(dividingBy: 1.0).magnitude) * size.width
                    let radiusNoise = sin(seed * 1.37) * 0.5 + 0.5
                    let radius = CGFloat(4.0 + radiusNoise * 9.0)
                    let yNoise = sin(seed * 2.17) * 0.5 + 0.5
                    let yOffset = CGFloat(sin(t * 0.24 + seed) * 1.4)
                    let y = surface - foamHeight * (0.36 + CGFloat(yNoise) * 0.55) + yOffset
                    let dome = CGRect(x: x - radius, y: y - radius * 0.60, width: radius * 2, height: radius * 1.20)
                    context.fill(Path(ellipseIn: dome), with: .radialGradient(Gradient(colors: [Color.white.opacity(0.40), foam.opacity(0.24), Color.black.opacity(0.12)]), center: CGPoint(x: x - radius * 0.24, y: y - radius * 0.26), startRadius: 0, endRadius: radius * 1.25))
                }

                // Slosh breaks a few foam pockets loose at the surface.
                if beer && energy > 0.12 {
                    for i in 0..<14 {
                        let seed = Double(i) * 15.617
                        let x = CGFloat((sin(seed * 1.8 + flow) * 43758.5).truncatingRemainder(dividingBy: 1.0).magnitude) * size.width
                        let y = surface + CGFloat(sin(seed * 2.4 + t * 1.6) * energy * 11.0) + CGFloat((sin(seed) * 0.5 + 0.5)) * 18
                        let radius = CGFloat(0.7 + Double(i % 3) * 0.55) * CGFloat(0.7 + energy)
                        context.fill(Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)), with: .color(.white.opacity(0.28 * energy)))
                    }
                }

                for i in 0..<42 {
                    let seed = Double(i) * 9.173
                    let x = CGFloat((sin(seed) * 43758.5).truncatingRemainder(dividingBy: 1.0).magnitude) * size.width
                    let y = surface - foamHeight + CGFloat((sin(seed * 1.7 + t * 0.3) * 0.5 + 0.5)) * (foamHeight + 20)
                    let radius = CGFloat(2 + Double(i % 4) * 2)
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

                // A few larger foam pockets get a shaded interior, like real bubbles
                // catching the overhead light rather than identical outlined circles.
                for i in 0..<16 {
                    let seed = Double(i) * 11.843
                    let x = CGFloat((sin(seed * 1.7) * 43758.5).truncatingRemainder(dividingBy: 1.0).magnitude) * size.width
                    let y = surface - foamHeight * 0.58 + CGFloat((sin(seed * 2.3 + t * 0.16) * 0.5 + 0.5)) * (foamHeight * 0.82)
                    let radius = CGFloat(4 + (i % 3) * 2)
                    let bubbleRect = CGRect(x: x - radius, y: y - radius * 0.58, width: radius * 2, height: radius * 1.16)
                    context.fill(Path(ellipseIn: bubbleRect), with: .radialGradient(Gradient(colors: [.white.opacity(0.44), foam.opacity(0.18), .black.opacity(0.16)]), center: CGPoint(x: x - radius * 0.28, y: y - radius * 0.24), startRadius: 0, endRadius: radius * 1.25))
                    context.stroke(Path(ellipseIn: bubbleRect.insetBy(dx: 0.8, dy: 0.8)), with: .color(.white.opacity(0.30)), lineWidth: 0.8)
                }

                var foamReflection = Path()
                foamReflection.move(to: CGPoint(x: -20, y: surface + 5))
                foamReflection.addCurve(to: CGPoint(x: size.width + 20, y: surface + 8), control1: CGPoint(x: size.width * 0.25, y: surface - 2), control2: CGPoint(x: size.width * 0.72, y: surface + 16))
                context.drawLayer { layer in
                    layer.addFilter(.blur(radius: 5))
                    layer.stroke(foamReflection, with: .color(.white.opacity(beer ? 0.36 : 0.12)), lineWidth: 3.5)
                }

                if beer {
                    for i in 0..<9 {
                        let seed = Double(i) * 8.31
                        let x = CGFloat((sin(seed * 1.91 + t * 0.12) * 43758.5).truncatingRemainder(dividingBy: 1.0).magnitude) * size.width
                        let y = surface - foamHeight * 0.14 + CGFloat(sin(seed * 1.4 + t * 0.4) * 3.0)
                        var wetHighlight = Path()
                        wetHighlight.move(to: CGPoint(x: x - 8, y: y))
                        wetHighlight.addCurve(to: CGPoint(x: x + 10, y: y + 1), control1: CGPoint(x: x - 3, y: y - 3), control2: CGPoint(x: x + 4, y: y + 3))
                        context.stroke(wetHighlight, with: .color(.white.opacity(0.18)), lineWidth: 1.4)
                    }
                    for i in 0..<12 {
                        let seed = Double(i) * 6.73
                        let x = CGFloat((sin(seed * 2.11) * 43758.5).truncatingRemainder(dividingBy: 1.0).magnitude) * size.width
                        let y = surface + 11 + CGFloat((sin(seed * 1.8) * 0.5 + 0.5) * 12)
                        let radius = CGFloat(2.0 + Double(i % 3))
                        let lace = Path(ellipseIn: CGRect(x: x - radius, y: y - radius * 0.45, width: radius * 2, height: radius * 0.9))
                        context.stroke(lace, with: .color(.white.opacity(0.16)), lineWidth: 0.7)
                    }
                }

                var sheen = Path()
                let sheenDrift = CGFloat(flow) * size.width * 0.045
                sheen.move(to: CGPoint(x: size.width * 0.18 + sheenDrift, y: surface + 35))
                sheen.addLine(to: CGPoint(x: size.width * 0.28 + sheenDrift, y: size.height))
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
                    let depthLight = 0.55 + progress * 0.55
                    let bubble = Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
                    context.fill(Path(ellipseIn: CGRect(x: x - r * 1.25, y: y - r * 1.25, width: r * 2.5, height: r * 2.5)), with: .color(.white.opacity((beer ? 0.045 : 0.025) * depthLight)))
                    context.stroke(bubble, with: .color(.white.opacity((beer ? 0.35 : 0.20) * depthLight)), lineWidth: 0.8)
                    context.fill(Path(ellipseIn: CGRect(x: x - r * 0.35, y: y - r * 0.45, width: r * 0.45, height: r * 0.45)), with: .color(.white.opacity((beer ? 0.45 : 0.25) * depthLight)))
                }

                // Fine carbonation dust fills the spaces between the larger bubbles.
                for i in 0..<52 {
                    let seed = Double(i) * 3.173
                    let x = CGFloat((sin(seed * 3.7) * 43758.5).truncatingRemainder(dividingBy: 1.0).magnitude) * size.width
                    let progress = (t * (0.010 + Double(i % 4) * 0.002) + seed).truncatingRemainder(dividingBy: 1.0)
                    let y = size.height - progress * (size.height - surface + 20)
                    let r = CGFloat(0.35 + Double(i % 3) * 0.22)
                    context.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(.white.opacity(beer ? 0.16 : 0.07)))
                }

                context.drawLayer { layer in
                    layer.addFilter(.blur(radius: 1.8))
                    for i in 0..<8 {
                        let seed = Double(i) * 19.17
                        let x = CGFloat((sin(seed * 2.8) * 43758.5).truncatingRemainder(dividingBy: 1.0).magnitude) * size.width
                        let rise = (t * 0.014 + seed).truncatingRemainder(dividingBy: 1.0)
                        let y = size.height - rise * (size.height - surface + 20)
                        var wakeTrail = Path()
                        wakeTrail.move(to: CGPoint(x: x, y: y + 10))
                        wakeTrail.addCurve(to: CGPoint(x: x + CGFloat(flow) * 7, y: y - 8), control1: CGPoint(x: x - 3, y: y + 3), control2: CGPoint(x: x + 5, y: y - 2))
                        layer.stroke(wakeTrail, with: .color(.white.opacity(beer ? 0.035 : 0.015)), lineWidth: 2.0)
                    }
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

                // Foreground bubbles are larger and softer than the distant carbonation,
                // giving the liquid a real near/far depth cue.
                context.drawLayer { layer in
                    layer.addFilter(.blur(radius: 1.2))
                    for i in 0..<18 {
                        let seed = Double(i) * 23.71
                        let depth = (sin(seed * 1.13) * 0.5 + 0.5)
                        let x = CGFloat((sin(seed * 1.9) * 43758.5).truncatingRemainder(dividingBy: 1.0).magnitude) * size.width
                        let rise = (t * (0.006 + depth * 0.006) + seed).truncatingRemainder(dividingBy: 1.0)
                        let y = size.height - rise * (size.height - surface + 18)
                        let r = CGFloat(2.2 + depth * 3.0)
                        let glow = Path(ellipseIn: CGRect(x: x - r * 1.5, y: y - r * 1.5, width: r * 3, height: r * 3))
                        layer.fill(glow, with: .color(.white.opacity(beer ? 0.025 + depth * 0.03 : 0.012)))
                        let aspect = 0.62 + depth * 0.32
                        let ring = Path(ellipseIn: CGRect(x: x - r, y: y - r * aspect, width: r * 2, height: r * aspect * 2))
                        layer.stroke(ring, with: .color(.white.opacity(beer ? 0.20 + depth * 0.16 : 0.10)), lineWidth: 1.0 + depth * 0.35)
                    }
                }

                context.drawLayer { layer in
                    layer.addFilter(.blur(radius: 8))
                    for band in 0..<5 {
                        var caustic = Path()
                        let y = surface + 90 + CGFloat(band) * size.height * 0.13 + CGFloat(sin(t * 0.35 + Double(band)) * 5.0)
                        caustic.move(to: CGPoint(x: -20, y: y))
                        caustic.addCurve(to: CGPoint(x: size.width + 20, y: y + 10 + CGFloat(sin(t * 0.4 + Double(band)) * 3.0)), control1: CGPoint(x: size.width * 0.28, y: y - 12), control2: CGPoint(x: size.width * 0.72, y: y + 18))
                        layer.stroke(caustic, with: .color(.white.opacity(beer ? 0.035 : 0.018)), lineWidth: 7)
                    }
                }

                // Final optical pass: a very soft diagonal reflection from the phone's
                // cover glass keeps the full-screen liquid from feeling like a flat render.
                var coverGlare = Path()
                let glareShift = CGFloat(tilt) * size.width * 0.06
                coverGlare.move(to: CGPoint(x: -size.width * 0.18 + glareShift, y: size.height * 0.35))
                coverGlare.addLine(to: CGPoint(x: size.width * 0.56 + glareShift, y: -20))
                context.drawLayer { layer in
                    layer.addFilter(.blur(radius: 24))
                    layer.stroke(coverGlare, with: .color(.white.opacity(beer ? 0.028 : 0.012)), lineWidth: 30)
                }
            }
        }
}

private final class MotionManager: ObservableObject {
    @Published var tilt: Double = 0
    @Published var level: Double = 0.94
    @Published var sloshEnergy: Double = 0
    @Published var flow: Double = 0
    @Published var isDrinking = false
    private let manager = CMMotionManager()
    private var tiltVelocity: Double = 0

    func start() {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        manager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            let roll = motion.attitude.roll
            let signedPitch = motion.attitude.pitch
            // Core Motion's positive direction is opposite to the visible liquid slope
            // for this portrait cup, so invert the combined tilt before driving the fluid.
            let forwardTilt = sin(signedPitch) * 0.62
            let targetTilt = max(-0.55, min(0.55, -(roll + forwardTilt)))
            let springForce = (targetTilt - self.tilt) * 13.0 - self.tiltVelocity * 3.8
            self.tiltVelocity += springForce / 30.0
            // A real glass reacts to a quick hand movement before its angle settles.
            // Feed lateral user acceleration into the same inertial slosh velocity.
            let handJolt = motion.userAcceleration.x * 0.018 + motion.userAcceleration.y * 0.008
            let lateralImpulse = max(-0.035, min(0.035, handJolt))
            self.tiltVelocity += lateralImpulse
            self.tilt += self.tiltVelocity / 30.0
            self.tilt = max(-0.55, min(0.55, self.tilt))
            self.sloshEnergy = min(1.0, max(abs(self.tiltVelocity) * 1.8, abs(lateralImpulse) * 10.0, self.sloshEnergy * 0.94))
            self.flow = max(-1.0, min(1.0, self.tiltVelocity * 4.0))
            // Treat the phone's top edge as the cup rim. When that rim is tilted
            // toward the mouth, liquid spills continuously over the top edge.
            // The drain rate is angle-proportional, so a gentle sip is slow and a
            // fully tipped phone empties like a joke glass.
            // Device mounting/orientation can report the forward pitch with either
            // sign. Once the phone reaches the spill angle, either sign means the
            // top rim is over the mouth, so use its magnitude for the joke behavior.
            let drinkingPitch = abs(signedPitch)
            let drinkingThreshold = 0.70
            self.isDrinking = drinkingPitch > drinkingThreshold && self.level > 0.06
            if self.isDrinking {
                let mouthAngle = drinkingPitch - drinkingThreshold
                let drainPerFrame = min(0.012, 0.0018 + mouthAngle * 0.008)
                self.level = max(0.06, self.level - drainPerFrame)
            }
        }
    }

    deinit { manager.stopDeviceMotionUpdates() }
}

#Preview { ContentView() }
