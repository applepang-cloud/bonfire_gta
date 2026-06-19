import 'dart:math';

import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';

import 'dialogue.dart';
import 'sprites.dart';
import 'ui_bus.dart';

/// 상호작용 가능한 마을 주민(촌장/상인). 공격해도 죽지 않으며,
/// 머리 위 마커로 표시되고 가까이 가면 안내가 뜬다.
/// 렌더가 확실한 SimpleEnemy 경로를 쓰되 피해는 받지 않는다(NONE).
abstract class TownNpc extends SimpleEnemy with BlockMovementCollision {
  final String promptLabel;
  final Panel panel;
  final List<String> lines;
  final Color markerColor;
  final String marker;
  final BarkTimer _bark = BarkTimer(min: 5, max: 9);
  double _t = 0;
  static const double s = 26;

  TownNpc(
    Vector2 position, {
    required String path,
    required this.promptLabel,
    required this.panel,
    required this.lines,
    required this.markerColor,
    required this.marker,
  }) : super(
          position: position,
          animation: PersonSprites(path: path).animation(),
          size: Vector2.all(s),
          speed: 0,
          life: 99999,
          initDirection: Direction.down,
        );

  @override
  Future<void> onLoad() {
    receivesAttackFrom = AcceptableAttackOriginEnum.NONE; // 공격 불가
    add(RectangleHitbox(
        size: Vector2(s * 0.5, s * 0.55), position: Vector2(s * 0.25, s * 0.4)));
    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _bark.update(dt, this, lines, markerColor);
    seePlayer(
      radiusVision: s * 2.6,
      observed: (_) => Interaction.instance
          .offer(this, promptLabel, () => UiBus.instance.open(panel)),
      notObserved: () => Interaction.instance.clear(this),
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // 머리 위 마커(둥둥 떠 있음).
    final bob = sin(_t * 4) * 2;
    final cx = size.x / 2;
    final y = -13 + bob;
    canvas.drawCircle(Offset(cx, y + 4), 7, Paint()..color = markerColor);
    canvas.drawCircle(
        Offset(cx, y + 4),
        7,
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    _mk.render(canvas, marker, Vector2(cx - 3, y - 2));
  }

  static final _mk = TextPaint(
    style: const TextStyle(
      fontFamily: 'Galmuri11',
      fontSize: 10,
      color: Colors.black,
      fontWeight: FontWeight.bold,
    ),
  );

  // 인트로/패널 중에도 가만히 서 있게(공격/이동 안 함).
  @override
  void onDie() {}
}

/// 촌장 — 의뢰를 준다.
class QuestGiver extends TownNpc {
  QuestGiver(Vector2 position)
      : super(
          position,
          path: 'human.png',
          promptLabel: '촌장과 대화  (E)',
          panel: Panel.quest,
          lines: const ['기사여, 의뢰가 있네.', '마을을 도와주게.', '자네만 믿네.'],
          markerColor: const Color(0xFFFFE082),
          marker: '!',
        );
}

/// 상인 — 무기/방어구/물약을 판다.
class Merchant extends TownNpc {
  Merchant(Vector2 position)
      : super(
          position,
          path: 'orc2.png',
          promptLabel: '상점 이용  (E)',
          panel: Panel.shop,
          lines: const ['좋은 물건 있소!', '검이며 갑옷이며 다 있다오.', '골드만 있으면 됩니다.'],
          markerColor: const Color(0xFFA5D6A7),
          marker: '상',
        );
}
