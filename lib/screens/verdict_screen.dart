import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import '../endings_eval.dart';

/// 深い部屋キャンペーンの結末画面。作話完全度 I=(T×M)(1+E/3) を
/// 「精神鑑定書」として提示し、GEDÄCHTNIS / VERLUST のモチーフを添える。
class VerdictScreen extends StatelessWidget {
  final EndingResult result;
  final int integrity; // 作話完全度 I
  final int survival; // T（生存度 0..100）
  final int correct; // M（作話＝嘘を選んだ数）
  final int evade; // E（逃避数）
  final int confront; // 直面数
  final bool brainDead;
  final bool syringeChosen;
  final bool allTruth;
  final int earned; // 実際に点灯できた GEDÄCHTNIS の文字数
  final int playSeconds; // 実プレイ時間（秒）
  final int totalHints; // ヒント閲覧の総回数
  final List<Map<String, dynamic>> floors; // フロア別 {name, seconds, hints}
  final String mode; // story / normal / normal_t / hard / hard_t
  final VoidCallback onRestart;

  const VerdictScreen({
    super.key,
    required this.result,
    required this.integrity,
    required this.survival,
    required this.correct,
    required this.evade,
    required this.confront,
    required this.brainDead,
    required this.syringeChosen,
    required this.allTruth,
    required this.earned,
    this.playSeconds = 0,
    this.totalHints = 0,
    this.floors = const [],
    this.mode = 'normal',
    required this.onRestart,
  });

  String get _modeLabel =>
      const {
        'story': 'ストーリー',
        'normal': 'ノーマル',
        'normal_t': 'ノーマル＋時間',
        'hard': 'ハード',
        'hard_t': 'ハード＋時間',
      }[mode] ??
      mode;

  static String fmtTime(int s) {
    final m = (s ~/ 60).toString();
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  // 共有文はネタバレ厳禁：結末名・結末記号・作話などの語は一切入れない。
  // 出すのはスコア／タイム／ヒント回数（数値）と、煽り文・タグ・URLのみ。
  String _shareText() =>
      '『アムネジィ・ケース』をクリア！\n'
      'モード：$_modeLabel\n'
      'スコア：$integrity\n'
      'クリアタイム：${fmtTime(playSeconds)} ／ ヒント：$totalHints回\n'
      'あなたは、どんな“結末”に辿り着く？\n'
      '#アムネジィケース\n'
      'https://sk1214-gkms.github.io/kioku-no-kairou/';

  Future<void> _share(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _shareText()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('結果をコピーしました。SNSに貼り付けて共有できます。')));
    }
  }

  bool get _verlust =>
      brainDead || result.ending == 'D' || result.ending == 'S';

  @override
  Widget build(BuildContext context) {
    // Ending D（精神の死）はスコア盤も符号も出さず、灰色の虚無＝純粋な暗転で見せる。
    if (result.ending == 'D') return _deathView(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0E0C14),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _motif(),
                const SizedBox(height: 18),
                Text(result.title,
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: _verlust ? Colors.redAccent : Colors.white),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Text(result.text,
                    style: const TextStyle(fontSize: 15, height: 1.9),
                    textAlign: TextAlign.left),
                const SizedBox(height: 28),
                _summaryRow(),
                const SizedBox(height: 14),
                _report(),
                const SizedBox(height: 14),
                _floorTable(),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _share(context),
                  icon: const Icon(Icons.ios_share, size: 18),
                  label: const Text('結果をSNS用にコピー'),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onRestart,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    child: Text(result.loopToStage != null
                        ? '回廊の最初へ戻される……'
                        : 'タイトルへ戻る'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Ending D 専用：灰色の虚無。スコア盤・符号モチーフを出さず、診断書だけが浮かぶ。
  Widget _deathView(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(result.text,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 14, height: 2.0),
                    textAlign: TextAlign.left),
                const SizedBox(height: 28),
                Text('到達 ${fmtTime(playSeconds)}　／　ヒント $totalHints回',
                    style: const TextStyle(color: Colors.white24, fontSize: 12)),
                TextButton.icon(
                  onPressed: () => _share(context),
                  icon: const Icon(Icons.ios_share,
                      size: 16, color: Colors.white24),
                  label: const Text('結果をコピー',
                      style: TextStyle(color: Colors.white24)),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: onRestart,
                  child: const Text('── タイトルへ ──',
                      style: TextStyle(color: Colors.white24, letterSpacing: 2)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _motif() {
    const target = 'GEDÄCHTNIS';
    final lit = earned.clamp(0, target.length);
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            // 実際に点灯できた分だけを表示（脳死で途中なら符号も途中まで）
            for (var i = 0; i < lit; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(target[i],
                    style: TextStyle(
                        fontFamily: 'Blackletter',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: _verlust ? Colors.white24 : Colors.amberAccent)),
              ),
          ],
        ),
        if (_verlust)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('V E R L U S T',
                style: TextStyle(
                    fontFamily: 'Blackletter',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: Colors.redAccent)),
          ),
      ],
    );
  }

  Widget _report() {
    final formula = '($survival × $correct) × (1 + $evade/3) ＝ $integrity';
    return Container(
      width: 520,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF15131C),
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('【精神鑑定書：蓮見 鏡介 ― 作話完全度評価】',
              style: TextStyle(
                  color: Colors.amberAccent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _row('生存度 T（脳の残存）', '$survival / 100'),
          _row('作話正解 M（嘘の補完）', '$correct / 3'),
          _row('逃避 E（直面の回避）', '$evade / 3　［直面 $confront / 3］'),
          _row('隠し / 真実', syringeChosen
              ? 'シリンジに到達（封印された真相）'
              : allTruth
                  ? '全て真実を選択（嘘の全拒絶）'
                  : '—'),
          const Divider(height: 18, color: Colors.white12),
          _row('作話完全度 I ＝ (T×M)(1+E/3)', formula),
          const SizedBox(height: 6),
          Text('→ 結末：${result.title}',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  /// クリアタイム／スコア／ヒント回数の要約（3枚のチップ）。
  Widget _summaryRow() {
    Widget chip(String label, String value, Color c) => Container(
          width: 160,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF15131C),
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      color: c, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
        );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        chip('モード', _modeLabel, Colors.cyanAccent),
        chip('クリアタイム', fmtTime(playSeconds), Colors.white),
        chip('スコア（作話完全度）', '$integrity', Colors.amberAccent),
        chip('ヒント閲覧', '$totalHints 回', Colors.white),
      ],
    );
  }

  /// 各フロアの所要タイムとヒント閲覧回数の明細。
  Widget _floorTable() {
    if (floors.isEmpty) return const SizedBox.shrink();
    Widget cell(String t, {bool head = false, Color? color, int flex = 3}) =>
        Expanded(
          flex: flex,
          child: Text(t,
              style: TextStyle(
                  color: color ?? (head ? Colors.white54 : Colors.white),
                  fontSize: head ? 11 : 12,
                  fontWeight: head ? FontWeight.bold : FontWeight.normal)),
        );
    return Container(
      width: 520,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF15131C),
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('【フロア別の記録】',
              style: TextStyle(
                  color: Colors.amberAccent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(children: [
            cell('フロア', head: true, flex: 5),
            cell('タイム', head: true, flex: 3),
            cell('ヒント', head: true, flex: 3),
          ]),
          const Divider(height: 12, color: Colors.white12),
          for (final f in floors)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                cell(f['name'] as String? ?? '—', flex: 5),
                cell(fmtTime((f['seconds'] as num?)?.toInt() ?? 0), flex: 3),
                cell(
                  ((f['hints'] as num?)?.toInt() ?? 0) > 0
                      ? '${f['hints']} 回'
                      : '—',
                  color: ((f['hints'] as num?)?.toInt() ?? 0) > 0
                      ? Colors.redAccent
                      : Colors.white38,
                  flex: 3,
                ),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 190,
              child: Text(label,
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ),
      );
}
