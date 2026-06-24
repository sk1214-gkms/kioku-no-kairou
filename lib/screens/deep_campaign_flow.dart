import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../content_repository.dart';
import '../endings_eval.dart';
import '../models.dart';
import 'deep_room_screen.dart';
import 'final_judgment_screen.dart';
import 'verdict_screen.dart';
import 'verlust_reveal_screen.dart';

enum _Phase { loading, room, reveal, judgment, ending }

/// 深い部屋キャンペーン：13部屋 → 30号室（最後の審判）→ 8結末。
/// 全モード共通で『脳細胞の壊死』カウントダウンを保持し、0で Ending D（精神の死）。
/// 結末は evaluateConfabEnding（離散ツリー）で決定し、作話完全度 I を VerdictScreen に表示。
class DeepCampaignFlow extends StatefulWidget {
  final String mode;
  const DeepCampaignFlow({super.key, this.mode = 'normal'});

  @override
  State<DeepCampaignFlow> createState() => _DeepCampaignFlowState();
}

class _DeepCampaignFlowState extends State<DeepCampaignFlow> {
  static const _manifest = 'data/deep_rooms/campaign.json';
  static const _judgmentPath = 'data/deep_rooms/judgment.json';

  ContentRepository? _repo;
  List<Map<String, dynamic>> _rooms = [];
  Map<String, dynamic> _judgment = {};
  late GameState _gs;
  _Phase _phase = _Phase.loading;
  int _idx = 0;
  EndingResult? _ending;

  // 脳死カウントダウン（全モード共通）
  Timer? _ticker;
  int _total = 0;
  final ValueNotifier<int> _remaining = ValueNotifier<int>(0); // 通知のみ→部屋全体の再描画を避ける
  int _tAtJudgment = 0; // 審判時点の残り秒（I 算出用に固定）
  int _earnedLetters = 0; // 結末時点で点灯できた GEDÄCHTNIS 文字数
  bool _brainDead = false;

  /// モード別の総制限時間（秒）。ハードほど短い。
  int _durationFor(String mode) {
    switch (mode) {
      case 'hard':
        return 720; // 12分
      case 'timer':
        return 900; // 15分
      default:
        return 1500; // ノーマル 25分
    }
  }

  @override
  void initState() {
    super.initState();
    _boot();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _remaining.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    final repo = await ContentRepository.load();
    final man = jsonDecode(await rootBundle.loadString(_manifest))
        as Map<String, dynamic>;
    final paths = (man['rooms'] as List).cast<String>();
    final rooms = <Map<String, dynamic>>[];
    for (final p in paths) {
      rooms.add(
          jsonDecode(await rootBundle.loadString(p)) as Map<String, dynamic>);
    }
    final judgment = jsonDecode(await rootBundle.loadString(_judgmentPath))
        as Map<String, dynamic>;
    final mem = <String, String>{};
    for (final r in rooms) {
      final id = r['memory_id'] as String?;
      if (id != null) mem[id] = 'unknown';
    }
    final dur = _durationFor(widget.mode);
    setState(() {
      _repo = repo;
      _rooms = rooms;
      _judgment = judgment;
      _gs = GameState(
        mode: widget.mode,
        memories: mem,
        items: [],
        flags: {
          'has_culprit_evidence': false,
          'deduction_correct': false,
          'deduction_answered': false,
          'all_truth': false,
          'syringe_chosen': false,
        },
        meters: {},
      );
      _total = dur;
      _remaining.value = dur;
      _brainDead = false;
      _ending = null;
      _phase = _Phase.room;
      _idx = 0;
    });
    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_phase == _Phase.ending) {
        t.cancel();
        return;
      }
      _remaining.value -= 1; // 通知のみ。クロックだけ再描画され、部屋は再構築されない
      if (_remaining.value <= 0) {
        t.cancel();
        _onBrainDeath();
      }
    });
  }

  void _onBrainDeath() {
    if (_phase == _Phase.ending) return;
    _brainDead = true;
    // 部屋途中で脳死なら点灯済みのみ。R13収束以降(reveal/judgment)は全10文字。
    _earnedLetters = _phase == _Phase.room ? _litCount(_idx) : 10;
    final res = evaluateConfabEnding(_gs, _repo!, brainDead: true);
    setState(() {
      _ending = res;
      _phase = _Phase.ending;
    });
  }

  void _advance() {
    if (_phase == _Phase.ending) return;
    setState(() {
      if (_idx < _rooms.length - 1) {
        _idx++;
      } else {
        _phase = _Phase.reveal; // R13クリア → アナグラム収束演出へ
      }
    });
  }

  void _onRevealDone() {
    if (_phase == _Phase.ending) return;
    setState(() => _phase = _Phase.judgment);
  }

  void _onJudged() {
    if (_phase == _Phase.ending) return;
    _ticker?.cancel();
    _tAtJudgment = _remaining.value < 0 ? 0 : _remaining.value;
    _earnedLetters = 10; // R13収束で抑圧されたHも露見＝GEDÄCHTNIS全10文字
    final res = evaluateConfabEnding(_gs, _repo!, brainDead: false);
    setState(() {
      _ending = res;
      _phase = _Phase.ending;
    });
  }

  void _restartOrTitle() {
    if (_ending?.loopToStage != null) {
      _boot(); // 忘却の揺り籠：回廊の最初へ戻る
    } else {
      Navigator.of(context).maybePop();
    }
  }

  int _litCount(int idx) => _litGlyphs(idx).length;

  /// idx 番目の部屋に入る時点で点灯済みのトラウマ文字（点灯順＝不規則）。
  List<String> _litGlyphs(int idx) {
    final out = <String>[];
    for (var i = 0; i < idx && i < _rooms.length; i++) {
      final l = _rooms[i]['letter'] as String?;
      if (l != null && l.isNotEmpty) out.add(l);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == _Phase.loading || _repo == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    switch (_phase) {
      case _Phase.room:
        final room = _rooms[_idx];
        return DeepRoomScreen(
          key: ValueKey('deep_${room['id']}_${widget.mode}'),
          room: room,
          gameState: _gs,
          mode: widget.mode,
          timed: true,
          remaining: _remaining,
          litGlyphs: _litGlyphs(_idx),
          onCleared: _advance,
        );
      case _Phase.reveal:
        return VerlustRevealScreen(
          earnedGlyphs: _litGlyphs(_rooms.length),
          onDone: _onRevealDone,
        );
      case _Phase.judgment:
        return FinalJudgmentScreen(
          data: _judgment,
          gameState: _gs,
          remaining: _remaining,
          onComplete: _onJudged,
        );
      case _Phase.ending:
        final m = _gs.meters['confab'] ?? 0;
        final e = countEvade(_gs);
        final conf = countConfront(_gs);
        final tRem = _brainDead ? 0 : _tAtJudgment;
        final integrity = confabIntegrity(
            correct: m, evade: e, tRemaining: tRem, tTotal: _total);
        return VerdictScreen(
          result: _ending!,
          integrity: integrity,
          survival: survivalT(tRem, _total),
          correct: m,
          evade: e,
          confront: conf,
          brainDead: _brainDead,
          syringeChosen: _gs.flags['syringe_chosen'] ?? false,
          allTruth: _gs.flags['all_truth'] ?? false,
          earned: _earnedLetters,
          onRestart: _restartOrTitle,
        );
      case _Phase.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
  }
}
