import 'package:shared_preferences/shared_preferences.dart';

/// プレミアム（¥480 買い切り）の購入状態を保持する土台。
///
/// ねらい：ストア連携（in_app_purchase）を**まだ追加せず**に、ゲーム側の
/// 「プレミアムなら広告除去＋ヒント無料」という分岐だけ先に完成させる。
/// 本番マネタイズ期に buyPremium()/restore() の中身をストアAPIに差し替える。
///
/// 購入状態は shared_preferences に保存（既にセーブで導入済みの依存のみ使用）。
class PurchaseService {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  static const _key = 'kioku_premium_v1';
  bool _premium = false;

  /// プレミアム購入済みか（広告除去＋ヒント無料の判定に使う）。
  bool get isPremium => _premium;

  /// 起動時に永続状態を読み込む（main で1回）。
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _premium = p.getBool(_key) ?? false;
  }

  /// ¥480 プレミアムを購入。
  /// 本番：in_app_purchase で購入フロー→検証→ _setPremium(true)。
  /// 現在：ストア未接続のため常に false（購入不可）。UIは「準備中」を出す想定。
  Future<bool> buyPremium() async {
    // TODO(マネタイズ期): in_app_purchase を pubspec に追加し、ここで購入→検証。
    return false;
  }

  /// 購入の復元（本番：restorePurchases）。現在は no-op。
  Future<void> restore() async {}

  /// 購入確定/デバッグ用の状態設定（本番の購入成功時にも使う）。
  Future<void> setPremium(bool v) async {
    _premium = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, v);
  }
}
