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

  final vars = <String, dynamic>{
    'memory_score': gs.memoryScore,
    'memory_high': thresholds['memory_high'],
    'memory_low': thresholds['memory_low'],
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
