import 'dart:async';
import 'package:flutter/material.dart';

/// R13収束演出。点灯したトラウマ文字（不規則）が、スロットのように
/// GEDÄCHTNIS へ並び替わり（抑圧されていた H が嵌まる）、最後に VERLUST が割り込む。
/// v1：クロスフェードによる段階表示。タップで早送り可。
class VerlustRevealScreen extends StatefulWidget {
  final List<String> earnedGlyphs; // 部屋で点灯した文字（点灯順）
  final VoidCallback onDone;

  const VerlustRevealScreen({
    super.key,
    required this.earnedGlyphs,
    required this.onDone,
  });

  @override
  State<VerlustRevealScreen> createState() => _VerlustRevealScreenState();
}

class _VerlustRevealScreenState extends State<VerlustRevealScreen> {
  static const String _word = 'GEDÄCHTNIS';
  final List<Timer> _timers = [];
  int _phase = 0; // 0:断片 1:Gedächtnis 2:Verlust 3:確定

  @override
  void initState() {
    super.initState();
    _timers.add(Timer(const Duration(milliseconds: 1700), () => _set(1)));
    _timers.add(Timer(const Duration(milliseconds: 3600), () => _set(2)));
    _timers.add(Timer(const Duration(milliseconds: 5200), () => _set(3)));
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  void _set(int p) {
    if (mounted) setState(() => _phase = p);
  }

  void _skip() {
    for (final t in _timers) {
      t.cancel();
    }
    setState(() => _phase = 3);
  }

  TextStyle _glyph(Color c, {double size = 34}) => TextStyle(
        fontFamily: 'Blackletter',
        fontSize: size,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
        color: c,
      );

  Widget _scattered() => Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final g in widget.earnedGlyphs)
            Text(g, style: _glyph(Colors.white38)),
        ],
      );

  Widget _assembled() => Wrap(
        alignment: WrapAlignment.center,
        children: [
          for (var i = 0; i < _word.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              // 抑圧されていた H（index 5）だけ血の色で嵌まる
              child: Text(_word[i],
                  style: _glyph(
                      i == 5 ? Colors.redAccent : Colors.amberAccent)),
            ),
        ],
      );

  String get _caption {
    switch (_phase) {
      case 0:
        return '── 断片が、ひとりでに回転を始める……';
      case 1:
        return '── Gedächtnis（記憶）。真犯人の名でも、館の秘密でもない。\nこれは、私の脳の機能そのものの名だ。';
      default:
        return '── 欠けていた一文字が、軋みながら嵌まる。\nGedächtnisverlust（記憶喪失）。';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _phase < 3 ? _skip : null,
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 700),
                    child: KeyedSubtree(
                      key: ValueKey(_phase == 0 ? 'scatter' : 'word'),
                      child: _phase == 0 ? _scattered() : _assembled(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  AnimatedOpacity(
                    opacity: _phase >= 2 ? 1 : 0,
                    duration: const Duration(milliseconds: 600),
                    child: Text('V E R L U S T',
                        style: _glyph(Colors.redAccent, size: 30)),
                  ),
                  const SizedBox(height: 28),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Text(_caption,
                        key: ValueKey(_phase),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14, height: 1.7)),
                  ),
                  const SizedBox(height: 32),
                  AnimatedOpacity(
                    opacity: _phase >= 3 ? 1 : 0,
                    duration: const Duration(milliseconds: 400),
                    child: IgnorePointer(
                      ignoring: _phase < 3,
                      child: FilledButton(
                        onPressed: widget.onDone,
                        style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF7A1620)),
                        child: const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Text('30号室 ― 現実の玄関ホールへ'),
                        ),
                      ),
                    ),
                  ),
                  if (_phase < 3)
                    const Padding(
                      padding: EdgeInsets.only(top: 18),
                      child: Text('（タップで早送り）',
                          style:
                              TextStyle(color: Colors.white24, fontSize: 11)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
