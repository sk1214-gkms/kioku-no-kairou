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

  // モード選択：難度3層＋制限時間トグル（ストーリーは常に時間なし）
  String _diff = 'normal'; // story / normal / hard
  bool _timed = false;

  static const List<Map<String, String>> _diffs = [
    {
      'key': 'story',
      'name': 'ストーリー',
      'goal': '物語を味わう',
      'desc': '時間制限なし。最終ヒントまで開放の安全網。推理が苦手でも結末へ辿り着ける。',
    },
    {
      'key': 'normal',
      'name': 'ノーマル',
      'goal': '標準の謎解き',
      'desc': '答えの最終ヒントは無し＝自力で導く。手応えと達成感のバランス。',
    },
    {
      'key': 'hard',
      'name': 'ハード',
      'goal': '限界に挑む',
      'desc': '手がかりを暗号化し、ミスリードを増した最難。',
    },
  ];

  String _resolveMode() =>
      _diff == 'story' ? 'story' : (_timed ? '${_diff}_t' : _diff);

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

  // 5モード。難度3層(story/normal/hard) × 時間制限(なし / 末尾_t=あり)。
  static const Map<String, String> _modeLabels = {
    'story': 'ストーリー',
    'normal': 'ノーマル',
    'normal_t': 'ノーマル＋時間',
    'hard': 'ハード',
    'hard_t': 'ハード＋時間',
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
                  _modeSelector(),
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

  // ===== モード選択：3カード（難度）＋制限時間トグル＋開始ボタン =====
  Widget _modeSelector() {
    final canTime = _diff != 'story';
    final dur = _diff == 'hard' ? '12分' : '15分';
    return SizedBox(
      width: 340,
      child: Column(
        children: [
          const Text('難易度を選ぶ',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 8),
          for (final d in _diffs) _diffCard(d),
          const SizedBox(height: 10),
          // 制限時間トグル（ストーリー時は無効）
          Opacity(
            opacity: canTime ? 1 : 0.35,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF15131C),
                border: Border.all(
                    color: (canTime && _timed)
                        ? Colors.redAccent
                        : Colors.white12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SwitchListTile(
                value: canTime && _timed,
                onChanged:
                    canTime ? (v) => setState(() => _timed = v) : null,
                dense: true,
                title: const Text('⏱ 制限時間（脳死カウント）',
                    style: TextStyle(fontSize: 13)),
                subtitle: Text(
                    canTime
                        ? '$dur で時間切れ＝“精神の死(D)”。この時だけの結末が加わる。'
                        : 'ストーリーは時間制限なし',
                    style: const TextStyle(fontSize: 10, color: Colors.white38)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _deepNew(_resolveMode()),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text('${_modeLabels[_resolveMode()]} で潜る  →',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _diffCard(Map<String, String> d) {
    final sel = _diff == d['key'];
    return GestureDetector(
      onTap: () => setState(() {
        _diff = d['key']!;
        if (_diff == 'story') _timed = false;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF241F33) : const Color(0xFF15131C),
          border: Border.all(
              color: sel ? Colors.amberAccent : Colors.white12,
              width: sel ? 2 : 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
                sel
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 18,
                color: sel ? Colors.amberAccent : Colors.white24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(d['name']!,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text('— ${d['goal']}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.amberAccent)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(d['desc']!,
                      style:
                          const TextStyle(fontSize: 11, color: Colors.white54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
