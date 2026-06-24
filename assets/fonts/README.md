# 黒文字体（亜簪文字）フォントの配置

HUD・結末画面・R13収束演出の符号（GEDÄCHTNIS / VERLUST）を亀甲文字で表示するためのフォント置き場です。

## 手順（自宅PC＝ネットワーク可の環境で）
1. Google Fonts の **UnifrakturMaguntia**（SIL Open Font License）を入手
   - https://fonts.google.com/specimen/UnifrakturMaguntia
2. ダウンロードした `.ttf` を、このフォルダに **`UnifrakturMaguntia-Regular.ttf`** という名前で置く
3. `pubspec.yaml` 末尾の `# fonts:` ブロックのコメントを外す
4. `flutter pub get` → `flutter run`

## 未配置の場合
コード側は `fontFamily: 'Blackletter'` を参照していますが、未登録時は標準フォントに
自動フォールバックするため**ビルド・実行は問題なく通ります**（見た目が亀甲文字でないだけ）。

UnifrakturMaguntia は通常のラテン文字（T, S, Ä, G…）をそのまま黒文字体で描くため、
数学用フラクトゥール Unicode（𝔗 等）の豆腐(□)問題や、Ä が存在しない問題を回避できます。
