import 'package:flutter/material.dart';
import '../endings_eval.dart';

class EndingScreen extends StatelessWidget {
  final EndingResult result;
  final GameStateSummary summary;
  final VoidCallback onRestart;

  const EndingScreen({
    super.key,
    required this.result,
    required this.summary,
    required this.onRestart,
  });

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
                Text('— ENDING ${result.ending} —',
                    style:
                        const TextStyle(color: Colors.white38, letterSpacing: 4)),
                const SizedBox(height: 12),
                Text(result.title,
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Text(result.text,
                    style: const TextStyle(fontSize: 16, height: 1.8),
                    textAlign: TextAlign.left),
                const SizedBox(height: 28),
                _reasonNote(),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onRestart,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Text('タイトルへ戻る'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 精神鑑定書（内訳表示）
  Widget _reasonNote() {
    final c = summary.confront;
    final sign = c >= 0 ? '+' : '−';
    final effLine =
        '${summary.memoryScore} ${c >= 0 ? '+' : '−'} ${c.abs()}×5 ＝ ${summary.effectiveScore}';
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
          const Text('【精神鑑定書：蓮見 鏡介】',
              style: TextStyle(
                  color: Colors.amberAccent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _row('基礎記憶充足度 (score)', '${summary.memoryScore}%'),
          _row('現実への直面度 (confront)', '$sign${c.abs()}　[ ${summary.confrontBreakdown} ]'),
          _row('最終実効スコア', effLine),
          _row('論理的客観推理 (Deduction)',
              '${summary.deductionScore} / ${summary.deductionTotal}　(${summary.deductionCorrect ? "True" : "False"})'),
          _row('深層遺留品 (Evidence)',
              summary.hasEvidence ? '金属製の筒・所持' : '未所持'),
          const Divider(height: 18, color: Colors.white12),
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
              width: 180,
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

/// エンディング画面に表示する状態サマリ（精神鑑定書）。
class GameStateSummary {
  final int memoryScore; // 基礎(raw)
  final int confront; // -3..+3
  final int effectiveScore; // raw + confront*5
  final int deductionScore; // 正解数
  final int deductionTotal; // 設問数
  final bool deductionCorrect; // 全問正解
  final bool hasEvidence;
  final String confrontBreakdown; // "5:直面 / 15:逃避 / 25:—"

  GameStateSummary({
    required this.memoryScore,
    required this.confront,
    required this.effectiveScore,
    required this.deductionScore,
    required this.deductionTotal,
    required this.deductionCorrect,
    required this.hasEvidence,
    required this.confrontBreakdown,
  });
}
