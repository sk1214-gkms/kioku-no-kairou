import 'package:flutter/material.dart';
import '../deep_save_service.dart';
import '../save_service.dart';
import 'deep_campaign_flow.dart';
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
  final DeepSaveService _deepSave = DeepSaveService();
  SavedRun? _saved;
  DeepSavedRun? _deepSaved;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final s = await _save.load();
    final d = await _deepSave.load();
    if (!mounted) return;
    setState(() {
      _saved = s;
      _deepSaved = d;
      _loading = false;
    });
  }

  Future<void> _deepNew(String mode) async {
    await _deepSave.clear();
    if (!mounted) return;
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => DeepCampaignFlow(mode: mode)));
    _reload();
  }

  Future<void> _deepContinue() async {
    final s = _deepSaved;
    if (s == null) return;
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => DeepCampaignFlow(mode: s.mode, resume: s)));
    _reload();
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
                  // ===== 本編（深い部屋・作話システム）=====
                  if (_deepSaved != null) ...[
                    SizedBox(
                      width: 320,
                      child: OutlinedButton(
                        onPressed: _deepContinue,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                              'つづきから（記憶の回廊・第${_deepSaved!.idx + 1}室）',
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
                  _modeButton('ノーマル', '深い部屋を解き、作話を完成させる。ヒントあり。', 'normal'),
                  _modeButton('タイマー', '脳死まで15分。時間に追われながら解く。', 'timer'),
                  _modeButton(
                      'ハード', '手がかりの説明を削りミスリードを足した最難。ヒント制限。', 'hard'),
                  const SizedBox(height: 24),
                  // ===== 旧30部屋ゲーム（参考・legacy）=====
                  const Text('― 旧30部屋ゲーム（参考・legacy）―',
                      style: TextStyle(color: Colors.white24, fontSize: 11)),
                  const SizedBox(height: 4),
                  if (_saved != null)
                    TextButton(
                      onPressed: _continue,
                      child: Text('（旧）${_savedSummary(_saved!)}',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12)),
                    ),
                  TextButton(
                    onPressed: () => _newGame('normal'),
                    child: const Text('旧版をプレイ（ノーマル）',
                        style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ),
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
        onPressed: () => _deepNew(mode),
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
