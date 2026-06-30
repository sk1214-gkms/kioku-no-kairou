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
  final void Function(int hintsUsed)? onCleared;
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

  // hard / hard_t は暗号・囮の難化層を使う
  bool get _hard => widget.mode.startsWith('hard');

  List<String> get _hints => ((_room['hints'] as List?) ?? []).cast<String>();
  // ストーリーのみ最終（答え直結）ヒントまで開放＝安全網。
  // ノーマル/ハード系は最終ヒントを伏せ、自力導出させる（詰み防止はスキップで担保）。
  int get _maxHint => widget.mode == 'story'
      ? _hints.length
      : (_hints.length - 1).clamp(0, _hints.length);

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

  /// 方向ごとの背景画像パス（規約: assets/images/rooms/<id>_<dir>.png）。
  /// subview(拡大)中は今は背景なし。未配置なら errorBuilder で暗色にフォールバック。
  String? get _bgAsset => _subStack.isNotEmpty
      ? null
      : 'assets/images/rooms/${_room['id']}_${_dirs[_dirIdx]}.png';

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
      setState(() => _msg = ''); // 前提未達は無反応（“何か先に要る”という糸口を出さない）
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
    if (o['dialogue'] != null) {
      _showDialogue(o, (o['dialogue'] as Map).cast<String, dynamic>());
      return;
    }
    if (o['chase'] != null) {
      if (_states[id] == 'cornered') {
        _zoom(o['label'] as String? ?? '',
            o['cornered_reveal'] as String? ?? 'すでに追い詰めた。');
      } else {
        _showChase(o, (o['chase'] as Map).cast<String, dynamic>());
      }
      return;
    }
    if (o['win'] == true) {
      final need = o['requires_item'] as String?;
      if (need != null && !_selected.contains(need)) {
        setState(() => _msg = '扉は、びくともしない。');
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
      } else if (lock['type'] == 'sequence') {
        _showSequence(o, lock);
      } else if (lock['type'] == 'dial') {
        _showDial(o, lock);
      } else if (lock['type'] == 'scrub') {
        _showScrub(o, lock);
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
        setState(() => _msg = '……今は、手の出しようがない。');
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

  /// 順序パズル：要素を正しい順にタップして確定。lock.elements[{id,label}], lock.answer=[id...]。
  void _showSequence(Map<String, dynamic> o, Map<String, dynamic> lock) {
    final elements = ((lock['elements'] as List?) ?? [])
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
    final answer = (lock['answer'] as List?)?.cast<String>() ?? const [];
    final chosen = <String>[];
    String labelOf(String id) => elements.firstWhere((e) => e['id'] == id,
        orElse: () => {'label': id})['label'] as String;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('${o['label']}：順序'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lock['prompt'] as String? ?? '正しい順にタップせよ。',
                    style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final el in elements)
                      OutlinedButton(
                        onPressed: chosen.contains(el['id'])
                            ? null
                            : () => setLocal(
                                () => chosen.add(el['id'] as String)),
                        child: Text(el['label'] as String),
                      ),
                  ],
                ),
                const Divider(height: 18),
                Text(
                    chosen.isEmpty
                        ? '選んだ順：—'
                        : '選んだ順：${chosen.map(labelOf).join(" → ")}',
                    style:
                        const TextStyle(color: Colors.amberAccent, fontSize: 12)),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => setLocal(chosen.clear),
                child: const Text('やり直す')),
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('やめる')),
            FilledButton(
              onPressed: chosen.length == answer.length
                  ? () {
                      var ok = true;
                      for (var i = 0; i < answer.length; i++) {
                        if (chosen[i] != answer[i]) ok = false;
                      }
                      Navigator.pop(ctx);
                      if (!mounted) return;
                      if (!ok) {
                        AudioService.instance.sfx('wrong');
                        setState(() => _msg = '順序が違うようだ…');
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
                        _msg = lock['reveal'] as String? ?? '開いた。';
                      });
                    }
                  : null,
              child: const Text('確定'),
            ),
          ],
        ),
      ),
    );
  }

  /// 時刻ダイヤル：針(HH:MM)を answer に合わせて解錠。lock.answer/"start"="HH:MM"。
  void _showDial(Map<String, dynamic> o, Map<String, dynamic> lock) {
    List<int> parse(String? s) {
      final p = (s ?? '0:00').split(':');
      return [int.tryParse(p[0]) ?? 0, int.tryParse(p.length > 1 ? p[1] : '0') ?? 0];
    }

    final tgt = parse(lock['answer'] as String?);
    final st = parse(lock['start'] as String?);
    var h = st[0], m = st[1];
    String two(int n) => n.toString().padLeft(2, '0');
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('${o['label']}：時刻'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(lock['prompt'] as String? ?? '針を合わせよ。',
                  style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 10),
              Text('${two(h)} : ${two(m)}',
                  style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.amberAccent,
                      letterSpacing: 2)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(children: [
                    const Text('時', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                          onPressed: () => setLocal(() => h = (h + 23) % 24),
                          icon: const Icon(Icons.remove)),
                      IconButton(
                          onPressed: () => setLocal(() => h = (h + 1) % 24),
                          icon: const Icon(Icons.add)),
                    ]),
                  ]),
                  Column(children: [
                    const Text('分', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                          onPressed: () => setLocal(() => m = (m + 55) % 60),
                          icon: const Icon(Icons.remove)),
                      IconButton(
                          onPressed: () => setLocal(() => m = (m + 5) % 60),
                          icon: const Icon(Icons.add)),
                    ]),
                  ]),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('やめる')),
            FilledButton(
              onPressed: () {
                final ok = h == tgt[0] && m == tgt[1];
                Navigator.pop(ctx);
                if (!mounted) return;
                if (!ok) {
                  AudioService.instance.sfx('wrong');
                  setState(() => _msg = '違うようだ…針が合っていない。');
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
                  _msg = lock['reveal'] as String? ?? '針が噛み合い、開いた。';
                });
              },
              child: const Text('合わせる'),
            ),
          ],
        ),
      ),
    );
  }

  // ---- 別動詞：記憶再生（映像スクラブ）----
  void _showScrub(Map<String, dynamic> o, Map<String, dynamic> lock) {
    int parse(String? s) {
      final p = (s ?? '0:00').split(':');
      return (int.tryParse(p[0]) ?? 0) * 60 +
          (int.tryParse(p.length > 1 ? p[1] : '0') ?? 0);
    }

    final start = parse(lock['start'] as String?);
    final end = parse(lock['end'] as String?);
    final tgt = parse(lock['answer'] as String?);
    final tol = (lock['tol'] as num?)?.toInt() ?? 1;
    final frames = ((lock['frames'] as List?) ?? [])
        .map((e) => (e as Map).cast<String, dynamic>())
        .map((f) => {
              'at': parse(f['at'] as String?),
              'cap': f['cap'] as String? ?? '',
              'key': f['key'] == true,
            })
        .toList();
    var cur = start;
    String two(int n) => n.toString().padLeft(2, '0');
    String hhmm(int t) => '${two(t ~/ 60)}:${two(t % 60)}';
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          var cap = '……砂嵐。判別できる像はない。';
          var isKey = false;
          if (frames.isNotEmpty) {
            var bi = 0, best = 1 << 30;
            for (var i = 0; i < frames.length; i++) {
              final d = (cur - (frames[i]['at'] as int)).abs();
              if (d < best) {
                best = d;
                bi = i;
              }
            }
            if (best <= 8) {
              cap = frames[bi]['cap'] as String;
              isKey = frames[bi]['key'] == true;
            }
          }
          final canSave = (cur - tgt).abs() <= tol;
          return AlertDialog(
            title: Text('${o['label']}：記録再生'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(lock['prompt'] as String? ?? '記録を再生し、決定的瞬間を探せ。',
                    style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                Text(hhmm(cur),
                    style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.amberAccent,
                        letterSpacing: 2)),
                Slider(
                  value: cur.toDouble(),
                  min: start.toDouble(),
                  max: end.toDouble(),
                  onChanged: (v) => setLocal(() => cur = v.round()),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: Colors.black26,
                  child: Text(
                    cap,
                    style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: isKey ? Colors.redAccent : Colors.white70),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('やめる')),
              FilledButton(
                onPressed: canSave
                    ? () {
                        Navigator.pop(ctx);
                        if (!mounted) return;
                        AudioService.instance.sfx('lock_open');
                        if (lock['win'] == true) {
                          _win();
                          return;
                        }
                        setState(() {
                          _states[o['id'] as String] =
                              lock['on_solve_state'] as String? ?? 'open';
                          _msg = lock['reveal'] as String? ?? '決定的瞬間を保存した。';
                        });
                      }
                    : null,
                child: const Text('この瞬間を保存'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---- 別動詞：追跡（気配を方向で追い詰める）----
  void _showChase(Map<String, dynamic> o, Map<String, dynamic> chase) {
    final rounds = ((chase['rounds'] as List?) ?? [])
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
    if (rounds.isEmpty) return;
    const dirLabel = {'north': '北', 'east': '東', 'south': '南', 'west': '西'};
    var idx = 0;
    var feedback =
        chase['prompt'] as String? ?? '気配を追え——逃げた方向を選べ。';
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final r = rounds[idx];
          return AlertDialog(
            title: Text('影を追う（${idx + 1}/${rounds.length}）'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r['tell'] as String? ?? '',
                      style: const TextStyle(fontSize: 15, height: 1.5)),
                  const SizedBox(height: 12),
                  Text(feedback,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final d in const ['north', 'east', 'south', 'west'])
                        OutlinedButton(
                          onPressed: () {
                            if (d == r['flee']) {
                              if (idx >= rounds.length - 1) {
                                Navigator.pop(ctx);
                                if (!mounted) return;
                                AudioService.instance.sfx('pickup');
                                setState(() {
                                  final g = chase['gives'] as String?;
                                  if (g != null && !_items.contains(g)) {
                                    _items.add(g);
                                  }
                                  final sf = chase['set_flag'] as String?;
                                  if (sf != null && widget.gameState != null) {
                                    widget.gameState!.flags[sf] = true;
                                  }
                                  _states[o['id'] as String] = 'cornered';
                                  _msg = chase['corner_text'] as String? ??
                                      '影を追い詰めた。';
                                });
                              } else {
                                AudioService.instance.sfx('glyph_light');
                                setLocal(() {
                                  idx++;
                                  feedback = '——追っている。さらに先へ。';
                                });
                              }
                            } else {
                              AudioService.instance.sfx('wrong');
                              setLocal(() {
                                idx = 0;
                                feedback = chase['lost_text'] as String? ??
                                    '——見失った。最初から追え。';
                              });
                            }
                          },
                          child: Text(dirLabel[d]!),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('やめる')),
            ],
          );
        },
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
      setState(() => _msg = ''); // 合成は成功時のみ反応（2つ未選択は無音）
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
    setState(() => _msg = ''); // 合成失敗は無反応（“その2つは組み合わない”という糸口を出さない）
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

  // ---- 別動詞：対峙（突きつけ尋問）----
  // 突きつけられる“記憶”のラベル（所持＝gs.flags がtrue）。
  static const Map<String, String> _memoryLabels = {
    'kept_culprit': '残るのは私、という結論',
    'kept_weapon': 'ペーパーナイフの感触',
    'kept_truth': 'この手が動いた記憶',
    'has_culprit_evidence': '金属製の筒',
  };

  void _showDialogue(Map<String, dynamic> o, Map<String, dynamic> dlg) {
    final lines = ((dlg['lines'] as List?) ?? [])
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
    if (lines.isEmpty) return;
    // terminal=false の対峙は脱出させず、論拠を突きつける“推理ビート”として使う（R6等）。
    final terminal = dlg['terminal'] != false;
    var idx = 0;
    var rebutted = false;
    var feedback = '——突きつける論拠を選べ。';
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final line = lines[idx];
          // 突きつける手札：dlg['cards']があれば部屋ローカルの論拠、無ければ所持記憶。
          final cards = dlg['cards'] != null
              ? ((dlg['cards'] as List)
                  .map((e) => (e as Map).cast<String, dynamic>())
                  .toList())
              : _memoryLabels.keys
                  .where((f) => widget.gameState?.flags[f] == true)
                  .map((f) => <String, dynamic>{'id': f, 'label': _memoryLabels[f]})
                  .toList();
          final last = idx >= lines.length - 1;
          return AlertDialog(
            title: Text(dlg['speaker'] as String? ?? '対峙'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('「${line['say']}」',
                      style: const TextStyle(fontSize: 15, height: 1.5)),
                  const SizedBox(height: 10),
                  Text(feedback,
                      style: TextStyle(
                          color: rebutted
                              ? Colors.greenAccent
                              : Colors.white54,
                          fontSize: 13)),
                  const Divider(height: 18),
                  if (!rebutted)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (cards.isEmpty)
                          const Text('突きつけられる論拠が無い……',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 12)),
                        for (final c in cards)
                          OutlinedButton(
                            onPressed: () {
                              if (c['id'] == line['press']) {
                                setLocal(() {
                                  rebutted = true;
                                  feedback = line['rebut'] as String? ?? '';
                                });
                              } else {
                                setLocal(() => feedback =
                                    line['fail'] as String? ?? '…それは違う。');
                              }
                            },
                            child: Text(c['label'] as String? ?? '?'),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (!mounted) return;
                  final out =
                      (dlg['on_yield'] as Map?)?.cast<String, dynamic>();
                  terminal ? _dialogueOutcome(out) : _dialogueResult(out);
                },
                child: const Text('目を背ける'),
              ),
              if (rebutted)
                FilledButton(
                  onPressed: () {
                    if (!last) {
                      setLocal(() {
                        idx++;
                        rebutted = false;
                        feedback = '——突きつける論拠を選べ。';
                      });
                    } else {
                      Navigator.pop(ctx);
                      if (!mounted) return;
                      final out =
                          (dlg['on_break'] as Map?)?.cast<String, dynamic>();
                      terminal ? _dialogueOutcome(out) : _dialogueResult(out);
                    }
                  },
                  child: Text(last ? '突きつけ終える' : '次へ'),
                ),
            ],
          );
        },
      ),
    );
  }

  void _dialogueOutcome(Map<String, dynamic>? outcome) {
    if (outcome == null || _done) return;
    _done = true;
    final gs = widget.gameState;
    if (gs != null) {
      final fl = outcome['flag'] as String?;
      if (fl != null) gs.flags[fl] = true;
      final d = (outcome['delta'] as num?)?.toInt() ?? 0;
      gs.meters['confront'] = (gs.meters['confront'] ?? 0) + d;
    }
    _clear({'text': outcome['text'] as String?});
  }

  /// 非終端の対峙（推理ビート）。脱出させず、フラグ/メーターを反映し結果文を表示。
  void _dialogueResult(Map<String, dynamic>? outcome) {
    if (outcome == null) return;
    final gs = widget.gameState;
    if (gs != null) {
      final fl = outcome['flag'] as String?;
      if (fl != null) gs.flags[fl] = true;
      final d = (outcome['delta'] as num?)?.toInt() ?? 0;
      if (d != 0) gs.meters['confront'] = (gs.meters['confront'] ?? 0) + d;
    }
    setState(() => _msg = outcome['text'] as String? ?? '');
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
      widget.onCleared!(_hintLevel);
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

  Future<void> _clear(Map<String, dynamic>? choice) async {
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
    // この部屋でトラウマ文字が点灯するなら、脳内で発火する全画面フラッシュを先に。
    final letter = _room['letter'] as String?;
    if (letter != null && letter.trim().isNotEmpty) {
      AudioService.instance.sfx('glyph_light');
      await _glyphIgnite(letter.trim());
      if (!mounted) return;
    }
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
                widget.onCleared!(_hintLevel);
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

  /// トラウマ文字が脳の最深部で発火する一瞬の演出（赤→琥珀、拡大しながら明滅）。
  Future<void> _glyphIgnite(String letter) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      builder: (ctx) {
        Future<void>.delayed(const Duration(milliseconds: 1150), () {
          if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
        });
        return Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, t, __) => Opacity(
              opacity: t < 0.8 ? t / 0.8 : 1.0,
              child: Transform.scale(
                scale: 0.55 + t * 0.75,
                child: Text(
                  letter,
                  style: TextStyle(
                    fontFamily: 'Blackletter',
                    fontSize: 130,
                    fontWeight: FontWeight.bold,
                    color: Color.lerp(Colors.redAccent, Colors.amberAccent, t),
                    shadows: [
                      Shadow(
                          color: Colors.redAccent.withValues(alpha: 0.7 * t),
                          blurRadius: 48),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 背景画像（未配置なら暗色にフォールバック）
                if (_bgAsset != null)
                  Image.asset(_bgAsset!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: const Color(0xFF15131C)))
                else
                  Container(color: const Color(0xFF15131C)),
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(8),
                  child: DesignCanvas(children: _hotspots()),
                ),
              ],
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
                  style: TextStyle(
                    fontFamily: 'Blackletter', // 黒文字体（未配置時は標準にフォールバック）
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: Colors.amberAccent,
                    shadows: [
                      Shadow(
                          color: Colors.amberAccent.withValues(alpha: 0.6),
                          blurRadius: 8),
                    ],
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset('assets/images/items/$id.png',
                                  width: 18,
                                  height: 18,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox.shrink()),
                              const SizedBox(width: 4),
                              Text(_itemLabel(id),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: _selected.contains(id)
                                          ? Colors.black
                                          : Colors.white)),
                            ],
                          ),
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
