import 'package:flutter/material.dart';
import '../content_repository.dart';
import '../models.dart';

/// 最終室。本格推理（3問：犯人・時刻・凶器）→ 3択 → エンディング分岐。
class FinalRoomScreen extends StatefulWidget {
  final Stage room;
  final GameState gameState;
  final ContentRepository repo;
  final void Function(String branch) onChoice;
  final VoidCallback? onChanged; // 推理結果を保存させる

  const FinalRoomScreen({
    super.key,
    required this.room,
    required this.gameState,
    required this.repo,
    required this.onChoice,
    this.onChanged,
  });

  @override
  State<FinalRoomScreen> createState() => _FinalRoomScreenState();
}

class _FinalRoomScreenState extends State<FinalRoomScreen> {
  bool _deductionDone = false;
  int _qIndex = 0;
  int _correct = 0;
  String? _deductionMessage;

  List<Map<String, dynamic>> get _questions {
    final ded = widget.room.deduction;
    if (ded == null) return const [];
    return ((ded['questions'] as List?) ?? [])
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
  }

  @override
  void initState() {
    super.initState();
    // 再開時：すでに推理を答えていればスキップ
    _deductionDone = widget.gameState.flags['deduction_answered'] == true;
    if (_deductionDone) {
      _correct = widget.gameState.meters['deduction'] ?? 0;
      _deductionMessage = widget.gameState.flags['deduction_correct'] == true
          ? '記憶が一本の線でつながった。真相に至った。'
          : '推理は途中で途切れた。確信が持てない。';
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = widget.repo;
    final room = widget.room;
    final ded = room.deduction;
    final questions = _questions;

    return Scaffold(
      appBar: AppBar(title: Text(room.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(repo.text(room.promptText ?? ''),
                style: const TextStyle(fontSize: 18, height: 1.5)),
            const SizedBox(height: 24),

            // ---- 推理（3問）----
            if (ded != null && questions.isNotEmpty && !_deductionDone) ...[
              Text(ded['intro'] as String? ?? '',
                  style: const TextStyle(color: Colors.white54)),
              const SizedBox(height: 12),
              Text('推理 ${_qIndex + 1} / ${questions.length}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 6),
              Text(questions[_qIndex]['q'] as String,
                  style: const TextStyle(
                      fontSize: 17, color: Colors.amberAccent)),
              const SizedBox(height: 12),
              ..._optionsFor(questions[_qIndex]),
              const SizedBox(height: 4),
              TextButton(
                  onPressed: _skip, child: const Text('推理せずに先へ進む')),
              const Divider(height: 32),
            ],

            if (_deductionMessage != null) ...[
              Text(_deductionMessage!,
                  style: const TextStyle(color: Colors.greenAccent)),
              const SizedBox(height: 16),
            ],

            // ---- 3つの選択肢 ----
            if (ded == null || questions.isEmpty || _deductionDone) ...[
              const Text('どうする？', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              ...(room.choices ?? []).map((c) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: FilledButton(
                      onPressed: () =>
                          widget.onChoice(c['ending_branch'] as String),
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        child: Text(c['label'] as String,
                            style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _optionsFor(Map<String, dynamic> q) {
    final reqs = ((q['requires_memories'] as List?) ?? []).cast<String>();
    final available =
        reqs.every((m) => widget.gameState.memories[m] == 'full');
    final options =
        (q['options'] as List).map((e) => (e as Map).cast<String, dynamic>());
    return options.map((o) {
      final correct = o['correct'] == true;
      // 記憶が欠けていると、正解選択肢が虫食いで判別しにくくなる
      final label = (!available && correct)
          ? '■■■（記憶が欠けて確証がない）'
          : o['text'] as String;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: OutlinedButton(
          onPressed: () => _answer(correct),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(label, textAlign: TextAlign.left),
          ),
        ),
      );
    }).toList();
  }

  void _answer(bool correct) {
    if (correct) _correct++;
    final total = _questions.length;
    if (_qIndex + 1 < total) {
      setState(() => _qIndex++);
    } else {
      _finish();
    }
  }

  void _skip() => _finish();

  void _finish() {
    final total = _questions.length;
    final allCorrect = total > 0 && _correct == total;
    setState(() {
      widget.gameState.flags['deduction_correct'] = allCorrect;
      widget.gameState.flags['deduction_answered'] = true;
      widget.gameState.meters['deduction'] = _correct;
      _deductionMessage = allCorrect
          ? '記憶が一本の線でつながった。真相に至った。'
          : '推理は $_correct / $total。確信は、持てない。';
      _deductionDone = true;
    });
    widget.onChanged?.call();
  }
}
