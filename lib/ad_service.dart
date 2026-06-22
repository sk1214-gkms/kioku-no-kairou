// 広告サービス（現在はスタブ）。
//
// ねらい：google_mobile_ads を依存から外し、Android で AdMob アプリID未設定でも
// アプリが起動時クラッシュしないようにする（テスト最優先）。広告は元々オフ。
//
// 本番で広告を入れる時の戻し方：
//  1) pubspec.yaml に google_mobile_ads を戻す
//  2) この実装を AdMob 版に戻す（git 履歴 / README「広告（マネタイズ）の土台」節を参照）
//  3) AndroidManifest / Info.plist に AdMob アプリIDを追加
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  /// 広告は現在無効（スタブ）。
  static const bool enabled = false;

  Future<void> init() async {}

  /// ステージ間広告（スタブ：何もしない）。
  Future<void> showInterstitial() async {}

  /// リワード広告（スタブ：常に false＝報酬なし）。
  /// 呼び出し側はこの場合ヒントを無料表示するフォールバックになっている。
  Future<bool> showRewarded() async => false;
}
