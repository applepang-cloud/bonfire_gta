import 'dart:math';

import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';

import 'audio.dart';
import 'dialogue.dart';
import 'events.dart';
import 'sprites.dart';
import 'wanted.dart';

final _rng = Random();

/// 마을 사람(작은 크리터) — 일터로 오가는 듯 목적지를 향해 걷고, 멈춰 잡담한다.
/// 공격받으면 비명 지르며 도주. 해치면 악명(수배)이 오른다.
class Villager extends SimpleEnemy with RandomMovement, BlockMovementCollision {
  static const double s = 16;
  double _fleeTimer = 0;
  bool _traveling = false;
  Vector2 _dest = Vector2.zero();
  double _phaseT = 0;
  final _bark = BarkTimer();

  Villager(Vector2 position)
      : super(
          position: position,
          animation: CivilianSprites.animation(),
          size: Vector2.all(s),
          speed: s * (1.4 + _rng.nextDouble() * 0.5),
          life: 24,
          initDirection: Direction.down,
        ) {
    _phaseT = _rng.nextDouble() * 3;
  }

  @override
  Future<void> onLoad() {
    add(RectangleHitbox(size: Vector2(s * 0.5, s * 0.5), position: Vector2(s * 0.25, s * 0.4)));
    return super.onLoad();
  }

  void _pickDestination() {
    final a = _rng.nextDouble() * pi * 2;
    final dist = 90 + _rng.nextDouble() * 160;
    _dest = absoluteCenter + Vector2(cos(a), sin(a)) * dist;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDead) return;

    // 공격받음 → 도주.
    if (_fleeTimer > 0) {
      _fleeTimer -= dt;
      final player = gameRef.player;
      if (player != null) {
        final away = absoluteCenter - player.absoluteCenter;
        moveFromAngle(atan2(away.y, away.x), speed: speed * 2.2);
      }
      if (_fleeTimer <= 0) stopMove();
      return;
    }

    _phaseT -= dt;
    if (_traveling) {
      final d = _dest - absoluteCenter;
      if (d.length < 12 || _phaseT <= 0) {
        _traveling = false;
        _phaseT = 1.5 + _rng.nextDouble() * 3; // 도착 후 잠시 머무름
        stopMove();
      } else {
        moveFromAngle(atan2(d.y, d.x), speed: speed);
      }
    } else {
      _bark.update(dt, this, Lines.villager, Colors.white);
      if (_phaseT <= 0) {
        _pickDestination();
        _traveling = true;
        _phaseT = 3 + _rng.nextDouble() * 4; // 이동 시간 제한(막히면 포기)
      } else {
        runRandomMovement(dt, speed: speed * 0.6, maxDistance: 28, minDistance: 12);
      }
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

/// 집 안 가족의 반응 성향.
enum FamilyReaction { welcome, chat, ask, fear, busy }

/// 집 안 가족 구성원(휴먼) — 성향에 따라 반기거나, 말 걸거나, 캐묻거나,
/// 놀라 문으로 도망치거나, 제 일을 한다. 공격받으면 분노해 맞서 싸운다.
/// 벽은 통과 못 하고(BlockMovementCollision) 바닥에서만 움직이며, 문으로만 나갈 수 있다.
class FamilyMember extends SimpleEnemy with RandomMovement, BlockMovementCollision {
  static const double s = 22;
  final FamilyReaction reaction;
  final Vector2? doorPos; // 도망칠 문 위치(있으면 그쪽으로)

  bool _hostile = false;
  bool _greeted = false;
  final BarkTimer _bark;

  FamilyMember(
    Vector2 position, {
    String path = 'human.png',
    this.reaction = FamilyReaction.ask,
    this.doorPos,
  })  : _bark = BarkTimer(min: 3, max: 6.5),
        super(
          position: position,
          animation: PersonSprites(path: path).animation(),
          size: Vector2.all(s),
          speed: s * 1.7,
          life: 50,
          initDirection: Direction.down,
        );

  @override
  Future<void> onLoad() {
    add(RectangleHitbox(
        size: Vector2(s * 0.45, s * 0.5), position: Vector2(s * 0.28, s * 0.42)));
    return super.onLoad();
  }

  void _moveToward(Vector2 target, {double? speed}) {
    final d = target - absoluteCenter;
    moveFromAngle(atan2(d.y, d.x), speed: speed ?? this.speed);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDead || !GameState.running) return;
    final player = gameRef.player;
    if (player == null) return;
    final dist = absoluteCenter.distanceTo(player.absoluteCenter);

    // 분노 → 맞서 싸움.
    if (_hostile) {
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

    final near = dist < s * 6;

    switch (reaction) {
      case FamilyReaction.fear:
        if (near) {
          if (!_greeted) {
            _greeted = true;
            GameAudio.intruder();
          }
          _bark.update(dt, this, Lines.familyFear, const Color(0xFFFFCDD2));
          // 문이 있으면 문으로, 없으면 플레이어 반대로.
          if (doorPos != null) {
            _moveToward(doorPos!, speed: speed * 1.4);
            if (absoluteCenter.y > doorPos!.y + s * 0.4) {
              removeFromParent(); // 문 밖으로 빠져나감
            }
          } else {
            final away = absoluteCenter - player.absoluteCenter;
            moveFromAngle(atan2(away.y, away.x), speed: speed * 1.4);
          }
        } else {
          _idleChores(dt, Lines.familyBusy, const Color(0xFFFFF59D));
        }
        break;

      case FamilyReaction.welcome:
        if (near) {
          _bark.update(dt, this, Lines.familyWelcome, const Color(0xFFB9F6CA));
          if (dist > s * 2.5) {
            _moveToward(player.absoluteCenter);
          } else {
            stopMove();
          }
        } else {
          _idleChores(dt, Lines.familyWelcome, const Color(0xFFB9F6CA));
        }
        break;

      case FamilyReaction.chat:
        if (near) {
          _bark.update(dt, this, Lines.familyChat, const Color(0xFFB3E5FC));
          if (dist > s * 2.2) {
            _moveToward(player.absoluteCenter, speed: speed * 0.9);
          } else {
            stopMove();
          }
        } else {
          _idleChores(dt, Lines.familyChat, const Color(0xFFB3E5FC));
        }
        break;

      case FamilyReaction.ask:
        if (near) {
          stopMove(); // 멈춰서 캐묻는다
          _bark.update(dt, this, Lines.familyAsk, const Color(0xFFFFF59D));
        } else {
          _idleChores(dt, Lines.familyAsk, const Color(0xFFFFF59D));
        }
        break;

      case FamilyReaction.busy:
        _idleChores(dt, Lines.familyBusy, const Color(0xFFE0E0E0)); // 제 일만
        break;
    }
  }

  void _idleChores(double dt, List<String> pool, Color color) {
    runRandomMovement(dt, speed: speed * 0.55, maxDistance: 26, minDistance: 10);
    _bark.update(dt, this, pool, color);
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
