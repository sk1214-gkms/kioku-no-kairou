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
                    style: const TextStyle(color: Colors.white38, letterSpacing: 4)),
                const SizedBox(height: 12),
                Text(result.title,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Text(result.text,
                    style: const TextStyle(fontSize: 16, height: 1.7),
                    textAlign: TextAlign.left),
                const SizedBox(height: 28),
                Text('記憶充足度: ${summary.memoryScore}%　遺留品: ${summary.hasEvidence ? "あり" : "なし"}　推理: ${summary.deductionCorrect ? "成功" : "—"}',
                    style: const TextStyle(color: Colors.white38, fontSize: 12)),
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
}

/// エンディング画面に表示する状態サマリ（デバッグ兼演出）。
class GameStateSummary {
  final int memoryScore;
  final bool hasEvidence;
  final bool deductionCorrect;
  GameStateSummary({
    required this.memoryScore,
    required this.hasEvidence,
    required this.deductionCorrect,
  });
}
