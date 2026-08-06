import SwiftUI

enum Drink: String, CaseIterable, Identifiable {
    case beer = "ビール"
    case cola = "コーラ"
    var id: Self { self }
    var symbol: String { self == .beer ? "🍺" : "🥤" }
    var liquid: Color { self == .beer ? Color(red: 0.64, green: 0.22, blue: 0.018) : Color(red: 0.10, green: 0.018, blue: 0.012) }
    var glow: Color { self == .beer ? Color(red: 0.98, green: 0.46, blue: 0.055) : Color(red: 0.34, green: 0.07, blue: 0.025) }
}

struct ContentView: View {
    @State private var drink: Drink = .beer

    var body: some View {
        ZStack {
            Color(red: 0.035, green: 0.028, blue: 0.025).ignoresSafeArea()
            RadialGradient(colors: [drink.glow.opacity(0.16), .clear], center: .center, startRadius: 30, endRadius: 330)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Spacer(minLength: 4)
                RealisticGlass(drink: drink)
                    .frame(maxWidth: .infinity, maxHeight: 530)
                Spacer(minLength: 10)
                drinkPicker
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.35), value: drink)
    }

    private var header: some View {
        HStack(alignment: .lastTextBaseline) {
            Text("iBeer").font(.system(size: 30, weight: .black, design: .rounded))
            Text("FULL POUR").font(.system(size: 10, weight: .bold, design: .rounded)).tracking(1.4).foregroundStyle(.white.opacity(0.38))
            Spacer()
        }
    }

    private var drinkPicker: some View {
        Picker("ドリンク", selection: $drink) {
            ForEach(Drink.allCases) { item in Text("\(item.symbol)  \(item.rawValue)").tag(item) }
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier("drinkPicker")
        .padding(.bottom, 8)
    }
}

private struct RealisticGlass: View {
    let drink: Drink

    var body: some View {
        GeometryReader { proxy in
            let width = min(proxy.size.width * 0.64, 252.0)
            let height = min(proxy.size.height * 0.90, 465.0)
            ZStack {
                Ellipse().fill(.black.opacity(0.50)).frame(width: width * 0.82, height: 26).blur(radius: 14).offset(y: height * 0.47)

                ZStack {
                    PintGlassShape()
                        .fill(.white.opacity(0.045))

                    VStack(spacing: 0) {
                        FoamHead(drink: drink).frame(height: height * 0.16)
                        Rectangle()
                            .fill(LinearGradient(colors: [drink.glow, drink.liquid, drink.liquid.opacity(0.88)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(height: height * 0.72)
                    }
                    .frame(width: width - 9, height: height * 0.89, alignment: .top)
                    .clipShape(PintGlassShape())

                    TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                        BubbleField(time: timeline.date.timeIntervalSinceReferenceDate, drink: drink)
                            .frame(width: width - 14, height: height * 0.74)
                            .clipShape(PintGlassShape())
                    }

                    GlassReflections()
                        .frame(width: width, height: height)
                        .clipShape(PintGlassShape())

                    MetalGlassView(drink: drink, fill: 1.0, carbonation: 0.75, tilt: 0, isPouring: false)
                        .frame(width: width - 10, height: height * 0.82)
                        .clipShape(PintGlassShape())
                }
                .frame(width: width, height: height)
                .overlay(PintGlassShape().stroke(.white.opacity(0.42), lineWidth: 1.6))
                .overlay(PintGlassShape().stroke(.black.opacity(0.42), lineWidth: 5).blur(radius: 2).mask(PintGlassShape().stroke(lineWidth: 8)))
                .shadow(color: drink.glow.opacity(0.26), radius: 28, y: 22)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .allowsHitTesting(false)
    }
}

private struct PintGlassShape: Shape {
    func path(in rect: CGRect) -> Path {
        let inset = rect.width * 0.045
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + inset, y: rect.minY + 5))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - inset, y: rect.minY + 5), control: CGPoint(x: rect.midX, y: rect.minY - 2))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.14, y: rect.maxY - rect.height * 0.07))
        path.addQuadCurve(to: CGPoint(x: rect.minX + rect.width * 0.14, y: rect.maxY - rect.height * 0.07), control: CGPoint(x: rect.midX, y: rect.maxY + rect.height * 0.015))
        path.closeSubpath()
        return path
    }
}

private struct FoamHead: View {
    let drink: Drink
    var body: some View {
        GeometryReader { _ in
            let cream = drink == .beer ? Color(red: 1.0, green: 0.83, blue: 0.57) : Color(red: 0.32, green: 0.12, blue: 0.07)
            let lightCream = drink == .beer ? Color(red: 1.0, green: 0.90, blue: 0.70) : Color(red: 0.38, green: 0.15, blue: 0.08)
            ZStack(alignment: .top) {
                Rectangle().fill(cream)
                HStack(spacing: -8) {
                    ForEach(0..<9, id: \.self) { index in
                        Circle().fill(index.isMultiple(of: 3) ? lightCream : cream)
                            .frame(width: CGFloat(22 + (index % 3) * 9), height: CGFloat(18 + (index % 3) * 7))
                            .offset(y: CGFloat(index % 2) * 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .offset(y: -7)
            }
        }
    }
}

private struct BubbleField: View {
    let time: Double
    let drink: Drink
    var body: some View {
        Canvas { context, size in
            let bubbles: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
                (0.18, 0.78, 3, 0.0), (0.31, 0.58, 2, 1.4), (0.43, 0.83, 2.5, 2.2), (0.54, 0.49, 2, 0.8),
                (0.63, 0.72, 3, 2.9), (0.75, 0.37, 1.8, 1.2), (0.27, 0.30, 1.7, 2.7), (0.49, 0.65, 1.5, 4.1)
            ]
            for (x, y, radius, phase) in bubbles {
                let rise = CGFloat((time * 0.022 + Double(phase)).truncatingRemainder(dividingBy: 1.0))
                let point = CGPoint(x: size.width * (x + 0.012 * sin(CGFloat(time) + phase)), y: size.height * (y - rise * 0.16))
                let circle = Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2))
                context.stroke(circle, with: .color(.white.opacity(drink == .beer ? 0.32 : 0.18)), lineWidth: 0.8)
            }
        }
    }
}

private struct GlassReflections: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [.white.opacity(0.42), .white.opacity(0.04), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                .frame(width: 7).blur(radius: 2).offset(x: -72)
            LinearGradient(colors: [.clear, .white.opacity(0.16), .clear], startPoint: .top, endPoint: .bottom)
                .frame(width: 2).offset(x: 77)
            VStack { Spacer(); Rectangle().fill(.white.opacity(0.10)).frame(height: 1).padding(.horizontal, 13) }
        }
    }
}

#Preview { ContentView() }
