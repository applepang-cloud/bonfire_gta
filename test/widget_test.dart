import 'package:flutter_test/flutter_test.dart';

import 'package:bonfire_gta/wanted.dart';

void main() {
  test('Wanted 수배 시스템: heat → 별 단계 변환', () {
    final w = Wanted.instance;
    w.resetAll();
    expect(w.starCount, 0);

    w.addHeat(25); // 20당 별 1개 → 25면 2개(ceil)
    expect(w.starCount, 2);

    // 시간 경과로 heat 감소 (25 / 2.2 ≈ 11.4초 필요 → 넉넉히 15초)
    for (var i = 0; i < 150; i++) {
      w.tick(0.1);
    }
    expect(w.starCount, 0);
  });

  test('돈 획득/사망 시 절반 손실', () {
    final w = Wanted.instance;
    w.resetAll();
    w.addMoney(100);
    expect(w.money.value, 100);
    w.onBusted();
    expect(w.money.value, 50);
    expect(w.busted.value, true);
  });
}
