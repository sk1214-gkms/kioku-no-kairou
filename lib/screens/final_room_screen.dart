import 'package:flutter/material.dart';
import '../content_repository.dart';
import '../models.dart';

/// 最終室。任意の推理ステップ（7.3）→ 3択 → エンディング分岐。
class FinalRoomScreen extends StatefulWidget {
  final Stage room;
  final GameState gameState;
  final ContentRepository repo;
  final void Function(String branch) onChoice;
  final VoidCallback? onChanged; // 推理の結果を保存させる

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
  String? _deductionMessage;

  @override
  void initState() {
    super.initState();
    // 再開時：すでに推理を答えていれば推理ステップを再表示しない
    _deductionDone = widget.gameState.flags['deduction_answered'] == true;
    if (_deductionDone) {
      _deductionMessage = widget.gameState.flags['deduction_correct'] == true
          ? '記憶が一本の線でつながった気がする。'
          : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = widget.repo;
    final room = widget.room;
    final ded = room.deduction;

    return Scaffold(
      appBar: AppBar(title: Text(room.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              repo.text(room.promptText ?? ''),
              style: const TextStyle(fontSize: 18, height: 1.5),
            ),
            const SizedBox(height: 24),

            // ---- 任意の推理（7.3）----
            if (ded != null && !_deductionDone) ...[
              Text(repo.text(ded['question'] as String),
                  style: const TextStyle(fontSize: 16, color: Colors.amberAccent)),
              const SizedBox(height: 12),
              ...(ded['options'] as List).map((o) => _deductionOption(
                  (o as Map).cast<String, dynamic>())),
              const SizedBox(height: 4),
              TextButton(
                onPressed: _skip,
                child: const Text('推理せずに先へ進む'),
              ),
              const Divider(height: 32),
            ],

            if (_deductionMessage != null) ...[
              Text(_deductionMessage!, style: const TextStyle(color: Colors.greenAccent)),
              const SizedBox(height: 16),
            ],

            // ---- 3つの選択肢 ----
            if (ded == null || _deductionDone) ...[
              const Text('どうする？', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              ...(room.choices ?? []).map((c) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: FilledButton(
                      onPressed: () => widget.onChoice(c['ending_branch'] as String),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(c['label'] as String, style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _deductionOption(Map<String, dynamic> o) {
    final reqs = ((o['requires_memories'] as List?) ?? []).cast<String>();
    final available =
        reqs.every((m) => widget.gameState.memories[m] == 'full');
    final label = available
        ? widget.repo.text(o['text'] as String)
        : '■■■（記憶が欠けていて、この結論は選べない）';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: OutlinedButton(
        onPressed: available ? () => _select(o) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(label, textAlign: TextAlign.left),
        ),
      ),
    );
  }

  void _select(Map<String, dynamic> o) {
    final correct = o['correct'] == true;
    setState(() {
      widget.gameState.flags['deduction_correct'] = correct;
      widget.gameState.flags['deduction_answered'] = true;
      _deductionMessage = correct
          ? '記憶が一本の線でつながった気がする。'
          : 'いや…本当にそうだろうか。確信が持てない。';
      _deductionDone = true;
    });
    widget.onChanged?.call(); // 保存
  }

  void _skip() {
    setState(() {
      widget.gameState.flags['deduction_answered'] = true;
      _deductionDone = true;
    });
    widget.onChanged?.call(); // 保存
  }
}
