import 'dart:math';

import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';

import 'main_story.dart';

/// 플레이어 머리 위에 떠서 메인 스토리 목표 방향을 가리키는 화살표(월드 공간).
class StoryArrow extends GameComponent {
  double _t = 0;

  StoryArrow() {
    position = Vector2.zero();
  }

  @override
  int get priority => 999980;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    final marker = MainStory.instance.marker.value;
    final player = gameRef.player;
    if (marker == null || player == null) return;
    final dir = marker - player.absoluteCenter;
    final dist = dir.length;
    if (dist < 40) return; // 목표 근처면 숨김

    final ang = atan2(dir.y, dir.x);
    final bob = sin(_t * 4) * 2;
    canvas.save();
    canvas.translate(
        player.absoluteCenter.x, player.absoluteCenter.y - 30 + bob);
    canvas.rotate(ang);
    final p = Path()
      ..moveTo(12, 0)
      ..lineTo(-5, -7)
      ..lineTo(-1, 0)
      ..lineTo(-5, 7)
      ..close();
    canvas.drawPath(
        p,
        Paint()
          ..color = const Color(0xFFFFD54F)
          ..style = PaintingStyle.fill);
    canvas.drawPath(
        p,
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    canvas.restore();
  }
}

/// 목표 위치에 표시되는 빛나는 비콘(맵 상의 목적지).
class Beacon extends GameComponent {
  double _t = 0;
  Beacon(Vector2 pos) {
    position = pos;
    size = Vector2.all(16);
    anchor = Anchor.center;
  }

  @override
  int get priority => 999970;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    final pulse = (sin(_t * 3) * 0.5 + 0.5);
    // 바닥 원
    canvas.drawCircle(Offset.zero, 10 + pulse * 4,
        Paint()..color = const Color(0x55FFD54F));
    // 다이아몬드 마커
    final d = Path()
      ..moveTo(0, -22 - pulse * 3)
      ..lineTo(6, -14)
      ..lineTo(0, -6)
      ..lineTo(-6, -14)
      ..close();
    canvas.drawPath(d, Paint()..color = const Color(0xFFFFC107));
    canvas.drawPath(
        d,
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
  }
}
