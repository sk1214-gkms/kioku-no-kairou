import 'dart:async';
import 'package:flutter/material.dart';
import '../ad_service.dart';
import '../content_repository.dart';
import '../models.dart';
import '../widgets/design_canvas.dart';

/// 1ステージを描画・操作する画面。
/// アート未制作のため、interactables はラベル付きの枠で代用表示する。
/// hard モードでは hard ブロックの interactables/gimmick を使い、手がかりは回廊文字で表示する。
class StageScreen extends StatefulWidget {
  final Stage stage;
  final GameState gameState;
  final ContentRepository repo;
  final String mode; // normal | hard | timer
  final bool timed;
  final int seconds;
  final void Function(Stage solved) onSolved;
  final void Function(Stage timedOut) onTimeout;

  const StageScreen({
    super.key,
    required this.stage,
    required this.gameState,
    required this.repo,
    required this.onSolved,
    required this.onTimeout,
    this.mode = 'normal',
    this.timed = false,
    this.seconds = 90,
  });

  @override
  State<StageScreen> createState() => _StageScreenState();
}

class _StageScreenState extends State<StageScreen> {
  final Map<String, String> _runtimeStates = {}; // toggle / on_use 用
  final List<String> _sequence = [];
  final Set<String> _used = {}; // 使用済みの対象
  final Map<String, String> _placement = {}; // drag: piece -> slot
  String? _selectedItem; // 選択中のアイテム
  String _entry = '';
  final TextEditingController _textCtrl = TextEditingController();
  String _message = 'まわりを調べてみよう。';
  Timer? _timer;
  int _remaining = 0;

  bool get _hard => widget.mode == 'hard';
  String get _solKey => _hard ? 'hard' : 'normal';
  StageHard? get _hardData => widget.stage.hard;

  /// この部屋で使う難化モディファイア。未宣言ならグリフの有無から推測。
  List<String> get _modifiers {
    final m = _hardData?.modifiers;
    if (m != null) return m;
    final hasGlyph = _interactables.any((it) =>
        it.revealsGlyphs != null ||
        it.revealsGlyphsReflected != null ||
        it.labelGlyph != null);
    return hasGlyph ? const ['cipher'] : const [];
  }

  List<Interactable> get _interactables =>
      (_hard && _hardData?.interactables != null)
          ? _hardData!.interactables!
          : widget.stage.interactables;

  Gimmick get _g => (_hard && _hardData?.gimmick != null)
      ? _hardData!.gimmick!
      : widget.stage.gimmick!;

  List<String> get _hints =>
      _hard ? (_hardData?.hints ?? const <String>[]) : widget.stage.hints;

  late final Map<String, Interactable> _interMap = {
    for (final it in _interactables) it.id: it
  };

  Set<String> get _sequenceButtonIds {
    if (_g.type != 'sequence_tap') return {};
    final sol = (_solution as List?) ?? [];
    return sol.map((e) => e.toString()).toSet();
  }

  @override
  void initState() {
    super.initState();
    for (final it in _interactables) {
      if (it.toggle && it.states.isNotEmpty) {
        _runtimeStates[it.id] = it.states.first;
      }
    }
    if (widget.timed) {
      _remaining = widget.seconds;
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _textCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _remaining -= 1);
      if (_remaining <= 0) {
        t.cancel();
        _handleTimeout();
      }
    });
  }

  void _handleTimeout() {
    // 調査/ヒント/解読書などのダイアログが開いていれば先に閉じる
    final myRoute = ModalRoute.of(context);
    if (myRoute != null && !myRoute.isCurrent) {
      Navigator.of(context).popUntil((r) => r == myRoute);
    }
    final r = widget.stage.rewards!;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('― 時間切れ ―'),
        content:
            SingleChildScrollView(child: Text(widget.repo.text(r.textCorrupt))),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onTimeout(widget.stage);
            },
            child: const Text('次へ進む'),
          ),
        ],
      ),
    );
  }

  String _fmt(int s) {
    final m = (s ~/ 60).toString();
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  bool _stateOk(List<Prerequisite> prs) =>
      prs.every((p) => _runtimeStates[p.interactable] == p.state);

  bool get _prereqSatisfied => _stateOk(_g.prerequisites);

  /// hard 解が無ければ normal にフォールバック
  dynamic get _solution => _g.solutions[_solKey] ?? _g.solutions['normal'];

  void _setMessage(String m) => setState(() => _message = m);

  /// condition タイプ：前提が揃ったら自動クリア
  void _checkCondition() {
    if (_g.type == 'condition' && _prereqSatisfied) _solve();
  }

  void _onTap(Interactable it) {
    // 1) 順番タップのボタン
    if (_sequenceButtonIds.contains(it.id)) {
      setState(() {
        _sequence.add(it.id);
        _message = '選択: ${_displayLabel(it.id)}（${_sequence.length}個目）';
      });
      final sol = (_solution as List).map((e) => e.toString()).toList();
      if (_sequence.length >= sol.length) _checkSequence(sol);
      return;
    }

    // 2) トグル（ブレーカー/照明など）— 常に操作可
    if (it.toggle && it.states.length >= 2) {
      final cur = _runtimeStates[it.id] ?? it.states.first;
      final next = it.states[(it.states.indexOf(cur) + 1) % it.states.length];
      setState(() {
        _runtimeStates[it.id] = next;
        _message = '${_label(it.id)} を切り替えた → $next';
      });
      _checkCondition();
      return;
    }

    // 3) この対象が前提状態を要求するなら、満たすまで反応しない
    if (it.requiresState != null && !_stateOk(it.requiresState!)) {
      _setMessage('今は反応しないようだ…（何かが足りない）');
      return;
    }

    // 4) アイテムを使う対象
    if (it.requiresItem != null) {
      _handleUse(it);
      return;
    }

    // 5) アイテム入手（隠し含む）
    if (it.givesItem != null) {
      if (!widget.gameState.items.contains(it.givesItem)) {
        setState(() {
          widget.gameState.items.add(it.givesItem!);
          if (it.givesItem == 'item_culprit_evidence') {
            widget.gameState.flags['has_culprit_evidence'] = true;
          }
          _message = '【${_itemLabel(it.givesItem!)}】を手に入れた。';
        });
      } else {
        _setMessage('もう調べ終えた。');
      }
      return;
    }

    // 6) 調査（拡大して手がかりを見る）
    final locked = _g.prerequisites.isNotEmpty && !_prereqSatisfied;
    _showZoom(_label(it.id), _revealBody(it, locked));
  }

  void _handleUse(Interactable it) {
    if (_used.contains(it.id)) {
      _showZoom(_label(it.id), it.onUseReveals ?? '（もう使った）');
      return;
    }
    if (_selectedItem != it.requiresItem) {
      _setMessage(
          'アイテムを選んでから使おう。（${_itemLabel(it.requiresItem!)}が要りそうだ）');
      return;
    }
    setState(() {
      _used.add(it.id);
      if (it.onUseState != null) _runtimeStates[it.id] = it.onUseState!;
      if (it.onUseGivesItem != null &&
          !widget.gameState.items.contains(it.onUseGivesItem)) {
        widget.gameState.items.add(it.onUseGivesItem!);
      }
      _selectedItem = null;
      _message = '${_itemLabel(it.requiresItem!)}を使った。';
    });
    if (it.onUseReveals != null) _showZoom(_label(it.id), it.onUseReveals!);
    _checkCondition();
  }

  String _revealBody(Interactable it, bool locked) {
    if (locked) return '（まだ何も見えない…暗くしないと？）';
    if (it.decoy && it.reveals == null && it.revealsGlyphs == null) {
      return '特に手がかりは無さそうだ…（ダミー）';
    }
    if (it.revealsGlyphs != null) {
      final s = it.revealsGlyphs!.map(widget.repo.glyphSymbol).join('   ');
      return '$s\n\n回廊文字だ。メニューの「暗号解読書」で変換しよう。';
    }
    if (it.revealsGlyphsReflected != null) {
      final s =
          it.revealsGlyphsReflected!.map(widget.repo.glyphSymbol).join('   ');
      return '$s\n\n鏡に映った回廊文字（左右が反転している）。';
    }
    return it.reveals ?? '（手がかり画像: ${it.zoomImage ?? "なし"}）';
  }

  void _showZoom(String title, String body) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content:
            Text(body, style: const TextStyle(fontSize: 22, letterSpacing: 2)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('閉じる')),
        ],
      ),
    );
  }

  void _showCipherBook() {
    final glyphs =
        (widget.repo.cipher['glyphs'] as Map).cast<String, dynamic>();
    final entries = glyphs.entries.toList();
    final name =
        (widget.repo.cipher['_meta']?['name'] as String?) ?? '暗号解読書';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(name),
        content: SizedBox(
          width: double.maxFinite,
          height: 380,
          child: GridView.count(
            crossAxisCount: 4,
            childAspectRatio: 0.8,
            children: [
              for (final e in entries)
                Card(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text((e.value['proto_symbol'] as String?) ?? '?',
                          style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 4),
                      Text((e.value['value'] as String?) ?? '',
                          style: const TextStyle(
                              fontSize: 13, color: Colors.amberAccent)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('閉じる')),
        ],
      ),
    );
  }

  void _checkSequence(List<String> sol) {
    if (_listEq(_sequence, sol)) {
      _solve();
    } else {
      setState(() {
        _message = '違うようだ…（最初からやり直し）';
        _sequence.clear();
      });
    }
  }

  void _submitNumber() {
    if (_g.prerequisites.isNotEmpty && !_prereqSatisfied) {
      _setMessage('まだ入力しても反応がない…');
      return;
    }
    final ans = (_solution ?? '').toString();
    if (_entry == ans) {
      _solve();
    } else {
      setState(() {
        _message = '違うようだ…';
        _entry = '';
      });
    }
  }

  void _submitText() {
    if (_g.prerequisites.isNotEmpty && !_prereqSatisfied) {
      _setMessage('入力しても、何も反応がない…');
      return;
    }
    final ans = (_solution ?? '').toString();
    final input = _textCtrl.text;
    final ok = _g.validate == 'case_insensitive'
        ? input.toLowerCase() == ans.toLowerCase()
        : input == ans;
    if (ok) {
      _solve();
    } else {
      setState(() => _message = '違うようだ…');
      _textCtrl.clear();
    }
  }

  void _solve() {
    _timer?.cancel();
    final r = widget.stage.rewards!;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('ドアが開いた'),
        content:
            SingleChildScrollView(child: Text(widget.repo.text(r.textFull))),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onSolved(widget.stage);
            },
            child: const Text('次へ進む'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stage = widget.stage;
    return Scaffold(
      appBar: AppBar(
        title: Text('STAGE ${stage.stageId}  ${stage.name}'),
        actions: [
          if (widget.timed)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  _fmt(_remaining < 0 ? 0 : _remaining),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _remaining <= 10 ? Colors.redAccent : Colors.white,
                  ),
                ),
              ),
            ),
          if (_hard && _modifiers.contains('cipher'))
            IconButton(
              tooltip: '暗号解読書',
              icon: const Icon(Icons.menu_book),
              onPressed: _showCipherBook,
            ),
          if (_hints.isNotEmpty)
            IconButton(
              tooltip: 'ヒント（動画広告）',
              icon: const Icon(Icons.lightbulb_outline),
              onPressed: _onHintPressed,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: const Color(0xFF15131C),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(8),
              child: DesignCanvas(
                children:
                    _g.type == 'drag' ? _dragChildren() : _canvasChildren(),
              ),
            ),
          ),
          _statusBar(),
          _panel(),
        ],
      ),
    );
  }

  Widget _doorDecoration() => Positioned(
        left: 110,
        top: 90,
        width: 140,
        height: 430,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A2438),
            border: Border.all(color: Colors.black54, width: 4),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 8),
          child: const Text('DOOR', style: TextStyle(color: Colors.white24)),
        ),
      );

  List<Widget> _canvasChildren() {
    final children = <Widget>[_doorDecoration()];

    for (final it in _interactables) {
      children.add(Positioned(
        left: it.rect[0],
        top: it.rect[1],
        width: it.rect[2],
        height: it.rect[3],
        child: GestureDetector(
          onTap: () => _onTap(it),
          child: Container(
            decoration: BoxDecoration(
              color: it.hidden
                  ? const Color(0x40795548) // brown 25%
                  : const Color(0x59673AB7), // deepPurple 35%
              border: Border.all(
                color:
                    _sequence.contains(it.id) ? Colors.amber : Colors.white70,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: _boxLabel(it),
          ),
        ),
      ));
    }
    return children;
  }

  // ---- drag（ピースをスロットへ）----
  List<Widget> _dragChildren() {
    final sol = (_solution as Map).cast<String, String>();
    final children = <Widget>[_doorDecoration()];

    // スロット（受け皿）
    for (final it in _interactables.where((i) => i.slot)) {
      final placed = _pieceInSlot(it.id);
      children.add(Positioned(
        left: it.rect[0],
        top: it.rect[1],
        width: it.rect[2],
        height: it.rect[3],
        child: DragTarget<String>(
          onWillAcceptWithDetails: (d) =>
              sol[d.data] == it.id && !_placement.containsKey(d.data),
          onAcceptWithDetails: (d) {
            setState(() {
              _placement[d.data] = it.id;
              _message = 'はまった。';
            });
            if (_placement.length == sol.length) _solve();
          },
          builder: (ctx, cand, rej) => Container(
            decoration: BoxDecoration(
              color: const Color(0x33FFFFFF),
              border: Border.all(
                color: cand.isNotEmpty ? Colors.amber : Colors.white38,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(placed != null ? _label(placed) : _label(it.id),
                style: const TextStyle(fontSize: 11, color: Colors.white)),
          ),
        ),
      ));
    }

    // ピース（未配置のみドラッグ可能）
    for (final it in _interactables.where((i) => i.draggable)) {
      if (_placement.containsKey(it.id)) continue;
      children.add(Positioned(
        left: it.rect[0],
        top: it.rect[1],
        width: it.rect[2],
        height: it.rect[3],
        child: Draggable<String>(
          data: it.id,
          feedback: Material(
            type: MaterialType.transparency,
            child: _pieceBox(it),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: _pieceBox(it)),
          child: _pieceBox(it),
        ),
      ));
    }
    return children;
  }

  Widget _pieceBox(Interactable it) => Container(
        width: it.rect[2],
        height: it.rect[3],
        decoration: BoxDecoration(
          color: const Color(0xFF4A3F66),
          border: Border.all(color: Colors.white70, width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(_label(it.id),
            style: const TextStyle(fontSize: 11, color: Colors.white)),
      );

  String? _pieceInSlot(String slotId) {
    for (final e in _placement.entries) {
      if (e.value == slotId) return e.key;
    }
    return null;
  }

  Widget _boxLabel(Interactable it) {
    if (it.labelGlyph != null) {
      return Text(widget.repo.glyphSymbol(it.labelGlyph!),
          style: const TextStyle(fontSize: 26, color: Colors.white));
    }
    final state = it.toggle ? (_runtimeStates[it.id] ?? '') : '';
    return Text(
      it.toggle ? '${_label(it.id)}\n[$state]' : _label(it.id),
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 11, color: Colors.white),
    );
  }

  Widget _statusBar() {
    final items = widget.gameState.items;
    return Container(
      width: double.infinity,
      color: const Color(0xFF1E1B26),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_message, style: const TextStyle(color: Colors.amberAccent)),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final id in items)
                  GestureDetector(
                    onTap: () => setState(
                        () => _selectedItem = _selectedItem == id ? null : id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _selectedItem == id
                            ? const Color(0xFFB8860B)
                            : const Color(0xFF2A2438),
                        border: Border.all(
                            color: _selectedItem == id
                                ? Colors.amber
                                : Colors.white24),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(_itemLabel(id),
                          style: TextStyle(
                              fontSize: 12,
                              color: _selectedItem == id
                                  ? Colors.black
                                  : Colors.white)),
                    ),
                  ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text('アイテムをタップで選択 → 対象をタップで使用',
                  style: TextStyle(color: Colors.white38, fontSize: 10)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _panel() {
    switch (_g.type) {
      case 'number_pad':
        return _numberPad();
      case 'text_input':
        return _textInput();
      case 'sequence_tap':
        return _sequenceBar();
      case 'drag':
        return _infoBar('ピースを正しい枠へドラッグしよう');
      case 'condition':
        return _infoBar('アイテムや仕掛けを使ってドアを開けよう');
      default:
        return _textInput();
    }
  }

  Widget _infoBar(String text) => Container(
        width: double.infinity,
        color: const Color(0xFF12101A),
        padding: const EdgeInsets.all(16),
        child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70)),
      );

  Widget _numberPad() {
    Widget key(String label, VoidCallback onTap) => Expanded(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: ElevatedButton(
                onPressed: onTap,
                child: Text(label, style: const TextStyle(fontSize: 20))),
          ),
        );
    Widget row(List<Widget> ks) => Row(children: ks);
    return Container(
      color: const Color(0xFF12101A),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(vertical: 10),
            width: double.infinity,
            color: Colors.black,
            alignment: Alignment.center,
            child: Text(_entry.isEmpty ? '____' : _entry,
                style: const TextStyle(
                    fontSize: 26,
                    letterSpacing: 6,
                    color: Colors.greenAccent)),
          ),
          row([for (final n in ['1', '2', '3']) key(n, () => _press(n))]),
          row([for (final n in ['4', '5', '6']) key(n, () => _press(n))]),
          row([for (final n in ['7', '8', '9']) key(n, () => _press(n))]),
          row([
            key('C', () => setState(() => _entry = '')),
            key('0', () => _press('0')),
            key('決定', _submitNumber),
          ]),
        ],
      ),
    );
  }

  void _press(String d) => setState(() => _entry += d);

  Widget _textInput() {
    return Container(
      color: const Color(0xFF12101A),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '答えを入力',
                isDense: true,
              ),
              onSubmitted: (_) => _submitText(),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(onPressed: _submitText, child: const Text('決定')),
        ],
      ),
    );
  }

  Widget _sequenceBar() {
    return Container(
      color: const Color(0xFF12101A),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _sequence.isEmpty
                  ? 'ボタンを順番にタップ'
                  : '入力中: ${_sequence.map(_displayLabel).join(" → ")}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () => setState(() {
              _sequence.clear();
              _message = 'リセットした。';
            }),
            child: const Text('リセット'),
          ),
        ],
      ),
    );
  }

  Future<void> _onHintPressed() async {
    final wasTimed = widget.timed;
    if (wasTimed) _timer?.cancel();
    await AdService.instance.showRewarded();
    if (!mounted) return;
    await _showHints();
    if (mounted && wasTimed && _remaining > 0) _startTimer();
  }

  Future<void> _showHints() {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ヒント'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < _hints.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('${i + 1}. ${widget.repo.text(_hints[i])}'),
              ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('閉じる')),
        ],
      ),
    );
  }

  // ---- ラベル（アート未制作のための日本語表示）----
  static const Map<String, String> _labels = {
    'painting': '絵画',
    'wall_clock': '掛け時計',
    'floor_books': '床の本',
    'btn_red': '赤ボタン',
    'btn_blue': '青ボタン',
    'btn_yellow': '黄ボタン',
    'btn_a': 'ボタンA',
    'btn_b': 'ボタンB',
    'btn_c': 'ボタンC',
    'broken_clock': '止まった時計',
    'mirror': '鏡',
    'wall_number': '壁の数字',
    'hidden_drawer': '引き出し',
    'breaker': 'ブレーカー',
    'door_glow_text': 'ドアの表面',
    'portrait': '肖像画',
    'shelf': '棚',
    'btn_pawn': 'ポーン',
    'btn_knight': 'ナイト',
    'btn_rook': 'ルーク',
    'lever': 'レバー',
    'bottles': '薬品棚',
    'wall_abcd': '壁のABCD',
    'blood': '血痕',
    'btn_circle': '◯',
    'btn_star': '☆',
    'btn_square': '□',
    'btn_triangle': '△',
    'calendar': 'カレンダー',
    'memo': 'メモ',
    'light_switch': '照明',
    'fireplace': '暖炉',
    'clue_panel': '暗号パネル',
    'door_mount': 'ドアの取付部',
    'decoy_memo': '別のメモ',
    'old_handle': '古い取っ手',
    'driver_floor': 'ドライバー',
    'panel': 'パネル',
    'decoy_panel': '別のパネル',
    'piece_a': '紙片A',
    'piece_b': '紙片B',
    'piece_c': '紙片C',
    'slot_1': '枠1',
    'slot_2': '枠2',
    'slot_3': '枠3',
  };
  String _label(String id) => _labels[id] ?? id;

  /// 順番タップの表示。hard でラベルが回廊文字なら記号を返す。
  String _displayLabel(String id) {
    final it = _interMap[id];
    if (it?.labelGlyph != null) return widget.repo.glyphSymbol(it!.labelGlyph!);
    return _label(id);
  }

  static const Map<String, String> _itemLabels = {
    'item_invitation': '館の招待状',
    'item_diary': '引きちぎられた日記',
    'item_culprit_evidence': '真犯人の遺留品',
    'item_driver': 'ドライバー',
    'item_doorknob': 'ドアノブ',
    'item_handle': '古い取っ手',
  };
  String _itemLabel(String id) => _itemLabels[id] ?? id;

  bool _listEq(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
