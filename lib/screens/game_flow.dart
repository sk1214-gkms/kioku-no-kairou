import 'package:flutter/material.dart';
import '../ad_service.dart';
import '../content_repository.dart';
import '../endings_eval.dart';
import '../models.dart';
import '../save_service.dart';
import 'ending_screen.dart';
import 'final_room_screen.dart';
import 'stage_screen.dart';

enum _Phase { loading, stage, finalRoom, ending }

/// ゲーム全体の進行を司る。stage 1..5 → 最終室 → エンディング。
/// mode によって体験が変わる（timer は時間切れで記憶が虫食いになる）。
/// resume が渡された場合は中断したプレイから再開する。
class GameFlow extends StatefulWidget {
  final String mode; // normal | hard | timer
  final SavedRun? resume;
  const GameFlow({super.key, this.mode = 'normal', this.resume});

  @override
  State<GameFlow> createState() => _GameFlowState();
}

class _GameFlowState extends State<GameFlow> {
  static const int timerSeconds = 90; // 1部屋の制限時間

  final SaveService _save = SaveService();
  ContentRepository? _repo;
  late GameState _gs;
  _Phase _phase = _Phase.loading;
  int _stageIndex = 0;
  int _clearCount = 0; // 広告頻度キャップ用
  EndingResult? _ending;

  bool get _timed => _gs.mode == 'timer';

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final repo = await ContentRepository.load();
    setState(() {
      _repo = repo;
      if (widget.resume != null) {
        _gs = widget.resume!.gameState;
        _stageIndex = widget.resume!.stageIndex;
        _phase = widget.resume!.phase == 'finalRoom'
            ? _Phase.finalRoom
            : _Phase.stage;
      } else {
        _gs = GameState.initial(repo.stages, mode: widget.mode);
        _stageIndex = 0;
        _phase = _Phase.stage;
      }
    });
    _persist();
  }

  void _persist() {
    _save.save(
      gameState: _gs,
      stageIndex: _stageIndex,
      phase: _phase == _Phase.finalRoom ? 'finalRoom' : 'stage',
    );
  }

  Future<void> _advance() async {
    _clearCount++;
    // 頻度キャップ：2クリアごとにステージ間広告。閉じてから次の部屋へ
    // （次の部屋のタイマーは広告のあとで開始されるので公平）。
    if (AdService.enabled && _clearCount % 2 == 0) {
      await AdService.instance.showInterstitial();
    }
    if (!mounted) return;
    setState(() {
      if (_stageIndex < _repo!.stages.length - 1) {
        _stageIndex++;
      } else {
        _phase = _Phase.finalRoom;
      }
    });
    _persist();
  }

  void _onSolved(Stage solved) {
    _gs.memories[solved.rewards!.memoryId] = 'full';
    _advance();
  }

  void _onTimeout(Stage timedOut) {
    _gs.memories[timedOut.rewards!.memoryId] = 'corrupted';
    _advance();
  }

  void _onChoice(String branch) {
    final result = evaluateEnding(branch, _gs, _repo!);
    _save.clear(); // 1プレイ完了 → 中断セーブは破棄
    setState(() {
      _ending = result;
      _phase = _Phase.ending;
    });
  }

  void _backToTitle() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    if (_phase == _Phase.loading || _repo == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    switch (_phase) {
      case _Phase.stage:
        final stage = _repo!.stages[_stageIndex];
        return StageScreen(
          key: ValueKey('stage_${stage.stageId}_${_gs.mode}'),
          stage: stage,
          gameState: _gs,
          repo: _repo!,
          mode: _gs.mode,
          timed: _timed,
          seconds: timerSeconds,
          onSolved: _onSolved,
          onTimeout: _onTimeout,
        );
      case _Phase.finalRoom:
        return FinalRoomScreen(
          room: _repo!.finalRoom,
          gameState: _gs,
          repo: _repo!,
          onChoice: _onChoice,
          onChanged: _persist,
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
            '5:${axis('s05_examine', 's05_hide')} / 15:${axis('s15_accept', 's15_deny')} / 25:${axis('s25_confront', 's25_avert')}';
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
          onRestart: _backToTitle,
        );
      case _Phase.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
  }
}
