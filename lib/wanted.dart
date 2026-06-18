import 'package:flutter/foundation.dart';

/// GTA식 "수배(Wanted)" 전역 상태.
/// 범죄(시민/경찰 공격)를 저지르면 heat이 올라가고, 별(★) 단계가 오른다.
/// 별 단계에 비례해 경찰이 스폰되어 플레이어를 추격한다.
/// 일정 시간 범죄를 멈추면 heat이 서서히 식는다.
class Wanted {
  Wanted._();
  static final Wanted instance = Wanted._();

  /// 0.0 ~ 100.0
  double _heat = 0;

  /// HUD 바인딩용 알림자들.
  final ValueNotifier<int> stars = ValueNotifier<int>(0);
  final ValueNotifier<int> money = ValueNotifier<int>(0);
  final ValueNotifier<double> health = ValueNotifier<double>(1.0);
  final ValueNotifier<int> kills = ValueNotifier<int>(0);
  final ValueNotifier<bool> busted = ValueNotifier<bool>(false);

  /// 현재 활성 경찰 수(스포너가 관리).
  int activeCops = 0;

  static const double _heatPerStar = 20.0;
  static const double _decayPerSecond = 2.2;

  int get starCount => stars.value;

  void addHeat(double v) {
    _heat = (_heat + v).clamp(0.0, 100.0);
    _syncStars();
  }

  void addMoney(int v) => money.value += v;

  // 중세 리브랜드: money == gold
  ValueNotifier<int> get gold => money;
  void addGold(int v) => addMoney(v);

  void addKill() => kills.value += 1;

  void _syncStars() {
    final s = (_heat / _heatPerStar).ceil().clamp(0, 5);
    if (s != stars.value) stars.value = s;
  }

  /// 게임 루프에서 매 프레임 호출 — heat 자연 감소.
  void tick(double dt) {
    if (_heat > 0) {
      _heat = (_heat - _decayPerSecond * dt).clamp(0.0, 100.0);
      _syncStars();
    }
  }

  void setHealth(double ratio) {
    final r = ratio.clamp(0.0, 1.0);
    if ((r - health.value).abs() > 0.001) health.value = r;
  }

  /// 사망(Busted) 처리 — 돈 절반 잃고 수배 초기화.
  void onBusted() {
    money.value = (money.value * 0.5).floor();
    _heat = 0;
    stars.value = 0;
    busted.value = true;
  }

  /// 새 라운드(리스폰/재시작) 초기화.
  void resetForRespawn() {
    _heat = 0;
    stars.value = 0;
    health.value = 1.0;
    activeCops = 0;
    busted.value = false;
  }

  /// 완전 초기화(새 게임).
  void resetAll() {
    resetForRespawn();
    money.value = 0;
    kills.value = 0;
  }
}
