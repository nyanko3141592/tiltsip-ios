import SwiftUI

enum Drink: String, CaseIterable, Identifiable {
    case beer = "ビール"
    case cola = "コーラ"
    var id: Self { self }
    var tint: Color { self == .beer ? Color(red: 0.98, green: 0.55, blue: 0.10) : Color(red: 0.14, green: 0.04, blue: 0.025) }
    var secondary: Color { self == .beer ? Color(red: 1.0, green: 0.78, blue: 0.25) : Color(red: 0.36, green: 0.10, blue: 0.045) }
    var symbol: String { self == .beer ? "🍺" : "🥤" }
}

struct ContentView: View {
    @State private var drink: Drink = .beer
    private let fill = 1.0
    private let carbonation = 0.72
    private let tilt = 0.0
    private let isPouring = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.035, green: 0.045, blue: 0.075), Color(red: 0.10, green: 0.055, blue: 0.11)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Spacer(minLength: 8)
                ZStack {
                    GlassShape(fill: fill, drink: drink, tilt: tilt)
                    MetalGlassView(drink: drink, fill: fill, carbonation: carbonation, tilt: tilt, isPouring: isPouring)
                }
                    .frame(maxWidth: .infinity, maxHeight: 500)
                Spacer(minLength: 14)
                controls
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("iBeer").font(.system(size: 34, weight: .black, design: .rounded))
                Text("満杯のコップ").font(.subheadline.weight(.medium)).foregroundStyle(.white.opacity(0.55))
            }
            Spacer()
        }
    }

    private var controls: some View {
        VStack(spacing: 18) {
            Picker("ドリンク", selection: $drink) {
                ForEach(Drink.allCases) { item in Text("\(item.symbol)  \(item.rawValue)").tag(item) }
            }.pickerStyle(.segmented).accessibilityIdentifier("drinkPicker")
            Text("コップを置いて、好きな飲み物を選べます").font(.caption).foregroundStyle(.white.opacity(0.42))
        }
        .padding(.bottom, 8)
    }
}

private struct GlassShape: View {
    let fill: Double
    let drink: Drink
    let tilt: Double
    var body: some View {
        GeometryReader { proxy in
            let w = min(proxy.size.width * 0.58, 220.0)
            let h = min(proxy.size.height * 0.88, 390.0)
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: w * 0.12, style: .continuous)
                    .fill(.white.opacity(0.045))
                    .overlay(RoundedRectangle(cornerRadius: w * 0.12, style: .continuous).stroke(.white.opacity(0.26), lineWidth: 2))
                    .frame(width: w, height: h)
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 20).fill(drink == .beer ? Color.white.opacity(0.8) : Color.white.opacity(0.18)).frame(height: min(50, h * 0.13))
                    Rectangle().fill(drink.tint.opacity(0.78)).frame(height: max(0, h * fill * 0.72))
                }
                .frame(width: w - 8, height: h * 0.82, alignment: .bottom)
                .clipShape(RoundedRectangle(cornerRadius: w * 0.10, style: .continuous))
                Rectangle().fill(.white.opacity(0.16)).frame(width: 4, height: h * 0.74).offset(x: -w * 0.28)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .rotationEffect(.degrees(tilt))
            .shadow(color: drink.tint.opacity(0.22), radius: 28, y: 18)
        }
        .allowsHitTesting(false)
    }
}

#Preview { ContentView() }
