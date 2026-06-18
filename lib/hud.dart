import 'package:flutter/material.dart';

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
                    builder: (_, v, __) => Text('\$$v',
                        style: _t(const Color(0xFFFFD54F), 18)),
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
            // 수배 별
            ValueListenableBuilder<int>(
              valueListenable: w.stars,
              builder: (_, stars, __) => Row(
                children: List.generate(5, (i) {
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

/// 우상단 조작 안내(데스크톱/웹).
class ControlsHint extends StatelessWidget {
  const ControlsHint({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'WASD/방향키 이동 · Space 공격\n시민·경찰을 치면 수배도↑',
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
        ),
      ),
    );
  }
}
