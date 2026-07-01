import 'package:flutter_test/flutter_test.dart';
import 'package:kioku_no_kairou/content_repository.dart';
import 'package:kioku_no_kairou/endings_eval.dart';
import 'package:kioku_no_kairou/models.dart';

/// confab_endings を最小構成で持つリポジトリ（アセット読込なし）。
ContentRepository _repo() {
  final endings = <String, dynamic>{
    'confab_endings': {
      'A+': {'title': '完璧な偽物', 'text': 't_end_A'},
      'A': {'title': '作話の綻び', 'text': 't_end_A_true'},
      'B': {'title': '忘却の揺り籠', 'text': 't_end_B', 'loop_to_stage': 1},
      'C': {'title': '断罪の重圧', 'text': 't_end_A2'},
      'D': {'title': '精神の死', 'text': 't_end_D'},
      'S': {'title': '深淵の白', 'text': 't_end_S'},
      'True': {'title': '白慈の審判', 'text': 't_end_true'},
    },
  };
  return ContentRepository(
    texts: const {},
    endings: endings,
    cipher: const {},
  );
}

/// テスト用 GameState 生成。evade/confront は分岐フラグ数で表す。
GameState _gs({
  int confab = 0,
  bool allTruth = false,
  bool syringe = false,
  bool evidence = false,
  int evade = 0,
  int confront = 0,
}) {
  const evadeKeys = ['s_r4_evade', 's_r8_evade', 's_r12_evade'];
  const confKeys = ['s_r4_confront', 's_r8_confront', 's_r12_confront'];
  final flags = <String, bool>{
    'all_truth': allTruth,
    'syringe_chosen': syringe,
    'has_culprit_evidence': evidence,
  };
  for (var i = 0; i < evade; i++) {
    flags[evadeKeys[i]] = true;
  }
  for (var i = 0; i < confront; i++) {
    flags[confKeys[i]] = true;
  }
  return GameState(
    mode: 'normal',
    memories: {},
    items: [],
    flags: flags,
    meters: {'confab': confab},
  );
}

void main() {
  final repo = _repo();
  String end(GameState gs, {bool brainDead = false}) =>
      evaluateConfabEnding(gs, repo, brainDead: brainDead).ending;

  group('evaluateConfabEnding 決定木', () {
    test('脳死 → D（最優先）', () {
      expect(end(_gs(), brainDead: true), 'D');
      // 他条件が揃っていても脳死が勝つ
      expect(
          end(_gs(confab: 3, evade: 3, syringe: true, evidence: true),
              brainDead: true),
          'D');
    });

    test('シリンジ＋筒 → S', () {
      expect(end(_gs(confab: 2, syringe: true, evidence: true, evade: 1)), 'S');
    });

    test('シリンジでも筒が無ければ S にならない（作話ミス側へ）', () {
      // 逃避×3＝B、直面ありなら C。ここは逃避×3で B を確認。
      expect(end(_gs(confab: 2, syringe: true, evidence: false, evade: 3)), 'B');
    });

    test('S は True より優先（シリンジ＋筒 が全真実＋全直面より先）', () {
      expect(
          end(_gs(
              syringe: true, evidence: true, allTruth: true, confront: 3)),
          'S');
    });

    test('全真実＋直面×3 → True', () {
      expect(end(_gs(confab: 0, allTruth: true, confront: 3)), 'True');
    });

    test('全真実でも直面が3未満なら True にならない', () {
      // confab=0, allTruth=true, confront=2(逃避1) → M<3 → C（直面あり）
      expect(end(_gs(confab: 0, allTruth: true, confront: 2, evade: 1)), 'C');
    });

    test('全作話正解＋逃避×3 → A+', () {
      expect(end(_gs(confab: 3, evade: 3)), 'A+');
    });

    test('全作話正解＋直面あり → A', () {
      expect(end(_gs(confab: 3, confront: 1, evade: 2)), 'A');
      expect(end(_gs(confab: 3, confront: 3)), 'A');
    });

    test('作話ミス＋逃避×3 → B（ループあり）', () {
      final r = evaluateConfabEnding(_gs(confab: 2, evade: 3), repo,
          brainDead: false);
      expect(r.ending, 'B');
      expect(r.loopToStage, 1);
    });

    test('作話ミス＋直面あり → C', () {
      expect(end(_gs(confab: 1, confront: 2, evade: 1)), 'C');
      expect(end(_gs(confab: 0)), 'C'); // 何もしない＝逃避未満→C
    });
  });

  group('作話完全度 I=(T×M)(1+E/3)', () {
    test('survivalT 正規化', () {
      expect(survivalT(900, 900), 100);
      expect(survivalT(0, 900), 0);
      expect(survivalT(450, 900), 50);
      expect(survivalT(100, 0), 100); // 総数0は満点扱い
    });
    test('integrity 計算', () {
      // T=100, M=3, E=3 → 100*3*(1+1)=600
      expect(
          confabIntegrity(correct: 3, evade: 3, tRemaining: 900, tTotal: 900),
          600);
      // M=0 → 0
      expect(
          confabIntegrity(correct: 0, evade: 3, tRemaining: 900, tTotal: 900),
          0);
      // T=50, M=2, E=0 → 50*2*1=100
      expect(
          confabIntegrity(correct: 2, evade: 0, tRemaining: 450, tTotal: 900),
          100);
    });
  });
}
