import 'dart:async';

import 'package:flutter/material.dart';

import 'events.dart';

class ChoiceOption {
  final String label;
  final void Function() onPick;
  const ChoiceOption(this.label, this.onPick);
}

class ChoiceRequest {
  final String speaker;
  final String prompt;
  final List<ChoiceOption> options;
  final void Function()? onTimeout; // 10초 무답
  final double seconds;
  const ChoiceRequest({
    required this.speaker,
    required this.prompt,
    required this.options,
    this.onTimeout,
    this.seconds = 10,
  });
}

/// 선택지 대화 버스. 표시되면 게임을 멈춘다.
class ChoiceBus {
  ChoiceBus._();
  static final ChoiceBus instance = ChoiceBus._();

  final ValueNotifier<ChoiceRequest?> request = ValueNotifier(null);

  void show(ChoiceRequest r) {
    request.value = r;
    GameState.running = false;
  }

  void resolve(int index) {
    final r = request.value;
    if (r == null) return;
    request.value = null;
    GameState.running = true;
    if (index >= 0 && index < r.options.length) {
      r.options[index].onPick();
    } else {
      r.onTimeout?.call();
    }
  }
}

/// 선택지 오버레이 — 10초 카운트다운, 무답 시 자동 종료.
class ChoiceOverlay extends StatelessWidget {
  const ChoiceOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ChoiceRequest?>(
      valueListenable: ChoiceBus.instance.request,
      builder: (_, req, __) {
        if (req == null) return const SizedBox.shrink();
        return _ChoiceCard(req: req, key: ValueKey(req));
      },
    );
  }
}

class _ChoiceCard extends StatefulWidget {
  final ChoiceRequest req;
  const _ChoiceCard({required this.req, super.key});
  @override
  State<_ChoiceCard> createState() => _ChoiceCardState();
}

class _ChoiceCardState extends State<_ChoiceCard> {
  late double _left;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _left = widget.req.seconds;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      setState(() => _left -= 0.1);
      if (_left <= 0) {
        t.cancel();
        ChoiceBus.instance.resolve(-1); // 무답
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _pick(int i) {
    _timer?.cancel();
    ChoiceBus.instance.resolve(i);
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.req;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 40, left: 16, right: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1f1a16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF8d6e4f), width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(req.speaker,
                      style: const TextStyle(
                          color: Color(0xFFFFD54F),
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(req.prompt,
                      style: const TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 12),
                  for (var i = 0; i < req.options.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: ElevatedButton(
                        onPressed: () => _pick(i),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4e342e),
                          foregroundColor: Colors.white,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                        child: Text('${i + 1}. ${req.options[i].label}'),
                      ),
                    ),
                  const SizedBox(height: 10),
                  // 카운트다운 바
                  Row(
                    children: [
                      Text('${_left.clamp(0, 99).toStringAsFixed(0)}s',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (_left / req.seconds).clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: Colors.white12,
                            valueColor: AlwaysStoppedAnimation(
                                _left < 3
                                    ? Colors.redAccent
                                    : const Color(0xFFFFD54F)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Text('답하지 않으면 무답으로 처리됩니다.',
                      style: TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
