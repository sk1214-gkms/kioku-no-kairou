# iPhoneでテストする手順（Windows＋iPhoneのみ・Mac不要）

対象：『アムネジィ・ケース ──教授の不完全な安楽──』を **TestFlight** で iPhone 実機にインストールし、使用感を確認する。
前提環境：**Windows PC ＋ iPhone のみ（Macは持っていない）**。

---

## 0. 全体像

```
[Windows PC] コード編集 → git push
        │
        ▼
[GitHub] リポジトリ
        │  （Webhook）
        ▼
[Codemagic] クラウド上の“mac”で iOS ビルド＋署名 → 自動アップロード
        │
        ▼
[App Store Connect / TestFlight]
        │
        ▼
[iPhone] TestFlight アプリでインストール → 動作確認
```

**ポイント：iOSアプリのビルドにはMac(Xcode)が必須だが、`Codemagic` のクラウドmacを使えば Mac を買わずに済む。** 社内ネットの遮断もクラウドで完結するため無関係。

---

## 1. 必要なもの・費用

| 項目 | 要否 | 費用 |
|---|---|---|
| Windows PC（編集・push） | 必須 | 既有 |
| iPhone（動作確認） | 必須 | 既有 |
| Apple ID | 必須 | 無料 |
| **Apple Developer Program** | **必須（回避不可）** | **年 $99（約1.5万円）** |
| GitHub アカウント＋本リポ | 必須 | 既有 |
| Codemagic アカウント | 必須 | 無料枠あり（月約500分のmacビルド） |
| **Mac 本体** | **不要** | — |

> 唯一どうしても避けられない出費が **Apple Developer の年$99**。これが無いと TestFlight は使えない。

---

## 2. 【最重要・無料】先にWindowsだけでコンパイル確認

iOSに進む前に、**アプリが実際にビルドできる状態か**をWindowsで無料確認する。未検証のコードがあるため、ここを必ず通す。

ASCIIパスの作業コピー（解析クラッシュ回避）で：

```bash
cd C:\src\kioku
git pull
flutter pub get
flutter analyze      # ← コンパイルエラーを検出。"No issues found!" を目指す
flutter test         # ← ロジックの単体テスト（結末判定木など）を実行
```

- `flutter analyze` でエラーが出たら、それを潰してから先へ（CodemagicやAppleの$99を使う前に無料で直す）。
- 可能なら Android 実機/エミュで `flutter run` まで通すと iOS の不確実性が「ビルド環境だけ」に絞れて安全。

---

## 3. 【Windowsで可】iOSプロジェクトの生成と設定

`ios/` フォルダ一式は **Windowsの `flutter create` で生成できる**（ビルドはMacが要るが、生成・編集はWindowsでOK）。

```bash
cd C:\src\kioku
# 既存の lib / pubspec は保持したまま ios/ を追加生成。Bundle ID の頭(org)を指定。
flutter create --org com.yourname --platforms=ios .
```

- これで Bundle ID は `com.yourname.kioku_no_kairou` 等になる（Apple/Codemagicで使う一意IDなので控える）。`yourname` は自分のドメイン逆順や任意の一意名に。
- **アプリ表示名**：`ios/Runner/Info.plist` の `CFBundleDisplayName` を編集（日本語可）。
  ```xml
  <key>CFBundleDisplayName</key>
  <string>アムネジィ・ケース</string>
  ```
- **アプリアイコン**：1024×1024 の不透過PNGを1枚用意し、`flutter_launcher_icons`（Windowsで生成可）で各サイズを生成。
  ```yaml
  # pubspec.yaml に追記
  dev_dependencies:
    flutter_launcher_icons: ^0.13.1
  flutter_launcher_icons:
    image_path: "assets/icon/icon_1024.png"
    ios: true
  ```
  ```bash
  dart run flutter_launcher_icons
  ```
- 生成・編集したら **`ios/` ごと commit & push**。

---

## 4. Apple Developer Program 登録（年$99）

1. iPhoneの「**Apple Developer**」アプリ、または [developer.apple.com](https://developer.apple.com) → Enroll。
2. **Individual（個人）** で登録（法人は書類が増える）。本人確認＋支払い。
3. 承認まで数時間〜数日。承認後、App Store Connect が使えるようになる。

---

## 5. App Store Connect でアプリ枠を作成

[appstoreconnect.apple.com](https://appstoreconnect.apple.com) → **マイApp → ＋ → 新規App**

| 項目 | 値 |
|---|---|
| プラットフォーム | iOS |
| 名前 | アムネジィ・ケース |
| 主要言語 | 日本語 |
| バンドルID | 手順3で決めたID（完全一致） |
| SKU | 任意の一意文字列（例 `amnesycase001`） |

---

## 6. App Store Connect API キーを発行（Codemagicの署名用）

[App Store Connect] → **ユーザーとアクセス → 統合(Integrations) → App Store Connect API → ＋**

- ロール：**App Manager**（または Admin）
- 生成される **`.p8` ファイル（DLは1回だけ）／Key ID／Issuer ID** を控える。
- これを Codemagic に渡すと、証明書・プロビジョニングを**全自動**で作ってくれる（Mac不要の肝）。

---

## 7. Codemagic 設定（クラウドでビルド→TestFlight）

1. [codemagic.io](https://codemagic.io) に **GitHubアカウントでサインアップ** → 本リポジトリを追加。
2. **Teams → Integrations → Apple Developer Portal** に、手順6の API キー（`.p8`／Key ID／Issuer ID）を登録（連携名を付ける。例 `AppStoreConnectKey`）。
3. ワークフロー作成。**初心者はGUIワークフローが楽**：
   - アプリ種別＝Flutter
   - Build platform＝**iOS** を有効化
   - **Code signing**＝iOS、distribution type＝**App Store**、bundle ID＝手順3のID、署名は**Automatic（API keyで自動）**
   - **Publishing**＝App Store Connect を有効化し **「Submit to TestFlight」をON**
4. **Start build** → 成功すると `.ipa` が App Store Connect の TestFlight に自動で上がる。

### （任意）codemagic.yaml で管理したい場合の雛形
リポジトリ直下に `codemagic.yaml` を置けば再現性が上がる（GUIでも可）。`<連携名>` と `<bundle id>` を自分の値に。

```yaml
workflows:
  ios-testflight:
    name: iOS TestFlight (Amnesy Case)
    instance_type: mac_mini_m2
    max_build_duration: 60
    integrations:
      app_store_connect: <連携名>          # 手順7-2で付けた名前
    environment:
      flutter: stable
      ios_signing:
        distribution_type: app_store
        bundle_identifier: <bundle id>     # 例 com.yourname.kioku_no_kairou
    scripts:
      - name: パッケージ取得
        script: flutter pub get
      - name: 解析とテスト
        script: |
          flutter analyze
          flutter test
      - name: 署名プロファイル適用
        script: xcode-project use-profiles
      - name: IPA ビルド
        script: flutter build ipa --release --export-options-plist=$HOME/export_options.plist
    artifacts:
      - build/ios/ipa/*.ipa
    publishing:
      app_store_connect:
        auth: integration
        submit_to_testflight: true
```

> ※ 雛形は出発点。最新の正確な記述は Codemagic 公式ドキュメント（「Flutter iOS」「Publishing to App Store Connect」）に従って微調整する。GUIワークフローならyaml不要。

---

## 8. iPhoneで TestFlight インストール

1. App Store Connect → **TestFlight → 内部テスト(Internal Testing)** → テスターに**自分のApple IDを追加**。
   - 内部テスト＝**Beta審査が不要・即時・最大100人**。まずはこれで十分。
2. iPhoneで App Store から **「TestFlight」アプリ** を入れる。
3. 招待メール/通知から受諾 → ビルドを **インストール** → 起動して使用感チェック。

> 知人など外部の人に配るなら「外部テスト（最大10,000人）」。こちらは初回に **Beta App Review（軽い審査・通常1日程度）** が要る。自分で触るだけなら内部テストでOK。

---

## 9. 2回目以降（更新）

1. Windowsでコード修正 → `git push`
2. Codemagicが自動（or手動Start）でビルド → TestFlightへ新ビルド
3. **ビルド番号は毎回必ず増やす**（重複不可）。`codemagic.yaml` で自動採番するか、`pubspec.yaml` の `version: 0.1.0+1` の `+N` を上げる。

---

## 10. つまずきポイント / 注意

- **$99/年は必須**（唯一回避不可の出費）。
- **Bundle ID** は App Store Connect・iOSプロジェクト・Codemagicで**完全一致**。
- **ビルド番号の重複不可**（毎回インクリメント）。
- **アイコンは1024×1024の不透過**（透過・角丸不可。角丸はAppleが自動付与）。
- Codemagic無料枠（月のmacビルド分）を超えると課金。失敗ビルドも分を消費するので、**手順2のWindows事前チェックで無駄打ちを減らす**。
- **広告**：本作はスタブ化済み（AdMob未使用）なので、iOSの広告設定・ATT（トラッキング許可）対応は**現時点では不要**。将来 `google_mobile_ads` を有効化する時に対応する。
- **黒文字体フォント未配置でも起動可**（標準フォントにフォールバック）。亀甲文字表示にしたい場合のみ `assets/fonts/` にUnifrakturMaguntiaを置く（[assets/fonts/README.md](../assets/fonts/README.md)）。
- iOS最低対応バージョンは Flutter 既定（iOS 12+ 目安）で問題なし。

---

## まとめ（最短ルート）

1. **Windowsで `flutter analyze` / `flutter test` を通す（無料・必須）**
2. `flutter create --org ... --platforms=ios .` で `ios/` 生成＋表示名/アイコン設定 → push
3. **Apple Developer 登録（$99）** → App Store Connect でApp枠＋APIキー
4. **Codemagic** にリポ接続＋APIキー登録 → iOSワークフローでビルド→TestFlight
5. iPhoneの **TestFlight** でインストールして使用感チェック

> 体感難易度：**中**。Mac購入は不要だが、Apple$99とCodemagic初回設定（半日〜1日）が要る。**まず手順2（Windowsでのコンパイル確認）を済ませるのが成功の鍵。**
