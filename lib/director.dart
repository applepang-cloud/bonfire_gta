import 'dart:math';

import 'package:bonfire/bonfire.dart';

import 'npcs.dart';
import 'wanted.dart';

/// 보이지 않는 "감독" 컴포넌트.
/// - 수배도(별)에 비례해 경찰을 스폰하여 플레이어를 추격시킨다.
/// - 시민/갱단 인구를 일정 수준으로 유지(플레이어 주변에 보충).
class WorldDirector extends GameComponent {
  final List<Vector2> roadPoints;
  final Random rng;

  double _copT = 0;
  double _popT = 0;

  static const int maxCivilians = 38;
  static const int maxGangsters = 14;

  WorldDirector(this.roadPoints, this.rng);

  @override
  Future<void> onMount() async {
    super.onMount();
    // 초기 인구 — 맵 전역에 흩뿌림.
    for (var i = 0; i < 22; i++) {
      final p = _anyPoint();
      if (p != null) gameRef.add(Civilian(p));
    }
    for (var i = 0; i < 4; i++) {
      final p = _anyPoint();
      if (p != null) gameRef.add(Gangster(p));
    }
  }

  Vector2? _anyPoint() =>
      roadPoints.isEmpty ? null : roadPoints[rng.nextInt(roadPoints.length)];

  Vector2? _pointNear(Vector2 from, {double min = 170, double max = 380}) {
    final ring = <Vector2>[];
    for (final p in roadPoints) {
      final d = p.distanceTo(from);
      if (d >= min && d <= max) ring.add(p);
    }
    if (ring.isNotEmpty) return ring[rng.nextInt(ring.length)];
    return _anyPoint();
  }

  @override
  void update(double dt) {
    super.update(dt);
    final player = gameRef.player;
    if (player == null || player.isDead) return;
    final center = player.absoluteCenter;

    // 경찰 스폰: 별 개수만큼 유지.
    _copT += dt;
    if (_copT >= 1.2) {
      _copT = 0;
      final target = Wanted.instance.starCount;
      var need = target - Wanted.instance.activeCops;
      var guard = 0;
      while (need > 0 && guard < 4) {
        final p = _pointNear(center, min: 150, max: 300);
        if (p == null) break;
        gameRef.add(Cop(p));
        need--;
        guard++;
      }
    }

    // 인구 보충(플레이어 주변).
    _popT += dt;
    if (_popT >= 3.5) {
      _popT = 0;
      final civ = gameRef.query<Civilian>().length;
      final gang = gameRef.query<Gangster>().length;
      if (civ < 18 && civ < maxCivilians) {
        final p = _pointNear(center);
        if (p != null) gameRef.add(Civilian(p));
      }
      if (gang < 6 && gang < maxGangsters) {
        final p = _pointNear(center);
        if (p != null) gameRef.add(Gangster(p));
      }
    }
  }
}
