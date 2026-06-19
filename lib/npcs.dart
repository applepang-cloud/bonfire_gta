import 'dart:math';

import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';

import 'audio.dart';
import 'dialogue.dart';
import 'events.dart';
import 'faction.dart';
import 'profile.dart';
import 'quests.dart';
import 'sprites.dart';
import 'wanted.dart';

final _rng = Random();

double _hpMul() => Profile.instance.enemyHpMul;
double _dmg(double base) => base * Profile.instance.enemyDmgMul;

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
        _phaseT = 1.5 + _rng.nextDouble() * 3;
        stopMove();
      } else {
        moveFromAngle(atan2(d.y, d.x), speed: speed);
      }
    } else {
      _bark.update(dt, this, Lines.villager, Colors.white);
      if (_phaseT <= 0) {
        _pickDestination();
        _traveling = true;
        _phaseT = 3 + _rng.nextDouble() * 4;
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

/// 조직(파벌)에 속한 적 베이스.
/// - 도발(피격)당하면 조직 전체가 플레이어를 추격(같은 조직 호출).
/// - 플레이어를 노리지 않을 땐, 사이 나쁜 조직(rival) 적과 마주치면 서로 싸운다.
abstract class FactionEnemy extends SimpleEnemy
    with RandomMovement, BlockMovementCollision {
  final Faction faction;
  final bool autoHostile; // 도발 없이도 플레이어를 추격하는가
  final double meleeDamage;
  final double vision;
  final bool ranged;
  final List<String> barkLines;
  final Color barkColor;
  final double hbFactor;

  final BarkTimer _bark;
  double _retarget = 0;
  FactionEnemy? _rival;
  bool _hitByPlayer = false;

  FactionEnemy({
    required Vector2 position,
    required SimpleDirectionAnimation animation,
    required double size,
    required double speed,
    required double life,
    required this.faction,
    required this.autoHostile,
    required this.meleeDamage,
    required this.vision,
    required this.barkLines,
    required this.barkColor,
    this.ranged = false,
    this.hbFactor = 0.5,
    double barkMin = 5,
    double barkMax = 9,
  })  : _bark = BarkTimer(min: barkMin, max: barkMax),
        super(
          position: position,
          animation: animation,
          size: Vector2.all(size),
          speed: speed,
          life: life,
          initDirection: Direction.down,
        );

  /// 처치 보상(서브클래스).
  void dropRewards();

  bool huntsPlayer() =>
      autoHostile ||
      FactionState.instance.isAlerted(faction) ||
      (faction == Faction.guard && Wanted.instance.starCount > 0);

  @override
  Future<void> onLoad() {
    final hb = size.x * hbFactor;
    add(RectangleHitbox(
        size: Vector2(hb, hb),
        position: Vector2((size.x - hb) / 2, size.y * 0.4)));
    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDead) return;
    _bark.update(dt, this, barkLines, barkColor);
    if (!GameState.running) return;

    if (huntsPlayer()) {
      _rival = null;
      _chasePlayer(dt);
      return;
    }
    // 플레이어를 안 노릴 때: 사이 나쁜 조직과 내전.
    _retarget -= dt;
    if (_retarget <= 0) {
      _retarget = 0.6;
      _rival = _findRival();
    }
    final r = _rival;
    if (r != null && !r.isDead && r.isMounted) {
      _fight(r, dt);
    } else {
      runRandomMovement(dt, speed: speed * 0.6, maxDistance: 40, minDistance: 16);
    }
  }

  void _chasePlayer(double dt) {
    if (ranged) {
      seeAndMoveToAttackRange(
        minDistanceFromPlayer: vision * 0.5,
        radiusVision: vision,
        positioned: (p) {
          animation?.showStroke(barkColor, 1);
          simpleAttackRange(
            animation: PlayerSprites.fireballRight,
            animationDestroy: PlayerSprites.explosion,
            size: size * 0.7,
            damage: _dmg(meleeDamage),
            speed: size.x * 7,
            interval: 1400,
            execute: GameAudio.swing,
          );
        },
        notObserved: () {
          animation?.hideStroke();
          return true;
        },
      );
    } else {
      seeAndMoveToPlayer(
        radiusVision: vision,
        margin: 4,
        runOnlyVisibleInScreen: false,
        closePlayer: (p) {
          animation?.showStroke(barkColor, 1);
          simpleAttackMelee(
            damage: _dmg(meleeDamage),
            size: size,
            interval: 950,
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
  }

  FactionEnemy? _findRival() {
    FactionEnemy? best;
    var bd = vision * vision;
    for (final e in gameRef.query<FactionEnemy>()) {
      if (identical(e, this) || e.isDead) continue;
      if (!FactionState.rivals(faction, e.faction)) continue;
      final d = absoluteCenter.distanceToSquared(e.absoluteCenter);
      if (d < bd) {
        bd = d;
        best = e;
      }
    }
    return best;
  }

  void _fight(FactionEnemy r, double dt) {
    final d = r.absoluteCenter - absoluteCenter;
    if (d.length > size.x * 0.85) {
      moveFromAngle(atan2(d.y, d.x), speed: speed * 0.9);
    } else {
      stopMove();
      if (checkInterval('infight', 700, dt)) {
        animation?.showStroke(barkColor, 1);
        r.removeLife(meleeDamage * 0.6); // 조직 간 직접 타격
        GameAudio.hit();
      }
    }
  }

  @override
  void onReceiveDamage(AttackOriginEnum attacker, double damage, identify) {
    if (attacker == AttackOriginEnum.PLAYER_OR_ALLY) {
      _hitByPlayer = true;
      FactionState.instance.alert(faction); // 조직 전체 도발 → 함께 추격
    }
    super.onReceiveDamage(attacker, damage, identify);
  }

  @override
  void onDie() {
    if (_hitByPlayer) dropRewards(); // 내전으로 죽으면 보상 없음
    removeFromParent();
    super.onDie();
  }
}

/// 산적(고블린) — 도발하면 조직 전체가 추격. 처치 시 골드/경험치.
class Bandit extends FactionEnemy {
  static const double s = 22;
  Bandit(Vector2 position)
      : super(
          position: position,
          animation: GoblinSprites.animation(),
          size: s,
          speed: s * 1.9,
          life: 55 * _hpMul(),
          faction: Faction.bandit,
          autoHostile: false,
          meleeDamage: 9,
          vision: s * 8,
          barkLines: Lines.bandit,
          barkColor: const Color(0xFFFFAB91),
        );

  @override
  void dropRewards() {
    Wanted.instance.addGold(20 + _rng.nextInt(20));
    Wanted.instance.addKill();
    Profile.instance.addXp(15);
    QuestLog.instance.onKill(QuestType.killBandit);
    GameAudio.coin();
  }
}

/// 궁수 산적 — 거리를 두고 마법 화살. 산적 조직.
class Archer extends FactionEnemy {
  static const double s = 22;
  Archer(Vector2 position)
      : super(
          position: position,
          animation: GoblinSprites.animation(),
          size: s,
          speed: s * 1.7,
          life: 38 * _hpMul(),
          faction: Faction.bandit,
          autoHostile: false,
          meleeDamage: 8,
          vision: s * 9,
          ranged: true,
          barkLines: Lines.bandit,
          barkColor: const Color(0xFFFFCC80),
        );

  @override
  void dropRewards() {
    Wanted.instance.addGold(22 + _rng.nextInt(20));
    Wanted.instance.addKill();
    Profile.instance.addXp(20);
    QuestLog.instance.onKill(QuestType.killBandit);
    GameAudio.coin();
  }
}

/// 괴물(오크) — 늘 플레이어를 노린다. 괴물 조직.
class Monster extends FactionEnemy {
  static const double s = 28;
  Monster(Vector2 position, {String path = 'orc.png'})
      : super(
          position: position,
          animation: PersonSprites(path: path).animation(),
          size: s,
          speed: s * 1.7,
          life: 110 * _hpMul(),
          faction: Faction.monster,
          autoHostile: true,
          meleeDamage: 18,
          vision: s * 8,
          barkLines: Lines.monster,
          barkColor: const Color(0xFFA5D6A7),
          hbFactor: 0.45,
        );

  @override
  void dropRewards() {
    Wanted.instance.addGold(35 + _rng.nextInt(40));
    Wanted.instance.addKill();
    Profile.instance.addXp(30);
    QuestLog.instance.onKill(QuestType.killMonster);
    GameAudio.coin();
  }
}

/// 오우거 — 크고 느리지만 매우 강하다. 괴물 조직.
class Ogre extends FactionEnemy {
  static const double s = 38;
  Ogre(Vector2 position)
      : super(
          position: position,
          animation: PersonSprites(path: 'orc.png').animation(),
          size: s,
          speed: s * 1.0,
          life: 280 * _hpMul(),
          faction: Faction.monster,
          autoHostile: true,
          meleeDamage: 30,
          vision: s * 7,
          barkLines: Lines.monster,
          barkColor: const Color(0xFF81C784),
          hbFactor: 0.5,
          barkMin: 4,
          barkMax: 8,
        );

  @override
  void dropRewards() {
    Wanted.instance.addGold(90 + _rng.nextInt(80));
    Wanted.instance.addKill();
    Profile.instance.addXp(60);
    QuestLog.instance.onKill(QuestType.killMonster);
    GameAudio.coin();
  }
}

/// 동굴 깡패 — 던전에 도사린 무리. 동굴 조직. 늘 적대적.
class CaveThug extends FactionEnemy {
  static const double s = 24;
  CaveThug(Vector2 position)
      : super(
          position: position,
          animation: GoblinSprites.animation(),
          size: s,
          speed: s * 2.0,
          life: 70 * _hpMul(),
          faction: Faction.cave,
          autoHostile: true,
          meleeDamage: 14,
          vision: s * 9,
          barkLines: Lines.thug,
          barkColor: const Color(0xFFEF9A9A),
        );

  @override
  void dropRewards() {
    Wanted.instance.addGold(28 + _rng.nextInt(28));
    Wanted.instance.addKill();
    Profile.instance.addXp(25);
    GameAudio.coin();
  }
}

/// 경비병 — 악명(수배)에 따라 출동. 법 조직. 수배 풀리면 철수.
class Guard extends FactionEnemy {
  static const double s = 26;
  bool _counted = false;

  Guard(Vector2 position)
      : super(
          position: position,
          animation: PersonSprites(path: 'orc2.png').animation(),
          size: s,
          speed: s * 2.2,
          life: 85 * _hpMul(),
          faction: Faction.guard,
          autoHostile: false,
          meleeDamage: 15,
          vision: s * 12,
          barkLines: Lines.guard,
          barkColor: const Color(0xFF90CAF9),
          hbFactor: 0.45,
        );

  @override
  Future<void> onLoad() {
    _counted = true;
    Wanted.instance.activeCops++;
    return super.onLoad();
  }

  void _release() {
    if (_counted) {
      _counted = false;
      Wanted.instance.activeCops =
          (Wanted.instance.activeCops - 1).clamp(0, 9999);
    }
  }

  @override
  void update(double dt) {
    if (!isDead && Wanted.instance.starCount == 0) {
      _release();
      removeFromParent();
      return;
    }
    super.update(dt);
  }

  @override
  void dropRewards() {
    Wanted.instance.addKill();
    Wanted.instance.addHeat(10);
    Profile.instance.addXp(20);
  }

  @override
  void onDie() {
    _release();
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
class FamilyMember extends SimpleEnemy with RandomMovement, BlockMovementCollision {
  static const double s = 22;
  final FamilyReaction reaction;
  final Vector2? doorPos;

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
          if (doorPos != null) {
            _moveToward(doorPos!, speed: speed * 1.4);
            if (absoluteCenter.y > doorPos!.y + s * 0.4) {
              removeFromParent();
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
          stopMove();
          _bark.update(dt, this, Lines.familyAsk, const Color(0xFFFFF59D));
        } else {
          _idleChores(dt, Lines.familyAsk, const Color(0xFFFFF59D));
        }
        break;
      case FamilyReaction.busy:
        _idleChores(dt, Lines.familyBusy, const Color(0xFFE0E0E0));
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
