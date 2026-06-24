import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../content_repository.dart';
import '../endings_eval.dart';
import '../models.dart';
import 'deep_room_screen.dart';
import 'ending_screen.dart';
import 'final_room_screen.dart';

enum _Phase { loading, room, finalRoom, ending }

/// 深い部屋キャンペーン：マニフェストの深部屋を順に進行 → 最終室（推理＋3択）→ 7エンディング。
/// モード(ノーマル/タイマー/ハード)・記憶(full/虫食い)・confront を統合。既存の最終室/エンディングを再利用。
class DeepCampaignFlow extends StatefulWidget {
  final String mode;
  const DeepCampaignFlow({super.key, this.mode = 'normal'});

  @override
  State<DeepCampaignFlow> createState() => _DeepCampaignFlowState();
}

class _DeepCampaignFlowState extends State<DeepCampaignFlow> {
  static const _manifest = 'data/deep_rooms/campaign.json';
  static const int roomSeconds = 240;

  ContentRepository? _repo;
  List<Map<String, dynamic>> _rooms = [];
  late GameState _gs;
  _Phase _phase = _Phase.loading;
  int _idx = 0;
  EndingResult? _ending;

  bool get _timed => widget.mode == 'timer';

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final repo = await ContentRepository.load();
    final man = jsonDecode(await rootBundle.loadString(_manifest))
        as Map<String, dynamic>;
    final paths = (man['rooms'] as List).cast<String>();
    final rooms = <Map<String, dynamic>>[];
    for (final p in paths) {
      rooms.add(jsonDecode(await rootBundle.loadString(p))
          as Map<String, dynamic>);
    }
    final mem = <String, String>{};
    for (final r in rooms) {
      final id = r['memory_id'] as String?;
      if (id != null) mem[id] = 'unknown';
    }
    setState(() {
      _repo = repo;
      _rooms = rooms;
      _gs = GameState(
        mode: widget.mode,
        memories: mem,
        items: [],
        flags: {
          'has_culprit_evidence': false,
          'deduction_correct': false,
          'deduction_answered': false,
        },
        meters: {},
      );
      _phase = _Phase.room;
      _idx = 0;
    });
  }

  void _advance() {
    setState(() {
      if (_idx < _rooms.length - 1) {
        _idx++;
      } else {
        _phase = _Phase.finalRoom;
      }
    });
  }

  void _onChoice(String branch) {
    final res = evaluateEnding(branch, _gs, _repo!);
    setState(() {
      _ending = res;
      _phase = _Phase.ending;
    });
  }

  void _toTitle() => Navigator.of(context).maybePop();

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
          timed: _timed,
          seconds: roomSeconds,
          onCleared: _advance,
          onTimedOut: _advance,
        );
      case _Phase.finalRoom:
        return FinalRoomScreen(
          room: _repo!.finalRoom,
          gameState: _gs,
          repo: _repo!,
          onChoice: _onChoice,
        );
      case _Phase.ending:
        final confront = _gs.meters['confront'] ?? 0;
        final eff = (_gs.memoryScore + confront * 5).clamp(0, 100);
        final dTotal =
            (_repo!.finalRoom.deduction?['questions'] as List?)?.length ?? 0;
        String axis(String a, String b) => (_gs.flags[a] == true)
            ? '直面'
            : (_gs.flags[b] == true)
                ? '逃避'
                : '—';
        final breakdown =
            'R4:${axis('s_r4_confront', 's_r4_evade')} / R8:${axis('s_r8_confront', 's_r8_evade')} / R12:${axis('s_r12_confront', 's_r12_evade')}';
        return EndingScreen(
          result: _ending!,
          summary: GameStateSummary(
            memoryScore: _gs.memoryScore,
            confront: confront,
            effectiveScore: eff,
            deductionScore: _gs.meters['deduction'] ?? 0,
            deductionTotal: dTotal,
            deductionCorrect: _gs.flags['deduction_correct'] ?? false,
            hasEvidence: _gs.flags['has_culprit_evidence'] ?? false,
            confrontBreakdown: breakdown,
          ),
          onRestart: _toTitle,
        );
      case _Phase.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
  }
}
