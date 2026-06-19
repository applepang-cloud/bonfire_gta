import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';

import 'player.dart';
import 'profile.dart';
import 'sprites.dart';
import 'wanted.dart';

/// 나무 — 충돌 데코(공원/블록 채우기용).
class Tree extends GameDecorationWithCollision {
  Tree(Vector2 position, double tile)
      : super.withSprite(
          sprite: Sprite.load('tile_random/tree.png'),
          position: position,
          size: Vector2(tile * 2, tile * 1.6),
          collisions: [
            RectangleHitbox(
              size: Vector2(tile * 0.9, tile * 0.5),
              position: Vector2(tile * 0.55, tile * 1.0),
            ),
          ],
        );

  @override
  bool onComponentTypeCheck(PositionComponent other) {
    if (other is Tree) return false;
    return super.onComponentTypeCheck(other);
  }
}

/// 건물/구조물 프롭 — 충돌 데코. 도시 블록을 채워 길을 만든다.
class Building extends GameDecorationWithCollision {
  Building({
    required Future<Sprite> sprite,
    required Vector2 position,
    required Vector2 size,
  }) : super.withSprite(
          sprite: sprite,
          position: position,
          size: size,
          collisions: [RectangleHitbox(size: size)],
        );
}

/// 돈 상자 — 밟으면 돈 획득.
class MoneyChest extends GameDecoration with Sensor<Player> {
  final int amount;
  bool _taken = false;

  MoneyChest(Vector2 position, double tile, {this.amount = 50})
      : super.withAnimation(
          animation: Fx.chestAnimated,
          position: position,
          size: Vector2.all(tile),
        );

  @override
  void onContact(Player component) {
    if (_taken) return;
    _taken = true;
    Wanted.instance.addMoney(amount);
    Profile.instance.save();
    _popup('+$amount G', Colors.amber);
    removeFromParent();
  }

  void _popup(String text, Color color) {
    gameRef.add(
      TextGameObject(
        position: position.clone(),
        text: text,
        color: color,
      ),
    );
  }
}

/// 생명 물약 — 밟으면 회복.
class PotionPickup extends GameDecoration with Sensor<Player> {
  final double heal;
  bool _taken = false;

  PotionPickup(Vector2 position, double tile, {this.heal = 40})
      : super.withSprite(
          sprite: Fx.potion,
          position: position,
          size: Vector2.all(tile * 0.8),
        );

  @override
  void onContact(Player component) {
    if (_taken) return;
    if (component is GtaPlayer && component.life < component.maxLife) {
      _taken = true;
      component.heal(heal);
      gameRef.add(
        TextGameObject(
          position: position.clone(),
          text: '+${heal.toInt()} HP',
          color: Colors.greenAccent,
        ),
      );
      removeFromParent();
    }
  }
}

/// 떠올랐다가 사라지는 짧은 텍스트(획득 피드백).
class TextGameObject extends TextComponent {
  double _life = 0.9;
  TextGameObject({
    required Vector2 position,
    required String text,
    required Color color,
  }) : super(
          text: text,
          position: position,
          priority: 1000000,
          textRenderer: TextPaint(
            style: TextStyle(
              fontFamily: 'Galmuri11',
              fontSize: 8,
              color: color,
              shadows: const [Shadow(blurRadius: 2, color: Colors.black)],
            ),
          ),
        );

  @override
  void update(double dt) {
    super.update(dt);
    position.y -= 14 * dt;
    _life -= dt;
    if (_life <= 0) removeFromParent();
  }
}
