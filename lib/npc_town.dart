import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';

import 'dialogue.dart';
import 'sprites.dart';
import 'ui_bus.dart';

/// 상호작용 가능한 마을 주민 베이스(공격 불가). 가까이 가면 안내가 뜬다.
abstract class TownNpc extends SimpleNpc with BlockMovementCollision {
  final String promptLabel;
  final Panel panel;
  final List<String> _lines;
  final Color _color;
  final _bark = BarkTimer(min: 5, max: 9);
  static const double s = 24;

  TownNpc(
    Vector2 position, {
    required String path,
    required this.promptLabel,
    required this.panel,
    required List<String> lines,
    required Color color,
  })  : _lines = lines,
        _color = color,
        super(
          position: position,
          animation: PersonSprites(path: path).animation(),
          size: Vector2.all(s),
          speed: 0,
          initDirection: Direction.down,
        );

  @override
  Future<void> onLoad() {
    add(RectangleHitbox(
        size: Vector2(s * 0.5, s * 0.5), position: Vector2(s * 0.25, s * 0.4)));
    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _bark.update(dt, this, _lines, _color);
    seePlayer(
      radiusVision: s * 2.6,
      observed: (_) =>
          Interaction.instance.offer(this, promptLabel, () => UiBus.instance.open(panel)),
      notObserved: () => Interaction.instance.clear(this),
    );
  }
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
          color: const Color(0xFFFFE082),
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
          color: const Color(0xFFA5D6A7),
        );
}
