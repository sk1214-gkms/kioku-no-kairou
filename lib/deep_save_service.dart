import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

/// 深い部屋キャンペーンの中断セーブ（部屋境界チェックポイント＋脳死残り時間）。
/// 部屋内の途中状態（視点・所持品・錠の解錠）は保存せず、再開時は当該部屋を頭から。
class DeepSavedRun {
  final String mode;
  final int idx; // 再開する部屋インデックス
  final int total; // 脳死タイマー総秒
  final int remaining; // 残り秒（継続）
  final GameState gameState;

  DeepSavedRun({
    required this.mode,
    required this.idx,
    required this.total,
    required this.remaining,
    required this.gameState,
  });
}

class DeepSaveService {
  static const _key = 'kioku_deep_save_v1';

  Future<void> save({
    required String mode,
    required int idx,
    required int total,
    required int remaining,
    required GameState gameState,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'mode': mode,
        'idx': idx,
        'total': total,
        'remaining': remaining,
        'gameState': gameState.toJson(),
      }),
    );
  }

  Future<DeepSavedRun?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return DeepSavedRun(
        mode: m['mode'] as String,
        idx: m['idx'] as int,
        total: m['total'] as int,
        remaining: m['remaining'] as int,
        gameState:
            GameState.fromJson((m['gameState'] as Map).cast<String, dynamic>()),
      );
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
