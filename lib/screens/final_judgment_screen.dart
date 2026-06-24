import 'package:flutter/material.dart';
import '../models.dart';

/// 30号室・最後の審判。3問の推理（作話/真実/隠しシリンジ）を記録し、
/// 結末判定に必要な値を GameState に書き込んで onComplete を呼ぶ。
/// - meters['confab']  : 作話（嘘）を選んだ数 M（0..3）
/// - flags['all_truth']: 全問で真実を選んだ
/// - flags['syringe_chosen'] : 隠しのシリンジを選んだ（→ Ending S）
class FinalJudgmentScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final GameState gameState;
  final VoidCallback onComplete;
  final int globalRemaining;
  final int globalTotal;

  const FinalJudgmentScreen({
    super.key,
    required this.data,
    required this.gameState,
    required this.onComplete,
    this.globalRemaining = 0,
    this.globalTotal = 0,
  });

  @override
  State<FinalJudgmentScreen> createState() => _FinalJudgmentScreenState();
}

class _FinalJudgmentScreenState extends State<FinalJudgmentScreen> {
  int _qIndex = 0;
  int _lie = 0;
  int _truth = 0;
  bool _syringe = false;
  bool _answered = false;
  final List<Map<String, String>> _conclusion = []; // 確定の儀式で見せる結論

  List<Map<String, dynamic>> get _questions =>
      ((widget.data['questions'] as List?) ?? [])
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();

  void _pick(Map<String, dynamic> opt, String qLabel) {
    final tag = opt['tag'] as String? ?? 'decoy';
    switch (tag) {
      case 'lie':
        _lie++;
        break;
      case 'truth':
        _truth++;
        break;
      case 'syringe':
        _syringe = true;
        break;
    }
    _conclusion.add({
      'label': qLabel,
      'summary': opt['summary'] as String? ?? (opt['text'] as String),
    });
    if (_qIndex + 1 < _questions.length) {
      setState(() => _qIndex++);
    } else {
      _finish();
    }
  }

  void _finish() {
    final gs = widget.gameState;
    final total = _questions.length;
    gs.meters['confab'] = _lie;
    gs.meters['deduction'] = _lie; // 鑑定書表示の互換
    gs.flags['all_truth'] = _truth == total && total > 0;
    gs.flags['syringe_chosen'] = _syringe;
    gs.flags['deduction_correct'] = _lie == total && total > 0;
    gs.flags['deduction_answered'] = true;
    setState(() => _answered = true);
  }

  String _fmt(int s) {
    final v = s < 0 ? 0 : s;
    return '${v ~/ 60}:${(v % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final questions = _questions;
    final showClock = widget.globalTotal > 0;
    final low = widget.globalRemaining <= 30;
    return Scaffold(
      backgroundColor: const Color(0xFF0E0C14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF15131C),
        title: Text(widget.data['name'] as String? ?? '最後の審判'),
        actions: [
          if (showClock)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(_fmt(widget.globalRemaining),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: low ? Colors.redAccent : Colors.white70)),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.data['prompt'] as String? ?? '',
                style: const TextStyle(fontSize: 17, height: 1.6)),
            const SizedBox(height: 18),
            Text(widget.data['intro'] as String? ?? '',
                style: const TextStyle(color: Colors.white38, fontSize: 13)),
            const Divider(height: 32, color: Colors.white12),
            if (!_answered) ...[
              Text('推理 ${_qIndex + 1} / ${questions.length}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 8),
              Text(questions[_qIndex]['q'] as String,
                  style: const TextStyle(
                      fontSize: 19, color: Colors.amberAccent, height: 1.5)),
              const SizedBox(height: 16),
              ...((questions[_qIndex]['options'] as List)
                  .map((e) => (e as Map).cast<String, dynamic>())
                  .map((o) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: OutlinedButton(
                          onPressed: () => _pick(
                              o, questions[_qIndex]['label'] as String? ?? ''),
                          style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.all(14)),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(o['text'] as String,
                                style: const TextStyle(
                                    fontSize: 15, height: 1.4)),
                          ),
                        ),
                      ))),
            ] else ...[
              const Text('── あなたが現実へ出力しようとしている「結論」',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF15131C),
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final c in _conclusion)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 84,
                              child: Text(c['label'] ?? '',
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 13)),
                            ),
                            Expanded(
                              child: Text(c['summary'] ?? '',
                                  style: const TextStyle(
                                      color: Colors.amberAccent,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text('一度確定すれば、この「記憶」が現実として出力される。もう、戻れない。',
                  style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.5)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: widget.onComplete,
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7A1620)),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('この記憶を、確定する', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
