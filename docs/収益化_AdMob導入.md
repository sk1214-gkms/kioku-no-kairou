# 収益化：AdMob 導入設計（確定方針）

2026-07-15 決定。**アプリ内広告＝AdMob**（※AdSenseはウェブ用。支払いは裏でAdSense/お支払いプロファイルを使う）。

## 方針（確定）
- **インタースティシャル（全画面）＝部屋移動/クリアの“合間”に表示**
- **リワード（動画視聴）＝ヒント解放の“ご褒美”に表示**
- バナー/ネイティブ[PR]は**当面なし**（誤タップBANリスクと没入低下を避ける）。
- 想定モデル：**無料＋広告**（有料¥480なら広告は入れないのが定石。※要最終確認）

## 必要な広告ユニット
| 種類 | 用途 | 数 |
|---|---|---|
| インタースティシャル | 部屋クリア→次室への遷移時 | 1 |
| リワード | ヒント解放 | 1 |
| （App ID） | アプリ全体 | 1（Android/iOS別） |

> 開発中は**必ずテスト用ID**を使う（自分の実広告クリック＝即BAN）。
> Android テストID：インタースティシャル `ca-app-pub-3940256099942544/1033173712` ／ リワード `ca-app-pub-3940256099942544/5224354917` ／ App ID `ca-app-pub-3940256099942544~3347511713`

## 表示ルール（重要・BAN&低評価回避）
### インタースティシャル
- **タイミング**：`DeepRoomScreen` の勝利(win)→次室ロードの**境目**でのみ。**謎解き中・部屋の途中では絶対に出さない**。
- **頻度制限（必須）**：毎回は出さない。例）**「2部屋クリアごと」かつ「前回表示から90秒以上」**。うるさいとGoogleの品質評価↓＆離脱。
- **事前ロード**：表示後すぐ次の1本を `load()` しておく（表示待ちの空振り防止）。
- アプリ起動直後・操作の不意打ちで出さない。
### リワード
- **ヒントUIに「動画を見てヒント」ボタン**。視聴完了(onUserEarnedReward)で**次の1ヒントを解放**。
- **ゲーム攻略を広告必須にしない**：ヒントは任意補助。最低限クリアは広告なしでも可能に（例：最初のヒントは無料、以降リワード等）。
- 視聴途中キャンセルでは報酬を与えない。

## Flutter 実装（自宅ビルド後）
- パッケージ：`google_mobile_ads`（pubspec）。初期化：`MobileAds.instance.initialize()`（main）。
- **App ID 記入**：
  - Android：`android/app/src/main/AndroidManifest.xml` の `<application>` に
    `<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" android:value="ca-app-pub-xxx~yyy"/>`
  - iOS：`ios/Runner/Info.plist` に `GADApplicationIdentifier` = App ID、＋ `SKAdNetworkItems`。
- **同意管理**：EU向け **UMP SDK**（`ConsentInformation`）で同意取得後に初期化。iOSは **ATT**（`AppTrackingTransparency`＝`Info.plist`に`NSUserTrackingUsageDescription`）。
- **AdService（単一箇所に集約）**の骨子：
```dart
class AdService {
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  int _clearsSinceAd = 0;
  DateTime _lastAd = DateTime.fromMillisecondsSinceEpoch(0);

  void loadInterstitial() { InterstitialAd.load(adUnitId: kInterstitialId, request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null)); }

  Future<void> maybeShowOnRoomClear() async {
    _clearsSinceAd++;
    final okFreq = _clearsSinceAd >= 2;
    final okTime = DateTime.now().difference(_lastAd).inSeconds >= 90; // ※Date.now相当は実機で
    if (okFreq && okTime && _interstitial != null) {
      _interstitial!.show(); _interstitial = null; _clearsSinceAd = 0; _lastAd = DateTime.now();
      loadInterstitial(); // 次を先読み
    }
  }

  void loadRewarded() { RewardedAd.load(adUnitId: kRewardedId, request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (_) => _rewarded = null)); }

  void showRewardedForHint(VoidCallback onReward) {
    _rewarded?.show(onUserEarnedReward: (_, __) => onReward());
    _rewarded = null; loadRewarded();
  }
}
```
- **フック位置**：
  - インタースティシャル：`DeepRoomScreen` の勝利処理（次室へ進む直前）で `maybeShowOnRoomClear()`。
  - リワード：ヒント表示UIの「動画でヒント」→ `showRewardedForHint(() => revealNextHint())`。

## 配信前チェック（広告関連）
- [ ] プライバシーポリシー公開（広告・データ収集の記載）＝Play/App Store/AdMob 必須
- [ ] `app-ads.txt` を開発者サイトに設置（売り手正当性）
- [ ] UMP同意（EU）／ATT（iOS）実装
- [ ] **テストIDで動作確認 → 公開直前に本番IDへ**（本番IDは**Publicリポジトリにコミットしない**）
- [ ] **リポジトリをPrivateへ**（解答キー流出防止）
- [ ] 有料/無料モデルの最終確定（無料＋広告 想定）

## 準備（今すぐ／アプリ未ビルドでも可）
1. AdMobアカウント作成＋**お支払いプロファイル（AdSense側）**設定（審査に時間→先行）
2. プライバシーポリシー雛形作成（別途HTML）
3. app-ads.txt 用ドメイン確保
> 広告ユニット作成・SDK実装は「アプリが実機で動く」段階で。まずアカウント/支払い/ポリシーを固める。
