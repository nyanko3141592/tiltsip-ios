# iBeer

SwiftUI + Metal で作った、ビール／コーラを注いで遊べる iOS アプリのMVPです。

## 仕様

- ビール／コーラ切り替え
- スライダーで注ぐ量を調整
- ドラッグでグラスを傾ける
- タップで注ぐ／停止、リセット
- Metal compute shader が液体・泡・気泡の粒子を毎フレーム更新
- Metal render pipeline が粒子をグラス内に描画

## Build

```sh
xcodegen generate
xcodebuild -project iBeer.xcodeproj -scheme iBeer -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build
```

