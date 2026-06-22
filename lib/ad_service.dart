import 'dart:async';
import 'dart:io' show Platform;
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 広告（マネタイズ）の土台。
/// - インタースティシャル: ステージ間
/// - リワード: ヒント解放
///
/// 既定は無効（enabled=false）。AdMob のアプリID設定（AndroidManifest / Info.plist）が
/// 済んでから true にすること。未設定のまま有効化すると起動時にクラッシュする恐れがある。
/// ゲーム進行は広告の有無に依存しない（広告が無くても詰まない）。
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  /// AdMob 設定が済んだら true にする。
  static const bool enabled = false;

  /// テスト用ユニットID（Google公式）。リリース前に本番IDへ差し替える。
  static String get _interstitialUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910';
  static String get _rewardedUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/5224354917'
      : 'ca-app-pub-3940256099942544/1712485313';

  bool _ready = false;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;

  Future<void> init() async {
    if (!enabled) return;
    try {
      await MobileAds.instance.initialize();
      _ready = true;
      _loadInterstitial();
      _loadRewarded();
    } catch (_) {
      _ready = false;
    }
  }

  // ---- インタースティシャル（ステージ間）----

  void _loadInterstitial() {
    if (!enabled || !_ready) return;
    InterstitialAd.load(
      adUnitId: _interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  /// 表示し、閉じられる（または失敗する）まで待つ。広告が無ければ即座に返る。
  Future<void> showInterstitial() async {
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    final completer = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _loadInterstitial();
        if (!completer.isCompleted) completer.complete();
      },
    );
    ad.show();
    _interstitial = null;
    return completer.future;
  }

  // ---- リワード（ヒント解放）----

  void _loadRewarded() {
    if (!enabled || !_ready) return;
    RewardedAd.load(
      adUnitId: _rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (_) => _rewarded = null,
      ),
    );
  }

  /// リワード動画を表示。報酬を得たら true、広告が無ければ false。
  Future<bool> showRewarded() async {
    final ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      return false;
    }
    final completer = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewarded();
        if (!completer.isCompleted) completer.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _loadRewarded();
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    ad.show(onUserEarnedReward: (ad, reward) => earned = true);
    _rewarded = null;
    return completer.future;
  }
}
