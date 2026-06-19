import 'dart:math';

import 'package:bonfire/bonfire.dart';

import 'collectibles.dart';
import 'houses.dart';

/// 절차적 중세 마을(오버월드).
/// 잔디 평원에 흙길이 굽이치고, 강이 흐르며, 집들이 마을을 이루고 숲이 둘러싼다.
/// 지형 값: 0 = 물(충돌), 1 = 흙길, 2 = 잔디.
class VillageWorld {
  static const double water = 0;
  static const double dirt = 1;
  static const double grass = 2;

  final double tile;
  final int w;
  final int h;

  late final List<List<double>> matrix;
  final List<GameComponent> decorations = [];
  final List<Vector2> roadPoints = [];
  final Set<int> _occupied = {};
  late final Vector2 playerSpawn;

  VillageWorld({this.tile = 16, this.w = 64, this.h = 64, required Random rng}) {
    _generate(rng);
  }

  int _key(int x, int y) => y * w + x;
  Vector2 _pos(int x, int y) => Vector2(x * tile, y * tile);
  bool _in(int x, int y) => x >= 1 && y >= 1 && x < w - 1 && y < h - 1;
  void _occupy(int x, int y) => _occupied.add(_key(x, y));
  bool _free(int x, int y) => !_occupied.contains(_key(x, y));

  void _generate(Random rng) {
    matrix = List.generate(w, (_) => List<double>.filled(h, grass));

    // 경계: 물(못 나가게).
    for (var x = 0; x < w; x++) {
      matrix[x][0] = water;
      matrix[x][h - 1] = water;
    }
    for (var y = 0; y < h; y++) {
      matrix[0][y] = water;
      matrix[w - 1][y] = water;
    }

    // 자연스러운 물가: 굵은 강 + 호수 + 1칸 모래 해변.
    _carveWater(rng);

    // 시작 지점 주변은 물이 닿지 않게 정리.
    final sx0 = w ~/ 3, sy0 = h ~/ 2;
    for (var dx = -2; dx <= 2; dx++) {
      for (var dy = -2; dy <= 2; dy++) {
        final x = sx0 + dx, y = sy0 + dy;
        if (_in(x, y) && matrix[x][y] == water) matrix[x][y] = grass;
      }
    }

    // 굽이치는 흙길(가로 1, 세로 1).
    final roadY = h ~/ 2;
    for (var x = 1; x < w - 1; x++) {
      final yy = roadY + (sin(x * 0.18) * 3).round();
      for (var dy = 0; dy < 2; dy++) {
        if (_in(x, yy + dy) && matrix[x][yy + dy] != water) {
          matrix[x][yy + dy] = dirt;
        }
      }
    }
    final roadX = w ~/ 3;
    for (var y = 1; y < h - 1; y++) {
      final xx = roadX + (sin(y * 0.16) * 3).round();
      for (var dx = 0; dx < 2; dx++) {
        if (_in(xx + dx, y) && matrix[xx + dx][y] != water) {
          matrix[xx + dx][y] = dirt;
        }
      }
    }

    // 집 배치(마을). 길 근처 잔디에, 서로 떨어지게.
    final roofs = <Future<Sprite>>[
      Sprite.load('build/house_red.png'),
      Sprite.load('build/house_green.png'),
      Sprite.load('build/house_thatch.png'),
    ];
    final houseAnchors = <Point<int>>[];
    var tries = 0;
    while (houseAnchors.length < 16 && tries < 3000) {
      tries++;
      final x = 3 + rng.nextInt(w - 8);
      final y = 3 + rng.nextInt(h - 9);
      // 집은 폭3 높이4 타일 차지 + 아래 문 공간 필요.
      var ok = matrix[x][y] == grass;
      for (var dx = 0; dx < 3 && ok; dx++) {
        for (var dy = 0; dy < 4 && ok; dy++) {
          if (!_in(x + dx, y + dy) ||
              !_free(x + dx, y + dy) ||
              matrix[x + dx][y + dy] == water) ok = false;
        }
      }
      // 다른 집과 거리.
      for (final a in houseAnchors) {
        if ((a.x - x).abs() < 5 && (a.y - y).abs() < 5) ok = false;
      }
      if (!ok) continue;
      houseAnchors.add(Point(x, y));
      for (var dx = -1; dx <= 3; dx++) {
        for (var dy = -1; dy <= 4; dy++) {
          if (_in(x + dx, y + dy)) _occupy(x + dx, y + dy);
        }
      }
      // 문 앞 마당(흙).
      for (var dx = 0; dx < 3; dx++) {
        final fy = y + 4;
        if (_in(x + dx, fy) && matrix[x + dx][fy] != water) {
          matrix[x + dx][fy] = dirt;
        }
      }
      decorations.add(House(
        sprite: roofs[houseAnchors.length % roofs.length],
        position: _pos(x, y),
        seed: x * 1000 + y,
      ));
    }

    // 숲(나무 군집) — 빈 잔디에.
    for (var i = 0; i < 26; i++) {
      final cx = 2 + rng.nextInt(w - 4);
      final cy = 2 + rng.nextInt(h - 4);
      final n = 2 + rng.nextInt(4);
      for (var k = 0; k < n; k++) {
        final x = cx + rng.nextInt(3);
        final y = cy + rng.nextInt(3);
        if (_in(x, y) && matrix[x][y] == grass && _free(x, y)) {
          _occupy(x, y);
          decorations.add(Tree(_pos(x, y), tile));
        }
      }
    }

    // 전리품: 보물상자(골드) + 물약.
    var chests = 0, potions = 0, lt = 0;
    while ((chests < 14 || potions < 9) && lt < 4000) {
      lt++;
      final x = 1 + rng.nextInt(w - 2);
      final y = 1 + rng.nextInt(h - 2);
      if (!_free(x, y) || matrix[x][y] == water) continue;
      _occupy(x, y);
      final p = _pos(x, y) + Vector2(tile * 0.1, tile * 0.1);
      if (chests < 14 && rng.nextBool()) {
        decorations.add(MoneyChest(p, tile, amount: 20 + rng.nextInt(50)));
        chests++;
      } else if (potions < 9) {
        decorations.add(PotionPickup(p, tile, heal: 35));
        potions++;
      }
    }

    // NPC 스폰 지점(길/잔디).
    for (var x = 1; x < w - 1; x++) {
      for (var y = 1; y < h - 1; y++) {
        final t = matrix[x][y];
        if ((t == dirt || t == grass) && _free(x, y) && (x + y) % 3 == 0) {
          roadPoints.add(_pos(x, y) + Vector2.all(tile / 2));
        }
      }
    }

    // 시작: 가로/세로 길 교차점 부근.
    playerSpawn = _pos(roadX, roadY) + Vector2.all(tile / 2);
  }

  // ---- 물가 생성 ----
  void _carveWater(Random rng) {
    // 굵은 강(세로), 완만한 곡선.
    final baseX = (w * 0.72).floor();
    for (var y = 1; y < h - 1; y++) {
      final meander = (sin(y * 0.11) * 4 + sin(y * 0.05) * 3).round();
      final cxr = baseX + meander;
      for (var dx = -3; dx <= 3; dx++) {
        final x = cxr + dx;
        if (_in(x, y)) matrix[x][y] = water;
      }
    }
    // 호수 2개(타원).
    _lake((w * 0.27).round(), (h * 0.30).round(), 6, 4);
    _lake((w * 0.52).round(), (h * 0.80).round(), 5, 4);
    _despikeWater();
    _shoreline();
  }

  void _lake(int cx, int cy, int rx, int ry) {
    for (var x = cx - rx; x <= cx + rx; x++) {
      for (var y = cy - ry; y <= cy + ry; y++) {
        if (!_in(x, y)) continue;
        final nx = (x - cx) / rx, ny = (y - cy) / ry;
        if (nx * nx + ny * ny <= 1.0) matrix[x][y] = water;
      }
    }
  }

  int _waterN4(int x, int y) {
    var n = 0;
    if (matrix[x - 1][y] == water) n++;
    if (matrix[x + 1][y] == water) n++;
    if (matrix[x][y - 1] == water) n++;
    if (matrix[x][y + 1] == water) n++;
    return n;
  }

  // 1칸 돌출/구멍 정리 → 매끈한 물 덩어리.
  void _despikeWater() {
    for (var pass = 0; pass < 2; pass++) {
      final changes = <List<num>>[];
      for (var x = 1; x < w - 1; x++) {
        for (var y = 1; y < h - 1; y++) {
          final n = _waterN4(x, y);
          if (matrix[x][y] == water && n <= 1) {
            changes.add([x, y, grass]);
          } else if (matrix[x][y] == grass && n >= 3) {
            changes.add([x, y, water]);
          }
        }
      }
      for (final c in changes) {
        matrix[c[0] as int][c[1] as int] = (c[2] as double);
      }
    }
  }

  // 물에 인접한 잔디 → 모래 해변(1칸).
  void _shoreline() {
    final sand = <List<int>>[];
    for (var x = 1; x < w - 1; x++) {
      for (var y = 1; y < h - 1; y++) {
        if (matrix[x][y] != grass) continue;
        var near = false;
        for (var dx = -1; dx <= 1 && !near; dx++) {
          for (var dy = -1; dy <= 1; dy++) {
            if (matrix[x + dx][y + dy] == water) {
              near = true;
              break;
            }
          }
        }
        if (near) sand.add([x, y]);
      }
    }
    for (final s in sand) {
      matrix[s[0]][s[1]] = dirt;
    }
  }

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
            value: dirt,
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
              TileSprite(path: 'tile_random/tile_types.png', size: Vector2.all(16)),
              TileSprite(
                path: 'tile_random/tile_types.png',
                size: Vector2.all(16),
                position: Vector2(1, 0),
              ),
            ],
          ),
          MapTerrainCorners(
            value: dirt,
            to: water,
            spriteSheet: TerrainSpriteSheet.create(
              path: 'tile_random/earth_to_water.png',
              tileSize: Vector2.all(16),
            ),
          ),
          MapTerrainCorners(
            value: dirt,
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
