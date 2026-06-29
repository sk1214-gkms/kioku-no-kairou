import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../audio_service.dart';
import '../collection_service.dart';
import '../content_repository.dart';
import '../deep_save_service.dart';
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
  final DeepSavedRun? resume; // 中断からの再開（null＝新規）
  const DeepCampaignFlow({super.key, this.mode = 'normal', this.resume});

  @override
  State<DeepCampaignFlow> createState() => _DeepCampaignFlowState();
}

class _DeepCampaignFlowState extends State<DeepCampaignFlow>
    with WidgetsBindingObserver {
  final DeepSaveService _saveService = DeepSaveService();
  final CollectionService _collection = CollectionService();

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

  // 結果画面用：フロア別の所要秒・ヒント閲覧回数を集計
  final List<Map<String, dynamic>> _floors = [];
  int _roomStartRem = 0; // 現在フロアに入った時点の残り秒

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
    WidgetsBinding.instance.addObserver(this);
    _boot();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _remaining.dispose();
    super.dispose();
  }

  /// バックグラウンド遷移＝タイマー停止＋オートセーブ。復帰＝タイマー再開。
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted &&
          _phase != _Phase.ending &&
          _phase != _Phase.loading &&
          _repo != null) {
        _startTicker();
      }
    } else {
      _ticker?.cancel();
      _autosave();
    }
  }

  /// 部屋境界チェックポイントを保存（room フェーズのみ）。fire-and-forget。
  void _autosave() {
    if (_repo == null || _phase != _Phase.room) return;
    _saveService.save(
      mode: widget.mode,
      idx: _idx,
      total: _total,
      remaining: _remaining.value,
      gameState: _gs,
    );
  }

  Future<void> _boot({bool fresh = false}) async {
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
    final r = fresh ? null : widget.resume; // ループ(B)再起動時は resume を無視して頭から
    setState(() {
      _repo = repo;
      _rooms = rooms;
      _judgment = judgment;
      if (r != null) {
        _gs = r.gameState;
        _total = r.total;
        _remaining.value = r.remaining;
        _idx = r.idx.clamp(0, rooms.length - 1);
      } else {
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
        _idx = 0;
      }
      _brainDead = false;
      _ending = null;
      _floors.clear();
      _roomStartRem = _remaining.value;
      _phase = _Phase.room;
    });
    _autosave();
    _startTicker();
    AudioService.instance.bgm(_idx < 4 ? 'ch1' : (_idx < 9 ? 'ch2' : 'ch3'));
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
      if (_remaining.value <= 60) AudioService.instance.sfx('heartbeat'); // 脳死接近
      if (_remaining.value <= 0) {
        t.cancel();
        _onBrainDeath();
      }
    });
  }

  void _onBrainDeath() {
    if (_phase == _Phase.ending) return;
    _saveService.clear(); // 結末到達＝セーブ破棄
    _brainDead = true;
    // 部屋途中で脳死なら点灯済みのみ。R13収束以降(reveal/judgment)は全10文字。
    _earnedLetters = _phase == _Phase.room ? _litCount(_idx) : 10;
    final res = evaluateConfabEnding(_gs, _repo!, brainDead: true);
    _collection.markSeen(res.ending); // 結末コレクションに記録
    AudioService.instance.sfx('flatline');
    AudioService.instance.bgm('ending');
    setState(() {
      _ending = res;
      _phase = _Phase.ending;
    });
  }

  void _advance(int hintsUsed) {
    if (_phase == _Phase.ending) return;
    _recordFloor(_rooms[_idx]['name'] as String? ?? 'R${_idx + 1}', hintsUsed);
    setState(() {
      if (_idx < _rooms.length - 1) {
        _idx++;
      } else {
        _phase = _Phase.reveal; // R13クリア → アナグラム収束演出へ
      }
    });
    _roomStartRem = _remaining.value; // 次フロア（reveal/judgment含む）の起点
    _autosave(); // 次の部屋頭でチェックポイント（reveal遷移時は no-op）
    if (_phase == _Phase.room) {
      AudioService.instance.bgm(_idx < 4 ? 'ch1' : (_idx < 9 ? 'ch2' : 'ch3'));
    }
  }

  /// 直前フロアの所要秒・ヒント回数を記録（残り秒の差分＝実消費時間）。
  void _recordFloor(String name, int hints) {
    final secs = _roomStartRem - _remaining.value;
    _floors.add({'name': name, 'seconds': secs < 0 ? 0 : secs, 'hints': hints});
  }

  void _onRevealDone() {
    if (_phase == _Phase.ending) return;
    AudioService.instance.bgm('finale');
    setState(() => _phase = _Phase.judgment);
  }

  void _onJudged() {
    if (_phase == _Phase.ending) return;
    _saveService.clear(); // 結末到達＝セーブ破棄
    _ticker?.cancel();
    _tAtJudgment = _remaining.value < 0 ? 0 : _remaining.value;
    _recordFloor('30号室（最後の審判）', 0); // 推理フェーズの所要も記録
    _earnedLetters = 10; // R13収束で抑圧されたHも露見＝GEDÄCHTNIS全10文字
    final res = evaluateConfabEnding(_gs, _repo!, brainDead: false);
    _collection.markSeen(res.ending); // 結末コレクションに記録
    AudioService.instance.bgm('ending');
    setState(() {
      _ending = res;
      _phase = _Phase.ending;
    });
  }

  void _restartOrTitle() {
    if (_ending?.loopToStage != null) {
      _boot(fresh: true); // 忘却の揺り籠：resumeを無視して回廊の最初へ
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
        // ① 記憶の上書き回数も“逃避（作話）”として E に合算（0..3にclamp）
        final ow = _gs.meters['overwrite'] ?? 0;
        final e = (countEvade(_gs) + ow).clamp(0, 3);
        final conf = countConfront(_gs);
        final tRem = _brainDead ? 0 : _tAtJudgment;
        final integrity = confabIntegrity(
            correct: m, evade: e, tRemaining: tRem, tTotal: _total);
        final remNow = _remaining.value < 0 ? 0 : _remaining.value;
        final playSeconds = (_total - remNow).clamp(0, _total); // 実消費時間
        final totalHints =
            _floors.fold<int>(0, (s, f) => s + (f['hints'] as int));
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
          playSeconds: playSeconds,
          totalHints: totalHints,
          floors: List<Map<String, dynamic>>.from(_floors),
          onRestart: _restartOrTitle,
        );
      case _Phase.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
  }
}
