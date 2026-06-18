import 'dart:math';

import 'package:bonfire/bonfire.dart';

import 'sprites.dart';
import 'wanted.dart';

/// 시민(크리터) — 길거리를 배회하다 공격받으면 패닉/도주.
/// 시민을 때리거나 죽이면 수배도가 오른다(GTA식).
class Civilian extends SimpleEnemy with RandomMovement {
  static const double s = 16;
  double _fleeTimer = 0;

  Civilian(Vector2 position)
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
    }
  }

  @override
  void onReceiveDamage(AttackOriginEnum attacker, double damage, identify) {
    if (attacker == AttackOriginEnum.PLAYER_OR_ALLY) {
      Wanted.instance.addHeat(9);
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

/// 갱단(고블린) — 플레이어를 발견하면 추격해 근접 공격. 처치 시 현상금($).
class Gangster extends SimpleEnemy with BlockMovementCollision {
  static const double s = 22;

  Gangster(Vector2 position)
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
    Wanted.instance.addMoney(25);
    Wanted.instance.addKill();
    removeFromParent();
    super.onDie();
  }
}

/// 경찰(휴먼형) — 수배도에 따라 스폰. 플레이어를 끈질기게 추격/공격.
/// 수배가 풀리면(별 0) 순찰을 멈추고 사라진다.
class Cop extends SimpleEnemy with BlockMovementCollision {
  static const double s = 26;
  bool _counted = false;

  Cop(Vector2 position)
      : super(
          position: position,
          animation: PersonSprites(path: 'orc2.png').animation(),
          size: Vector2.all(s),
          speed: s * 2.2,
          life: 80,
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
      Wanted.instance.activeCops =
          (Wanted.instance.activeCops - 1).clamp(0, 9999);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDead) return;
    // 수배 해제 → 철수.
    if (Wanted.instance.starCount == 0) {
      _release();
      removeFromParent();
      return;
    }
    seeAndMoveToPlayer(
      radiusVision: s * 12,
      margin: 4,
      runOnlyVisibleInScreen: false,
      closePlayer: (player) {
        animation?.showStroke(const Color(0xFF42A5F5), 1);
        simpleAttackMelee(
          damage: 16,
          size: Vector2.all(s),
          interval: 800,
          withPush: true,
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
    Wanted.instance.addHeat(10); // 경찰 살해 → 수배 상승
    removeFromParent();
    super.onDie();
  }

  @override
  void onRemove() {
    _release();
    super.onRemove();
  }
}
