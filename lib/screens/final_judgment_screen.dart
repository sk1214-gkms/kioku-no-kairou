import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import '../models.dart';

/// 30号室・証拠連結盤（② Phase 2）。
/// 各推理（真犯人/凶器/あの夜）に、手元の「記憶の断片（証拠）」を連結して“固定”する。
/// - 真実の証拠(ev_self_culprit 等)は各部屋で「直視」した時のみ手に入る＝書き換えた人は固定不可。
/// - シリンジ＝R9の金属製の筒(ev_tube)が要る。嘘/decoyは根拠なしでも固定可（嘘はいつでもつける）。
/// 確定内容から meters['confab']／flags(all_truth/syringe_chosen) を書き込み onComplete。
class FinalJudgmentScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final GameState gameState;
  final VoidCallback onComplete;
  final ValueListenable<int>? remaining;

  const FinalJudgmentScreen({
    super.key,
    required this.data,
    required this.gameState,
    required this.onComplete,
    this.remaining,
  });

  @override
  State<FinalJudgmentScreen> createState() => _FinalJudgmentScreenState();
}

class _FinalJudgmentScreenState extends State<FinalJudgmentScreen> {
  final Map<String, Map<String, dynamic>> _confirmed = {}; // qid -> 固定した推理
  String? _active; // 編集中の claim
  int? _selOpt; // 選択中の選択肢index
  final Set<String> _linked = {}; // 現在の選択に連結した証拠id

  List<Map<String, dynamic>> get _questions =>
      ((widget.data['questions'] as List?) ?? [])
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();

  List<Map<String, dynamic>> get _pool =>
      ((widget.data['evidence_pool'] as List?) ?? [])
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();

  List<Map<String, dynamic>> get _held => _pool.where((ev) {
        final w = ev['when'] as String? ?? 'always';
        return w == 'always' || widget.gameState.flags[w] == true;
      }).toList();

  bool _hasEv(String id) => _held.any((e) => e['id'] == id);
  String _evLabel(String id) {
    for (final e in _pool) {
      if (e['id'] == id) return e['label'] as String? ?? id;
    }
    return id;
  }

  /// その推理について、プレイヤーが“真実の証拠”を握っているか
  /// （＝真実選択肢の必要証拠を全て所持）。嘘で固定すれば「自覚ある嘘」。
  bool _knowsTruth(String qid) {
    for (final q in _questions) {
      if (q['id'] != qid) continue;
      for (final o in (q['options'] as List)) {
        final om = (o as Map).cast<String, dynamic>();
        if (om['tag'] == 'truth') {
          final needs = (om['needs'] as List?)?.cast<String>() ?? const [];
          return needs.isNotEmpty && needs.every(_hasEv);
        }
      }
    }
    return false;
  }

  void _selectOption(int i) => setState(() {
        _selOpt = i;
        _linked.clear();
      });

  void _toggleLink(String id) => setState(() {
        if (_linked.contains(id)) {
          _linked.remove(id);
        } else {
          _linked.add(id);
        }
      });

  void _confirmClaim(String qid, Map<String, dynamic> opt) => setState(() {
        _confirmed[qid] = opt;
        _active = null;
        _selOpt = null;
        _linked.clear();
      });

  void _tapClaim(String qid) => setState(() {
        if (_confirmed.containsKey(qid)) {
          _confirmed.remove(qid); // 再編集
          _active = qid;
        } else {
          _active = (_active == qid) ? null : qid;
        }
        _selOpt = null;
        _linked.clear();
      });

  void _finish() {
    final gs = widget.gameState;
    final total = _questions.length;
    int lie = 0, truth = 0;
    bool syringe = false;
    for (final q in _questions) {
      final tag = _confirmed[q['id']]?['tag'];
      if (tag == 'lie') {
        lie++;
      } else if (tag == 'truth') {
        truth++;
      } else if (tag == 'syringe') {
        syringe = true;
      }
    }
    gs.meters['confab'] = lie;
    gs.meters['deduction'] = lie;
    gs.flags['all_truth'] = truth == total && total > 0;
    gs.flags['syringe_chosen'] = syringe;
    gs.flags['deduction_correct'] = lie == total && total > 0;
    gs.flags['deduction_answered'] = true;
    widget.onComplete();
  }

  String _fmt(int s) {
    final v = s < 0 ? 0 : s;
    return '${v ~/ 60}:${(v % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final qs = _questions;
    final allDone = qs.every((q) => _confirmed.containsKey(q['id']));
    return Scaffold(
      backgroundColor: const Color(0xFF0E0C14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF15131C),
        title: Text(widget.data['name'] as String? ?? '最後の審判'),
        actions: [
          if (widget.remaining != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ValueListenableBuilder<int>(
                  valueListenable: widget.remaining!,
                  builder: (_, v, __) => Text(_fmt(v),
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: v <= 30 ? Colors.redAccent : Colors.white70)),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.data['prompt'] as String? ?? '',
                style: const TextStyle(fontSize: 16, height: 1.6)),
            const SizedBox(height: 12),
            Text(widget.data['intro'] as String? ?? '',
                style: const TextStyle(color: Colors.white38, fontSize: 12)),
            const Divider(height: 28, color: Colors.white12),
            for (final q in qs) _claimCard(q),
            const SizedBox(height: 14),
            _inventory(),
            const SizedBox(height: 22),
            if (allDone) ...[
              const Text('── この推理を、現実へ出力する',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 6),
              const Text('一度確定すれば、この「記憶」が現実として出力される。もう、戻れない。',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _finish,
                style:
                    FilledButton.styleFrom(backgroundColor: const Color(0xFF7A1620)),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('この記憶を、確定する', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _claimCard(Map<String, dynamic> q) {
    final qid = q['id'] as String;
    final confirmed = _confirmed[qid];
    final isActive = _active == qid;
    // 真実を握りながら嘘/逃げで固定＝自覚ある嘘
    final knowingLie = confirmed != null &&
        confirmed['tag'] != 'truth' &&
        _knowsTruth(qid);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF15131C),
        border: Border.all(
            color: confirmed != null
                ? (knowingLie ? Colors.redAccent : Colors.green)
                : Colors.white24),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(q['label'] as String? ?? '',
                style: const TextStyle(
                    color: Colors.amberAccent, fontWeight: FontWeight.bold)),
            subtitle: Text(
                confirmed != null
                    ? '確定：${confirmed['summary']}${knowingLie ? '　— 自覚ある嘘' : ''}'
                    : (isActive ? '推理中…' : '未確定 — タップして推理'),
                style: TextStyle(
                    color: confirmed != null
                        ? (knowingLie ? Colors.redAccent : Colors.greenAccent)
                        : Colors.white54)),
            trailing: Icon(
                confirmed != null
                    ? Icons.check_circle
                    : (isActive ? Icons.expand_less : Icons.expand_more),
                color: confirmed != null ? Colors.greenAccent : Colors.white38),
            onTap: () => _tapClaim(qid),
          ),
          if (isActive && confirmed == null) _editor(q),
        ],
      ),
    );
  }

  Widget _editor(Map<String, dynamic> q) {
    final qid = q['id'] as String;
    final opts = (q['options'] as List)
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q['q'] as String? ?? '',
              style: const TextStyle(fontSize: 15, height: 1.4)),
          const SizedBox(height: 8),
          for (var i = 0; i < opts.length; i++) _optionRow(qid, opts, i),
        ],
      ),
    );
  }

  Widget _optionRow(String qid, List<Map<String, dynamic>> opts, int i) {
    final o = opts[i];
    final erased =
        o['tag'] == 'truth' && widget.gameState.flags['ow_$qid'] == true;
    final selected = _selOpt == i;
    final needs = (o['needs'] as List?)?.cast<String>() ?? const [];
    final missing = needs.where((id) => !_hasEv(id)).toList();
    final canFix = missing.isEmpty && needs.every((id) => _linked.contains(id));
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        border:
            Border.all(color: selected ? Colors.amberAccent : Colors.white12),
        borderRadius: BorderRadius.circular(6),
        color: selected ? const Color(0xFF1E1B26) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: erased ? null : () => _selectOption(i),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                  erased
                      ? '■■■■（書き換えた記憶——もう思い出せない）'
                      : o['text'] as String,
                  style: TextStyle(
                      fontSize: 14, color: erased ? Colors.white24 : null)),
            ),
          ),
          if (selected && !erased)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (o['tag'] != 'truth' && _knowsTruth(qid))
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('⚠ あなたは“真実”の証拠を握っている。これは、自覚ある嘘だ。',
                          style:
                              TextStyle(color: Colors.redAccent, fontSize: 12)),
                    ),
                  const Text('必要な証拠を連結：',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 6),
                  if (needs.isEmpty)
                    const Text('（根拠なし＝当て推量。そのまま固定できる）',
                        style: TextStyle(color: Colors.white38, fontSize: 12)),
                  if (needs.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [for (final id in needs) _needChip(id)],
                    ),
                  const SizedBox(height: 10),
                  FilledButton.tonal(
                    onPressed: canFix ? () => _confirmClaim(qid, o) : null,
                    child: Text(missing.isNotEmpty
                        ? '証拠が足りない（${missing.map(_evLabel).join("、")}）'
                        : 'この結論を盤に固定'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _needChip(String id) {
    final held = _hasEv(id);
    final linked = _linked.contains(id);
    return GestureDetector(
      onTap: held ? () => _toggleLink(id) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: linked
              ? const Color(0xFF2E5D34)
              : (held ? const Color(0xFF2A2438) : const Color(0xFF1A1620)),
          border: Border.all(
              color: linked
                  ? Colors.greenAccent
                  : (held ? Colors.white24 : Colors.white10)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
                linked
                    ? Icons.link
                    : (held ? Icons.circle_outlined : Icons.help_outline),
                size: 14,
                color: linked
                    ? Colors.greenAccent
                    : (held ? Colors.white54 : Colors.white24)),
            const SizedBox(width: 4),
            Text(held ? _evLabel(id) : '未発見の証拠',
                style: TextStyle(
                    fontSize: 12, color: held ? Colors.white : Colors.white24)),
          ],
        ),
      ),
    );
  }

  Widget _inventory() {
    final held = _held;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF15131C),
        border: Border.all(color: Colors.white12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('▼ 手元の証拠（記憶の断片）',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 6),
          if (held.isEmpty)
            const Text('（証拠なし）',
                style: TextStyle(color: Colors.white38, fontSize: 12))
          else
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final e in held)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2438),
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(e['label'] as String? ?? '',
                        style: const TextStyle(fontSize: 12, color: Colors.white)),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
