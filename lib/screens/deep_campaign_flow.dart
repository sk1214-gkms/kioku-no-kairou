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

/// 深い部屋キャンペーン：13部屋 → 30号室（最後の審判）→ 7結末（A+/A/B/C/S/True/D）。
/// 全モード共通で『脳細胞の壊死』カウントダウンを保持し、0で Ending D（精神の死）。
/// 結末は evaluateConfabEnding（離散ツリー）で決定し、作話完全度 I を VerdictScreen に表示。
class DeepCampaignFlow extends StatefulWidget {
  final String mode;
  final DeepSavedRun? resume; // 中断からの再開（null＝新規）
  final JudgmentCheckpoint? retry; // 「最後の審判からやり直す」（審判へ直行）
  const DeepCampaignFlow(
      {super.key, this.mode = 'normal', this.resume, this.retry});

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
  bool _resumedRoom = false; // 続きから再開した“最初の部屋”だけイントロを出さない
  EndingResult? _ending;

  // 脳死カウントダウン（ストーリー以外）。ストーリーは時間制限なし＝出さない。
  Timer? _ticker;
  int _total = 0;
  final ValueNotifier<int> _remaining = ValueNotifier<int>(0); // 通知のみ→部屋全体の再描画を避ける
  int _tAtJudgment = 0; // 審判時点の残り秒（I 算出用に固定）
  int _earnedLetters = 0; // 結末時点で点灯できた GEDÄCHTNIS 文字数
  bool _brainDead = false;

  // 審判やり直し：審判のみを再走するセッション（タイマー無し＝Dは発生しない）
  bool _judgmentOnly = false;
  bool _hasJudgmentCp = false; // この周回で審判チェックポイントが存在するか
  int _retrySeq = 0; // 審判画面を作り直すためのキー
  int _playBaseMs = 0; // やり直し時：突入時点までの実プレイ時間（表示用の底上げ）

  /// 時間制限の有無。末尾 _t（normal_t / hard_t）＝あり、story/normal/hard＝なし。
  bool get _timed => widget.mode.endsWith('_t');

  // 実プレイ時間の計測（全モード共通・バックグラウンド中は停止）
  final Stopwatch _watch = Stopwatch();

  // 結果画面用：フロア別の所要秒・ヒント閲覧回数を集計
  final List<Map<String, dynamic>> _floors = [];
  int _roomStartMs = 0; // 現在フロアに入った時点の経過ミリ秒

  /// 制限時間（秒）。時間あり版のみ実効（時間なしは名目値＝T算出で生存度100扱い）。
  int _durationFor(String mode) {
    switch (mode) {
      case 'hard_t':
        return 720; // ハード＋時間：12分
      case 'normal_t':
        return 900; // ノーマル＋時間：15分
      default:
        return 1500; // 時間なし（story/normal/hard）の名目値
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
        _watch.start();
        if (_timed && !_judgmentOnly) _startTicker();
      }
    } else {
      _ticker?.cancel();
      _watch.stop();
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
    if (!mounted) return; // 読込中に画面が閉じられた場合の dispose後 setState を防ぐ
    final mem = <String, String>{};
    for (final r in rooms) {
      final id = r['memory_id'] as String?;
      if (id != null) mem[id] = 'unknown';
    }
    final dur = _durationFor(widget.mode);
    final r = fresh ? null : widget.resume; // ループ(B)再起動時は resume を無視して頭から
    final cp = fresh ? null : widget.retry; // 審判やり直し（ループ時は頭から）
    setState(() {
      _repo = repo;
      _rooms = rooms;
      _judgment = judgment;
      _brainDead = false;
      _ending = null;
      _floors.clear();
      _playBaseMs = 0;
      _judgmentOnly = cp != null;
      _hasJudgmentCp = cp != null;
      _resumedRoom = cp == null && r != null; // 再開＝この部屋はイントロ省略
      if (cp != null) {
        // 「最後の審判からやり直す」：スナップショットから審判へ直行。
        // タイマーは走らせない（やり直しでDは発生しない）。スコアTは保存値で固定。
        _gs = cp.gameState;
        _total = cp.total;
        _remaining.value = cp.remaining;
        _idx = rooms.length - 1;
        _floors.addAll(List<Map<String, dynamic>>.from(cp.floors));
        _playBaseMs = cp.playSeconds * 1000;
        _phase = _Phase.judgment;
      } else if (r != null) {
        _gs = r.gameState;
        _total = r.total;
        _remaining.value = r.remaining;
        _idx = r.idx.clamp(0, rooms.length - 1);
        _phase = _Phase.room;
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
        _phase = _Phase.room;
      }
    });
    _watch
      ..reset()
      ..start();
    _roomStartMs = 0;
    if (_judgmentOnly) {
      AudioService.instance.bgm('finale');
    } else {
      _autosave();
      if (_timed) _startTicker(); // ストーリーは時間制限なし＝砂時計を動かさない
      AudioService.instance.bgm(_idx < 4 ? 'ch1' : (_idx < 9 ? 'ch2' : 'ch3'));
    }
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
    _watch.stop();
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
      _resumedRoom = false; // 次の部屋は通常どおりイントロを出す
      if (_idx < _rooms.length - 1) {
        _idx++;
      } else {
        _phase = _Phase.reveal; // R13クリア → アナグラム収束演出へ
      }
    });
    _roomStartMs = _watch.elapsedMilliseconds; // 次フロア（reveal/judgment含む）の起点
    _autosave(); // 次の部屋頭でチェックポイント（reveal遷移時は no-op）
    if (_phase == _Phase.room) {
      AudioService.instance.bgm(_idx < 4 ? 'ch1' : (_idx < 9 ? 'ch2' : 'ch3'));
    }
  }

  /// 直前フロアの所要秒・ヒント回数を記録（実プレイ経過の差分＝実消費時間）。
  void _recordFloor(String name, int hints) {
    final secs = ((_watch.elapsedMilliseconds - _roomStartMs) / 1000).round();
    _floors.add({'name': name, 'seconds': secs < 0 ? 0 : secs, 'hints': hints});
  }

  void _onRevealDone() {
    if (_phase == _Phase.ending) return;
    // 審判チェックポイント（「最後の審判からやり直す」用）。周回ごとに上書き。
    _saveService.saveJudgment(
      mode: widget.mode,
      total: _total,
      remaining: _remaining.value,
      gameState: _gs,
      playSeconds: ((_playBaseMs + _watch.elapsedMilliseconds) / 1000).round(),
      floors: List<Map<String, dynamic>>.from(_floors),
    );
    _hasJudgmentCp = true;
    AudioService.instance.bgm('finale');
    setState(() => _phase = _Phase.judgment);
  }

  /// 結果画面から審判のみを再走（チェックポイントを毎回読み直し＝状態は突入時点に巻き戻る）。
  Future<void> _retryJudgment() async {
    final cp = await _saveService.loadJudgment();
    if (cp == null || !mounted) return;
    _ticker?.cancel();
    setState(() {
      _gs = cp.gameState;
      _total = cp.total;
      _remaining.value = cp.remaining;
      _brainDead = false;
      _ending = null;
      _floors
        ..clear()
        ..addAll(List<Map<String, dynamic>>.from(cp.floors));
      _playBaseMs = cp.playSeconds * 1000;
      _judgmentOnly = true;
      _retrySeq++;
      _phase = _Phase.judgment;
    });
    _watch
      ..reset()
      ..start();
    _roomStartMs = 0;
    AudioService.instance.bgm('finale');
  }

  void _onJudged() {
    if (_phase == _Phase.ending) return;
    // やり直しセッションでは中断セーブに触らない（放置中の別周回を消さない）
    if (!_judgmentOnly) _saveService.clear(); // 結末到達＝セーブ破棄
    _ticker?.cancel();
    _watch.stop();
    // ストーリー(時間制限なし)は残り=総時間のまま＝T(生存度)=100扱い
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
    // B(ループ)の自動再走は本編セッションのみ。やり直しセッションで再走すると
    // その _autosave が放置中の別周回の中断セーブを上書きしてしまうため、タイトルへ帰す。
    if (_ending?.loopToStage != null && !_judgmentOnly) {
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
          timed: _timed, // ストーリーは砂時計非表示
          remaining: _remaining,
          litGlyphs: _litGlyphs(_idx),
          showIntro: !_resumedRoom, // 続きから再開した部屋はイントロ省略
          onCleared: _advance,
        );
      case _Phase.reveal:
        return VerlustRevealScreen(
          earnedGlyphs: _litGlyphs(_rooms.length),
          onDone: _onRevealDone,
        );
      case _Phase.judgment:
        return FinalJudgmentScreen(
          key: ValueKey('judgment_$_retrySeq'), // やり直しごとに作り直す
          data: _judgment,
          gameState: _gs,
          // ストーリー・審判やり直しは砂時計非表示（やり直しでDは発生しない）
          remaining: (_timed && !_judgmentOnly) ? _remaining : null,
          retry: _judgmentOnly, // 「もう、戻れない」文言をやり直し用に差し替える
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
        // 実プレイ時間は Stopwatch 実測（やり直し時は突入時点までの実測を底上げ）
        final playSeconds =
            ((_playBaseMs + _watch.elapsedMilliseconds) / 1000).round();
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
          mode: widget.mode,
          onRestart: _restartOrTitle,
          // この周回で審判に到達していれば、答えだけ変えて再挑戦できる
          onRetryJudgment: _hasJudgmentCp ? _retryJudgment : null,
          // やり直しセッションのB(ループ)は自動再走しない（中断セーブ保護）
          loopRestart: !_judgmentOnly,
        );
      case _Phase.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
  }
}
