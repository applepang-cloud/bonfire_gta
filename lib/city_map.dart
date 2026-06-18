import 'dart:math';

import 'package:bonfire/bonfire.dart';

import 'collectibles.dart';
import 'sprites.dart';

/// 절차적 오픈월드 "도시" 생성기.
/// tile_random/tile_types.png(잔디/모래/물)로 지형을 깔고,
/// 모래(=도로)를 격자로 그어 블록을 만들고, 블록 안에 건물/공원/전리품을 배치한다.
/// 지형 값: 0 = 물(충돌), 1 = 모래(도로), 2 = 잔디(블록 바닥).
class CityWorld {
  static const double water = 0;
  static const double sand = 1;
  static const double grass = 2;

  final double tile;
  final int w;
  final int h;

  late final List<List<double>> matrix;
  final List<GameComponent> decorations = [];
  final List<Vector2> roadPoints = [];
  final Set<int> _occupied = {};
  late final Vector2 playerSpawn;

  CityWorld({this.tile = 16, this.w = 64, this.h = 64, required Random rng}) {
    _generate(rng);
  }

  int _key(int x, int y) => y * w + x;
  Vector2 _pos(int x, int y) => Vector2(x * tile, y * tile);
  bool _inBounds(int x, int y) => x >= 0 && y >= 0 && x < w && y < h;

  void _generate(Random rng) {
    // 1) 기본은 잔디.
    matrix = List.generate(w, (_) => List<double>.filled(h, grass));

    const step = 9; // 블록 간격
    const roadW = 2; // 도로 폭

    // 2) 도로 격자(모래).
    for (var x = 0; x < w; x++) {
      for (var y = 0; y < h; y++) {
        if (x % step < roadW || y % step < roadW) {
          matrix[x][y] = sand;
        }
      }
    }

    // 3) 연못 몇 개(물). 주변을 모래로 둘러 자연스러운 전환.
    for (var i = 0; i < 5; i++) {
      final cx = roadW + step + rng.nextInt(w - 2 * step);
      final cy = roadW + step + rng.nextInt(h - 2 * step);
      for (var dx = -1; dx <= 1; dx++) {
        for (var dy = -1; dy <= 1; dy++) {
          final x = cx + dx, y = cy + dy;
          if (_inBounds(x, y) && matrix[x][y] == grass) matrix[x][y] = water;
        }
      }
      for (var dx = -2; dx <= 2; dx++) {
        for (var dy = -2; dy <= 2; dy++) {
          final x = cx + dx, y = cy + dy;
          if (_inBounds(x, y) && matrix[x][y] == grass) matrix[x][y] = sand;
        }
      }
    }

    // 4) 맵 경계는 물 벽으로 막아 밖으로 못 나가게.
    for (var x = 0; x < w; x++) {
      matrix[x][0] = water;
      matrix[x][h - 1] = water;
    }
    for (var y = 0; y < h; y++) {
      matrix[0][y] = water;
      matrix[w - 1][y] = water;
    }

    // 5) 블록마다 건물/공원/빈터 배치.
    for (var bx = roadW; bx < w - step; bx += step) {
      for (var by = roadW; by < h - step; by += step) {
        final roll = rng.nextDouble();
        if (roll < 0.45) {
          _placeBuilding(bx, by, step - roadW, rng);
        } else if (roll < 0.75) {
          _placePark(bx, by, step - roadW, rng);
        }
      }
    }

    // 6) 도로 지점 수집(NPC 스폰용) + 7) 전리품 배치.
    for (var x = 1; x < w - 1; x++) {
      for (var y = 1; y < h - 1; y++) {
        if (matrix[x][y] == sand && (x + y) % 3 == 0) {
          roadPoints.add(_pos(x, y) + Vector2.all(tile / 2));
        }
      }
    }
    _scatterLoot(rng);

    // 플레이어는 중앙 부근 도로 교차점에서 시작.
    final sx = ((w ~/ 2) ~/ step) * step;
    final sy = ((h ~/ 2) ~/ step) * step;
    playerSpawn = _pos(sx, sy) + Vector2.all(tile / 2);
  }

  void _placeBuilding(int ox, int oy, int size, Random rng) {
    final bw = 2 + rng.nextInt(size - 2);
    final bh = 2 + rng.nextInt(size - 2);
    final sprites = [Fx.bookshelf, Fx.table, Fx.barrel];
    final sprite = sprites[rng.nextInt(sprites.length)];
    for (var x = ox; x < ox + bw; x++) {
      for (var y = oy; y < oy + bh; y++) {
        if (!_inBounds(x, y) || matrix[x][y] != grass) continue;
        _occupied.add(_key(x, y));
        decorations.add(Building(
          sprite: sprite,
          position: _pos(x, y),
          size: Vector2.all(tile),
        ));
      }
    }
  }

  void _placePark(int ox, int oy, int size, Random rng) {
    final count = 3 + rng.nextInt(5);
    for (var i = 0; i < count; i++) {
      final x = ox + rng.nextInt(size);
      final y = oy + rng.nextInt(size);
      if (!_inBounds(x, y) || matrix[x][y] != grass) continue;
      if (_occupied.contains(_key(x, y))) continue;
      _occupied.add(_key(x, y));
      decorations.add(Tree(_pos(x, y), tile));
    }
  }

  void _scatterLoot(Random rng) {
    var chests = 0, potions = 0;
    var tries = 0;
    while ((chests < 16 || potions < 10) && tries < 4000) {
      tries++;
      final x = 1 + rng.nextInt(w - 2);
      final y = 1 + rng.nextInt(h - 2);
      if (_occupied.contains(_key(x, y))) continue;
      final t = matrix[x][y];
      if (t == water) continue;
      _occupied.add(_key(x, y));
      final p = _pos(x, y) + Vector2.all(tile * 0.1);
      if (chests < 16 && rng.nextBool()) {
        decorations.add(MoneyChest(p, tile, amount: 25 + rng.nextInt(60)));
        chests++;
      } else if (potions < 10) {
        decorations.add(PotionPickup(p, tile, heal: 35));
        potions++;
      }
    }
  }

  /// MatrixMap 생성 — 지형 + 충돌(물).
  GameMap buildMap() {
    return MatrixMapGenerator.generate(
      layers: [MatrixLayer(matrix: matrix)],
      builder: (props) => TerrainBuilder(
        tileSize: tile,
        terrainList: [
          MapTerrain(
            value: water,
            collisionOnlyCloseCorners: true,
            collisionsBuilder: () => [RectangleHitbox(size: Vector2.all(tile))],
            sprites: [
              TileSprite(
                path: 'tile_random/tile_types.png',
                size: Vector2.all(16),
                position: Vector2(0, 1),
              ),
            ],
          ),
          MapTerrain(
            value: sand,
            sprites: [
              TileSprite(
                path: 'tile_random/tile_types.png',
                size: Vector2.all(16),
                position: Vector2(0, 2),
              ),
            ],
          ),
          MapTerrain(
            value: grass,
            spritesProportion: const [0.7, 0.3],
            sprites: [
              TileSprite(
                path: 'tile_random/tile_types.png',
                size: Vector2.all(16),
              ),
              TileSprite(
                path: 'tile_random/tile_types.png',
                size: Vector2.all(16),
                position: Vector2(1, 0),
              ),
            ],
          ),
          MapTerrainCorners(
            value: sand,
            to: water,
            spriteSheet: TerrainSpriteSheet.create(
              path: 'tile_random/earth_to_water.png',
              tileSize: Vector2.all(16),
            ),
          ),
          MapTerrainCorners(
            value: sand,
            to: grass,
            spriteSheet: TerrainSpriteSheet.create(
              path: 'tile_random/earth_to_grass.png',
              tileSize: Vector2.all(16),
            ),
          ),
        ],
      ).build(props),
    );
  }
}
