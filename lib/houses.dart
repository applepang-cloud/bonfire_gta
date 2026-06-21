import 'package:bonfire/bonfire.dart';

import 'events.dart';
import 'interact_sensor.dart';

/// 마을의 집(외부). 벽은 충돌, 정면 문 앞에서 E로 들어가면 내부로 전환된다.
class House extends GameDecorationWithCollision {
  final int seed;

  House({
    required Future<Sprite> sprite,
    required Vector2 position,
    required this.seed,
  }) : super.withSprite(
          sprite: sprite,
          position: position,
          size: Vector2(48, 56),
          collisions: [
            RectangleHitbox(size: Vector2(38, 20), position: Vector2(5, 2)),
            RectangleHitbox(size: Vector2(13, 33), position: Vector2(5, 22)),
            RectangleHitbox(size: Vector2(13, 33), position: Vector2(30, 22)),
          ],
        );

  @override
  Future<void> onLoad() {
    add(EntrySensor(
      position: Vector2(16, 38),
      size: Vector2(16, 20),
      label: '집에 들어가기  (E)',
      onEnter: () =>
          GameEvents.instance.go('house', position + Vector2(24, 78), seed),
    ));
    return super.onLoad();
  }
}
