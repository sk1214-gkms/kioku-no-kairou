import 'package:shared_preferences/shared_preferences.dart';

/// 到達した結末コードを永続記録する（周回・コンプリート動機）。
/// セーブ(中断)とは別物。新規開始でクリアしない（コレクションは積み上げ）。
class CollectionService {
  static const _key = 'kioku_endings_seen_v1';

  Future<Set<String>> seen() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_key) ?? const <String>[]).toSet();
  }

  Future<void> markSeen(String code) async {
    if (code.isEmpty) return;
    final p = await SharedPreferences.getInstance();
    final s = (p.getStringList(_key) ?? <String>[]).toSet();
    if (s.add(code)) await p.setStringList(_key, s.toList());
  }

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}
