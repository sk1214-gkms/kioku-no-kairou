import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import '../audio_service.dart';
import '../models.dart';
import '../widgets/design_canvas.dart';

/// 深い部屋（東西南北4視点 × ネスト調査 × アイテム合成 × 多段ロック）。
/// キャンペーンから room データ＋GameState を注入して使う（onCleared を呼ぶ）。
/// 脳死カウントダウンはキャンペーン側が保持し、残り秒(remaining: ValueListenable)を購読して表示するだけ。
/// デモ用途では gameState/onCleared を省略でき、その場合は脱出でタイトルへ戻る。
class DeepRoomScreen extends StatefulWidget {
  final Map<String, dynamic> room;
  final GameState? gameState;
  final String mode; // normal | hard | timer
  final bool timed; // 脳死クロックを表示するか
  final ValueListenable<int>? remaining; // 脳死までの残り秒（キャンペーン保持・通知）
  final VoidCallback? onCleared;
  final List<String> litGlyphs; // これまで点灯したトラウマ文字（点灯順＝不規則）

  const DeepRoomScreen({
    super.key,
    required this.room,
    this.gameState,
    this.mode = 'normal',
    this.timed = false,
    this.remaining,
    this.onCleared,
    this.litGlyphs = const [],
  });

  @override
  State<DeepRoomScreen> createState() => _DeepRoomScreenState();
}

class _DeepRoomScreenState extends State<DeepRoomScreen> {
  static const _dirs = ['north', 'east', 'south', 'west'];
  int _dirIdx = 0;
  final List<Map<String, dynamic>> _subStack = [];
  final Map<String, String> _states = {};
  final List<String> _items = [];
  final List<String> _selected = [];
  String _msg = '';
  bool _done = false;
  int _hintLevel = 0; // 公開済みヒント段数（最大3）

  Map<String, dynamic> get _room => widget.room;

  bool get _hard => widget.mode == 'hard';

  List<String> get _hints => ((_room['hints'] as List?) ?? []).cast<String>();
  // ハードは最終（答え直結）ヒントを伏せる＝説明を減らす難化
  int get _maxHint =>
      _hard ? (_hints.length - 1).clamp(0, _hints.length) : _hints.length;

  /// ハードでは reveal_hard（あれば）を使い、親切な説明を伏せる。
  String _reveal(Map<String, dynamic> o) =>
      (_hard && o['reveal_hard'] != null)
          ? o['reveal_hard'] as String
          : (o['reveal'] as String? ?? '特に何もないようだ。');

  @override
  void initState() {
    super.initState();
    _msg = _room['intro'] as String? ?? '四方の壁を調べよう。';
  }

  Map<String, String> get _itemLabels =>
      ((_room['item_labels'] as Map?)?.cast<String, String>()) ?? {};
  String _itemLabel(String id) => _itemLabels[id] ?? id;

  List<Map<String, dynamic>> get _objects {
    final src = _subStack.isNotEmpty
        ? _subStack.last
        : ((_room['views'] as Map)[_dirs[_dirIdx]] as Map);
    return ((src['objects'] as List?) ?? [])
        .map((e) => (e as Map).cast<String, dynamic>())
        // hard_only=ハードのみ表示（ミスリード等）／normal_only=ノーマルのみ表示
        .where((o) => _hard ? o['normal_only'] != true : o['hard_only'] != true)
        .toList();
  }

  String get _placeLabel {
    if (_subStack.isNotEmpty) return _subStack.last['label'] as String? ?? '拡大';
    final v = (_room['views'] as Map)[_dirs[_dirIdx]] as Map;
    return v['label'] as String? ?? _dirs[_dirIdx];
  }

  bool _stateOk(List? prs) {
    if (prs == null) return true;
    for (final p in prs) {
      final m = (p as Map);
      if (_states[m['interactable']] != m['state']) return false;
    }
    return true;
  }

  void _rotate(int d) => setState(() {
        _dirIdx = (_dirIdx + d) % 4;
        if (_dirIdx < 0) _dirIdx += 4;
      });

  void _tap(Map<String, dynamic> o) {
    final id = o['id'] as String;
    if (o['toggle'] == true) {
      final st = (o['states'] as List).cast<String>();
      final cur = _states[id] ?? st.first;
      final next = st[(st.indexOf(cur) + 1) % st.length];
      setState(() {
        _states[id] = next;
        _msg = '${o['label']} → $next';
      });
      return;
    }
    if (!_stateOk(o['requires_state'] as List?)) {
      setState(() => _msg = '今は反応しないようだ…');
      return;
    }
    if (o['editable_memory'] != null) {
      final em = (o['editable_memory'] as Map).cast<String, dynamic>();
      final st = _states[id];
      if (st == 'faced') {
        final t = (em['truth'] as Map?)?.cast<String, dynamic>();
        _zoom(o['label'] as String? ?? '',
            (t?['reveal'] as String?) ?? '私は、もう直視した。');
      } else if (st == 'overwritten') {
        final w = (em['overwrite'] as Map?)?.cast<String, dynamic>();
        _zoom(o['label'] as String? ?? '',
            (w?['reveal'] as String?) ?? '私は、記憶を書き換えた。');
      } else {
        _showEditableMemory(o, em);
      }
      return;
    }
    if (o['win'] == true) {
      final need = o['requires_item'] as String?;
      if (need != null && !_selected.contains(need)) {
        setState(() => _msg = '${_itemLabel(need)} を選んでから使おう。');
        return;
      }
      _win();
      return;
    }
    if (o['subview'] != null) {
      setState(() {
        _subStack.add((o['subview'] as Map).cast<String, dynamic>());
        _msg = '${o['label']} を調べた。';
      });
      return;
    }
    if (o['lock'] != null) {
      final lock = (o['lock'] as Map).cast<String, dynamic>();
      final solved = _states[id] == (lock['on_solve_state'] ?? 'open');
      if (solved) {
        _zoom(o['label'] as String, lock['reveal'] as String? ?? '開いている。');
      } else {
        _showLock(o, lock);
      }
      return;
    }
    final need = o['requires_item'] as String?;
    if (need != null) {
      final usedState = o['on_use_state'] as String?;
      if (usedState != null && _states[id] == usedState) {
        _zoom(o['label'] as String, o['on_use_reveal'] as String? ?? '（開いている）');
        return;
      }
      if (_selected.contains(need)) {
        setState(() {
          if (usedState != null) _states[id] = usedState;
          final g = o['on_use_gives'] as String?;
          if (g != null && !_items.contains(g)) _items.add(g);
          _selected.clear();
          _msg = o['on_use_reveal'] as String? ?? '${_itemLabel(need)} を使った。';
        });
      } else {
        setState(() => _msg = '${_itemLabel(need)} が必要だ（下で選んでからタップ）。');
      }
      return;
    }
    final g = o['gives'] as String?;
    if (g != null) {
      setState(() {
        if (!_items.contains(g)) {
          _items.add(g);
          _msg = '【${_itemLabel(g)}】を手に入れた。';
        } else {
          _msg = 'もう手に入れた。';
        }
        // 永続フラグ（例：隠しの筒→has_culprit_evidence）を立てる
        final sf = o['set_flag'] as String?;
        if (sf != null && widget.gameState != null) {
          widget.gameState!.flags[sf] = true;
        }
      });
      AudioService.instance.sfx('pickup');
      return;
    }
    _zoom(o['label'] as String? ?? '', _reveal(o));
  }

  void _zoom(String title, String body) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
            child: Text(body, style: const TextStyle(fontSize: 16, height: 1.5))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('閉じる'))
        ],
      ),
    );
  }

  void _showLock(Map<String, dynamic> o, Map<String, dynamic> lock) {
    final ctrl = TextEditingController();
    final isNum = (lock['type'] as String? ?? 'number') == 'number';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${o['label']}：暗証'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: isNum ? TextInputType.number : TextInputType.text,
          decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '入力'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('やめる')),
          FilledButton(
            onPressed: () {
              final ok = _norm(ctrl.text) == _norm(lock['answer'] as String);
              Navigator.pop(ctx);
              if (!mounted) return;
              if (!ok) {
                AudioService.instance.sfx('wrong');
                setState(() => _msg = '違うようだ…');
                return;
              }
              AudioService.instance.sfx('lock_open');
              if (lock['win'] == true) {
                _win();
                return;
              }
              setState(() {
                _states[o['id'] as String] =
                    lock['on_solve_state'] as String? ?? 'open';
                final g = lock['on_solve_gives'] as String?;
                if (g != null && !_items.contains(g)) _items.add(g);
                _msg = lock['reveal'] as String? ?? '開いた。';
              });
              _zoom(o['label'] as String, lock['reveal'] as String? ?? '開いた。');
            },
            child: const Text('決定'),
          ),
        ],
      ),
    );
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        if (_selected.length >= 2) _selected.removeAt(0);
        _selected.add(id);
      }
    });
  }

  void _combine() {
    if (_selected.length != 2) {
      setState(() => _msg = '合成するアイテムを2つ選ぼう。');
      return;
    }
    for (final r0 in (_room['combines'] as List?) ?? []) {
      final r = (r0 as Map).cast<String, dynamic>();
      final pair = {r['a'], r['b']};
      if (pair.length == 2 &&
          _selected.toSet().containsAll(pair) &&
          pair.containsAll(_selected)) {
        setState(() {
          _items.remove(r['a']);
          _items.remove(r['b']);
          final res = r['result'] as String;
          if (!_items.contains(res)) _items.add(res);
          _selected.clear();
          _msg = r['msg'] as String? ?? '合成した。';
        });
        return;
      }
    }
    setState(() => _msg = 'この2つは組み合わせられないようだ。');
  }

  // ---- ① 記憶の上書き（直視 vs 書き換え）----
  void _showEditableMemory(Map<String, dynamic> o, Map<String, dynamic> em) {
    final truth = (em['truth'] as Map?)?.cast<String, dynamic>() ?? const {};
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(o['label'] as String? ?? '記憶'),
        content: SingleChildScrollView(
            child: Text((truth['reveal'] as String?) ??
                (em['prompt'] as String?) ??
                '')),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (!mounted) return;
              _faceMemory(o, em);
            },
            child: const Text('直視する'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: const Color(0xFF7A1620)),
            onPressed: () {
              Navigator.pop(ctx);
              if (!mounted) return;
              _overwriteMemory(o, em);
            },
            child: const Text('記憶を書き換える'),
          ),
        ],
      ),
    );
  }

  void _faceMemory(Map<String, dynamic> o, Map<String, dynamic> em) {
    AudioService.instance.sfx('face');
    final factId = em['fact_id'] as String? ?? '';
    final truth = (em['truth'] as Map?)?.cast<String, dynamic>() ?? const {};
    setState(() {
      final gs = widget.gameState;
      if (gs != null && factId.isNotEmpty) gs.flags['kept_$factId'] = true;
      _states[o['id'] as String] = 'faced';
      _msg = (truth['after'] as String?) ?? '私は、直視した。';
    });
  }

  void _overwriteMemory(Map<String, dynamic> o, Map<String, dynamic> em) {
    if (_done) return;
    AudioService.instance.sfx('overwrite');
    final factId = em['fact_id'] as String? ?? '';
    final ow = (em['overwrite'] as Map?)?.cast<String, dynamic>() ?? const {};
    final gs = widget.gameState;
    if (gs != null) {
      if (factId.isNotEmpty) gs.flags['ow_$factId'] = true; // 真実の記憶を喪失
      gs.meters['overwrite'] = (gs.meters['overwrite'] ?? 0) + 1; // 作話完全度↑
    }
    if (ow['opens'] == true) {
      _done = true;
      _clear({'text': ow['reveal'] as String?}); // 書き換えで楽に突破
    } else {
      setState(() {
        _states[o['id'] as String] = 'overwritten'; // 再選択不可（嘘は確定）
        _msg = (ow['reveal'] as String?) ?? '記憶を書き換えた。';
      });
    }
  }

  // ---- ヒント／スキップ（詰み防止）----
  void _showHint() {
    final hints = _hints;
    final max = _maxHint;
    if (hints.isEmpty || max <= 0) {
      setState(() => _msg = 'この部屋にヒントは無い……自力で解け。');
      return;
    }
    if (_hintLevel >= max) {
      _zoom('ヒント $max / $max', hints[max - 1]);
      return;
    }
    final next = _hintLevel + 1;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('ヒント $next / $max'),
        content: const Text('広告を見て、次のヒントを表示しますか？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('やめる')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (!mounted) return;
              // 広告はスタブ（no-op）。視聴完了とみなしてヒントを解放。
              setState(() => _hintLevel = next);
              _zoom('ヒント $next / ${hints.length}', hints[next - 1]);
            },
            child: const Text('見る'),
          ),
        ],
      ),
    );
  }

  void _skip() {
    if (_done) return;
    _done = true;
    if (widget.onCleared != null) {
      widget.onCleared!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  // ---- クリア／時間切れ／分岐 ----
  void _win() {
    if (_done) return;
    _done = true;
    final branch = _room['branch'] as Map?;
    if (branch != null) {
      _showBranch(branch.cast<String, dynamic>());
    } else {
      _clear(null);
    }
  }

  void _showBranch(Map<String, dynamic> b) {
    final opts = (b['options'] as List)
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('扉の前で'),
        content: Text(b['prompt'] as String? ?? 'どうする？'),
        actions: [
          for (final o in opts)
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (!mounted) return;
                _clear(o);
              },
              child: Text(o['label'] as String),
            ),
        ],
      ),
    );
  }

  void _clear(Map<String, dynamic>? choice) {
    AudioService.instance.sfx('glyph_light');
    final gs = widget.gameState;
    if (gs != null) {
      final mid = _room['memory_id'] as String?;
      if (mid != null) gs.memories[mid] = 'full';
      (_room['grants_flags'] as Map?)
          ?.forEach((k, v) => gs.flags[k.toString()] = v as bool);
      if (choice != null) {
        final meter = (_room['branch']?['meter'] as String?) ?? 'confront';
        gs.meters[meter] =
            (gs.meters[meter] ?? 0) + ((choice['delta'] as num?)?.toInt() ?? 0);
        final fl = choice['flag'] as String?;
        if (fl != null) gs.flags[fl] = true;
      }
    }
    final txt = choice?['text'] as String? ??
        _room['clear_text'] as String? ??
        '——四方の謎を解き、扉を開けた。';
    final verlust = _room['verlust'] == true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(verlust ? 'GEDÄCHTNIS → VERLUST' : '脱出',
            style: TextStyle(
                color: verlust ? Colors.redAccent : null,
                fontWeight: verlust ? FontWeight.bold : null)),
        content: SingleChildScrollView(child: Text(txt)),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (!mounted) return;
              if (widget.onCleared != null) {
                widget.onCleared!();
              } else {
                Navigator.of(context).maybePop();
              }
            },
            child: const Text('次へ'),
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

  /// 全角→半角・トリム・小文字化で錠前判定を頑健に（全角数字「０４１５」対策）。
  String _norm(String s) {
    final b = StringBuffer();
    for (final r in s.runes) {
      if (r >= 0xFF01 && r <= 0xFF5E) {
        b.writeCharCode(r - 0xFEE0); // 全角英数記号 → 半角
      } else if (r == 0x3000) {
        b.write(' '); // 全角空白 → 半角
      } else {
        b.writeCharCode(r);
      }
    }
    return b.toString().trim().toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final inSub = _subStack.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text('${_room['name']}  ［$_placeLabel］'),
        actions: [
          if (widget.timed && widget.remaining != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ValueListenableBuilder<int>(
                  valueListenable: widget.remaining!,
                  builder: (_, v, __) {
                    final r = v < 0 ? 0 : v;
                    return Text(_fmt(r),
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: r <= 30 ? Colors.redAccent : Colors.white));
                  },
                ),
              ),
            ),
          if (inSub)
            TextButton(
              onPressed: () => setState(() => _subStack.removeLast()),
              child: const Text('戻る', style: TextStyle(color: Colors.white)),
            )
          else ...[
            IconButton(
                onPressed: () => _rotate(-1),
                icon: const Icon(Icons.chevron_left)),
            IconButton(
                onPressed: () => _rotate(1),
                icon: const Icon(Icons.chevron_right)),
          ],
        ],
      ),
      body: Column(
        children: [
          _letterHud(),
          Expanded(
            child: Container(
              color: const Color(0xFF15131C),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(8),
              child: DesignCanvas(children: _hotspots()),
            ),
          ),
          _statusBar(),
        ],
      ),
    );
  }

  Widget _letterHud() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0E0C14),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        height: 22,
        // 点灯したトラウマ文字だけを点灯順（不規則）に表示。未点灯は出さず単語を伏せる。
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final g in widget.litGlyphs)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Text(
                  g,
                  style: const TextStyle(
                    fontFamily: 'Blackletter', // 黒文字体（未配置時は標準にフォールバック）
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: Colors.amberAccent,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _hotspots() {
    return [
      for (final o in _objects)
        Positioned(
          left: (o['rect'][0] as num).toDouble(),
          top: (o['rect'][1] as num).toDouble(),
          width: (o['rect'][2] as num).toDouble(),
          height: (o['rect'][3] as num).toDouble(),
          child: GestureDetector(
            onTap: () => _tap(o),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0x59673AB7),
                border: Border.all(color: Colors.white70, width: 2),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                o['toggle'] == true
                    ? '${o['label']}\n[${_states[o['id']] ?? (o['states'] as List).first}]'
                    : '${o['label']}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Colors.white),
              ),
            ),
          ),
        ),
    ];
  }

  Widget _statusBar() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1E1B26),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_msg, style: const TextStyle(color: Colors.amberAccent)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (_items.isEmpty)
                      const Text('（所持品なし）',
                          style: TextStyle(color: Colors.white38, fontSize: 12)),
                    for (final id in _items)
                      GestureDetector(
                        onTap: () => _toggleSelect(id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _selected.contains(id)
                                ? const Color(0xFFB8860B)
                                : const Color(0xFF2A2438),
                            border: Border.all(
                                color: _selected.contains(id)
                                    ? Colors.amber
                                    : Colors.white24),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(_itemLabel(id),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: _selected.contains(id)
                                      ? Colors.black
                                      : Colors.white)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(onPressed: _combine, child: const Text('合成')),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text('アイテムをタップで選択 → 対象に使う／2つ選んで「合成」',
                style: TextStyle(color: Colors.white38, fontSize: 10)),
          ),
          Row(
            children: [
              TextButton.icon(
                onPressed: _showHint,
                icon: const Icon(Icons.lightbulb_outline,
                    size: 16, color: Colors.amberAccent),
                label: Text(
                  _hints.isEmpty || _maxHint <= 0
                      ? 'ヒント'
                      : 'ヒント（$_hintLevel/$_maxHint・広告）',
                  style: const TextStyle(color: Colors.amberAccent, fontSize: 12),
                ),
              ),
              const Spacer(),
              if (_hints.isNotEmpty && _hintLevel >= _maxHint)
                TextButton(
                  onPressed: _skip,
                  child: const Text('……諦めて先へ進む',
                      style: TextStyle(color: Colors.white38, fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
