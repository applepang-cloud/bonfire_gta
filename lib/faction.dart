/// 적 조직(파벌). 같은 조직은 함께 싸우고, 사이 나쁜 조직끼리는 서로 공격한다.
enum Faction { bandit, monster, cave, guard, neutral }

class FactionState {
  FactionState._();
  static final FactionState instance = FactionState._();

  // 파벌별 "플레이어 경계" 잔여 시간(초). >0이면 그 조직 전체가 플레이어를 추격.
  final Map<int, double> _alert = {};

  /// 그 조직을 도발 → 조직 전체가 플레이어를 노린다(같은 조직 호출).
  void alert(Faction f, {double dur = 22}) {
    final k = f.index;
    final cur = _alert[k] ?? 0;
    if (dur > cur) _alert[k] = dur;
  }

  bool isAlerted(Faction f) => (_alert[f.index] ?? 0) > 0;

  void calm(Faction f) => _alert[f.index] = 0;

  void tick(double dt) {
    _alert.updateAll((k, v) => v > 0 ? v - dt : 0);
  }

  void reset() => _alert.clear();

  /// 두 조직이 서로 적대(infighting)하는가.
  /// 산적·괴물·동굴깡패는 서로 사이가 나빠 마주치면 싸운다.
  static bool rivals(Faction a, Faction b) {
    if (a == b) return false;
    const fight = {Faction.bandit, Faction.monster, Faction.cave};
    return fight.contains(a) && fight.contains(b);
  }
}
