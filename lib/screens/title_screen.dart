import 'package:flutter/material.dart';
import '../collection_service.dart';
import '../deep_save_service.dart';
import 'deep_campaign_flow.dart';

/// タイトル＋モード選択。ここで選んだモードが体験（記憶・結末）を変える。
/// 中断したプレイがあれば「つづきから」を表示する。
class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key});

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> {
  final DeepSaveService _deepSave = DeepSaveService();
  final CollectionService _collection = CollectionService();
  DeepSavedRun? _deepSaved;
  JudgmentCheckpoint? _judgmentCp; // 「最後の審判からやり直す」
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

  // A3：未取得の結末チップをタップすると浮かぶ“条件のティーザー”（初回クリア後）。
  static const Map<String, String> _teasers = {
    'A+': 'すべてを偽り、すべてから目を背けたなら——',
    'A': '嘘は完成した。だが、目は逸らしきれなかった。',
    'B': '嘘は綻び、それでも背け続けたなら——',
    'C': '嘘は綻び、直視だけが残ったなら——',
    'S': '標本室の奥に隠された“それ”が、鍵になる。',
    'True': 'すべての真実を直視し、すべてに向き合ったなら——',
    'D': '刻限の中で、脳が灼き切れたら——（時間制限モードのみ）',
  };

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final d = await _deepSave.load();
    final jc = await _deepSave.loadJudgment();
    final seen = await _collection.seen();
    if (!mounted) return;
    setState(() {
      _deepSaved = d;
      _judgmentCp = jc;
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

  /// 「最後の審判からやり直す」：保存済みチェックポイントから審判へ直行。
  Future<void> _retryJudgment() async {
    final cp = _judgmentCp;
    if (cp == null) return;
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => DeepCampaignFlow(mode: cp.mode, retry: cp)));
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
                  // 審判到達済みなら、答えだけ変えて別の結末を回収できる
                  if (_judgmentCp != null) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: 320,
                      child: OutlinedButton.icon(
                        onPressed: _retryJudgment,
                        icon: const Icon(Icons.gavel,
                            size: 18, color: Colors.amberAccent),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            '最後の審判からやり直す（${_modeLabels[_judgmentCp!.mode] ?? _judgmentCp!.mode}）',
                            style: const TextStyle(
                                fontSize: 13, color: Colors.amberAccent),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _endingCollection(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _endingCollection() {
    final teasable = _seen.isNotEmpty && _seen.length < _allEndings.length;
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
          // A3：初回クリア後は「？？？」タップで条件のティーザーが浮かぶ
          if (teasable)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('？？？ に触れると、手がかりが浮かぶ',
                  style: TextStyle(color: Colors.white24, fontSize: 10)),
            ),
        ],
      ),
    );
  }

  Widget _endingChip(List<String> e) {
    final got = _seen.contains(e[0]);
    final chip = Container(
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
    // A3：未取得＋初回クリア済み → タップでティーザー表示
    if (got || _seen.isEmpty) return chip;
    return GestureDetector(
      onTap: () => _showTeaser(e[0]),
      child: chip,
    );
  }

  void _showTeaser(String code) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF15131C),
        title: const Text('？？？',
            style: TextStyle(color: Colors.amberAccent, letterSpacing: 4)),
        content: Text(_teasers[code] ?? '……',
            style: const TextStyle(color: Colors.white70, height: 1.8)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
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
