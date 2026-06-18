import 'dart:math';

import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';

/// NPC/몬스터 대사 풀. 머리 위에 말풍선으로 계속 떠오른다.
class Lines {
  static final _rng = Random();
  static T pick<T>(List<T> l) => l[_rng.nextInt(l.length)];

  static const villager = [
    '좋은 날이오, 나그네.',
    '밭일은 끝이 없구먼…',
    '요즘 숲에 늑대가 부쩍 늘었어.',
    '대장간에 들러야 하는데.',
    '맥주 한 잔이 간절하군.',
    '아이들이 또 어디로 갔담.',
    '올해 수확은 풍년이려나.',
    '성벽 너머는 위험하다네.',
    '여행자는 처음 보는구먼.',
    '신께서 굽어살피시길.',
  ];

  static const villagerScared = [
    '히익! 무, 무기 치워요!',
    '사, 살려주세요!',
    '경비병! 경비병!',
    '미친 자다! 도망쳐!',
    '왜 이러는 거요!',
    '누, 누가 좀 도와줘요!',
  ];

  static const bandit = [
    '가진 거 다 내놔!',
    '이 길은 우리 구역이다.',
    '크크, 좋은 먹잇감이군.',
    '목숨이 아깝거든 꺼져라.',
    '동전 한 닢까지 털어주마.',
    '오늘 운이 없구나, 애송이.',
  ];

  static const guard = [
    '질서를 지켜라.',
    '수상한 자는 잡아들인다.',
    '마을의 평화를 위하여.',
    '말썽 부리지 마시오.',
    '검을 거두시오, 당장!',
    '법을 어기면 대가를 치른다.',
  ];

  static const monster = [
    '그르르…',
    '크아아아!',
    '인간의 냄새다…',
    '뼈를 발라주마.',
    '배가… 고프다…',
    '살점이 그립군…',
    '쿠워어어!',
  ];

  static const family = [
    '여긴 우리 집이야!',
    '누, 누구세요?!',
    '당장 나가요!',
    '여보, 낯선 사람이!',
    '애들 뒤로 숨어!',
    '도, 도둑이야!',
  ];

  static const story = [
    '— 백참 기사단의 마지막 기사여,',
    '역병과 산적이 들끓는 변경의 마을.',
    '당신의 검이 곧 이곳의 법이 된다.',
    '마을을 누비고, 집을 살피고, 괴물을 베어라.',
  ];
}

/// 머리 위 말풍선(잠깐 떠올랐다 사라짐).
class Speech extends PositionComponent {
  final String text;
  final Color color;
  double _life = 2.0;
  late final TextPaint _paint;
  late final double _w;

  Speech(Vector2 worldPos, this.text, this.color)
      : super(position: worldPos, priority: 1000000) {
    _paint = TextPaint(
      style: TextStyle(
        fontSize: 7,
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
    _w = text.length * 4.6; // 폭 추정(한글 기준)
  }

  @override
  void render(Canvas canvas) {
    final pad = 2.0;
    final rect = Rect.fromLTWH(-_w / 2 - pad, -9, _w + pad * 2, 11);
    final a = (_life.clamp(0.0, 1.0));
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      Paint()..color = Colors.black.withValues(alpha: 0.55 * a),
    );
    _paint.render(canvas, text, Vector2(-_w / 2, -8));
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y -= 6 * dt;
    _life -= dt;
    if (_life <= 0) removeFromParent();
  }
}

/// NPC가 주기적으로 대사를 말하도록 돕는 타이머.
class BarkTimer {
  double _t;
  final double min;
  final double max;
  final Random _rng = Random();
  BarkTimer({this.min = 4.5, this.max = 9.0}) : _t = 3 + Random().nextDouble() * 5;

  /// 말할 때가 되면 pool에서 한 줄을 머리 위에 띄운다.
  void update(double dt, GameComponent owner, List<String> pool, Color color) {
    _t -= dt;
    if (_t > 0) return;
    _t = min + _rng.nextDouble() * (max - min);
    if (!owner.isVisible) return;
    owner.gameRef.add(
      Speech(owner.absoluteCenter - Vector2(0, owner.size.y * 0.55), pool[_rng.nextInt(pool.length)], color),
    );
  }

  /// 즉시 한 줄(놀람/위협 등).
  static void shout(GameComponent owner, List<String> pool, Color color) {
    owner.gameRef.add(
      Speech(owner.absoluteCenter - Vector2(0, owner.size.y * 0.55),
          Lines.pick(pool), color),
    );
  }
}
