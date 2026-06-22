import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

/// 中断した1プレイを保存・復元する（shared_preferences）。
class SavedRun {
  final GameState gameState;
  final int stageIndex;
  final String phase; // 'stage' | 'finalRoom'

  SavedRun({
    required this.gameState,
    required this.stageIndex,
    required this.phase,
  });
}

class SaveService {
  static const _key = 'kioku_save_v1';

  Future<void> save({
    required GameState gameState,
    required int stageIndex,
    required String phase,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'gameState': gameState.toJson(),
        'stageIndex': stageIndex,
        'phase': phase,
      }),
    );
  }

  Future<SavedRun?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return SavedRun(
        gameState:
            GameState.fromJson((m['gameState'] as Map).cast<String, dynamic>()),
        stageIndex: m['stageIndex'] as int,
        phase: m['phase'] as String,
      );
    } catch (_) {
      // 壊れたセーブは無視して破棄
      await clear();
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
