import 'package:flutter/material.dart';
import '../collection_service.dart';
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
  final CollectionService _collection = CollectionService();
  SavedRun? _saved;
  DeepSavedRun? _deepSaved;
  Set<String> _seen = {};
  bool _loading = true;

  // 結末コレクション表示用（コード→題）。配布順＝物語の振れ幅。
  static const List<List<String>> _allEndings = [
    ['A+', '完璧な偽物'],
    ['A', '作話の綻び'],
    ['B', '忘却の揺り籠'],
    ['C', '断罪の重圧'],
    ['S', '深淵の白'],
    ['True', '白慈の審判'],
    ['D', '精神の死'],
  ];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final s = await _save.load();
    final d = await _deepSave.load();
    final seen = await _collection.seen();
    if (!mounted) return;
    setState(() {
      _saved = s;
      _deepSaved = d;
      _seen = seen;
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

  // 時間のゆとり順のラダー：ストーリー(25分) > ノーマル(15分) > ハード(12分)。
  // 内部キーは据え置き（normal=ストーリー / timer=ノーマル / hard=ハード）。
  static const Map<String, String> _modeLabels = {
    'normal': 'ストーリー',
    'hard': 'ハード',
    'timer': 'ノーマル',
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
                const Text('アムネジィ・ケース',
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3)),
                const SizedBox(height: 8),
                const Text('── 教授の不完全な安楽 ──',
                    style: TextStyle(color: Colors.white54, letterSpacing: 1)),
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
                              'つづきから（第${_deepSaved!.idx + 1}室）',
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
                  _modeButton('ストーリー',
                      '時間にゆとり（脳死まで25分）。じっくり推理。ヒントあり。', 'normal'),
                  _modeButton('ノーマル', '脳死まで15分。標準の緊張感で解く。', 'timer'),
                  _modeButton('ハード',
                      '脳死まで12分。手がかりの説明を削りミスリードを足した最難。ヒント制限。', 'hard'),
                  const SizedBox(height: 24),
                  _endingCollection(),
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

  Widget _endingCollection() {
    return SizedBox(
      width: 320,
      child: Column(
        children: [
          Text('── 結末コレクション　${_seen.length} / ${_allEndings.length} ──',
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [for (final e in _allEndings) _endingChip(e)],
          ),
        ],
      ),
    );
  }

  Widget _endingChip(List<String> e) {
    final got = _seen.contains(e[0]);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: got ? const Color(0xFF2A2438) : const Color(0xFF15131C),
        border: Border.all(color: got ? Colors.amberAccent : Colors.white12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(got ? '${e[0]} ${e[1]}' : '？？？',
          style: TextStyle(
              fontSize: 11, color: got ? Colors.amberAccent : Colors.white24)),
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
