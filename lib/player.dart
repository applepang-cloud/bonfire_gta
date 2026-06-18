import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audio.dart';
import 'events.dart';
import 'sprites.dart';
import 'wanted.dart';

/// 공격 액션 ID.
enum PlayerAction { attack }

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
    // 발 부분만 충돌 → 자연스러운 탑다운 이동.
    add(RectangleHitbox(
      size: Vector2(tile * 0.5, tile * 0.4),
      position: Vector2(tile * 0.25, tile * 0.55),
    ));
    return super.onLoad();
  }

  void heal(double v) => addLife(v);

  @override
  void onJoystickAction(JoystickActionEvent event) {
    if (isDead) return;
    final isAttack = event.id == PlayerAction.attack ||
        event.id == LogicalKeyboardKey.shiftRight;
    if (isAttack && event.event == ActionEvent.DOWN) {
      _meleeAttack();
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
