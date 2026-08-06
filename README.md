# Water Sim

SwiftUI + Metal で作った、画面全体を器に見立てた液体シミュレーション iOS アプリのMVPです。

## 仕様

- ビール／コーラ切り替え（画面タップ）
- 画面全体を液体面として表示
- Metal compute shader による気泡計算
- Metal render pipeline による液面描画

## Build

```sh
xcodegen generate
xcodebuild -project WaterSim.xcodeproj -scheme WaterSim -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build
```
