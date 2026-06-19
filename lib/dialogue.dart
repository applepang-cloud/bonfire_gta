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
    '일하러 가야지, 늦겠어.',
    '주막 교대 시간이군.',
    '시장에 물건 떼러 가는 길이라네.',
    '오늘도 방앗간 일이 산더미야.',
    '품삯이라도 두둑하면 좋으련만.',
    '우물물 길어오라 했는데.',
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

  static const dragon = [
    '크오오오— 감히 내 둥지에…',
    '한 줌 재로 만들어주마.',
    '인간 따위가!',
    '불타올라라!',
    '천 년의 잠을 깨운 죄, 무겁다.',
  ];

  static const thug = [
    '여긴 우리 소굴이다.',
    '겁도 없이 기어들어왔군.',
    '동굴 밖으로 살아 나갈 줄 아나?',
    '두목님이 좋아하시겠어.',
    '끝장내주마, 애송이.',
    '여기서 뼈를 묻어라.',
  ];

  static const family = [
    '여긴 우리 집이야!',
    '누, 누구세요?!',
    '당장 나가요!',
    '여보, 낯선 사람이!',
    '애들 뒤로 숨어!',
    '도, 도둑이야!',
  ];

  // 가족 반응 타입별 대사
  static const familyWelcome = [
    '어서 오시오, 손님!',
    '귀한 발걸음이구려.',
    '먼 길 오느라 고생했소.',
    '따뜻한 수프라도 드릴까?',
    '편히 쉬다 가시오.',
  ];
  static const familyChat = [
    '얘기나 나눕시다.',
    '바깥 소식 좀 들려주오.',
    '한잔 하고 가려오?',
    '요즘 마을이 흉흉하다오.',
    '앉으시오, 심심하던 참인데.',
  ];
  static const familyAsk = [
    '뉘신지 여쭤도 되겠소?',
    '무슨 용건으로 오셨소?',
    '기사님이신가? 검을 차셨군.',
    '길을 잃으셨소?',
    '혹 전갈이라도 가져오셨소?',
  ];
  static const familyFear = [
    '끼야! 저, 저리 가요!',
    '무기를 든 자가 집에!',
    '여, 여보 도와줘요!',
    '문으로! 어서 도망쳐!',
    '제발 해치지 말아요!',
  ];
  static const familyBusy = [
    '바쁘니 방해 마시오.',
    '빨래가 산더미라오.',
    '저녁 준비 중이라서…',
    '아이고, 허리야.',
    '장작을 더 패야 하는데.',
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
        fontFamily: 'Galmuri11',
        fontSize: 8,
        color: color,
      ),
    );
    _w = text.length * 5.2; // 폭 추정(한글 기준)
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
