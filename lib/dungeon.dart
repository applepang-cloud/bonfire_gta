import 'dart:math';

import 'package:bonfire/bonfire.dart';

import 'events.dart';
import 'npcs.dart';

/// 동굴 입구(오버월드). 정면 아래로 들어가면 던전 1층으로.
class CaveEntrance extends GameDecorationWithCollision {
  final int seed;
  CaveEntrance(Vector2 position, {this.seed = 7})
      : super.withSprite(
          sprite: Sprite.load('build/cave_entrance.png'),
          position: position,
          size: Vector2.all(32),
          collisions: [
            RectangleHitbox(size: Vector2(26, 12), position: Vector2(3, 8)),
          ],
        );

  @override
  Future<void> onLoad() {
    add(_CaveDoor(
      position: Vector2(11, 20),
      size: Vector2(10, 11),
      returnSpawn: position + Vector2(16, 40),
      seed: seed,
    ));
    return super.onLoad();
  }
}

class _CaveDoor extends GameComponent with Sensor<Player> {
  final Vector2 returnSpawn;
  final int seed;
  bool _used = false;
  _CaveDoor({
    required Vector2 position,
    required Vector2 size,
    required this.returnSpawn,
    required this.seed,
  }) {
    this.position = position;
    this.size = size;
  }

  @override
  void onContact(Player component) {
    if (_used) return;
    _used = true;
    GameEvents.instance.go('dungeon1', returnSpawn, seed);
  }
}

/// 던전 한 층. floor 1 → 아래로 내려가는 계단, floor 2 → 두목.
/// 둘 다 아래쪽 출구로 나가면 마을(또는 진행). 지형 0=벽, 1=바닥.
class Dungeon {
  static const double wall = 0;
  static const double floor = 1;

  final int floorNum;
  final int seed;
  final Vector2 overworldReturn;
  final double tile;
  final int w;
  final int h;

  late final List<List<double>> matrix;
  final List<GameComponent> components = [];
  late final Vector2 playerSpawn;

  Dungeon({
    required this.floorNum,
    required this.seed,
    required this.overworldReturn,
    this.tile = 16,
  })  : w = 22,
        h = 16 {
    _generate();
  }

  Vector2 _p(int x, int y) => Vector2(x * tile, y * tile);

  void _pillar(int x, int y) {
    components.add(GameDecorationWithCollision.withSprite(
      sprite: Sprite.load('build/cave_wall.png'),
      position: _p(x, y),
      size: Vector2.all(tile),
      collisions: [RectangleHitbox(size: Vector2.all(tile))],
    ));
  }

  void _generate() {
    final rng = Random(seed * 31 + floorNum);
    matrix = List.generate(
      w,
      (x) => List.generate(
        h,
        (y) => (x == 0 || y == 0 || x == w - 1 || y == h - 1) ? wall : floor,
      ),
    );
    final cx = w ~/ 2;

    // 기둥(엄폐물).
    for (var i = 0; i < 6; i++) {
      final px = 3 + rng.nextInt(w - 6);
      final py = 3 + rng.nextInt(h - 6);
      _pillar(px, py);
      if (rng.nextBool()) _pillar(px + 1, py);
    }

    // 아래쪽 출구(마을로). 러그 대신 계단 그림.
    components.add(GameDecoration.withSprite(
      sprite: Sprite.load('build/stairs_down.png'),
      position: _p(cx, h - 2),
      size: Vector2.all(tile),
    ));
    components.add(_Portal(
      position: _p(cx, h - 2),
      size: Vector2.all(tile),
      scene: 'overworld',
      spawn: overworldReturn,
      seed: 0,
    ));
    playerSpawn = _p(cx, h - 4) + Vector2(tile / 2, tile / 2);

    if (floorNum == 1) {
      // 위쪽: 더 깊은 곳으로 내려가는 계단.
      components.add(GameDecoration.withSprite(
        sprite: Sprite.load('build/stairs_down.png'),
        position: _p(cx, 1),
        size: Vector2.all(tile),
      ));
      components.add(_Portal(
        position: _p(cx, 1),
        size: Vector2.all(tile),
        scene: 'dungeon2',
        spawn: overworldReturn,
        seed: seed,
      ));
      // 깡패 무리.
      for (var i = 0; i < 5; i++) {
        components.add(CaveThug(_p(3 + rng.nextInt(w - 6), 3 + rng.nextInt(h - 7)) +
            Vector2(tile / 2, tile / 2)));
      }
    } else {
      // 2층: 더 많은 깡패 + 두목(오우거).
      for (var i = 0; i < 6; i++) {
        components.add(CaveThug(_p(3 + rng.nextInt(w - 6), 3 + rng.nextInt(h - 7)) +
            Vector2(tile / 2, tile / 2)));
      }
      components.add(Ogre(_p(cx, 2) + Vector2(tile / 2, tile / 2)));
    }
  }

  GameMap buildMap() {
    return MatrixMapGenerator.generate(
      layers: [MatrixLayer(matrix: matrix)],
      builder: (props) => TerrainBuilder(
        tileSize: tile,
        terrainList: [
          MapTerrain(
            value: wall,
            collisionsBuilder: () => [RectangleHitbox(size: Vector2.all(tile))],
            sprites: [
              TileSprite(path: 'build/cave_wall.png', size: Vector2.all(16)),
            ],
          ),
          MapTerrain(
            value: floor,
            sprites: [
              TileSprite(path: 'build/cave_floor.png', size: Vector2.all(16)),
            ],
          ),
        ],
      ).build(props),
    );
  }
}

/// 던전 내 이동 포털(계단/출구).
class _Portal extends GameComponent with Sensor<Player> {
  final String scene;
  final Vector2 spawn;
  final int seed;
  bool _used = false;
  double _ignore = 0.9;

  _Portal({
    required Vector2 position,
    required Vector2 size,
    required this.scene,
    required this.spawn,
    required this.seed,
  }) {
    this.position = position;
    this.size = size;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_ignore > 0) _ignore -= dt;
  }

  @override
  void onContact(Player component) {
    if (_used || _ignore > 0) return;
    _used = true;
    GameEvents.instance.go(scene, spawn, seed);
  }
}
