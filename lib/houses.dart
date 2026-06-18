import 'package:bonfire/bonfire.dart';

import 'events.dart';

/// 마을의 집(외부). 벽은 충돌, 정면 문에는 센서가 있어 들어가면 내부로 전환된다.
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
          // 문(가운데 아래)을 제외한 벽/지붕만 충돌.
          collisions: [
            RectangleHitbox(size: Vector2(38, 20), position: Vector2(5, 2)), // 지붕
            RectangleHitbox(size: Vector2(13, 33), position: Vector2(5, 22)), // 좌벽
            RectangleHitbox(size: Vector2(13, 33), position: Vector2(30, 22)), // 우벽
          ],
        );

  @override
  Future<void> onLoad() {
    // 문 센서(가운데 아래). 밟으면 내부로.
    add(_DoorSensor(
      position: Vector2(18, 40),
      size: Vector2(12, 18),
      seed: seed,
      // 돌아올 위치: 문 아래쪽 마당(센서와 겹치지 않게 충분히 아래).
      returnSpawn: position + Vector2(24, 78),
    ));
    return super.onLoad();
  }
}

class _DoorSensor extends GameComponent with Sensor<Player> {
  final int seed;
  final Vector2 returnSpawn;
  bool _used = false;

  _DoorSensor({
    required Vector2 position,
    required Vector2 size,
    required this.seed,
    required this.returnSpawn,
  }) {
    this.position = position;
    this.size = size;
  }

  @override
  void onContact(Player component) {
    if (_used) return;
    _used = true;
    GameEvents.instance.go('house', returnSpawn, seed);
  }
}
