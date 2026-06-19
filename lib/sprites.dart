import 'package:bonfire/bonfire.dart';

/// 모든 캐릭터/이펙트 스프라이트 시트 로더.
/// Bonfire 예제(`example/assets`)에 들어있는 리소스를 그대로 사용한다.

/// 16x16 N프레임짜리 단순 시트(knight, goblin, critter)용 헬퍼.
Future<SpriteAnimation> _futSeq16(String path, int amount,
    {double step = 0.12}) {
  return SpriteAnimation.load(
    path,
    SpriteAnimationData.sequenced(
      amount: amount,
      stepTime: step,
      textureSize: Vector2.all(16),
    ),
  );
}

/// 플레이어(기사) 스프라이트.
class PlayerSprites {
  static SimpleDirectionAnimation animation() => SimpleDirectionAnimation(
        idleRight: _futSeq16('player/knight_idle.png', 6),
        idleLeft: _futSeq16('player/knight_idle_left.png', 6),
        runRight: _futSeq16('player/knight_run.png', 6),
        runLeft: _futSeq16('player/knight_run_left.png', 6),
      );

  /// 근접 공격 이펙트(48x16 = 3프레임).
  static Future<SpriteAnimation> get attackEffectRight => _futSeq16(
        'player/attack_effect_right.png',
        3,
        step: 0.08,
      );

  /// 원거리(마법 화살) — fireball_right.png 69x23 = 3프레임.
  static Future<SpriteAnimation> get fireballRight => SpriteAnimation.load(
        'player/fireball_right.png',
        SpriteAnimationData.sequenced(
          amount: 3,
          stepTime: 0.1,
          textureSize: Vector2.all(23),
        ),
      );

  /// 명중 폭발 — explosion_fire.png 192x32 = 6프레임.
  static Future<SpriteAnimation> get explosion => SpriteAnimation.load(
        'player/explosion_fire.png',
        SpriteAnimationData.sequenced(
          amount: 6,
          stepTime: 0.08,
          textureSize: Vector2.all(32),
        ),
      );
}

/// 드래곤 보스 — 2프레임(날개 펄럭) 시트(128x64), 모든 방향에 재사용.
class DragonSprites {
  static Future<SpriteAnimation> _flap() => SpriteAnimation.load(
        'build/dragon.png',
        SpriteAnimationData.sequenced(
          amount: 2,
          stepTime: 0.28,
          textureSize: Vector2(64, 64),
        ),
      );

  static SimpleDirectionAnimation animation() => SimpleDirectionAnimation(
        idleRight: _flap(),
        runRight: _flap(),
      );
}

/// 갱단(고블린) 스프라이트.
class GoblinSprites {
  static SimpleDirectionAnimation animation() => SimpleDirectionAnimation(
        idleRight: _futSeq16('enemy/goblin_idle.png', 6),
        idleLeft: _futSeq16('enemy/goblin_idle_left.png', 6),
        runRight: _futSeq16('enemy/goblin_run_right.png', 6),
        runLeft: _futSeq16('enemy/goblin_run_left.png', 6),
      );

  static Future<SpriteAnimation> get attackEffectRight => _futSeq16(
        'enemy/attack_effect_right.png',
        3,
        step: 0.08,
      );
}

/// 시민(작은 크리터) 스프라이트. 128x16 = 8프레임.
class CivilianSprites {
  static SimpleDirectionAnimation animation() => SimpleDirectionAnimation(
        idleRight: _futSeq16('npc/critter_idle.png', 8),
        runRight: _futSeq16('npc/critter_run_right.png', 8),
        runLeft: _futSeq16('npc/critter_run_left.png', 8),
      );
}

/// 경찰: 32x32 휴먼형 8방향 시트(orc2.png). Bonfire 예제 PersonSpritesheet 패턴.
class PersonSprites {
  final String path;
  PersonSprites({this.path = 'orc2.png'});

  Future<SpriteAnimation> _idle(double row) => SpriteAnimation.load(
        path,
        SpriteAnimationData.sequenced(
          amount: 2,
          stepTime: 0.2,
          textureSize: Vector2.all(32),
          texturePosition: Vector2(0, 32 * row),
        ),
      );

  Future<SpriteAnimation> _run(double row) => SpriteAnimation.load(
        path,
        SpriteAnimationData.sequenced(
          amount: 2,
          stepTime: 0.2,
          textureSize: Vector2.all(32),
          texturePosition: Vector2(64, 32 * row),
        ),
      );

  SimpleDirectionAnimation animation() => SimpleDirectionAnimation(
        idleDown: _idle(0),
        idleDownRight: _idle(1),
        idleRight: _idle(2),
        idleUpRight: _idle(3),
        idleUp: _idle(4),
        idleUpLeft: _idle(5),
        idleLeft: _idle(6),
        idleDownLeft: _idle(7),
        runDown: _run(0),
        runDownRight: _run(1),
        runRight: _run(2),
        runUpRight: _run(3),
        runUp: _run(4),
        runUpLeft: _run(5),
        runLeft: _run(6),
        runDownLeft: _run(7),
      );
}

/// 공통 이펙트/오브젝트.
class Fx {
  static Future<SpriteAnimation> get chestAnimated => SpriteAnimation.load(
        'itens/chest_spritesheet.png',
        SpriteAnimationData.sequenced(
          amount: 8,
          stepTime: 0.12,
          textureSize: Vector2.all(16),
        ),
      );

  static Future<Sprite> get potion => Sprite.load('itens/potion_life.png');
  static Future<Sprite> get barrel => Sprite.load('itens/barrel.png');
  static Future<Sprite> get table => Sprite.load('itens/table.png');
  static Future<Sprite> get column => Sprite.load('itens/column.png');
  static Future<Sprite> get bookshelf => Sprite.load('itens/bookshelf.png');
  static Future<Sprite> get crypt => Sprite.load('player/crypt.png');
}
