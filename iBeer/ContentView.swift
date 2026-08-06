import SwiftUI

enum Drink: String, CaseIterable, Identifiable {
    case beer = "BEER"
    case cola = "COLA"
    var id: Self { self }
}

struct ContentView: View {
    @State private var drink: Drink = .beer

    var body: some View {
        ZStack {
            FluidBackdrop(drink: drink)
            MetalGlassView(drink: drink, fill: 0.73, carbonation: 0.82, tilt: 0, isPouring: false)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            HStack(spacing: 8) {
                Circle().fill(drink == .beer ? Color.orange : Color.red.opacity(0.7)).frame(width: 7, height: 7)
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
    }
}

private struct FluidBackdrop: View {
    let drink: Drink

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            FluidCanvas(drink: drink, time: timeline.date.timeIntervalSinceReferenceDate)
        }
    }
}

private struct FluidCanvas: View {
    let drink: Drink
    let time: TimeInterval

    var body: some View {
        Canvas { context, size in
                let t = time
                let surface = size.height * 0.32
                var liquid = Path()
                liquid.move(to: CGPoint(x: 0, y: surface))
                for x in stride(from: 0, through: size.width, by: 8) {
                    let normalizedX = Double(x / size.width)
                    let wave1 = sin(normalizedX * 15.0 + t * 0.9) * 7.0
                    let wave2 = sin(normalizedX * 31.0 - t * 0.5) * 2.0
                    let y = surface + CGFloat(wave1 + wave2)
                    liquid.addLine(to: CGPoint(x: x, y: y))
                }
                liquid.addLine(to: CGPoint(x: size.width, y: size.height))
                liquid.addLine(to: CGPoint(x: 0, y: size.height))
                liquid.closeSubpath()

                let beer = drink == .beer
                let liquidColors: [Color] = beer ? [Color(red: 1.0, green: 0.58, blue: 0.12), Color(red: 0.42, green: 0.075, blue: 0.006)] : [Color(red: 0.25, green: 0.035, blue: 0.02), Color(red: 0.035, green: 0.004, blue: 0.003)]
                context.fill(liquid, with: .linearGradient(Gradient(colors: liquidColors), startPoint: CGPoint(x: 0, y: surface), endPoint: CGPoint(x: 0, y: size.height)))

                let foam = beer ? Color(red: 1.0, green: 0.80, blue: 0.46) : Color(red: 0.28, green: 0.08, blue: 0.06)
                var foamBand = Path()
                foamBand.move(to: CGPoint(x: 0, y: surface - 17))
                for x in stride(from: 0, through: size.width, by: 8) {
                    let y = surface - 17 + sin(Double(x / size.width) * 17.0 + t * 0.55) * 3
                    foamBand.addLine(to: CGPoint(x: x, y: y))
                }
                foamBand.addLine(to: CGPoint(x: size.width, y: surface + 27))
                foamBand.addLine(to: CGPoint(x: 0, y: surface + 27))
                foamBand.closeSubpath()
                context.fill(foamBand, with: .linearGradient(Gradient(colors: [foam.opacity(0.98), foam.opacity(0.70)]), startPoint: CGPoint(x: 0, y: surface - 17), endPoint: CGPoint(x: 0, y: surface + 27)))

                for i in 0..<42 {
                    let seed = Double(i) * 9.173
                    let x = CGFloat((sin(seed) * 43758.5).truncatingRemainder(dividingBy: 1.0).magnitude) * size.width
                    let y = surface - 10 + CGFloat((sin(seed * 1.7 + t * 0.3) * 0.5 + 0.5)) * 32
                    let radius = CGFloat(2 + (i % 4) * 2)
                    context.fill(Path(ellipseIn: CGRect(x: x - radius, y: y - radius * 0.6, width: radius * 2, height: radius * 1.2)), with: .color(foam.opacity(0.22)))
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
                    let y = size.height - progress * (size.height - surface + 30)
                    let r = CGFloat(1.0 + Double(i % 3))
                    let bubble = Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
                    context.stroke(bubble, with: .color(.white.opacity(beer ? 0.35 : 0.20)), lineWidth: 0.8)
                    context.fill(Path(ellipseIn: CGRect(x: x - r * 0.35, y: y - r * 0.45, width: r * 0.45, height: r * 0.45)), with: .color(.white.opacity(beer ? 0.45 : 0.25)))
                }
            }
        }
}

#Preview { ContentView() }
