import 'package:flutter/material.dart';

import 'dialogue.dart';

/// 인트로 스토리 오버레이. "모험 시작"을 누르면 BGM이 켜지고 게임이 시작된다.
class StoryIntro extends StatelessWidget {
  final VoidCallback onStart;
  const StoryIntro({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.82),
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('변경의 기사',
                  style: TextStyle(
                    color: Color(0xFFFFD54F),
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  )),
              const SizedBox(height: 4),
              const Text('A Knight of the Frontier',
                  style: TextStyle(color: Colors.white38, fontSize: 13)),
              const SizedBox(height: 20),
              ...Lines.story.map(
                (l) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(l,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14, height: 1.4)),
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.shield),
                label: const Text('모험 시작'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6D4C41),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  textStyle:
                      const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              const Text('WASD/방향키 이동 · 우 Shift 공격',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
