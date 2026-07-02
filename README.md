# アムネジィ・ケース ──教授の不完全な安楽── — 開発リポジトリ

> 旧称：記憶の回廊（仮）

1画面完結型・連続ステージ脱出ミステリーゲーム。
**「どう遊んだか」がストーリーと結末を変える**ことをコア体験とする。

## ドキュメント
- [**TODO（今後やること）**](docs/TODO.md) … ★残作業一覧（実プレイ→アセット→配信）。優先度付き
- [**改善ロードマップ（採用決定4件）**](docs/改善ロードマップ.md) … ★30号室の伏線化(済)／追想モード＋結末ヒント／収益ハイブリッド／多言語方針（アートに文字を焼かない規則）
- [**GitHub Pages で公開**](docs/GitHubPages公開.md) … push で自動ビルド→Web公開（スマホ可・社内ネット無関係）。URL: https://sk1214-gkms.github.io/kioku-no-kairou/
- [**仕様書 v3（作話システム）**](docs/仕様書_v3_作話システム.md) … ★現行の正本。深い部屋13室＋作話完全度＋7結末＋設計原則
- [構成案 v1（謎と物語）](docs/構成案_謎と物語_v1.md) … 館＝記憶の設計思想
- [**構想：謎・推理の質を上げる設計案**](docs/構想_謎強化.md) … ①記憶の上書き ②証拠連結推理 ほか
- [**謎リデザイン：コンポーネント式＋収束(メタ)型 設計提案**](docs/謎リデザイン_コンポーネント設計.md) … ★攻略定石を踏まえ「複数手がかりで解ける」深い謎へ。部品体系＋段階実装
- [**謎案：全室（ストーリー準拠・改良版）**](docs/謎案_全室.md) … 各部屋の謎の作成案＋自己評価
- [**謎解き＆推理 一覧（推定難易度つき）**](docs/謎一覧_難易度.md) … ★全13室の早見表＋推理(②盤)＋結末判定
- [**解答と進捗連動ヒント 全室（解答キー）**](docs/解答とヒント_全室.md) … ★JSON実データ準拠。各室の解き方＋答え＋収束手がかり＋囮＋5段進捗連動ヒント（達成トリガ付）＋30号室＋結末
- [ストーリー分岐フロー図](docs/story_flow.drawio) … draw.io（GEDÄCHTNIS/作話完全度/7結末 現行版）
- [**アセット完全チェックリスト（必要なものすべて）**](docs/アセット完全チェックリスト.md) … ★背景52＋差分16＋アイテム15＋フォント＋音。各素材の描く内容・命名・合計まで
- [**画像の理想像（自然言語ADガイド）**](docs/画像イメージ_自然言語.md) … ★各画像が"どう見えるのが理想か"を日本語で描写（情景・焦点・光・色・物語）
- [**背景の作り方：MMDステージ→Blender→レンダリング**](docs/Blender制作手順_MMD取り込み.md) … ★3Dで部屋1個→カメラ4方向で背景量産（Myst型の王道／MMD経験者向け初心者手順・商用ライセンス注意つき）
- [アセット仕様書](docs/アセット仕様書.md) … 必要な画像/イラストの詳細一覧（13室4方向）＋生成プロンプト
- [音響仕様書（BGM・SE）](docs/音響仕様書_BGM_SE.md) … BGM/効果音の一覧・ムード・生成プロンプト・ツール
- [**BGM・SEプロンプト（コピペ用）**](docs/音楽SEプロンプト_コピペ用.md) … ★1個ずつコードブロックで即コピペ。貼り付け先(Suno/ElevenLabs)と設定つき
- [**iPhone配信手順（Windows＋iPhoneのみ・Mac不要）**](docs/iPhone配信手順_Windowsのみ.md) … TestFlight配信の段取り
- [**Stable Diffusion（ローカル）生成手順**](docs/StableDiffusion_ローカル生成手順.md) … 画像アセットをローカルSDで作る（Windows）
- [**Adobe Firefly 生成手順**](docs/AdobeFirefly_生成手順.md) … 商用安全なFirefly＋Photoshopで作る（流血表現の回避策つき）

## データ（Flutter の assets に同梱して読み込む）
| ファイル | 役割 |
|---|---|
| [data/deep_rooms/](data/deep_rooms/) | ★本編。campaign.json（13室マニフェスト）＋judgment.json（30号室）＋r1〜r13.json |
| [data/text_ja.json](data/text_ja.json) | 全文言（結末テキスト等をID参照で外部化） |
| [data/endings.json](data/endings.json) | エンディング定義（`confab_endings` ＝7結末のタイトル/テキストID） |
| [data/cipher.json](data/cipher.json) | 回廊文字グリフ表（ハード演出のグリフ表示用） |

> 旧「30部屋ステージ制」（data/stages・stage.schema・save_template）は撤去済み（現行＝深い部屋キャンペーンに一本化）。

## 設計のキモ（現行＝作話システム）
1. **作話完全度 `I=(T×M)(1+E/3)`** が結末を駆動（T=生存度／M=嘘の推理数／E=逃避回数）
2. **7結末＋D**：選択（真実/嘘）× 分岐（直面/逃避）× 隠し条件で分岐（[endings_eval.dart](lib/endings_eval.dart)）
3. **収束型の謎**：複数の手がかりを突き合わせて初めて解ける（各室の「手がかり」パネル）
4. **記憶の上書き①／証拠連結②／対峙／記憶再生(scrub)／追跡** など動詞多様化
5. **情景変化**：`bg_variants`/`show_when` で状態により背景・オブジェクトが出現
6. **進捗連動ヒント**：達成済み手順を自動スキップし“今の詰まり”だけ提示（最終段は物語のみ）

## 技術スタック
- **Flutter**（現行の正本は [仕様書 v3](docs/仕様書_v3_作話システム.md)）。依存は `shared_preferences` のみ。

## アプリ実装
5モード（ストーリー／ノーマル(±時間)／ハード(±時間)）で深い部屋13室→30号室→結末まで到達できる実装。
アート未制作の間はプレースホルダ画像で稼働（`tools/gen_placeholders.py`／`gen_item_icons.py`）。

| パス | 役割 |
|---|---|
| [pubspec.yaml](pubspec.yaml) | 依存・アセット定義 |
| [lib/main.dart](lib/main.dart) | エントリポイント |
| [lib/models.dart](lib/models.dart) | データモデル＋状態（GameState 等） |
| [lib/content_repository.dart](lib/content_repository.dart) | JSON ローダ（text_ja／endings／cipher） |
| [lib/deep_save_service.dart](lib/deep_save_service.dart) | 深い部屋の永続セーブ（shared_preferences） |
| [lib/collection_service.dart](lib/collection_service.dart) | 結末コレクションの記録 |
| [lib/audio_service.dart](lib/audio_service.dart) | BGM/SE 発火（現在は無音スタブ） |
| [lib/ad_service.dart](lib/ad_service.dart) | 広告（現在は no-op スタブ・既定オフ） |
| [lib/endings_eval.dart](lib/endings_eval.dart) | 作話完全度＋7結末の評価器 |
| [lib/widgets/design_canvas.dart](lib/widgets/design_canvas.dart) | 360×640 設計面のスケーリング＋ホットスポット配置 |
| [lib/screens/title_screen.dart](lib/screens/title_screen.dart) | タイトル＋モード選択（難度3×時間トグル） |
| [lib/screens/deep_campaign_flow.dart](lib/screens/deep_campaign_flow.dart) | 進行管理（13室→30号室→結末／脳死タイマー／セーブ） |
| [lib/screens/deep_room_screen.dart](lib/screens/deep_room_screen.dart) | 部屋エンジン（4方向・ネスト調査・合成・多段ロック・各動詞・進捗連動ヒント） |
| [lib/screens/final_judgment_screen.dart](lib/screens/final_judgment_screen.dart) | 30号室（②証拠連結の推理） |
| [lib/screens/verlust_reveal_screen.dart](lib/screens/verlust_reveal_screen.dart) | VERLUST 収束演出 |
| [lib/screens/verdict_screen.dart](lib/screens/verdict_screen.dart) | 結果／結末表示＋スコア＋ネタバレ無し共有 |

### 実行手順（Flutter SDK 導入後）
```bash
# 1. このディレクトリで（lib/ と pubspec.yaml を残したまま）プラットフォーム雛形を生成
flutter create .
# ※ pubspec.yaml が初期化された場合は assets: の各行を再追記

# 2. 仮画像を生成（任意・画風が必ず揃う）
python tools/gen_placeholders.py && python tools/gen_item_icons.py

# 3. 依存取得 → 実行
flutter pub get
flutter run
```

### 対応範囲 / 未対応
- 対応：**タイトル/5モード選択**、**深い部屋13室＋30号室＋7結末＋D**、収束型の謎、記憶の上書き①／証拠連結②／対峙／記憶再生／追跡、情景変化、**進捗連動ヒント（5段）**、脳死タイマー、**永続セーブ＋つづきから**、結末コレクション、ネタバレ無しSNS共有、広告/音の土台（既定オフ）
- 未対応（次段）：**実プレイテスト＆バランス調整**、本番アート、BGM/SE、オーディオ実装、本番AdMob（[docs/TODO.md](docs/TODO.md)）

## 広告（マネタイズ）の土台
> **現在はスタブ化中**：テスト優先のため `google_mobile_ads` を依存から外し、[lib/ad_service.dart](lib/ad_service.dart) は no-op スタブにしてある（依存に入れるだけで AndroidがアプリID未設定で起動クラッシュするのを回避）。マネタイズ時に以下の手順で戻す。本実装は git 履歴に保存。

[lib/ad_service.dart](lib/ad_service.dart) に実装（※現在スタブ）。**既定は無効**（`AdService.enabled = false`）。AdMob のアプリID設定が済むまではオフのまま安全に開発できる（未設定で有効化すると起動クラッシュの恐れ）。広告の有無でゲームは詰まない。

- **発火点は現行フロー（[deep_campaign_flow.dart](lib/screens/deep_campaign_flow.dart)／[deep_room_screen.dart](lib/screens/deep_room_screen.dart)）へ再配線が必要**（旧30部屋の配線は撤去済み）。
  - **インタースティシャル**：章替わり／部屋クリアの区切りで表示（想定）。
  - **リワード**：ヒント解放（[deep_room_screen.dart](lib/screens/deep_room_screen.dart) の `_showHint`＝「ヒント（広告）」ボタン）。
- いまは **Google公式のテスト広告ID** を使用する前提（本番前に自分のIDへ差し替え）。

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
