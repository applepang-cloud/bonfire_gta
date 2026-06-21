import 'dart:math';

import 'package:bonfire/bonfire.dart';

import 'npcs.dart';
import 'sprites.dart';
import 'wanted.dart';

/// 보이지 않는 "감독" — 마을 인구(마을사람/산적/괴물) 유지 + 악명에 따른 경비병 출동.
class WorldDirector extends GameComponent {
  final List<Vector2> roadPoints;
  final Random rng;

  double _guardT = 0;
  double _popT = 0;

  static const int maxVillagers = 42;
  static const int maxBandits = 12;
  static const int maxMonsters = 10;

  WorldDirector(this.roadPoints, this.rng);

  // 어른 행인(휴먼) 비율을 섞어 거리를 북적이게.
  void _spawnCivilian(Vector2 p) {
    if (rng.nextDouble() < 0.45) {
      gameRef.add(Villager(p,
          anim: PersonSprites(path: 'human.png').animation(), dim: 22));
    } else {
      gameRef.add(Villager(p));
    }
  }

  @override
  Future<void> onMount() async {
    super.onMount();
    // 초기엔 조금만 스폰(초반 렉 완화), 나머지는 시간이 지나며 보충.
    for (var i = 0; i < 12; i++) {
      final p = _anyPoint();
      if (p != null) _spawnCivilian(p);
    }
    for (var i = 0; i < 3; i++) {
      final p = _anyPoint();
      if (p != null) gameRef.add(Bandit(p));
    }
    for (var i = 0; i < 3; i++) {
      final p = _anyPoint();
      if (p != null) gameRef.add(Monster(p));
    }
    final ap = _anyPoint();
    if (ap != null) gameRef.add(Archer(ap));
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

    // 경비병: 악명(별)만큼 유지.
    _guardT += dt;
    if (_guardT >= 1.2) {
      _guardT = 0;
      final need = Wanted.instance.starCount - Wanted.instance.activeCops;
      var guard = 0;
      var n = need;
      while (n > 0 && guard < 4) {
        final p = _pointNear(center, min: 150, max: 300);
        if (p == null) break;
        gameRef.add(Guard(p));
        n--;
        guard++;
      }
    }

    // 인구 보충(플레이어 주변).
    _popT += dt;
    if (_popT >= 3.5) {
      _popT = 0;
      // 일반인을 플레이어 주변에 넉넉히 유지(거리에 늘 사람이 보이게).
      final civ = gameRef.query<Villager>().length;
      if (civ < 24 && civ < maxVillagers) {
        for (var k = 0; k < 2; k++) {
          final p = _pointNear(center, min: 120, max: 360);
          if (p != null) _spawnCivilian(p);
        }
      }
      if (gameRef.query<Bandit>().length < 6 &&
          gameRef.query<Bandit>().length < maxBandits) {
        final p = _pointNear(center);
        if (p != null) gameRef.add(Bandit(p));
      }
      if (gameRef.query<Monster>().length < 5 &&
          gameRef.query<Monster>().length < maxMonsters) {
        final p = _pointNear(center, min: 220, max: 420);
        if (p != null) gameRef.add(Monster(p));
      }
      if (gameRef.query<Archer>().length < 3) {
        final p = _pointNear(center, min: 200, max: 400);
        if (p != null) gameRef.add(Archer(p));
      }
      if (gameRef.query<Ogre>().length < 2 && rng.nextDouble() < 0.5) {
        final p = _pointNear(center, min: 260, max: 460);
        if (p != null) gameRef.add(Ogre(p));
      }
    }
  }
}
