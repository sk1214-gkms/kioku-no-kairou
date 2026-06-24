import 'content_repository.dart';
import 'models.dart';

class EndingResult {
  final String ending;
  final String title;
  final String text;
  final int? loopToStage;
  EndingResult({
    required this.ending,
    required this.title,
    required this.text,
    this.loopToStage,
  });
}

/// endings.json のルールを評価して、選択肢(branch)に対する結末を返す。
EndingResult evaluateEnding(
    String branch, GameState gs, ContentRepository repo) {
  final endings = repo.endings;
  final thresholds = (endings['thresholds'] as Map).cast<String, dynamic>();

  // 案A：confront（逃避⇄直面 −3〜+3）を加味した実効スコアで判定する。
  final confront = gs.meters['confront'] ?? 0;
  final effective = (gs.memoryScore + confront * 5).clamp(0, 100);
  final vars = <String, dynamic>{
    'memory_score': effective,
    'memory_high': thresholds['memory_high'],
    'memory_low': thresholds['memory_low'],
    'confront': confront,
    'deduction_correct': gs.flags['deduction_correct'] ?? false,
    'has_culprit_evidence': gs.flags['has_culprit_evidence'] ?? false,
  };

  final rules = (endings['rules'] as List).cast<Map<String, dynamic>>();
  final rule = rules.firstWhere(
    (r) => r['branch'] == branch,
    orElse: () => rules.first,
  );

  for (final c in (rule['conditions'] as List).cast<Map<String, dynamic>>()) {
    if (_evalCondition(c['when'] as String, vars)) {
      return EndingResult(
        ending: c['ending'] as String,
        title: c['title'] as String,
        text: repo.text(c['text'] as String),
        loopToStage: c['loop_to_stage'] as int?,
      );
    }
  }

  // どれも一致しない場合は最後の条件をフォールバックに使う
  final last = (rule['conditions'] as List).last as Map<String, dynamic>;
  return EndingResult(
    ending: last['ending'] as String,
    title: last['title'] as String,
    text: repo.text(last['text'] as String),
    loopToStage: last['loop_to_stage'] as int?,
  );
}

/// "memory_score >= memory_high && deduction_correct == true" 形式の簡易評価器。
bool _evalCondition(String cond, Map<String, dynamic> vars) {
  for (final raw in cond.split('&&')) {
    if (!_evalComparison(raw.trim(), vars)) return false;
  }
  return true;
}

bool _evalComparison(String expr, Map<String, dynamic> vars) {
  // 2文字演算子を先に判定する
  for (final op in ['>=', '<=', '==', '>', '<']) {
    final i = expr.indexOf(op);
    if (i < 0) continue;
    final lhs = expr.substring(0, i).trim();
    final rhs = expr.substring(i + op.length).trim();
    final lv = vars[lhs];
    final rv = _resolve(rhs, vars);
    switch (op) {
      case '>=':
        return (lv as num) >= (rv as num);
      case '<=':
        return (lv as num) <= (rv as num);
      case '>':
        return (lv as num) > (rv as num);
      case '<':
        return (lv as num) < (rv as num);
      case '==':
        return lv == rv;
    }
  }
  return false;
}

dynamic _resolve(String token, Map<String, dynamic> vars) {
  if (vars.containsKey(token)) return vars[token];
  if (token == 'true') return true;
  if (token == 'false') return false;
  return num.tryParse(token) ?? token;
}

// =====================================================================
// 深い部屋キャンペーン：作話完全度（Confabulation Integrity）と8結末
// =====================================================================

/// 生存度 T（0..100）。脳死カウントダウンの残り割合。
int survivalT(int tRemaining, int tTotal) =>
    tTotal > 0 ? (tRemaining / tTotal * 100).round().clamp(0, 100) : 100;

/// 作話完全度 I = (T × M) × (1 + E/3)。
/// T=生存度(0..100)、M=作話（嘘）を選んだ推理数、E=逃避を選んだ回数。
int confabIntegrity({
  required int correct,
  required int evade,
  required int tRemaining,
  required int tTotal,
}) {
  final t = survivalT(tRemaining, tTotal);
  final i = (t * correct) * (1 + evade / 3);
  return i.round();
}

/// 逃避/直面フラグの集計（s_r4/r8/r12）。
int countEvade(GameState gs) => ['s_r4_evade', 's_r8_evade', 's_r12_evade']
    .where((k) => gs.flags[k] == true)
    .length;
int countConfront(GameState gs) =>
    ['s_r4_confront', 's_r8_confront', 's_r12_confront']
        .where((k) => gs.flags[k] == true)
        .length;

/// 深い部屋キャンペーンの結末を、離散決定木で確定する。
/// 優先順位：脳死(D) > 隠しシリンジ(S) > 全真実+全直面(True) >
///           全作話(A+/A) > 作話ミス(B/C)。
EndingResult evaluateConfabEnding(
  GameState gs,
  ContentRepository repo, {
  required bool brainDead,
}) {
  final m = gs.meters['confab'] ?? 0; // 作話（嘘）を選んだ数 0..3
  final allTruth = gs.flags['all_truth'] == true; // 全問で真実を選んだ
  final syringe = gs.flags['syringe_chosen'] == true;
  final allEvade = countEvade(gs) >= 3;
  final allConfront = countConfront(gs) >= 3;

  String code;
  if (brainDead) {
    code = 'D';
  } else if (syringe) {
    code = 'S';
  } else if (allTruth && allConfront) {
    code = 'True';
  } else if (m >= 3) {
    code = allEvade ? 'A+' : 'A';
  } else {
    code = allEvade ? 'B' : 'C';
  }

  final map =
      ((repo.endings['confab_endings'] as Map?) ?? {}).cast<String, dynamic>();
  final e = (map[code] as Map?)?.cast<String, dynamic>() ?? {};
  return EndingResult(
    ending: code,
    title: e['title'] as String? ?? code,
    text: repo.text(e['text'] as String? ?? ''),
    loopToStage: e['loop_to_stage'] as int?,
  );
}
