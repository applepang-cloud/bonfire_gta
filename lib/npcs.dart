import 'dart:math';

import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';

import 'audio.dart';
import 'dialogue.dart';
import 'events.dart';
import 'sprites.dart';
import 'wanted.dart';

final _rng = Random();

/// 마을 사람(작은 크리터) — 배회하며 잡담, 공격받으면 비명 지르며 도주.
/// 시민을 때리거나 죽이면 악명(수배)이 오른다.
class Villager extends SimpleEnemy with RandomMovement {
  static const double s = 16;
  double _fleeTimer = 0;
  final _bark = BarkTimer();

  Villager(Vector2 position)
      : super(
          position: position,
          animation: CivilianSprites.animation(),
          size: Vector2.all(s),
          speed: s * 1.6,
          life: 24,
          initDirection: Direction.down,
        );

  @override
  Future<void> onLoad() {
    add(RectangleHitbox(size: Vector2(s * 0.5, s * 0.5), position: Vector2(s * 0.25, s * 0.4)));
    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDead) return;
    if (_fleeTimer > 0) {
      _fleeTimer -= dt;
      final player = gameRef.player;
      if (player != null) {
        final away = absoluteCenter - player.absoluteCenter;
        moveFromAngle(atan2(away.y, away.x), speed: speed * 2.2);
      }
      if (_fleeTimer <= 0) stopMove();
    } else {
      runRandomMovement(dt, speed: speed, maxDistance: 60, minDistance: 20);
      _bark.update(dt, this, Lines.villager, Colors.white);
    }
  }

  @override
  void onReceiveDamage(AttackOriginEnum attacker, double damage, identify) {
    if (attacker == AttackOriginEnum.PLAYER_OR_ALLY) {
      Wanted.instance.addHeat(9);
      if (_fleeTimer <= 0) {
        BarkTimer.shout(this, Lines.villagerScared, const Color(0xFFFFCDD2));
        GameAudio.gasp();
      }
      _fleeTimer = 3.5;
    }
    super.onReceiveDamage(attacker, damage, identify);
  }

  @override
  void onDie() {
    Wanted.instance.addHeat(16);
    Wanted.instance.addKill();
    removeFromParent();
    super.onDie();
  }
}

/// 산적(고블린) — 발견 시 추격해 약탈. 처치 시 골드.
class Bandit extends SimpleEnemy with BlockMovementCollision {
  static const double s = 22;
  final _bark = BarkTimer(min: 5, max: 10);

  Bandit(Vector2 position)
      : super(
          position: position,
          animation: GoblinSprites.animation(),
          size: Vector2.all(s),
          speed: s * 1.9,
          life: 55,
          initDirection: Direction.down,
        );

  @override
  Future<void> onLoad() {
    add(RectangleHitbox(size: Vector2(s * 0.5, s * 0.5), position: Vector2(s * 0.25, s * 0.4)));
    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDead) return;
    _bark.update(dt, this, Lines.bandit, const Color(0xFFFFAB91));
    if (!GameState.running) return;
    seeAndMoveToPlayer(
      radiusVision: s * 7,
      margin: 4,
      closePlayer: (player) {
        animation?.showStroke(const Color(0xFFFF5252), 1);
        simpleAttackMelee(
          damage: 9,
          size: Vector2.all(s),
          interval: 950,
          withPush: false,
          animationRight: GoblinSprites.attackEffectRight,
          execute: GameAudio.hit,
        );
      },
      notObserved: () {
        animation?.hideStroke();
        return true;
      },
    );
  }

  @override
  void onDie() {
    Wanted.instance.addGold(20 + _rng.nextInt(20));
    Wanted.instance.addKill();
    GameAudio.coin();
    removeFromParent();
    super.onDie();
  }
}

/// 괴물(오크) — 더 강하고 끈질김. 처치 시 골드 + 위업(악명 없음).
class Monster extends SimpleEnemy with BlockMovementCollision {
  static const double s = 28;
  final _bark = BarkTimer(min: 4, max: 8);

  Monster(Vector2 position, {String path = 'orc.png'})
      : super(
          position: position,
          animation: PersonSprites(path: path).animation(),
          size: Vector2.all(s),
          speed: s * 1.7,
          life: 110,
          initDirection: Direction.down,
        );

  @override
  Future<void> onLoad() {
    add(RectangleHitbox(size: Vector2(s * 0.45, s * 0.5), position: Vector2(s * 0.28, s * 0.42)));
    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDead) return;
    _bark.update(dt, this, Lines.monster, const Color(0xFFA5D6A7));
    if (!GameState.running) return;
    seeAndMoveToPlayer(
      radiusVision: s * 8,
      margin: 4,
      closePlayer: (player) {
        animation?.showStroke(const Color(0xFF8BC34A), 1);
        simpleAttackMelee(
          damage: 18,
          size: Vector2.all(s),
          interval: 1000,
          withPush: true,
          execute: GameAudio.hit,
        );
      },
      notObserved: () {
        animation?.hideStroke();
        return true;
      },
    );
  }

  @override
  void onDie() {
    Wanted.instance.addGold(35 + _rng.nextInt(40));
    Wanted.instance.addKill();
    GameAudio.coin();
    removeFromParent();
    super.onDie();
  }
}

/// 경비병(휴먼 병사) — 악명에 따라 출동, 플레이어를 추격/제압. 수배 풀리면 철수.
class Guard extends SimpleEnemy with BlockMovementCollision {
  static const double s = 26;
  bool _counted = false;
  final _bark = BarkTimer(min: 4, max: 8);

  Guard(Vector2 position)
      : super(
          position: position,
          animation: PersonSprites(path: 'orc2.png').animation(),
          size: Vector2.all(s),
          speed: s * 2.2,
          life: 85,
          initDirection: Direction.down,
        );

  @override
  Future<void> onLoad() {
    _counted = true;
    Wanted.instance.activeCops++;
    add(RectangleHitbox(size: Vector2(s * 0.45, s * 0.5), position: Vector2(s * 0.28, s * 0.42)));
    return super.onLoad();
  }

  void _release() {
    if (_counted) {
      _counted = false;
      Wanted.instance.activeCops = (Wanted.instance.activeCops - 1).clamp(0, 9999);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDead) return;
    if (Wanted.instance.starCount == 0) {
      _release();
      removeFromParent();
      return;
    }
    _bark.update(dt, this, Lines.guard, const Color(0xFF90CAF9));
    if (!GameState.running) return;
    seeAndMoveToPlayer(
      radiusVision: s * 12,
      margin: 4,
      runOnlyVisibleInScreen: false,
      closePlayer: (player) {
        animation?.showStroke(const Color(0xFF42A5F5), 1);
        simpleAttackMelee(
          damage: 15,
          size: Vector2.all(s),
          interval: 800,
          withPush: true,
          execute: GameAudio.hit,
        );
      },
      notObserved: () {
        animation?.hideStroke();
        return true;
      },
    );
  }

  @override
  void onDie() {
    _release();
    Wanted.instance.addKill();
    Wanted.instance.addHeat(10); // 경비병 살해 → 악명 상승
    removeFromParent();
    super.onDie();
  }

  @override
  void onRemove() {
    _release();
    super.onRemove();
  }
}

/// 집 안 가족 구성원(휴먼) — 침입자(플레이어)를 보면 놀라 뒤로 물러선다.
/// 공격받으면 분노해 맞서 싸운다.
class FamilyMember extends SimpleEnemy with RandomMovement {
  static const double s = 22;
  bool _hostile = false;
  bool _alarmed = false;
  double _cooldown = 0;
  final _bark = BarkTimer(min: 3.5, max: 7);

  FamilyMember(Vector2 position, {String path = 'human.png'})
      : super(
          position: position,
          animation: PersonSprites(path: path).animation(),
          size: Vector2.all(s),
          speed: s * 1.8,
          life: 50,
          initDirection: Direction.down,
        );

  @override
  Future<void> onLoad() {
    add(RectangleHitbox(size: Vector2(s * 0.45, s * 0.5), position: Vector2(s * 0.28, s * 0.42)));
    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDead || !GameState.running) return;
    final player = gameRef.player;
    if (player == null) return;
    final dist = absoluteCenter.distanceTo(player.absoluteCenter);

    if (_hostile) {
      // 분노 → 맞서 싸움
      _bark.update(dt, this, Lines.bandit, const Color(0xFFFF8A80));
      seeAndMoveToPlayer(
        radiusVision: s * 14,
        margin: 3,
        runOnlyVisibleInScreen: false,
        closePlayer: (p) {
          animation?.showStroke(const Color(0xFFFF5252), 1);
          simpleAttackMelee(
            damage: 10,
            size: Vector2.all(s),
            interval: 900,
            withPush: true,
            execute: GameAudio.hit,
          );
        },
        notObserved: () => true,
      );
      return;
    }

    // 침입자 발견 → 놀람 + 뒤로 물러섬
    if (dist < s * 5) {
      if (!_alarmed) {
        _alarmed = true;
        GameAudio.intruder();
        BarkTimer.shout(this, Lines.family, const Color(0xFFFFF59D));
      }
      final away = absoluteCenter - player.absoluteCenter;
      moveFromAngle(atan2(away.y, away.x), speed: speed);
      _cooldown = 1.2;
    } else {
      _alarmed = false;
      if (_cooldown > 0) {
        _cooldown -= dt;
        stopMove();
      } else {
        runRandomMovement(dt, speed: speed * 0.7, maxDistance: 32, minDistance: 12);
        _bark.update(dt, this, Lines.family, const Color(0xFFFFF59D));
      }
    }
  }

  @override
  void onReceiveDamage(AttackOriginEnum attacker, double damage, identify) {
    if (attacker == AttackOriginEnum.PLAYER_OR_ALLY && !_hostile) {
      _hostile = true;
      Wanted.instance.addHeat(12);
      BarkTimer.shout(this, Lines.villagerScared, const Color(0xFFFF8A80));
    }
    super.onReceiveDamage(attacker, damage, identify);
  }

  @override
  void onDie() {
    Wanted.instance.addHeat(20);
    Wanted.instance.addKill();
    removeFromParent();
    super.onDie();
  }
}
