import 'package:flutter/foundation.dart';

import 'events.dart';

/// 열려 있는 전체화면 패널.
enum Panel { none, quest, shop, settings }

/// 패널 열기/닫기 버스. 패널이 열리면 게임을 일시정지한다.
class UiBus {
  UiBus._();
  static final UiBus instance = UiBus._();

  final ValueNotifier<Panel> panel = ValueNotifier(Panel.none);

  void open(Panel p) {
    panel.value = p;
    GameState.running = false; // 일시정지
  }

  void close() {
    panel.value = Panel.none;
    GameState.running = true;
  }
}

/// 플레이어 근처 상호작용 대상(촌장/상인 등) 제안.
class Interaction {
  Interaction._();
  static final Interaction instance = Interaction._();

  final ValueNotifier<String?> prompt = ValueNotifier(null);
  Object? _owner;
  void Function()? _action;

  void offer(Object owner, String label, void Function() action) {
    _owner = owner;
    _action = action;
    if (prompt.value != label) prompt.value = label;
  }

  void clear(Object owner) {
    if (_owner == owner) {
      _owner = null;
      _action = null;
      prompt.value = null;
    }
  }

  void activate() {
    _action?.call();
  }
}
