import 'package:flutter/material.dart';
import '../endings_eval.dart';

/// 深い部屋キャンペーンの結末画面。作話完全度 I=(T×M)(1+E/3) を
/// 「精神鑑定書」として提示し、GEDÄCHTNIS / VERLUST のモチーフを添える。
class VerdictScreen extends StatelessWidget {
  final EndingResult result;
  final int integrity; // 作話完全度 I
  final int survival; // T（生存度 0..100）
  final int correct; // M（作話＝嘘を選んだ数）
  final int evade; // E（逃避数）
  final int confront; // 直面数
  final bool brainDead;
  final bool syringeChosen;
  final bool allTruth;
  final int earned; // 実際に点灯できた GEDÄCHTNIS の文字数
  final VoidCallback onRestart;

  const VerdictScreen({
    super.key,
    required this.result,
    required this.integrity,
    required this.survival,
    required this.correct,
    required this.evade,
    required this.confront,
    required this.brainDead,
    required this.syringeChosen,
    required this.allTruth,
    required this.earned,
    required this.onRestart,
  });

  bool get _verlust =>
      brainDead || result.ending == 'D' || result.ending == 'S';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0C14),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _motif(),
                const SizedBox(height: 18),
                Text('— ENDING ${result.ending} —',
                    style: const TextStyle(
                        color: Colors.white38, letterSpacing: 4)),
                const SizedBox(height: 10),
                Text(result.title,
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: _verlust ? Colors.redAccent : Colors.white),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Text(result.text,
                    style: const TextStyle(fontSize: 15, height: 1.9),
                    textAlign: TextAlign.left),
                const SizedBox(height: 28),
                _report(),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onRestart,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    child: Text(result.loopToStage != null
                        ? '回廊の最初へ戻される……'
                        : 'タイトルへ戻る'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _motif() {
    const target = 'GEDÄCHTNIS';
    final lit = earned.clamp(0, target.length);
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            // 実際に点灯できた分だけを表示（脳死で途中なら符号も途中まで）
            for (var i = 0; i < lit; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(target[i],
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: _verlust ? Colors.white24 : Colors.amberAccent)),
              ),
          ],
        ),
        if (_verlust)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('V E R L U S T',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: Colors.redAccent)),
          ),
      ],
    );
  }

  Widget _report() {
    final formula = '($survival × $correct) × (1 + $evade/3) ＝ $integrity';
    return Container(
      width: 520,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF15131C),
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('【精神鑑定書：蓮見 鏡介 ― 作話完全度評価】',
              style: TextStyle(
                  color: Colors.amberAccent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _row('生存度 T（脳の残存）', '$survival / 100'),
          _row('作話正解 M（嘘の補完）', '$correct / 3'),
          _row('逃避 E（直面の回避）', '$evade / 3　［直面 $confront / 3］'),
          _row('隠し / 真実', syringeChosen
              ? 'シリンジに到達（封印された真相）'
              : allTruth
                  ? '全て真実を選択（嘘の全拒絶）'
                  : '—'),
          const Divider(height: 18, color: Colors.white12),
          _row('作話完全度 I ＝ (T×M)(1+E/3)', formula),
          const SizedBox(height: 6),
          Text('→ 結末 ${result.ending}：${result.title}',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 190,
              child: Text(label,
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ),
      );
}
