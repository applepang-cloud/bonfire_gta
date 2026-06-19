import 'dart:math';

import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';

/// 화면 전체에 시간대 틴트를 입히는 HUD 컴포넌트(낮↔밤 순환).
/// hudComponents 로 추가하면 월드 위·플러터 HUD 아래에 그려진다.
class DayNight extends GameComponent {
  static double time = 0.30; // 0=자정, 0.5=정오 (세션 동안 유지)
  static const double dayLength = 200; // 한 사이클(초)

  final _paint = Paint();

  @override
  void update(double dt) {
    super.update(dt);
    time = (time + dt / dayLength) % 1.0;
  }

  @override
  void render(Canvas canvas) {
    // 자정(time=0)에 가장 어둡고 정오(0.5)에 밝음.
    final darkness = (cos(time * 2 * pi) * 0.5 + 0.5) * 0.55;
    if (darkness < 0.02) return;
    _paint.color = Color.fromRGBO(18, 22, 64, darkness);
    final s = gameRef.size;
    canvas.drawRect(Rect.fromLTWH(0, 0, s.x, s.y), _paint);
  }

  @override
  int get priority => 999990;
}
