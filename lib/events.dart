import 'package:bonfire/bonfire.dart';
import 'package:flutter/foundation.dart';

/// 게임 진행 상태 — 인트로 동안엔 전투/피해를 멈춘다.
class GameState {
  static bool running = false;
}

/// 씬 전환 요청(오버월드 ↔ 집 내부).
class SceneRequest {
  final String scene; // 'overworld' | 'house'
  final Vector2 spawn; // 새 씬에서 플레이어 시작 위치
  final int seed; // 집(가족) 식별/생성 시드
  const SceneRequest(this.scene, this.spawn, this.seed);
}

/// 컴포넌트(문 센서)에서 위젯(GameScreen)으로 씬 전환을 전달하는 버스.
class GameEvents {
  GameEvents._();
  static final GameEvents instance = GameEvents._();

  final ValueNotifier<SceneRequest?> request = ValueNotifier<SceneRequest?>(null);

  void go(String scene, Vector2 spawn, int seed) {
    request.value = SceneRequest(scene, spawn, seed);
  }
}
