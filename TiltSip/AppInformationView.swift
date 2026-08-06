import SwiftUI

enum AppLinks {
    static let privacy = URL(string: "https://nyanko3141592.github.io/tiltsip-ios/privacy/")!
    static let support = URL(string: "https://nyanko3141592.github.io/tiltsip-ios/support/")!
}

struct AppInformationView: View {
    @Environment(\.dismiss) private var dismiss
    let onRefill: () -> Void
    let onReplayOnboarding: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        onRefill()
                        dismiss()
                    } label: {
                        Label("グラスを満タンに戻す", systemImage: "arrow.clockwise")
                    }

                    Button {
                        onReplayOnboarding()
                        dismiss()
                    } label: {
                        Label("使い方をもう一度見る", systemImage: "hand.tap")
                    }
                }

                Section("使い方") {
                    Label("左右に傾けて飲む", systemImage: "arrow.left.and.right")
                    Label("液体部分をタップして種類を変更", systemImage: "drop")
                    Text("傾き情報は液体表現のため端末内でのみ処理され、保存・送信されません。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("サポート") {
                    Link(destination: AppLinks.privacy) {
                        Label("プライバシーポリシー", systemImage: "hand.raised")
                    }
                    Link(destination: AppLinks.support) {
                        Label("サポート・お問い合わせ", systemImage: "questionmark.circle")
                    }
                }

                Section {
                    LabeledContent("アプリ", value: "TiltSip")
                    LabeledContent("バージョン", value: versionDescription)
                }
            }
            .navigationTitle("TiltSip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                }
            }
        }
    }

    private var versionDescription: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }
}

#Preview("Information") {
    AppInformationView(onRefill: {}, onReplayOnboarding: {})
}
