import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// data/ 配下の JSON を読み込んで保持する。テキストは ID 参照で引く。
/// （旧30部屋ステージ制は撤去済み。現行＝深い部屋キャンペーンは endings/cipher/text_ja を使う）
class ContentRepository {
  final Map<String, String> texts;
  final Map<String, dynamic> endings;
  final Map<String, dynamic> cipher; // ハードの回廊文字（グリフ表示用）

  ContentRepository({
    required this.texts,
    required this.endings,
    required this.cipher,
  });

  String text(String id) => texts[id] ?? id;

  /// 回廊文字グリフ id → 表示記号
  String glyphSymbol(String id) {
    final g = (cipher['glyphs'] as Map?)?[id] as Map?;
    return (g?['proto_symbol'] as String?) ?? id;
  }

  /// 回廊文字グリフ id → 解読後の値
  String glyphValue(String id) {
    final g = (cipher['glyphs'] as Map?)?[id] as Map?;
    return (g?['value'] as String?) ?? id;
  }

  static Future<Map<String, dynamic>> _json(String path) async {
    final raw = await rootBundle.loadString(path);
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<ContentRepository> load() async {
    final textsRaw = await _json('data/text_ja.json');
    final texts = <String, String>{};
    textsRaw.forEach((k, v) {
      if (v is String) texts[k] = v;
    });

    final endings = await _json('data/endings.json');
    final cipher = await _json('data/cipher.json');

    return ContentRepository(
      texts: texts,
      endings: endings,
      cipher: cipher,
    );
  }
}
