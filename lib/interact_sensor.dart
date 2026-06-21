import 'package:bonfire/bonfire.dart';

import 'ui_bus.dart';

/// 입장/퇴장 지점 — 자동 전환 대신 "E로 입장" 상호작용을 제안한다.
/// (넉백/이동 중 사고로 씬이 바뀌는 것을 방지)
class EntrySensor extends GameComponent with Sensor<Player> {
  final String label;
  final void Function() onEnter;

  EntrySensor({
    required Vector2 position,
    required Vector2 size,
    required this.label,
    required this.onEnter,
  }) {
    this.position = position;
    this.size = size;
  }

  @override
  void onContact(Player component) {
    Interaction.instance.offer(this, label, onEnter);
  }

  @override
  void onContactExit(Player component) {
    Interaction.instance.clear(this);
  }

  @override
  void onRemove() {
    Interaction.instance.clear(this);
    super.onRemove();
  }
}
