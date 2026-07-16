import 'package:flutter/material.dart';
import '../collection_service.dart';
import '../deep_save_service.dart';
import 'deep_campaign_flow.dart';

/// タイトル＋モード選択。ここで選んだモードが体験（記憶・結末）を変える。
/// 中断したプレイがあれば「つづきから」を表示する。
/// 見た目は docs/design_title_mock.html のデザイン案に準拠（配色HEX一致）。
class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key});

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> {
  // ===== 館のDNA配色（design_title_mock.html と一致）=====
  static const _bg = Color(0xFF0E0C14);
  static const _panel = Color(0xFF15131C);
  static const _sel = Color(0xFF241F33);
  static const _line = Color(0xFF2A2733);
  static const _red = Color(0xFF961A1A);
  static const _redAccent = Color(0xFFFF5A5A);
  static const _gold = Colors.amberAccent; // ≒ #FFD740
  static const _sub = Color(0xFF8A8496);

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
      'echo': 'STORY',
      'goal': '物語を味わう',
      'desc': '時間制限なし。最終ヒントまで開放の安全網。推理が苦手でも結末へ辿り着ける。',
    },
    {
      'key': 'normal',
      'name': 'ノーマル',
      'echo': 'NORMAL',
      'goal': '標準の謎解き',
      'desc': '答えの最終ヒントは無し＝自力で導く。手応えと達成感のバランス。',
    },
    {
      'key': 'hard',
      'name': 'ハード',
      'echo': 'HARD',
      'goal': '限界に挑む',
      'desc': '手がかりを暗号化し、ミスリードを増した最難。記憶が牙を剥く。',
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
      backgroundColor: _bg,
      body: Stack(
        children: [
          const Positioned.fill(child: _Atmosphere()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(26, 44, 26, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _logo(),
                      const SizedBox(height: 18),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        )
                      else ...[
                        if (_deepSaved != null) ...[
                          _continueButton(),
                          const SizedBox(height: 12),
                          const Text('― はじめから ―',
                              style: TextStyle(color: Colors.white38)),
                          const SizedBox(height: 6),
                        ],
                        _modeSelector(),
                        if (_judgmentCp != null) ...[
                          const SizedBox(height: 10),
                          _retryButton(),
                        ],
                        const SizedBox(height: 12),
                        _collectionButton(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== ロゴ（紋章＝アプリアイコン＋kicker＋明朝風タイトル＋副題）=====
  Widget _logo() {
    return Column(
      children: [
        // アプリの顔（V3：頭文字A×鍵穴）を封蝋のような円形の紋章として据える
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _gold.withValues(alpha: 0.45), width: 1.5),
            boxShadow: [
              BoxShadow(color: _red.withValues(alpha: 0.28), blurRadius: 26),
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6), blurRadius: 18),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/icon/app_icon.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text('A M N E S I E   C A S E',
            style: TextStyle(
                fontFamily: 'Blackletter',
                color: Color(0xFFB9B1C4),
                fontSize: 15,
                letterSpacing: 4)),
        const SizedBox(height: 8),
        Text.rich(
          const TextSpan(children: [
            TextSpan(text: 'アムネジィ・ケー'),
            TextSpan(
                text: 'ス',
                style: TextStyle(color: _redAccent, shadows: [
                  Shadow(color: _red, blurRadius: 16),
                ])),
          ]),
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              color: Color(0xFFF2ECE0),
              height: 1.15,
              shadows: [Shadow(color: Colors.black, blurRadius: 24)]),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ruleLine(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('教授の不完全な安楽',
                  style: TextStyle(
                      color: _sub, fontSize: 14, letterSpacing: 4)),
            ),
            _ruleLine(),
          ],
        ),
      ],
    );
  }

  Widget _ruleLine() =>
      Container(width: 30, height: 1, color: _line);

  Widget _continueButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _deepContinue,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _gold),
          foregroundColor: _gold,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text('つづきから（第${_deepSaved!.idx + 1}室）',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _retryButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _retryJudgment,
        icon: const Icon(Icons.gavel, size: 18, color: _gold),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            '最後の審判からやり直す（${_modeLabels[_judgmentCp!.mode] ?? _judgmentCp!.mode}）',
            style: const TextStyle(fontSize: 13, color: _gold),
          ),
        ),
      ),
    );
  }

  // 縦を圧迫しないよう、結末コレクションはボタン→ボトムシートに退避（既定は畳む）。
  Widget _collectionButton() {
    return TextButton(
      onPressed: _showCollection,
      child: Text(
          '── 結末コレクション　${_seen.length} / ${_allEndings.length} ──',
          style: const TextStyle(color: _sub, fontSize: 12)),
    );
  }

  void _showCollection() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final teasable = _seen.isNotEmpty && _seen.length < _allEndings.length;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('結末コレクション　${_seen.length} / ${_allEndings.length}',
                  style: const TextStyle(
                      color: _gold, fontSize: 14, letterSpacing: 2)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [for (final e in _allEndings) _endingChip(e)],
              ),
              if (teasable)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text('？？？ に触れると、手がかりが浮かぶ',
                      style: TextStyle(color: Color(0xFF4B465A), fontSize: 10)),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _endingChip(List<String> e) {
    final got = _seen.contains(e[0]);
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: got ? _sel : const Color(0xFF100E17),
        border: Border.all(color: got ? _gold : _line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(got ? '${e[0]} ${e[1]}' : '？？？',
          style: TextStyle(
              fontSize: 11,
              letterSpacing: got ? 0 : 2,
              color: got ? _gold : const Color(0xFF4B465A))),
    );
    if (got || _seen.isEmpty) return chip;
    return GestureDetector(onTap: () => _showTeaser(e[0]), child: chip);
  }

  void _showTeaser(String code) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _panel,
        title: const Text('？？？',
            style: TextStyle(color: _gold, letterSpacing: 4)),
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
    return Column(
      children: [
        const Text('── 記憶に、潜る難度を選ぶ ──',
            style: TextStyle(color: _sub, fontSize: 12, letterSpacing: 1)),
        const SizedBox(height: 10),
        for (final d in _diffs) _diffCard(d),
        const SizedBox(height: 10),
        // 制限時間トグル（ストーリー時は無効）
        Opacity(
          opacity: canTime ? 1 : 0.4,
          child: Container(
            decoration: BoxDecoration(
              color: _panel,
              border: Border.all(
                  color: (canTime && _timed) ? _redAccent : _line),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SwitchListTile(
              value: canTime && _timed,
              onChanged: canTime ? (v) => setState(() => _timed = v) : null,
              dense: true,
              title: const Text('⏱ 制限時間（脳死カウント）',
                  style: TextStyle(fontSize: 13)),
              subtitle: Text(
                  canTime
                      ? '$dur で時間切れ＝“精神の死”。この時だけの結末が加わる。'
                      : 'ストーリーは時間制限なし',
                  style: const TextStyle(fontSize: 10, color: _sub)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _diveButton(),
      ],
    );
  }

  Widget _diveButton() {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A2440), Color(0xFF1C1830)],
          ),
          border: Border.all(color: const Color(0xFF4A3F6B)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 8)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _deepNew(_resolveMode()),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('${_modeLabels[_resolveMode()]} で潜る　→',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Color(0xFFEDE7DA))),
            ),
          ),
        ),
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
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: sel ? _sel : _panel,
          border: Border.all(
              color: sel ? _gold : _line, width: sel ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
          boxShadow: sel
              ? [
                  BoxShadow(
                      color: _gold.withValues(alpha: 0.10), blurRadius: 26),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
                sel
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 18,
                color: sel ? _gold : const Color(0xFF4A4560)),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(d['name']!,
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              color: sel ? _gold : Colors.white)),
                      const SizedBox(width: 8),
                      Text(d['echo']!,
                          style: const TextStyle(
                              fontFamily: 'Blackletter',
                              fontSize: 12,
                              color: Color(0xFF5F5A70))),
                      const Spacer(),
                      Text(d['goal']!,
                          style: TextStyle(
                              fontSize: 11,
                              color: _gold.withValues(alpha: 0.85))),
                    ],
                  ),
                  // 説明は選択中のカードだけ表示＝縦の圧迫を抑える
                  if (sel) ...[
                    const SizedBox(height: 5),
                    Text(d['desc']!,
                        style: const TextStyle(
                            fontSize: 11, color: _sub, height: 1.5)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 背景の雰囲気レイヤ（暗い階調＋ビネット＋血の赤の一差し＋巨大な亀甲文字）。
class _Atmosphere extends StatelessWidget {
  const _Atmosphere();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          // 階調（ティール寄りの上→漆黒の下）
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF141A1C), Color(0xFF0E0C14), Color(0xFF070609)],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: SizedBox.expand(),
          ),
          // 巨大な亀甲文字の焼き込み（アイコンと同じ頭文字 A）
          Center(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Text('A',
                  style: TextStyle(
                      fontFamily: 'Blackletter',
                      fontSize: 460,
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.03))),
            ),
          ),
          // 血の赤の一差し（斜めの滲み）
          Align(
            alignment: const Alignment(0.35, -0.55),
            child: Transform.rotate(
              angle: 0.42,
              child: Container(
                width: 3,
                height: 220,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _red0(0),
                      _red0(0.5),
                      _red0(0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // ビネット（周辺を締める）
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.95,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.62),
                ],
                stops: const [0.6, 1.0],
              ),
            ),
            child: const SizedBox.expand(),
          ),
        ],
      ),
    );
  }

  static Color _red0(double a) => const Color(0xFF961A1A).withValues(alpha: a);
}
