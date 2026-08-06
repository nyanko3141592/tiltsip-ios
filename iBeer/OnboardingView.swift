import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var page = 0

    private let pages = OnboardingPage.allCases

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.18, green: 0.10, blue: 0.01)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("WATER SIM")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .tracking(2.6)
                    Spacer()
                    Text("\(page + 1) / \(pages.count)")
                        .font(.caption.monospacedDigit())
                }
                .foregroundStyle(.white.opacity(0.55))
                .padding(.horizontal, 24)
                .padding(.top, 12)

                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                        OnboardingPageView(page: item)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                VStack(spacing: 20) {
                    HStack(spacing: 7) {
                        ForEach(pages.indices, id: \.self) { index in
                            Capsule()
                                .fill(index == page ? Color.white : Color.white.opacity(0.22))
                                .frame(width: index == page ? 24 : 7, height: 7)
                                .animation(.easeOut(duration: 0.2), value: page)
                        }
                    }

                    Button(page == pages.count - 1 ? "はじめる" : "次へ") {
                        if page == pages.count - 1 {
                            onComplete()
                        } else {
                            withAnimation(.easeInOut(duration: 0.28)) { page += 1 }
                        }
                    }
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(.white, in: Capsule())
                    .accessibilityHint(page == pages.count - 1 ? "液体シミュレーションを開始します" : "次の説明を表示します")

                    if page == pages.count - 1 {
                        Link("プライバシーポリシー", destination: AppLinks.privacy)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.58))
                    } else {
                        Text("左右にスワイプして移動")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.38))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 22)
            }
        }
    }
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 24)

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 190, height: 190)
                Circle()
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    .frame(width: 150, height: 150)
                Image(systemName: page.symbol)
                    .font(.system(size: 64, weight: .thin))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color(red: 1.0, green: 0.78, blue: 0.20))
                    .rotationEffect(.degrees(page.symbolRotation))
            }

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 29, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                Text(page.message)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.66))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
            }
            .padding(.horizontal, 30)

            Spacer()
        }
        .foregroundStyle(.white)
    }
}

private enum OnboardingPage: CaseIterable {
    case glass
    case tilt
    case switchDrink

    var symbol: String {
        switch self {
        case .glass: "iphone"
        case .tilt: "arrow.left.and.right"
        case .switchDrink: "drop.fill"
        }
    }

    var symbolRotation: Double {
        self == .tilt ? -8 : 0
    }

    var title: String {
        switch self {
        case .glass: "Phoneがグラスになる"
        case .tilt: "左右に傾けて飲む"
        case .switchDrink: "タップで切り替える"
        }
    }

    var message: String {
        switch self {
        case .glass:
            "画面の上端がグラスの縁。\n液体は最初から並々入っています。"
        case .tilt:
            "端末を左右に傾けると水面は水平を保ち、\n縁を越えた分だけ自然に減っていきます。"
        case .switchDrink:
            "液体部分をタップするとビールとコーラを変更。\n上部の名前をタップすると補充できます。"
        }
    }
}

#Preview("Onboarding") {
    OnboardingView(onComplete: {})
}
