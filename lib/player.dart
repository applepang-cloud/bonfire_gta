import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audio.dart';
import 'choice.dart';
import 'events.dart';
import 'faction.dart';
import 'input.dart';
import 'profile.dart';
import 'sprites.dart';
import 'ui_bus.dart';
import 'wanted.dart';

/// 공격 액션 ID.
enum PlayerAction { attack, attackRange }

/// 플레이어(기사). 조이스틱 + 키보드(WASD/방향키 이동, Space 공격).
/// 사망하면 Busted 상태로 전환되어 게임 화면이 리스폰을 띄운다.
class GtaPlayer extends SimplePlayer with BlockMovementCollision {
  static const double tile = 24;

  double attackPower = 25;
  bool _busted = false;
  double _invuln = 0; // 리스폰 직후 무적 시간

  GtaPlayer(Vector2 position)
      : super(
          animation: PlayerSprites.animation(),
          size: Vector2.all(tile),
          position: position,
          speed: tile * 3.2,
          life: 150,
        ) {
    setupMovementByJoystick(intensityEnabled: true);
  }

  @override
  Future<void> onLoad() {
    _invuln = 3.0; // 스폰 직후 무적 3초
    applyStats();
    // 발 부분만 충돌 → 자연스러운 탑다운 이동.
    add(RectangleHitbox(
      size: Vector2(tile * 0.5, tile * 0.4),
      position: Vector2(tile * 0.25, tile * 0.55),
    ));
    return super.onLoad();
  }

  /// Profile(레벨/장비)에 따라 체력·공격력 재계산. 구매 시에도 호출(완전 회복).
  void applyStats() {
    final p = Profile.instance;
    initialLife(150 + p.hpBonus); // maxLife 갱신 + 완전 회복
    attackPower = 25 + p.atkBonus;
  }

  void heal(double v) => addLife(v);

  bool get _menuOpen =>
      UiBus.instance.panel.value != Panel.none ||
      ChoiceBus.instance.request.value != null;

  // 마우스 클릭에서 호출(가드 포함).
  void mouseMelee() {
    if (!isDead && GameState.running && !_menuOpen) _meleeAttack();
  }

  void mouseRanged() {
    if (!isDead && GameState.running && !_menuOpen) _rangedAttack();
  }

  @override
  void onMount() {
    super.onMount();
    PlayerActions.instance.melee = mouseMelee;
    PlayerActions.instance.ranged = mouseRanged;
  }

  @override
  void onRemove() {
    PlayerActions.instance.melee = null;
    PlayerActions.instance.ranged = null;
    super.onRemove();
  }

  @override
  void onJoystickChangeDirectional(JoystickDirectionalEvent event) {
    if (_menuOpen) {
      stopMove();
      return;
    }
    super.onJoystickChangeDirectional(event);
  }

  @override
  void onJoystickAction(JoystickActionEvent event) {
    if (isDead) {
      super.onJoystickAction(event);
      return;
    }
    if (event.event == ActionEvent.DOWN) {
      final id = event.id;
      if (_menuOpen) {
        if (id is LogicalKeyboardKey) MenuKeys.instance.dispatch(id);
      } else if (id == LogicalKeyboardKey.keyE) {
        Interaction.instance.activate(); // 대화/입장
      } else if (GameState.running) {
        if (id == PlayerAction.attackRange) {
          _rangedAttack();
        } else if (id == LogicalKeyboardKey.shiftRight ||
            id == PlayerAction.attack) {
          _meleeAttack();
        }
      }
    }
    super.onJoystickAction(event);
  }

  void _meleeAttack() {
    GameAudio.swing();
    GameAudio.kiai();
    simpleAttackMelee(
      damage: attackPower,
      size: Vector2.all(tile),
      animationRight: PlayerSprites.attackEffectRight,
      withPush: true,
    );
  }

  void _rangedAttack() {
    if (!Profile.instance.hasBow) return;
    GameAudio.swing();
    simpleAttackRange(
      animationRight: PlayerSprites.fireballRight,
      animationDestroy: PlayerSprites.explosion,
      size: Vector2.all(tile * 0.7),
      destroySize: Vector2.all(tile),
      speed: tile * 8,
      damage: 14 + attackPower * 0.5,
    );
  }

  @override
  void onReceiveDamage(AttackOriginEnum attacker, double damage, identify) {
    if (!GameState.running || _invuln > 0) return;
    super.onReceiveDamage(attacker, damage, identify);
  }

  @override
  void onRemoveLife(double life) {
    showDamage(
      life,
      config: TextStyle(
        fontFamily: 'Galmuri11',
        fontSize: 9,
        color: Colors.red.shade300,
      ),
    );
    super.onRemoveLife(life);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_invuln > 0) _invuln -= dt;
    Wanted.instance.tick(dt);
    FactionState.instance.tick(dt);
    Wanted.instance.setHealth(maxLife == 0 ? 0 : life / maxLife);
  }

  @override
  void onDie() {
    if (_busted) return;
    _busted = true;
    Wanted.instance.onBusted();
    gameRef.add(
      GameDecoration.withSprite(
        sprite: Fx.crypt,
        position: position.clone(),
        size: Vector2.all(tile),
      ),
    );
    removeFromParent();
    super.onDie();
  }
}
