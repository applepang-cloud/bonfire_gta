import 'package:flutter/material.dart';

import 'profile.dart';
import 'quests.dart';
import 'ui_bus.dart';
import 'wanted.dart';

/// 화면 좌상단 HUD — 돈/처치수/수배별(★)/체력바.
class Hud extends StatelessWidget {
  const Hud({super.key});

  @override
  Widget build(BuildContext context) {
    final w = Wanted.instance;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 돈 / 처치 수
            Row(
              children: [
                _chip(
                  ValueListenableBuilder<int>(
                    valueListenable: w.money,
                    builder: (_, v, __) => Row(children: [
                      const Icon(Icons.monetization_on,
                          color: Color(0xFFFFD54F), size: 16),
                      const SizedBox(width: 4),
                      Text('$v', style: _t(const Color(0xFFFFD54F), 17)),
                    ]),
                  ),
                ),
                const SizedBox(width: 8),
                _chip(
                  ValueListenableBuilder<int>(
                    valueListenable: w.kills,
                    builder: (_, v, __) => Row(children: [
                      const Icon(Icons.local_fire_department,
                          color: Colors.orangeAccent, size: 16),
                      const SizedBox(width: 4),
                      Text('$v', style: _t(Colors.white, 15)),
                    ]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 악명(별)
            ValueListenableBuilder<int>(
              valueListenable: w.stars,
              builder: (_, stars, __) => Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Text('악명',
                        style: TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                  ...List.generate(5, (i) {
                  final on = i < stars;
                  return Icon(
                    Icons.star,
                    size: 22,
                    color: on ? const Color(0xFFFFC107) : Colors.white24,
                    shadows: on
                        ? const [Shadow(blurRadius: 6, color: Colors.black)]
                        : null,
                  );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // 체력바
            ValueListenableBuilder<double>(
              valueListenable: w.health,
              builder: (_, hp, __) => Container(
                width: 160,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: Colors.white24),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: hp.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        hp > 0.3 ? const Color(0xFF66BB6A) : Colors.red,
                        hp > 0.3 ? const Color(0xFF43A047) : Colors.redAccent,
                      ]),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            // 레벨 + 경험치
            ValueListenableBuilder<int>(
              valueListenable: Profile.instance.level,
              builder: (_, lv, __) => ValueListenableBuilder<int>(
                valueListenable: Profile.instance.xp,
                builder: (_, xp, __) {
                  final need = Profile.instance.xpToNext;
                  return Row(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5C6BC0),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text('Lv $lv',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 118,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: (xp / need).clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF9FA8DA),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            // 퀘스트 목표
            ValueListenableBuilder<int>(
              valueListenable: QuestLog.instance.tick,
              builder: (_, __, ___) {
                final a = QuestLog.instance.active.value;
                if (a == null) return const SizedBox.shrink();
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFFD54F), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.assignment,
                          color: Color(0xFFFFD54F), size: 13),
                      const SizedBox(width: 5),
                      Text(
                        '${a.def.title}  ${a.progress}/${a.def.target}',
                        style: TextStyle(
                            color: a.isDone
                                ? const Color(0xFF8BC34A)
                                : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(Widget child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: child,
      );

  TextStyle _t(Color c, double s) => TextStyle(
        color: c,
        fontSize: s,
        fontWeight: FontWeight.bold,
        shadows: const [Shadow(blurRadius: 3, color: Colors.black)],
      );
}

/// "BUSTED" 사망 오버레이 + 리스폰 버튼.
class BustedOverlay extends StatelessWidget {
  final VoidCallback onRespawn;
  const BustedOverlay({super.key, required this.onRespawn});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: Wanted.instance.busted,
      builder: (_, busted, __) {
        if (!busted) return const SizedBox.shrink();
        return Container(
          color: Colors.black.withValues(alpha: 0.7),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('BUSTED',
                  style: TextStyle(
                    color: Color(0xFFE53935),
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  )),
              const SizedBox(height: 6),
              const Text('현상금을 잃고 병원에서 깨어났다…',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: onRespawn,
                icon: const Icon(Icons.refresh),
                label: const Text('리스폰'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF43A047),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 14),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 공격 버튼 위에 겹쳐 표시하는 키보드 키 라벨("Space").
/// game_screen 의 JoystickAction 위치(우하단, margin bottom36/right36, size70)에 맞춰 배치.
class ActionKeyLabel extends StatelessWidget {
  const ActionKeyLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        // 버튼 중앙(우 71 / 하 71)에 가로 정렬, 버튼 상단쯤에 라벨이 오도록.
        padding: const EdgeInsets.only(right: 44, bottom: 98),
        child: IgnorePointer(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white70, width: 1.5),
              boxShadow: const [
                BoxShadow(blurRadius: 3, color: Colors.black54),
              ],
            ),
            child: const Text(
              '⇧ Shift',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 우상단 조작 안내(데스크톱/웹).
class ControlsHint extends StatelessWidget {
  const ControlsHint({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(top: 48, right: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'WASD 이동 · 우 Shift 공격 · F 원거리 · E 대화',
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
        ),
      ),
    );
  }
}

/// 우상단 설정(톱니) 버튼.
class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(top: 6, right: 8),
          child: Material(
            color: Colors.black54,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => UiBus.instance.open(Panel.settings),
              child: const Padding(
                padding: EdgeInsets.all(7),
                child: Icon(Icons.settings, color: Colors.white70, size: 22),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
