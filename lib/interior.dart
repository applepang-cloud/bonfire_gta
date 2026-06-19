import 'dart:math';

import 'package:bonfire/bonfire.dart';

import 'events.dart';
import 'npcs.dart';

/// 집 내부 — 가구가 갖춰진 가정집. 가족이 살며 돌아다닌다.
/// 아래쪽 러그(출구)로 나가면 마을로.
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
  })  : w = 16,
        h = 12 {
    _generate();
  }

  Vector2 _px(double x, double y) => Vector2(x, y);

  void _decor(String sprite, Vector2 pos, Vector2 size) {
    components.add(GameDecoration.withSprite(
      sprite: Sprite.load(sprite),
      position: pos,
      size: size,
    ));
  }

  void _solid(String sprite, Vector2 pos, Vector2 size, Vector2 colSize,
      Vector2 colPos) {
    components.add(GameDecorationWithCollision.withSprite(
      sprite: Sprite.load(sprite),
      position: pos,
      size: size,
      collisions: [RectangleHitbox(size: colSize, position: colPos)],
    ));
  }

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
    final t = tile;

    // 아래 벽 가운데에 문 개구부(NPC가 도망쳐 나갈 수 있게).
    matrix[cx][h - 1] = floor;
    final doorPos = _px(cx * t + t / 2, (h - 1) * t + t / 2);

    // 출구(아래 가운데): 러그 + 센서.
    _decor('build/rug.png', _px(cx * t, (h - 2) * t), Vector2.all(t));
    components.add(_ExitSensor(
      position: _px(cx * t, (h - 2) * t),
      size: Vector2.all(t),
      returnSpawn: returnSpawn,
    ));
    // 플레이어는 출구에서 두 칸 이상 위에서 시작(겹침 방지).
    playerSpawn = _px(cx * t + t / 2, (h - 5) * t + t / 2);

    // 벽난로(위벽 가운데).
    _solid('build/hearth.png', _px(cx * t - 8, 2), Vector2(16, 22),
        Vector2(14, 8), Vector2(1, 12));

    // 침대(좌상단).
    _solid('build/bed.png', _px(t + 2, t + 4), Vector2(28, 18),
        Vector2(28, 14), Vector2(0, 4));

    // 식탁 + 의자(가운데).
    _solid('itens/table.png', _px(cx * t - 8, 5 * t), Vector2.all(16),
        Vector2.all(14), Vector2(1, 1));
    _decor('build/chair.png', _px(cx * t - 22, 5 * t + 2), Vector2(10, 12));
    _decor('build/chair.png', _px(cx * t + 14, 5 * t + 2), Vector2(10, 12));

    // 책장/찬장(우측 벽), 통, 화분.
    _solid('itens/bookshelf.png', _px((w - 3) * t, 2 * t), Vector2.all(16),
        Vector2.all(15), Vector2(0.5, 0.5));
    _solid('itens/barrel.png', _px(t + 2, (h - 3) * t), Vector2.all(16),
        Vector2.all(14), Vector2(1, 1));
    _decor('build/plant.png', _px((w - 3) * t + 2, t + 2), Vector2(12, 14));

    // 가족(3~4명) — 성향을 다양하게 섞어 배치.
    final count = 3 + rng.nextInt(2);
    final spots = [
      _px(3 * t, 3 * t),
      _px((w - 4) * t, 4 * t),
      _px(4 * t, (h - 4) * t),
      _px((w - 5) * t, (h - 4) * t),
    ];
    final reactions = [
      FamilyReaction.welcome,
      FamilyReaction.fear,
      FamilyReaction.ask,
      FamilyReaction.chat,
      FamilyReaction.busy,
    ]..shuffle(rng);
    for (var i = 0; i < count; i++) {
      components.add(FamilyMember(
        spots[i % spots.length] + Vector2(t / 2, t / 2),
        path: i.isEven ? 'human.png' : 'orc.png',
        reaction: reactions[i % reactions.length],
        doorPos: doorPos,
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
  double _ignore = 0.9; // 진입 직후 잠깐은 무시(스폰 겹침 방지)

  _ExitSensor({
    required Vector2 position,
    required Vector2 size,
    required this.returnSpawn,
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
    GameEvents.instance.go('overworld', returnSpawn, 0);
  }
}
