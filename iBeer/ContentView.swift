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
                let liquidColors: [Color] = beer ? [Color(red: 1.0, green: 0.52, blue: 0.07), Color(red: 0.52, green: 0.12, blue: 0.01)] : [Color(red: 0.25, green: 0.035, blue: 0.02), Color(red: 0.035, green: 0.004, blue: 0.003)]
                context.fill(liquid, with: .linearGradient(Gradient(colors: liquidColors), startPoint: CGPoint(x: 0, y: surface), endPoint: CGPoint(x: 0, y: size.height)))

                let foam = beer ? Color(red: 1.0, green: 0.80, blue: 0.46) : Color(red: 0.28, green: 0.08, blue: 0.06)
                for i in 0..<18 {
                    let x = size.width * CGFloat(i) / 17.0
                    let y = surface - 5 + sin(CGFloat(i) * 1.9 + CGFloat(t) * 0.6) * 4
                    let radius = 15 + CGFloat((i * 7) % 11)
                    context.fill(Path(ellipseIn: CGRect(x: x - radius, y: y - radius * 0.42, width: radius * 2, height: radius * 0.84)), with: .color(foam.opacity(0.92)))
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
                }
            }
        }
}

#Preview { ContentView() }
