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
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var presentedSheet: AppSheet?

    var body: some View {
        ZStack {
            ZStack {
                FluidBackdrop(drink: drink, fill: motion.level, tilt: motion.tilt, energy: motion.sloshEnergy, flow: motion.flow)
                    .accessibilityHidden(true)
                if drink == .beer {
                    FoamPhotoTexture(fill: motion.level, tilt: motion.tilt, energy: motion.sloshEnergy)
                        .accessibilityHidden(true)
                }
                MetalGlassView(drink: drink, fill: motion.level, carbonation: 0.82, tilt: motion.tilt * 180 / .pi, isPouring: false)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityHidden(true)
                if hasCompletedOnboarding {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { drink = drink == .beer ? .cola : .beer }
                        .accessibilityLabel("ビールとコーラを切り替える")
                        .accessibilityAddTraits(.isButton)
                }
            }
            .ignoresSafeArea()
            .accessibilityHidden(!hasCompletedOnboarding)
            .allowsHitTesting(hasCompletedOnboarding)

            if hasCompletedOnboarding {
                Button {
                    presentedSheet = .information
                } label: {
                    HStack(spacing: 8) {
                        Circle().fill(drink == .beer ? Color.yellow : Color.red.opacity(0.7)).frame(width: 7, height: 7)
                        Text(drink.rawValue).font(.system(size: 11, weight: .bold, design: .rounded)).tracking(2.2)
                    }
                    .foregroundStyle(.white.opacity(0.48))
                    .frame(minWidth: 88, minHeight: 44)
                }
                .buttonStyle(.plain)
                .frame(maxHeight: .infinity, alignment: .top)
                .accessibilityLabel("TiltSipの情報と補充")
            }

            if !hasCompletedOnboarding {
                OnboardingView {
                    withAnimation(.easeOut(duration: 0.35)) {
                        hasCompletedOnboarding = true
                    }
                }
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .preferredColorScheme(.dark)
        .task {
#if DEBUG
            let arguments = ProcessInfo.processInfo.arguments
            if arguments.contains("-appStoreScreenshotCola") {
                drink = .cola
            }
            if arguments.contains("-appStoreScreenshotInfo") {
                presentedSheet = .information
            }
#endif
            motion.start()
        }
        .sheet(item: $presentedSheet) { _ in
            AppInformationView(
                onRefill: { motion.refill() },
                onReplayOnboarding: { hasCompletedOnboarding = false }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

private enum AppSheet: String, Identifiable {
    case information
    var id: String { rawValue }
}

private struct FoamPhotoTexture: View {
    let fill: Double
    let tilt: Double
    let energy: Double

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
            GeometryReader { proxy in
                let surfaceAngle = max(-1.15, min(1.15, tilt))
                let slope = CGFloat(tan(surfaceAngle))
                let surface = conservedSurfaceCenter(size: proxy.size, fill: fill, slope: slope)
                let foamHeight = 14.0 + CGFloat(fill) * 46.0
                let shimmer = sin(timeline.date.timeIntervalSinceReferenceDate * 0.72) * 0.012
                let drift = CGFloat(sin(timeline.date.timeIntervalSinceReferenceDate * 0.31) * 1.2)
                let tiltFade = 1.0 - min(0.58, abs(tilt) * 0.46)
                Image(decorative: "FoamTextureV2")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: foamHeight + 28)
                    .clipped()
                    .opacity((0.105 + shimmer + energy * 0.018) * tiltFade)
                    .blendMode(.screen)
                    .rotationEffect(.radians(tilt), anchor: .center)
                    .offset(x: drift, y: surface - foamHeight)
                    .accessibilityHidden(true)
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
            render(context: &context, size: size)
        }
    }

    private func render(context: inout GraphicsContext, size: CGSize) {
                let t = time
                // The free surface stays horizontal in world space. Core Motion gives
                // us that horizon angle; solve the intercept so rotating the line does
                // not magically create or destroy liquid area inside the phone-cup.
                let surfaceAngle = max(-1.15, min(1.15, tilt))
                let slope = CGFloat(tan(surfaceAngle))
                let surface = conservedSurfaceCenter(size: size, fill: fill, slope: slope)
                let surfaceY: (CGFloat) -> CGFloat = { x in
                    surface + slope * (x - size.width * 0.5)
                }
                let buoyancyX = CGFloat(sin(surfaceAngle))
                let buoyancyY = CGFloat(-cos(surfaceAngle))
                let tangentX = CGFloat(cos(surfaceAngle))
                let tangentY = CGFloat(sin(surfaceAngle))
                let bubbleTravel = hypot(size.width, size.height) * 1.08
                let bubblePoint: (CGFloat, Double, CGFloat) -> CGPoint = { surfaceX, progress, lateralOffset in
                    let distanceToSurface = CGFloat(1.0 - progress) * bubbleTravel
                    return CGPoint(
                        x: surfaceX - buoyancyX * distanceToSurface + tangentX * lateralOffset,
                        y: surfaceY(surfaceX) - buoyancyY * distanceToSurface + tangentY * lateralOffset
                    )
                }
                let waveAmplitude = 1.5 + CGFloat(energy) * 14.0
                let foamHeight = 14.0 + CGFloat(fill) * 46.0
                let foamNormalScale = min(1.65, sqrt(1.0 + slope * slope))
                let foamVerticalHeight = foamHeight * foamNormalScale
                var liquid = Path()
                liquid.move(to: CGPoint(x: 0, y: surfaceY(0)))
                for x in stride(from: 0, through: size.width, by: 8) {
                    let normalizedX = Double(x / size.width)
                    let wave1 = sin(normalizedX * 15.0 + t * 0.9) * waveAmplitude
                    let wave2 = sin(normalizedX * 31.0 - t * 0.5) * waveAmplitude * 0.28
                    let microRipple = sin(normalizedX * 73.0 + t * 1.7 + flow * 4.0) * (0.35 + Double(energy) * 1.8)
                    let crossWave = sin(normalizedX * 9.0 - t * 0.7 + tilt * 5.0) * Double(energy) * 3.5
                    let wakePhase = normalizedX * 44.0 - t * 2.4 + flow * 3.0
                    let wakeEnvelope = exp(-abs(normalizedX - 0.5) * 2.8)
                    let wake = sin(wakePhase) * 7.0 * Double(energy) * wakeEnvelope
                    let waveOffset = CGFloat(wave1 + wave2 + wake + microRipple + crossWave)
                    let y = surfaceY(x) + waveOffset
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
                surfaceGleam.move(to: CGPoint(x: -8, y: surfaceY(-8) + 2))
                for x in stride(from: 0, through: size.width, by: 8) {
                    let normalizedX = Double(x / size.width)
                    let wave = sin(normalizedX * 15.0 + t * 0.9) * waveAmplitude
                    let ripple = sin(normalizedX * 31.0 - t * 0.5) * waveAmplitude * 0.28
                    let micro = sin(normalizedX * 73.0 + t * 1.7 + flow * 4.0) * (0.35 + Double(energy) * 1.8)
                    let cross = sin(normalizedX * 9.0 - t * 0.7 + tilt * 5.0) * Double(energy) * 3.5
                    surfaceGleam.addLine(to: CGPoint(x: x, y: surface + CGFloat(wave + ripple + micro + cross) + slope * (x - size.width / 2) - 1))
                }
                context.drawLayer { layer in
                    layer.addFilter(.blur(radius: 2.5))
                    layer.stroke(surfaceGleam, with: .color(.white.opacity(beer ? 0.22 : 0.08)), lineWidth: 2.2)
                }

                var leftMeniscus = Path()
                let leftSurface = surfaceY(0)
                let rightSurface = surfaceY(size.width)
                leftMeniscus.move(to: CGPoint(x: 1, y: leftSurface - 10))
                leftMeniscus.addCurve(to: CGPoint(x: 10, y: leftSurface + 20), control1: CGPoint(x: 1, y: leftSurface - 2), control2: CGPoint(x: 5, y: leftSurface + 10))
                var rightMeniscus = Path()
                rightMeniscus.move(to: CGPoint(x: size.width - 1, y: rightSurface - 10))
                rightMeniscus.addCurve(to: CGPoint(x: size.width - 10, y: rightSurface + 20), control1: CGPoint(x: size.width - 1, y: rightSurface - 2), control2: CGPoint(x: size.width - 5, y: rightSurface + 10))
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
                    leftEdge.move(to: CGPoint(x: 3, y: leftSurface + 18))
                    leftEdge.addLine(to: CGPoint(x: 3, y: size.height))
                    var rightEdge = Path()
                    rightEdge.move(to: CGPoint(x: size.width - 3, y: rightSurface + 18))
                    rightEdge.addLine(to: CGPoint(x: size.width - 3, y: size.height))
                    let edgeLight = beer ? 0.075 + abs(tilt) * 0.035 : 0.03
                    let edgeShade = beer ? 0.17 + abs(tilt) * 0.025 : 0.22
                    layer.stroke(leftEdge, with: .color(.white.opacity(edgeLight)), lineWidth: 10)
                    layer.stroke(rightEdge, with: .color(.black.opacity(edgeShade)), lineWidth: 14)
                }

                let foam = beer ? Color(red: 1.0, green: 0.94, blue: 0.78) : Color(red: 0.52, green: 0.30, blue: 0.18)
                var foamBand = Path()
                foamBand.move(to: CGPoint(x: 0, y: surfaceY(0) - foamVerticalHeight))
                for x in stride(from: 0, through: size.width, by: 8) {
                    let normalizedX = Double(x / size.width)
                    let foamWave = sin(normalizedX * 17.0 + t * 0.55) * (1.8 + CGFloat(energy) * 7)
                    let foamRipple = sin(normalizedX * 41.0 - t * 0.9 + flow * 2.0) * (0.6 + CGFloat(energy) * 2.4)
                    let y = surfaceY(x) - foamVerticalHeight + foamWave + foamRipple
                    foamBand.addLine(to: CGPoint(x: x, y: y))
                }
                for x in stride(from: size.width, through: 0, by: -8) {
                    foamBand.addLine(to: CGPoint(x: x, y: surfaceY(x) + 27 * foamNormalScale))
                }
                foamBand.closeSubpath()
                context.fill(foamBand, with: .linearGradient(Gradient(colors: [foam.opacity(0.98), foam.opacity(0.70)]), startPoint: CGPoint(x: 0, y: surface - foamVerticalHeight), endPoint: CGPoint(x: 0, y: surface + 27 * foamNormalScale)))

                var foamShadow = Path()
                foamShadow.move(to: CGPoint(x: -10, y: surfaceY(-10) + 5 + CGFloat(flow) * 2.0))
                for x in stride(from: 0, through: size.width + 10, by: 12) {
                    let shadowWave = CGFloat(sin(Double(x / size.width) * 12.0 + t * 0.5)) * (1.5 + CGFloat(energy) * 2.0)
                    foamShadow.addLine(to: CGPoint(x: x, y: surfaceY(x) + 6 + shadowWave))
                }
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
                    let y = surfaceY(x) - foamVerticalHeight * (0.36 + CGFloat(yNoise) * 0.55) + yOffset
                    let dome = CGRect(x: x - radius, y: y - radius * 0.60, width: radius * 2, height: radius * 1.20)
                    context.fill(Path(ellipseIn: dome), with: .radialGradient(Gradient(colors: [Color.white.opacity(0.40), foam.opacity(0.24), Color.black.opacity(0.12)]), center: CGPoint(x: x - radius * 0.24, y: y - radius * 0.26), startRadius: 0, endRadius: radius * 1.25))
                }

                // Slosh breaks a few foam pockets loose at the surface.
                if beer && energy > 0.12 {
                    for i in 0..<14 {
                        let seed = Double(i) * 15.617
                        let x = CGFloat((sin(seed * 1.8 + flow) * 43758.5).truncatingRemainder(dividingBy: 1.0).magnitude) * size.width
                        let y = surfaceY(x) + CGFloat(sin(seed * 2.4 + t * 1.6) * energy * 11.0) + CGFloat((sin(seed) * 0.5 + 0.5)) * 18
                        let radius = CGFloat(0.7 + Double(i % 3) * 0.55) * CGFloat(0.7 + energy)
                        context.fill(Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)), with: .color(.white.opacity(0.28 * energy)))
                    }
                }

                for i in 0..<42 {
                    let seed = Double(i) * 9.173
                    let x = CGFloat((sin(seed) * 43758.5).truncatingRemainder(dividingBy: 1.0).magnitude) * size.width
                    let y = surfaceY(x) - foamVerticalHeight + CGFloat((sin(seed * 1.7 + t * 0.3) * 0.5 + 0.5)) * (foamVerticalHeight + 20)
                    let radius = CGFloat(2 + Double(i % 4) * 2)
                    context.fill(Path(ellipseIn: CGRect(x: x - radius, y: y - radius * 0.6, width: radius * 2, height: radius * 1.2)), with: .color(foam.opacity(0.22)))
                }

                for i in 0..<24 {
                    let seed = Double(i) * 6.417
                    let x = CGFloat((sin(seed * 2.1) * 43758.5).truncatingRemainder(dividingBy: 1.0).magnitude) * size.width
                    let y = surfaceY(x) - 8 + CGFloat((sin(seed * 1.3) * 0.5 + 0.5)) * 28
                    let radius = CGFloat(2 + (i % 3))
                    context.fill(Path(ellipseIn: CGRect(x: x - radius, y: y - radius * 0.55, width: radius * 2, height: radius * 1.1)), with: .color(.black.opacity(0.065)))
                }

                // Foam cells catch a narrow highlight and keep a soft shadow on their lower rim.
                for i in 0..<30 {
                    let seed = Double(i) * 4.271
                    let x = CGFloat((sin(seed * 2.7) * 43758.5).truncatingRemainder(dividingBy: 1.0).magnitude) * size.width
                    let y = surfaceY(x) - foamVerticalHeight * 0.72 + CGFloat((sin(seed * 1.9 + t * 0.22) * 0.5 + 0.5)) * (foamVerticalHeight * 1.35)
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
                    let y = surfaceY(x) - foamVerticalHeight * 0.58 + CGFloat((sin(seed * 2.3 + t * 0.16) * 0.5 + 0.5)) * (foamVerticalHeight * 0.82)
                    let radius = CGFloat(4 + (i % 3) * 2)
                    let bubbleRect = CGRect(x: x - radius, y: y - radius * 0.58, width: radius * 2, height: radius * 1.16)
                    context.fill(Path(ellipseIn: bubbleRect), with: .radialGradient(Gradient(colors: [.white.opacity(0.44), foam.opacity(0.18), .black.opacity(0.16)]), center: CGPoint(x: x - radius * 0.28, y: y - radius * 0.24), startRadius: 0, endRadius: radius * 1.25))
                    context.stroke(Path(ellipseIn: bubbleRect.insetBy(dx: 0.8, dy: 0.8)), with: .color(.white.opacity(0.30)), lineWidth: 0.8)
                }

                var foamReflection = Path()
                foamReflection.move(to: CGPoint(x: -20, y: surfaceY(-20) + 5))
                for x in stride(from: 0, through: size.width + 20, by: 12) {
                    let reflectionWave = CGFloat(sin(Double(x / size.width) * 10.0 + t * 0.45)) * 2.0
                    foamReflection.addLine(to: CGPoint(x: x, y: surfaceY(x) + 7 + reflectionWave))
                }
                context.drawLayer { layer in
                    layer.addFilter(.blur(radius: 5))
                    layer.stroke(foamReflection, with: .color(.white.opacity(beer ? 0.36 : 0.12)), lineWidth: 3.5)
                }

                if beer {
                    for i in 0..<9 {
                        let seed = Double(i) * 8.31
                        let x = CGFloat((sin(seed * 1.91 + t * 0.12) * 43758.5).truncatingRemainder(dividingBy: 1.0).magnitude) * size.width
                        let y = surfaceY(x) - foamVerticalHeight * 0.14 + CGFloat(sin(seed * 1.4 + t * 0.4) * 3.0)
                        var wetHighlight = Path()
                        wetHighlight.move(to: CGPoint(x: x - 8, y: y))
                        wetHighlight.addCurve(to: CGPoint(x: x + 10, y: y + 1), control1: CGPoint(x: x - 3, y: y - 3), control2: CGPoint(x: x + 4, y: y + 3))
                        context.stroke(wetHighlight, with: .color(.white.opacity(0.18)), lineWidth: 1.4)
                    }
                    for i in 0..<12 {
                        let seed = Double(i) * 6.73
                        let x = CGFloat((sin(seed * 2.11) * 43758.5).truncatingRemainder(dividingBy: 1.0).magnitude) * size.width
                        let y = surfaceY(x) + 11 + CGFloat((sin(seed * 1.8) * 0.5 + 0.5) * 12)
                        let radius = CGFloat(2.0 + Double(i % 3))
                        let lace = Path(ellipseIn: CGRect(x: x - radius, y: y - radius * 0.45, width: radius * 2, height: radius * 0.9))
                        context.stroke(lace, with: .color(.white.opacity(0.16)), lineWidth: 0.7)
                    }
                }

                // From here down, carbonation and internal light must remain below
                // the tilted free surface instead of leaking into the empty region.
                context.clip(to: liquid)

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
                    let surfaceX = CGFloat((sin(seed) * 43758.5).truncatingRemainder(dividingBy: 1.0).magnitude) * size.width
                    let speed = 0.015 + Double(i % 5) * 0.004
                    let progress = (t * speed + Double(i) * 0.071).truncatingRemainder(dividingBy: 1.0)
                    let lateral = CGFloat(sin(t * 0.7 + seed) * 3.0) + CGFloat(flow) * CGFloat(progress) * 10.0
                    let point = bubblePoint(surfaceX, progress, lateral)
                    let x = point.x
                    let y = point.y
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
                    let surfaceX = CGFloat((sin(seed * 3.7) * 43758.5).truncatingRemainder(dividingBy: 1.0).magnitude) * size.width
                    let progress = (t * (0.010 + Double(i % 4) * 0.002) + seed).truncatingRemainder(dividingBy: 1.0)
                    let lateral = CGFloat(sin(t * 0.45 + seed) * 1.5)
                    let point = bubblePoint(surfaceX, progress, lateral)
                    let x = point.x
                    let y = point.y
                    let r = CGFloat(0.35 + Double(i % 3) * 0.22)
                    context.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(.white.opacity(beer ? 0.16 : 0.07)))
                }

                context.drawLayer { layer in
                    layer.addFilter(.blur(radius: 1.8))
                    for i in 0..<8 {
                        let seed = Double(i) * 19.17
                        let surfaceX = CGFloat((sin(seed * 2.8) * 43758.5).truncatingRemainder(dividingBy: 1.0).magnitude) * size.width
                        let rise = (t * 0.014 + seed).truncatingRemainder(dividingBy: 1.0)
                        let lateral = CGFloat(sin(t * 0.38 + seed) * 4.0)
                        let point = bubblePoint(surfaceX, rise, lateral)
                        var wakeTrail = Path()
                        wakeTrail.move(to: CGPoint(x: point.x - buoyancyX * 11, y: point.y - buoyancyY * 11))
                        wakeTrail.addCurve(
                            to: CGPoint(x: point.x + buoyancyX * 7, y: point.y + buoyancyY * 7),
                            control1: CGPoint(x: point.x - buoyancyX * 5 - tangentX * 3, y: point.y - buoyancyY * 5 - tangentY * 3),
                            control2: CGPoint(x: point.x + buoyancyX * 2 + tangentX * 4, y: point.y + buoyancyY * 2 + tangentY * 4)
                        )
                        layer.stroke(wakeTrail, with: .color(.white.opacity(beer ? 0.035 : 0.015)), lineWidth: 2.0)
                    }
                }

                // Carbonation rises in loose trails rather than as a uniform random field.
                for lane in 0..<18 {
                    let seed = Double(lane) * 17.31
                    let originX = CGFloat((sin(seed) * 43758.5).truncatingRemainder(dividingBy: 1.0).magnitude) * size.width
                    for bead in 0..<7 {
                        let beadPhase = (t * (0.018 + Double(lane % 4) * 0.002) + Double(bead) * 0.11 + seed).truncatingRemainder(dividingBy: 1.0)
                        let lateral = CGFloat(sin(beadPhase * 13.0 + seed) * (4.0 + beadPhase * 16.0)) + CGFloat(flow) * CGFloat(beadPhase) * 8
                        let point = bubblePoint(originX, beadPhase, lateral)
                        let x = point.x
                        let y = point.y
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
                        let surfaceX = CGFloat((sin(seed * 1.9) * 43758.5).truncatingRemainder(dividingBy: 1.0).magnitude) * size.width
                        let rise = (t * (0.006 + depth * 0.006) + seed).truncatingRemainder(dividingBy: 1.0)
                        let lateral = CGFloat(sin(t * 0.3 + seed) * (2.0 + depth * 5.0))
                        let point = bubblePoint(surfaceX, rise, lateral)
                        let x = point.x
                        let y = point.y
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

/// Finds the vertical intercept of a world-horizontal free surface while
/// preserving the visible 2D liquid area in the rectangular phone-cup.
private func conservedSurfaceCenter(size: CGSize, fill: Double, slope: CGFloat) -> CGFloat {
    let targetFraction = CGFloat(max(0.0, min(1.0, 0.12 + fill * 0.80)))
    let samples = 48

    func liquidFraction(center: CGFloat) -> CGFloat {
        var sum: CGFloat = 0
        for index in 0..<samples {
            let x = (CGFloat(index) + 0.5) / CGFloat(samples) * size.width
            let lineY = center + slope * (x - size.width * 0.5)
            let clippedY = max(0, min(size.height, lineY))
            sum += (size.height - clippedY) / size.height
        }
        return sum / CGFloat(samples)
    }

    var low = -size.height * 2
    var high = size.height * 3
    for _ in 0..<18 {
        let middle = (low + high) * 0.5
        if liquidFraction(center: middle) > targetFraction {
            low = middle
        } else {
            high = middle
        }
    }
    return (low + high) * 0.5
}

private final class MotionManager: ObservableObject {
    @Published var tilt: Double = 0
    @Published var level: Double = 0.94
    @Published var sloshEnergy: Double = 0
    @Published var flow: Double = 0
    @Published var isDrinking = false
    private let manager = CMMotionManager()
    private var tiltVelocity: Double = 0
    private var drainRate: Double = 0
    private var lastMotionTimestamp: TimeInterval?

    func start() {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        manager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            let gravity = motion.gravity
            let rawDelta = lastMotionTimestamp.map { motion.timestamp - $0 } ?? (1.0 / 30.0)
            let deltaTime = max(1.0 / 120.0, min(1.0 / 15.0, rawDelta))
            lastMotionTimestamp = motion.timestamp
            // This is a side-view glass: only the screen's left/right edge may tilt.
            // gravity.x is the vertical component of that edge, so asin gives its
            // world-space angle without letting front/back pitch (y/z) rotate it.
            let lateralTilt = asin(max(-1.0, min(1.0, -gravity.x)))
            let targetTilt = max(-1.15, min(1.15, lateralTilt))
            let previousTilt = self.tilt
            let horizonResponse = 1.0 - exp(-deltaTime * 16.0)
            self.tilt += (targetTilt - self.tilt) * horizonResponse
            self.tilt = max(-1.15, min(1.15, self.tilt))
            let angularSpeed = (self.tilt - previousTilt) / deltaTime
            self.tiltVelocity += (angularSpeed - self.tiltVelocity) * 0.28

            // Hand acceleration excites waves, but never rotates the mean free
            // surface away from the gravity-defined world horizon.
            let handJolt = motion.userAcceleration.x * 0.018 + motion.userAcceleration.y * 0.008
            let lateralImpulse = max(-0.035, min(0.035, handJolt))
            let decayedEnergy = self.sloshEnergy * exp(-deltaTime * 2.2)
            self.sloshEnergy = min(1.0, max(abs(angularSpeed) * 0.14, abs(lateralImpulse) * 12.0, decayedEnergy))
            self.flow = max(-1.0, min(1.0, angularSpeed * 0.12 + lateralImpulse * 6.0))
            // The visible left/right rim is the only spill edge in this side-view
            // simulation. Front/back pitch is deliberately ignored here as well.
            let spillAngle = abs(lateralTilt)
            let spillThreshold = 0.70
            let emptyAngle = 1.48
            let spillProgress = max(0.0, min(1.0, (spillAngle - spillThreshold) / (emptyAngle - spillThreshold)))
            let smoothSpill = spillProgress * spillProgress * (3.0 - 2.0 * spillProgress)
            let retainedLevel = max(0.06, 0.94 - smoothSpill * 0.88)
            let overflow = max(0.0, self.level - retainedLevel)
            self.isDrinking = overflow > 0.001
            let targetDrainRate = self.isDrinking
                ? min(0.26, 0.015 + overflow * 0.28 + spillProgress * 0.035)
                : 0.0
            let drainResponse = 1.0 - exp(-deltaTime * (self.isDrinking ? 5.0 : 12.0))
            self.drainRate += (targetDrainRate - self.drainRate) * drainResponse
            if self.isDrinking {
                let drainedVolume = min(overflow, self.drainRate * deltaTime)
                self.level = max(0.06, self.level - drainedVolume)
            } else if self.drainRate < 0.0001 {
                self.drainRate = 0
            }
        }
    }

    func refill() {
        level = 0.94
        drainRate = 0
        isDrinking = false
        sloshEnergy = max(sloshEnergy, 0.28)
    }

    deinit { manager.stopDeviceMotionUpdates() }
}

#Preview { ContentView() }
