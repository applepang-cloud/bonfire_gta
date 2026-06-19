import 'package:flutter/material.dart';

/// 보스 전투 상태 — 보스가 등장하면 상단에 이름+체력바를 표시.
class BossState {
  BossState._();
  static final BossState instance = BossState._();

  final ValueNotifier<bool> active = ValueNotifier(false);
  final ValueNotifier<double> hp = ValueNotifier(1.0);
  String name = '';

  void begin(String n) {
    name = n;
    hp.value = 1.0;
    active.value = true;
  }

  void setHp(double ratio) => hp.value = ratio.clamp(0.0, 1.0);

  void end() => active.value = false;
}

/// 상단 보스 체력바 오버레이.
class BossBar extends StatelessWidget {
  const BossBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: BossState.instance.active,
      builder: (_, active, __) {
        if (!active) return const SizedBox.shrink();
        return SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(BossState.instance.name,
                      style: const TextStyle(
                        color: Color(0xFFFF8A80),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 3, color: Colors.black)],
                      )),
                  const SizedBox(height: 3),
                  ValueListenableBuilder<double>(
                    valueListenable: BossState.instance.hp,
                    builder: (_, hp, __) => Container(
                      width: 260,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF7f1d1d), width: 2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: hp,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [
                              Color(0xFFD32F2F),
                              Color(0xFFFF5252),
                            ]),
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
