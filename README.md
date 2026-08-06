# TiltSip

TiltSip turns the entire iPhone display into a playful, physics-driven glass.
Tilt the phone sideways to drink, watch the world-horizontal surface spill at the
rim, and tap the liquid to switch between beer and cola.

SwiftUI、Core Motion、Metalで作った、画面全体を器に見立てる液体シミュレーションiOSアプリです。

## 仕様

- ビール／コーラ切り替え（画面タップ）
- 画面全体を液体面として表示
- 左右の傾きだけに反応する水平液面と流出モデル
- 重力と逆方向へ上昇する炭酸・泡
- Metal compute shader による気泡計算
- Metal render pipeline による液面描画
- 初回オンボーディング、補充、プライバシー／サポート導線

## Privacy

Motion data is processed only on the device to animate the liquid. The app does
not collect, retain, or transmit personal data. See the [privacy policy](docs/privacy/index.html).

## Build

```sh
xcodegen generate
xcodebuild -project TiltSip.xcodeproj -scheme TiltSip -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build
```

## Requirements

- iOS 18 or later
- Xcode 26.2 or later
- iPhone (portrait only)

Copyright © 2026 Naoki Takahashi. No license is granted for redistribution or
commercial use unless stated otherwise.
