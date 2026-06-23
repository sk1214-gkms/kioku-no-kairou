import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../widgets/design_canvas.dart';

/// 「深い部屋」試作：東西南北の4視点 × ネスト調査（サブ画面）× アイテム合成 × 多段ロック。
/// 既存の30部屋とは独立。タイトルから単体で起動して手触りを確認する。
class DeepRoomScreen extends StatefulWidget {
  final String path;
  const DeepRoomScreen({super.key, this.path = 'data/deep_rooms/study.json'});

  @override
  State<DeepRoomScreen> createState() => _DeepRoomScreenState();
}

class _DeepRoomScreenState extends State<DeepRoomScreen> {
  Map<String, dynamic>? _room;
  static const _dirs = ['north', 'east', 'south', 'west'];
  int _dirIdx = 0;
  final List<Map<String, dynamic>> _subStack = []; // ネスト中のサブ画面
  final Map<String, String> _states = {}; // 全画面共通の状態（lamp=on, safe=open 等）
  final List<String> _items = [];
  final List<String> _selected = []; // 選択中アイテム（最大2／使用・合成用）
  String _msg = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString(widget.path);
    final m = jsonDecode(raw) as Map<String, dynamic>;
    setState(() {
      _room = m;
      _msg = m['intro'] as String? ?? '';
    });
  }

  Map<String, String> get _itemLabels =>
      ((_room!['item_labels'] as Map?)?.cast<String, String>()) ?? {};
  String _itemLabel(String id) => _itemLabels[id] ?? id;

  List<Map<String, dynamic>> get _objects {
    final src = _subStack.isNotEmpty
        ? _subStack.last
        : ((_room!['views'] as Map)[_dirs[_dirIdx]] as Map);
    return ((src['objects'] as List?) ?? [])
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
  }

  String get _placeLabel {
    if (_subStack.isNotEmpty) return _subStack.last['label'] as String? ?? '拡大';
    final v = (_room!['views'] as Map)[_dirs[_dirIdx]] as Map;
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

  void _rotate(int d) {
    setState(() {
      _dirIdx = (_dirIdx + d) % 4;
      if (_dirIdx < 0) _dirIdx += 4;
    });
  }

  void _tap(Map<String, dynamic> o) {
    final id = o['id'] as String;
    // 1) トグル（常に操作可）
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
    // 2) 前提状態のゲート
    if (!_stateOk(o['requires_state'] as List?)) {
      setState(() => _msg = '今は反応しないようだ…（何かが足りない）');
      return;
    }
    // 3) 脱出（win）：必要アイテムを選んで使う
    if (o['win'] == true) {
      final need = o['requires_item'] as String?;
      if (need != null && !_selected.contains(need)) {
        setState(() => _msg = '${_itemLabel(need)} を選んでから使おう。');
        return;
      }
      _win();
      return;
    }
    // 4) ネスト（サブ画面へ）
    if (o['subview'] != null) {
      setState(() {
        _subStack.add((o['subview'] as Map).cast<String, dynamic>());
        _msg = '${o['label']} を調べた。';
      });
      return;
    }
    // 5) ロック（暗証）
    if (o['lock'] != null) {
      final solved = _states[id] == (o['lock']['on_solve_state'] ?? 'open');
      if (solved) {
        _zoom(o['label'] as String, o['lock']['reveal'] as String? ?? '開いている。');
      } else {
        _showLock(o);
      }
      return;
    }
    // 6) アイテムを使う
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
        setState(() => _msg = '${_itemLabel(need)} が必要だ（下のアイテムを選んでからタップ）。');
      }
      return;
    }
    // 7) アイテム入手
    final g = o['gives'] as String?;
    if (g != null) {
      setState(() {
        if (!_items.contains(g)) {
          _items.add(g);
          _msg = '【${_itemLabel(g)}】を手に入れた。';
        } else {
          _msg = 'もう手に入れた。';
        }
      });
      return;
    }
    // 8) 調査
    _zoom(o['label'] as String? ?? '', o['reveal'] as String? ?? '特に何もないようだ。');
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

  void _showLock(Map<String, dynamic> o) {
    final lock = (o['lock'] as Map).cast<String, dynamic>();
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
              final ok = ctrl.text.trim().toLowerCase() ==
                  (lock['answer'] as String).toLowerCase();
              Navigator.pop(ctx);
              if (ok) {
                setState(() {
                  _states[o['id'] as String] =
                      lock['on_solve_state'] as String? ?? 'open';
                  final g = lock['on_solve_gives'] as String?;
                  if (g != null && !_items.contains(g)) _items.add(g);
                  _msg = lock['reveal'] as String? ?? '開いた。';
                });
                _zoom(o['label'] as String, lock['reveal'] as String? ?? '開いた。');
              } else {
                setState(() => _msg = '違うようだ…');
              }
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
    final recipes = (_room!['combines'] as List?) ?? [];
    for (final r0 in recipes) {
      final r = (r0 as Map).cast<String, dynamic>();
      final pair = {r['a'], r['b']};
      if (pair.containsAll(_selected) && _selected.toSet().containsAll(pair)) {
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

  void _win() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('― 脱出成功 ―'),
        content: const Text(
            '四方の謎を解き、道具を組み合わせ、扉を開けた。\n（これは「深い部屋」試作のクリアです）'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).maybePop();
            },
            child: const Text('タイトルへ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_room == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final inSub = _subStack.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text('${_room!['name']}  ［$_placeLabel］'),
        actions: [
          if (inSub)
            TextButton(
              onPressed: () => setState(() => _subStack.removeLast()),
              child: const Text('戻る', style: TextStyle(color: Colors.white)),
            )
          else ...[
            IconButton(
                onPressed: () => _rotate(-1),
                icon: const Icon(Icons.chevron_left),
                tooltip: '左を向く'),
            IconButton(
                onPressed: () => _rotate(1),
                icon: const Icon(Icons.chevron_right),
                tooltip: '右を向く'),
          ],
        ],
      ),
      body: Column(
        children: [
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
              FilledButton.tonal(
                onPressed: _combine,
                child: const Text('合成'),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text('アイテムをタップで選択 → 対象に使う／2つ選んで「合成」',
                style: TextStyle(color: Colors.white38, fontSize: 10)),
          ),
        ],
      ),
    );
  }
}
