import 'dart:math';

import 'package:bonfire/bonfire.dart';

import 'events.dart';
import 'npcs.dart';

/// 집 내부 — 돌벽으로 둘러싸인 방. 가족이 살고 있고, 아래쪽 출구로 나가면 마을로.
/// 지형 값: 0 = 돌벽(충돌), 1 = 나무 바닥.
class Interior {
  static const double wall = 0;
  static const double floor = 1;

  final double tile;
  final int seed;
  final Vector2 returnSpawn;
  final int w;
  final int h;

  late final List<List<double>> matrix;
  final List<GameComponent> components = [];
  late final Vector2 playerSpawn;

  Interior({
    this.tile = 16,
    required this.seed,
    required this.returnSpawn,
  })  : w = 14,
        h = 10 {
    _generate();
  }

  Vector2 _pos(int x, int y) => Vector2(x * tile, y * tile);

  void _generate() {
    final rng = Random(seed);
    matrix = List.generate(
      w,
      (x) => List.generate(
        h,
        (y) => (x == 0 || y == 0 || x == w - 1 || y == h - 1) ? wall : floor,
      ),
    );

    final cx = w ~/ 2;

    // 출구(아래 가운데) — 바닥에 러그를 깔고 센서 배치.
    components.add(
      GameDecoration.withSprite(
        sprite: Sprite.load('build/rug.png'),
        position: _pos(cx, h - 2),
        size: Vector2.all(tile),
      ),
    );
    components.add(_ExitSensor(
      position: _pos(cx, h - 2),
      size: Vector2.all(tile),
      returnSpawn: returnSpawn,
    ));
    playerSpawn = _pos(cx, h - 3) + Vector2(tile / 2, tile / 2);

    // 가구(통/탁자).
    components.add(GameDecorationWithCollision.withSprite(
      sprite: Sprite.load('itens/table.png'),
      position: _pos(2, 2),
      size: Vector2.all(tile),
      collisions: [RectangleHitbox(size: Vector2.all(tile))],
    ));
    components.add(GameDecorationWithCollision.withSprite(
      sprite: Sprite.load('itens/barrel.png'),
      position: _pos(w - 3, 2),
      size: Vector2.all(tile),
      collisions: [RectangleHitbox(size: Vector2.all(tile))],
    ));

    // 가족 2~4명.
    final count = 2 + rng.nextInt(3);
    final spots = [
      _pos(3, 3),
      _pos(w - 4, 4),
      _pos(4, h - 4),
      _pos(w - 5, h - 4),
    ];
    for (var i = 0; i < count; i++) {
      components.add(FamilyMember(
        spots[i % spots.length] + Vector2(tile / 2, tile / 2),
        path: i.isEven ? 'human.png' : 'orc.png',
      ));
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
              TileSprite(path: 'build/wall_stone.png', size: Vector2.all(16)),
            ],
          ),
          MapTerrain(
            value: floor,
            sprites: [
              TileSprite(path: 'build/floor_wood.png', size: Vector2.all(16)),
            ],
          ),
        ],
      ).build(props),
    );
  }
}

class _ExitSensor extends GameComponent with Sensor<Player> {
  final Vector2 returnSpawn;
  bool _used = false;

  _ExitSensor({
    required Vector2 position,
    required Vector2 size,
    required this.returnSpawn,
  }) {
    this.position = position;
    this.size = size;
  }

  @override
  void onContact(Player component) {
    if (_used) return;
    _used = true;
    GameEvents.instance.go('overworld', returnSpawn, 0);
  }
}
