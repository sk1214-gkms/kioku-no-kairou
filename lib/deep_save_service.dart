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

/// 審判チェックポイント：「最後の審判からやり直す」用。
/// 審判突入時点の全状態（フラグ/メーター/残り時間T/フロア記録）を保持し、
/// 3問の答えだけを変えて別の結末を回収できるようにする。
/// 周回が審判へ到達するたび上書き。※やり直しでは脳死(D)は発生しない。
class JudgmentCheckpoint {
  final String mode;
  final int total; // 脳死タイマー総秒
  final int remaining; // 審判突入時点の残り秒（スコアTの算出用に固定）
  final GameState gameState;
  final int playSeconds; // 突入時点の実プレイ秒（結果画面の表示用）
  final List<Map<String, dynamic>> floors; // フロア別記録（R1..R13）

  JudgmentCheckpoint({
    required this.mode,
    required this.total,
    required this.remaining,
    required this.gameState,
    required this.playSeconds,
    required this.floors,
  });
}

class DeepSaveService {
  static const _key = 'kioku_deep_save_v1';
  static const _judgmentKey = 'kioku_deep_judgment_v1';

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

  /// 審判チェックポイントを保存（審判突入時に毎回上書き）。
  Future<void> saveJudgment({
    required String mode,
    required int total,
    required int remaining,
    required GameState gameState,
    required int playSeconds,
    required List<Map<String, dynamic>> floors,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _judgmentKey,
      jsonEncode({
        'mode': mode,
        'total': total,
        'remaining': remaining,
        'gameState': gameState.toJson(),
        'playSeconds': playSeconds,
        'floors': floors,
      }),
    );
  }

  /// 審判チェックポイントを読み込む（毎回JSONから新規生成＝独立コピー。
  /// 前回のやり直しで書き換わった flags/meters を持ち越さない）。
  Future<JudgmentCheckpoint?> loadJudgment() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_judgmentKey);
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return JudgmentCheckpoint(
        mode: m['mode'] as String,
        total: m['total'] as int,
        remaining: m['remaining'] as int,
        gameState:
            GameState.fromJson((m['gameState'] as Map).cast<String, dynamic>()),
        playSeconds: (m['playSeconds'] as num?)?.toInt() ?? 0,
        floors: ((m['floors'] as List?) ?? const [])
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList(),
      );
    } catch (_) {
      await prefs.remove(_judgmentKey);
      return null;
    }
  }
}
