import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'models.dart';

/// data/ 配下の JSON を読み込んで保持する。テキストは ID 参照で引く。
class ContentRepository {
  final Map<String, String> texts;
  final List<Stage> stages; // stage_01 .. stage_05
  final Stage finalRoom;
  final Map<String, dynamic> endings;
  final Map<String, dynamic> cipher; // ハードの回廊文字

  ContentRepository({
    required this.texts,
    required this.stages,
    required this.finalRoom,
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

    const stagePaths = [
      'data/stages/stage_01.json',
      'data/stages/stage_02.json',
      'data/stages/stage_03.json',
      'data/stages/stage_04.json',
      'data/stages/stage_05.json',
      'data/stages/stage_06.json',
      'data/stages/stage_07.json',
      'data/stages/stage_08.json',
      'data/stages/stage_09.json',
      'data/stages/stage_10.json',
      'data/stages/stage_11.json',
      'data/stages/stage_12.json',
      'data/stages/stage_13.json',
      'data/stages/stage_14.json',
      'data/stages/stage_15.json',
      'data/stages/stage_16.json',
      'data/stages/stage_17.json',
      'data/stages/stage_18.json',
      'data/stages/stage_19.json',
      'data/stages/stage_20.json',
      'data/stages/stage_21.json',
      'data/stages/stage_22.json',
      'data/stages/stage_23.json',
      'data/stages/stage_24.json',
      'data/stages/stage_25.json',
      'data/stages/stage_26.json',
      'data/stages/stage_27.json',
      'data/stages/stage_28.json',
      'data/stages/stage_29.json',
    ];
    final stages = <Stage>[];
    for (final p in stagePaths) {
      stages.add(Stage.fromJson(await _json(p)));
    }

    final finalRoom = Stage.fromJson(await _json('data/stages/final_room.json'));
    final endings = await _json('data/endings.json');
    final cipher = await _json('data/cipher.json');

    return ContentRepository(
      texts: texts,
      stages: stages,
      finalRoom: finalRoom,
      endings: endings,
      cipher: cipher,
    );
  }
}
