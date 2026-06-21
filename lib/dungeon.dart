import 'dart:math';

import 'package:bonfire/bonfire.dart';

import 'events.dart';
import 'interact_sensor.dart';
import 'npcs.dart';

/// 동굴 입구(오버월드). 정면 아래에서 E로 들어가면 던전 1층으로.
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
    add(EntrySensor(
      position: Vector2(9, 20),
      size: Vector2(14, 12),
      label: '동굴로 들어가기  (E)',
      onEnter: () =>
          GameEvents.instance.go('dungeon1', position + Vector2(16, 40), seed),
    ));
    return super.onLoad();
  }
}

/// 던전 한 층. floor 1 → 아래로 내려가는 계단, floor 2 → 두목 드래곤.
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

    for (var i = 0; i < 6; i++) {
      final px = 3 + rng.nextInt(w - 6);
      final py = 3 + rng.nextInt(h - 6);
      _pillar(px, py);
      if (rng.nextBool()) _pillar(px + 1, py);
    }

    // 아래쪽 출구(마을로).
    components.add(GameDecoration.withSprite(
      sprite: Sprite.load('build/stairs_down.png'),
      position: _p(cx, h - 2),
      size: Vector2.all(tile),
    ));
    components.add(EntrySensor(
      position: _p(cx, h - 2),
      size: Vector2.all(tile),
      label: '동굴 밖으로 나가기  (E)',
      onEnter: () => GameEvents.instance.go('overworld', overworldReturn, 0),
    ));
    playerSpawn = _p(cx, h - 4) + Vector2(tile / 2, tile / 2);

    if (floorNum == 1) {
      components.add(GameDecoration.withSprite(
        sprite: Sprite.load('build/stairs_down.png'),
        position: _p(cx, 1),
        size: Vector2.all(tile),
      ));
      components.add(EntrySensor(
        position: _p(cx, 1),
        size: Vector2.all(tile),
        label: '더 깊이 내려가기  (E)',
        onEnter: () =>
            GameEvents.instance.go('dungeon2', overworldReturn, seed),
      ));
      for (var i = 0; i < 5; i++) {
        components.add(CaveThug(
            _p(3 + rng.nextInt(w - 6), 3 + rng.nextInt(h - 7)) +
                Vector2(tile / 2, tile / 2)));
      }
    } else {
      // 2층: 깡패 무리 + 최종 보스 드래곤.
      for (var i = 0; i < 5; i++) {
        components.add(CaveThug(
            _p(3 + rng.nextInt(w - 6), 5 + rng.nextInt(h - 9)) +
                Vector2(tile / 2, tile / 2)));
      }
      components.add(Dragon(_p(cx - 2, 1)));
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
