import 'package:flutter/material.dart';

/// 設計上の固定キャンバス（例 360x640）に Positioned 配置した子を、
/// 画面サイズに合わせて等倍スケールする。interactables の rect 座標を
/// そのまま使えるようにするためのラッパー。
class DesignCanvas extends StatelessWidget {
  static const double designWidth = 360;
  static const double designHeight = 640;

  final List<Widget> children;
  const DesignCanvas({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: designWidth,
        height: designHeight,
        child: Stack(children: children),
      ),
    );
  }
}
