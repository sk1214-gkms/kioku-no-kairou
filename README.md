# アムネジィ・ケース ──教授の不完全な安楽── — 開発リポジトリ

> 旧称：記憶の回廊（仮）

1画面完結型・連続ステージ脱出ミステリーゲーム。
**「どう遊んだか」がストーリーと結末を変える**ことをコア体験とする。

## ドキュメント
- [**TODO（今後やること）**](docs/TODO.md) … ★残作業一覧（実プレイ→アセット→配信）。優先度付き
- [**GitHub Pages で公開**](docs/GitHubPages公開.md) … push で自動ビルド→Web公開（スマホ可・社内ネット無関係）。URL: https://sk1214-gkms.github.io/kioku-no-kairou/
- [**仕様書 v3（作話システム）**](docs/仕様書_v3_作話システム.md) … ★現行の正本。深い部屋13室＋作話完全度＋7結末＋設計原則
- [仕様書 v2.0](docs/仕様書_v2.md) … 旧「30部屋ゲーム」仕様（legacy・参考）
- [構成案 v1（謎と物語）](docs/構成案_謎と物語_v1.md) … 館＝記憶の設計思想
- [**構想：謎・推理の質を上げる設計案**](docs/構想_謎強化.md) … ①記憶の上書き ②証拠連結推理 ほか
- [**謎リデザイン：コンポーネント式＋収束(メタ)型 設計提案**](docs/謎リデザイン_コンポーネント設計.md) … ★攻略定石を踏まえ「複数手がかりで解ける」深い謎へ。部品体系＋段階実装
- [**謎案：全室（ストーリー準拠・改良版）**](docs/謎案_全室.md) … 各部屋の謎の作成案＋自己評価
- [**謎解き＆推理 一覧（推定難易度つき）**](docs/謎一覧_難易度.md) … ★全13室の早見表＋推理(②盤)＋結末判定
- [**解答とヒント 全室（解答キー）**](docs/解答とヒント_全室.md) … ★各部屋の解き方＋答え＋3段ヒント＋30号室＋結末条件
- [ストーリー分岐フロー図](docs/story_flow.drawio) … draw.io（GEDÄCHTNIS/作話完全度/7結末 現行版）
- [**必要な画像 まとめ（現行反映）**](docs/必要画像まとめ.md) … ★背景52＋状態差分12＋アイテム15…の枚数・命名・注意（情景変化対応）
- [アセット仕様書](docs/アセット仕様書.md) … 必要な画像/イラストの詳細一覧（13室4方向）＋生成プロンプト
- [音響仕様書（BGM・SE）](docs/音響仕様書_BGM_SE.md) … BGM/効果音の一覧・ムード・生成プロンプト・ツール
- [テスト手順（解答キー付き）](docs/テスト手順_第1章.md)
- [**iPhone配信手順（Windows＋iPhoneのみ・Mac不要）**](docs/iPhone配信手順_Windowsのみ.md) … TestFlight配信の段取り
- [**Stable Diffusion（ローカル）生成手順**](docs/StableDiffusion_ローカル生成手順.md) … 画像アセットをローカルSDで作る（Windows）
- [**Adobe Firefly 生成手順**](docs/AdobeFirefly_生成手順.md) … 商用安全なFirefly＋Photoshopで作る（流血表現の回避策つき）

## データ（Flutter の assets/data/ に配置して読み込む想定）
| ファイル | 役割 |
|---|---|
| [data/stage.schema.json](data/stage.schema.json) | ステージ定義の JSON Schema |
| [data/stages/](data/stages/) | ステージ実データ（stage_01〜05 + final_room） |
| [data/cipher.json](data/cipher.json) | ハードモードの架空言語『回廊文字』＋暗号解読書 |
| [data/text_ja.json](data/text_ja.json) | 全文言（ID参照で外部化） |
| [data/endings.json](data/endings.json) | エンディング分岐ルール（選択×記憶充足度×推理） |
| [data/save_template.json](data/save_template.json) | セーブ状態の雛形 |

## 設計のキモ
1. **記憶充足度 `memory_score`** が結末を駆動（モードではなく実績で決まる）
2. **エンディング = 選択（系統）× 状態（変種）** のマトリクス
3. **隠しアイテム** はステージ4の隠しホットスポットで入手 → Ending C 前提
4. **仕掛けは type による判別ユニオン**＋**interactables（タップ領域）**で多様性に対応
5. **ハード = 回廊文字＋暗号解読書**（解読書を見ないと解けない追加手数）
6. **最終問題（7.3）= 任意・加点式の推理**（正解で真エンド A＋ に格上げ）

## 技術スタック
- **Flutter** に決定（実装メモは [仕様書 第11章](docs/仕様書_v2.md)）

## アプリ実装
ノーマル/タイマー/ハードの3モードで St.1〜5 を解き、`memory_score` と選択でエンディングまで到達できる実装。
依存は `shared_preferences`（セーブ）のみ。アート未制作のため interactables はラベル枠で代用表示。

| パス | 役割 |
|---|---|
| [pubspec.yaml](pubspec.yaml) | 依存・アセット定義（data/ を読み込む） |
| [lib/main.dart](lib/main.dart) | エントリポイント |
| [lib/models.dart](lib/models.dart) | データモデル＋セーブ状態（memory_score 計算） |
| [lib/content_repository.dart](lib/content_repository.dart) | JSON ローダ／テキストID参照／回廊文字 |
| [lib/save_service.dart](lib/save_service.dart) | 永続セーブ（shared_preferences） |
| [lib/ad_service.dart](lib/ad_service.dart) | 広告（インタースティシャル／リワード） |
| [lib/endings_eval.dart](lib/endings_eval.dart) | endings.json のルール評価器 |
| [lib/screens/title_screen.dart](lib/screens/title_screen.dart) | タイトル＋モード選択（ノーマル/タイマー/ハード） |
| [lib/screens/game_flow.dart](lib/screens/game_flow.dart) | 進行管理（モード対応／stage→最終室→ending） |
| [lib/screens/stage_screen.dart](lib/screens/stage_screen.dart) | ステージ描画・各仕掛けの入力・タイマー |
| [lib/screens/final_room_screen.dart](lib/screens/final_room_screen.dart) | 最終室（任意推理＋3択） |
| [lib/screens/ending_screen.dart](lib/screens/ending_screen.dart) | エンディング表示 |

### 実行手順（Flutter SDK 導入後）
```bash
# 1. このディレクトリで（lib/ と pubspec.yaml を残したまま）プラットフォーム雛形を生成
flutter create .
# ※ pubspec.yaml が初期化された場合は assets: の data/, data/stages/ を再追記

# 2. 依存取得 → 実行
flutter pub get
flutter run
```

### 対応範囲 / 未対応
- 対応：**タイトル/モード選択**、**ノーマル**／**タイマー（90秒・時間切れで虫食い）**／**ハード**、**全30部屋の骨格（St.1〜29＋最終室30）**、隠しアイテム、最終室の任意推理、A/A＋/A′/B/B′/C/C′ 分岐、**永続セーブ＋つづきから**、**広告の土台**（既定オフ）
  - **全30部屋でノーマル＋ハード対応**（11-29のハード変種も実装：cipher/scramble/decoy/hidden_clue/extra_step）。5/15/25 は選択分岐（逃避⇄直面）でハード無し。
- **ハードの難化モディファイア**：cipher（回廊文字）/ decoy / hidden_clue / extra_step / scramble / indirection
- **テスト手順**：[docs/テスト手順_第1章.md](docs/テスト手順_第1章.md)
- **仕掛けタイプ**：number_pad / text_input / sequence_tap / 状態トグル＋前提 / **item_use** / **condition** / **drag** / **branch（複数回答→物語分岐）**
- **物語軸**：`meters.confront`（逃避⇄直面）。5/15/25号室の選択で増減し、将来エンディングに反映（構成案 [docs/構成案_謎と物語_v1.md](docs/構成案_謎と物語_v1.md)）
- 未対応（次段）：効果音、アート/BGM、ハード/難易度のバランス調整、本番AdMob ID
- **🔍 深い部屋（試作）**：タイトルから起動。**東西南北4視点＋ネスト調査＋アイテム合成＋多段ロック**の“濃い1部屋”を検証する縦スライス（[lib/screens/deep_room_screen.dart](lib/screens/deep_room_screen.dart) / [data/deep_rooms/study.json](data/deep_rooms/study.json)）。手触り確認後に本編へ展開予定。

## 広告（マネタイズ）の土台
> **現在はスタブ化中**：テスト優先のため `google_mobile_ads` を依存から外し、[lib/ad_service.dart](lib/ad_service.dart) は no-op スタブにしてある（依存に入れるだけで AndroidがアプリID未設定で起動クラッシュするのを回避）。マネタイズ時に以下の手順で戻す。本実装は git 履歴に保存。

[lib/ad_service.dart](lib/ad_service.dart) に実装（※現在スタブ）。**既定は無効**（`AdService.enabled = false`）。AdMob のアプリID設定が済むまではオフのまま安全に開発できる（未設定で有効化すると起動クラッシュの恐れ）。広告の有無でゲームは詰まない。

- **インタースティシャル**：2クリアごと（[game_flow.dart](lib/screens/game_flow.dart) の `_clearCount`）。閉じてから次の部屋へ進むので次のタイマーは広告後に開始。
- **リワード**：ヒント解放（[stage_screen.dart](lib/screens/stage_screen.dart) の `_onHintPressed`）。広告中はタイマー一時停止。広告が無ければ暫定でヒント表示。
- いまは **Google公式のテスト広告ID** を使用（本番前に自分のIDへ差し替え）。

### 有効化の手順
1. AdMob でアプリ登録 → アプリID・各ユニットIDを取得。
2. **Android**: `android/app/src/main/AndroidManifest.xml` の `<application>` 内に追記（下はテストID）:
   ```xml
   <meta-data
     android:name="com.google.android.gms.ads.APPLICATION_ID"
     android:value="ca-app-pub-3940256099942544~3347511713"/>
   ```
   `android/app/build.gradle` の `minSdkVersion` を **23 以上**に。
3. **iOS**: `ios/Runner/Info.plist` に追記（下はテストID）:
   ```xml
   <key>GADApplicationIdentifier</key>
   <string>ca-app-pub-3940256099942544~1458002511</string>
   ```
4. [lib/ad_service.dart](lib/ad_service.dart) の `enabled` を `true` に。
5. リリース前に [lib/ad_service.dart](lib/ad_service.dart) のユニットIDを本番IDへ差し替え。

> **アート方針（予定）**: 素材サイトをベースに AI 生成（img2img 等）で画風を統一。実装は後日。
> 商用（広告収益）前提のため、**素材サイト側と AI ツール側の双方で商用利用可否を要確認**
> （特に素材を AI に入力して改変する行為が元ライセンスで許可されているか）。
