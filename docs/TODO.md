# TODO ── 今後やること

『アムネジィ・ケース ──教授の不完全な安楽──』の残作業一覧。
**コード/データ/謎の設計は実装・静的検証まで完了**（`flutter analyze`＝No issues／`flutter test`＝12/12）。
ここから先は **①実プレイ確認 → ②アセット制作 → ③配信** が主軸。

> 凡例： 🔴最優先 / 🟡やるべき / 🟢任意（伸びしろ） ／ ☐未着手 ・ ☑完了

---

## 0. いま完了していること（参考）
- ☑ 深い部屋エンジン（4方向・ネスト調査・合成・多段ロック・セーブ/レジューム/ポーズ）
- ☑ 作話システム（GEDÄCHTNIS→VERLUST、作話完全度 I=(T×M)(1+E/3)、7結末＋D）
- ☑ 謎の多様化：暗証錠(number/text)・dial・sequence・**dialogue(対峙)**・**scrub(記憶再生)**・①記憶の上書き・②証拠連結盤
- ☑ 残る数字錠を diegetic 化（R4=7305／R6=0345／R7=0415）
- ☑ 各種仕様書・生成手順書（画像/音響/配信）

---

## 1. 🔴 実プレイテスト（最優先・唯一の本質的残課題）
机上では全て緑だが、**新メカが大量に未プレイテスト**。テンポ・難易度・手触りは実際に触らないと分からない。

- ☐ 通しプレイ（R1→R13→30号室→結末）を最低1周　※Edge or 自宅Android
- ☐ 新メカの手触り確認：dial(R3)／sequence(R11,R12)／**dialogue(R8)**／**scrub(R10)**／①(R3,R6,R7)／②(30号室)
- ☐ 7結末すべてに到達できるか検証（A+ / A / B / C / S / True / D）
- ☐ 脳死タイマーの妥当性（ノーマル1500 / タイマー900 / ハード720秒）
- ☐ 詰み防止（3段ヒント・スキップ）が機能するか
- ☐ セーブ/「つづきから」/バックグラウンド復帰/結末コレクション
- ☐ ハードモード（reveal_hard・最終ヒント封じ）の難度確認
- ☐ プレイして気になった点を `謎案_全室.md` §6 の観点で記録 → 次の調整へ

> 起動：自宅Androidは `flutter run`（無改修）。社内Edgeは Web実行（ads/dart:io のWeb対応が要・下記6章）。

---

## 2. 🟡 アセット制作（画像・フォント）
エンジンは描画対応済。**画像を置けば即反映**（未配置でも errorBuilder でフォールバックし動く）。

- ☐ 背景画像 13室 × 4方向（`assets/images/rooms/<id>_<dir>.png`）
- ☐ アイテムアイコン（`assets/images/items/<itemId>.png`）
- ☐ タイトル/結末用のキービジュアル（任意）
- ☐ 配置後、`pubspec.yaml` の `assets:` に画像ディレクトリを登録
- ☐ 黒文字体フォント UnifrakturMaguntia(.ttf) を `assets/fonts/` に配置 → `pubspec.yaml` の `# fonts:` コメント解除（グリフHUD用）
- 参考：[アセット仕様書](アセット仕様書.md)（必要画像一覧＋生成プロンプト）／[Stable Diffusion手順](StableDiffusion_ローカル生成手順.md)／[Adobe Firefly手順](AdobeFirefly_生成手順.md)

---

## 3. 🟡 音響（BGM・SE）
発火点は配線済（`AudioService`）。**現在は無音スタブ**。

- ☐ BGM 制作/入手：ch1(序)／ch2(中)／ch3(終)／finale／ending
- ☐ SE 制作/入手：lock_open / wrong / pickup / glyph_light / face / overwrite / anagram / verlust / flatline / heartbeat
- ☐ `audioplayers` を pubspec に追加し、音源を `assets/audio/` に配置
- ☐ `lib/audio_service.dart` の `enabled = true` に切替（実装本体を後日実装）
- 参考：[音響仕様書（BGM・SE）](音響仕様書_BGM_SE.md)

---

## 4. 🟢 謎・ゲーム性の伸びしろ（任意）── ✅ 概ね完了（机上A級）
- ☑ 別動詞#3「追跡」（R9：気配を方向で追い詰めて隠しS鍵を入手）
- ☑ R6 の論証を逆転裁判式に（消去法でアリバイを突きつけ→残るアリバイ無き私）。対峙エンジンを cards/terminal で一般化
- ☑ 演出強化（部屋クリア時のトラウマ文字 発火フラッシュ＋HUDグロウ）
- ☐ （任意）さらなる新動詞、R7も対峙化、カットイン等の追加演出
- 参考：[謎案_全室](謎案_全室.md) §6 自己評価

---

## 5. 🟡 配信（リリース）
WindowsとiPhone/Androidのみで配信する段取り。

- ☐ 自宅PCで Android ビルド（`flutter build apk` / 実機 `flutter run`）
- ☐ iPhone：TestFlight 配信（Mac不要ルート）→ 使用感確認
- ☐ ストア用素材：アプリアイコン・スクリーンショット・説明文・年齢レーティング（流血表現に注意）
- ☐ プライバシーポリシー（広告/データ収集を入れる場合）
- 参考：[iPhone配信手順（Windowsのみ）](iPhone配信手順_Windowsのみ.md)

---

## 6. 🟢 技術的後始末（必要時）
- ☐ Web(Edge)で動かすなら：`ad_service`/`dart:io` 依存箇所のWeb対応 or 分岐（`web/` 生成含む）
- ☐ マネタイズ時：AdMob アプリID設定 → `ad_service` を本番実装 → `enabled=true`（[README](../README.md) の広告手順）
- ☐ パッケージ名/表示名の最終確認（内部 `kioku_no_kairou` は不変、表示は「アムネジィ・ケース」）
- ☐ `pubspec.yaml` の依存最終整理（shared_preferences＋audioplayers＋必要なら ads）

---

## 推奨の進め方
**1) まず実プレイ（1章）で手触りを掴む → 2) 画像・音（2,3章）でゲームを“本物”にする → 3) 配信（5章）。**
4章（謎の伸びしろ）と6章（技術後始末）は、その合間に必要に応じて。
