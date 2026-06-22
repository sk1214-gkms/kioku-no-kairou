import 'package:flutter/material.dart';
import '../save_service.dart';
import 'game_flow.dart';

/// タイトル＋モード選択。ここで選んだモードが体験（記憶・結末）を変える。
/// 中断したプレイがあれば「つづきから」を表示する。
class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key});

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> {
  final SaveService _save = SaveService();
  SavedRun? _saved;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final s = await _save.load();
    if (!mounted) return;
    setState(() {
      _saved = s;
      _loading = false;
    });
  }

  Future<void> _newGame(String mode) async {
    await _save.clear();
    if (!mounted) return;
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => GameFlow(mode: mode)));
    _reload();
  }

  Future<void> _continue() async {
    final saved = _saved;
    if (saved == null) return;
    await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => GameFlow(resume: saved)));
    _reload();
  }

  static const Map<String, String> _modeLabels = {
    'normal': 'ノーマル',
    'hard': 'ハード',
    'timer': 'タイマー',
  };

  String _savedSummary(SavedRun s) {
    final mode = _modeLabels[s.gameState.mode] ?? s.gameState.mode;
    final where =
        s.phase == 'finalRoom' ? '最終室' : 'STAGE ${s.stageIndex + 1}';
    return 'つづきから（$mode・$where）';
  }

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
                const Text('記憶の回廊',
                    style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 6)),
                const SizedBox(height: 8),
                const Text('― 1画面完結 脱出ミステリー ―',
                    style: TextStyle(color: Colors.white54)),
                const SizedBox(height: 40),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  )
                else ...[
                  if (_saved != null) ...[
                    SizedBox(
                      width: 320,
                      child: OutlinedButton(
                        onPressed: _continue,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(_savedSummary(_saved!),
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('― はじめから ―',
                        style: TextStyle(color: Colors.white38)),
                    const SizedBox(height: 8),
                  ],
                  _modeButton('ノーマル', 'じっくり解く。ヒントあり。', 'normal'),
                  _modeButton(
                      'タイマー', '1部屋90秒。時間切れで記憶が虫食いに。結末が変わる。', 'timer'),
                  _modeButton(
                      'ハード', '謎の言語「回廊文字」＋暗号解読書で解く上級モード。', 'hard'),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeButton(String title, String desc, String mode) {
    return Container(
      width: 320,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: FilledButton(
        onPressed: () => _newGame(mode),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(desc,
                  style: const TextStyle(fontSize: 11),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
