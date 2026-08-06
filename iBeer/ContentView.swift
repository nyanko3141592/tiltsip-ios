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
    @State private var fill: Double = 0.76
    @State private var carbonation: Double = 0.68
    @State private var tilt: Double = 0
    @State private var isPouring = true
    @State private var dragStartTilt: Double?

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.035, green: 0.045, blue: 0.075), Color(red: 0.10, green: 0.055, blue: 0.11)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Spacer(minLength: 12)
                ZStack {
                    GlassShape(fill: fill, drink: drink, tilt: tilt)
                    MetalGlassView(drink: drink, fill: fill, carbonation: carbonation, tilt: tilt, isPouring: isPouring)
                }
                    .frame(maxWidth: .infinity, maxHeight: 460)
                    .contentShape(Rectangle())
                    .gesture(tiltGesture)
                    .onTapGesture { withAnimation(.spring(response: 0.35)) { isPouring.toggle() } }
                Spacer(minLength: 8)
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
                Text(isPouring ? "注いでいます…" : "タップして注ぐ").font(.subheadline.weight(.medium)).foregroundStyle(.white.opacity(0.55))
            }
            Spacer()
            Button { withAnimation(.spring) { fill = 0.04; isPouring = false } } label: {
                Image(systemName: "arrow.counterclockwise").font(.headline).frame(width: 42, height: 42).background(.white.opacity(0.10), in: Circle())
            }.accessibilityLabel("リセット")
        }
    }

    private var controls: some View {
        VStack(spacing: 18) {
            Picker("ドリンク", selection: $drink) {
                ForEach(Drink.allCases) { item in Text("\(item.symbol)  \(item.rawValue)").tag(item) }
            }.pickerStyle(.segmented).accessibilityIdentifier("drinkPicker")

            VStack(spacing: 10) {
                sliderRow(title: "注ぐ量", value: $fill, range: 0.08...1.0, icon: "drop.fill")
                sliderRow(title: "炭酸", value: $carbonation, range: 0...1, icon: "sparkles")
            }

            Button {
                withAnimation(.spring(response: 0.3)) { isPouring.toggle() }
            } label: {
                Label(isPouring ? "注ぐのを止める" : "注ぐ", systemImage: isPouring ? "pause.fill" : "play.fill")
                    .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(drink.tint.gradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .foregroundStyle(.white)
            .accessibilityIdentifier("pourButton")
            Text("グラスを左右にドラッグして傾けられます").font(.caption).foregroundStyle(.white.opacity(0.42))
        }
        .padding(.bottom, 8)
    }

    private func sliderRow(title: String, value: Binding<Double>, range: ClosedRange<Double>, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(drink.secondary).frame(width: 20)
            Text(title).font(.subheadline.weight(.semibold)).frame(width: 54, alignment: .leading)
            Slider(value: value, in: range).tint(drink.secondary)
            Text("\(Int(value.wrappedValue * 100))%").font(.caption.monospacedDigit()).foregroundStyle(.white.opacity(0.55)).frame(width: 38, alignment: .trailing)
        }
    }

    private var tiltGesture: some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { gesture in
                if dragStartTilt == nil { dragStartTilt = tilt }
                tilt = min(18, max(-18, (dragStartTilt ?? 0) + gesture.translation.width / 8))
            }
            .onEnded { _ in dragStartTilt = nil }
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
