import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';

import 'audio.dart';
import 'player.dart';
import 'profile.dart';
import 'quests.dart';
import 'ui_bus.dart';
import 'wanted.dart';

/// 공용 패널 틀(가운데 카드).
class _Frame extends StatelessWidget {
  final String title;
  final Widget child;
  const _Frame({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {}, // 뒤 게임 입력 차단
      child: Container(
        color: Colors.black.withValues(alpha: 0.78),
        alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF2a2018),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF8d6e4f), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            color: Color(0xFFFFD54F),
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    onPressed: () => UiBus.instance.close(),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Flexible(child: SingleChildScrollView(child: child)),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

Widget _goldBar() => ValueListenableBuilder<int>(
      valueListenable: Wanted.instance.money,
      builder: (_, g, __) => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Icon(Icons.monetization_on, color: Color(0xFFFFD54F), size: 18),
          const SizedBox(width: 4),
          Text('$g',
              style: const TextStyle(
                  color: Color(0xFFFFD54F),
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );

// ----------------- 퀘스트 -----------------
class QuestPanel extends StatelessWidget {
  const QuestPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return _Frame(
      title: '촌장의 의뢰',
      child: ValueListenableBuilder<int>(
        valueListenable: QuestLog.instance.tick,
        builder: (_, __, ___) {
          final active = QuestLog.instance.active.value;
          if (active != null) {
            final d = active.def;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.title,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(d.desc, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 10),
                Text('진행: ${active.progress} / ${d.target}',
                    style: const TextStyle(color: Color(0xFF8BC34A), fontSize: 16)),
                Text('보상: 골드 ${d.rewardGold} · 경험치 ${d.rewardXp}',
                    style: const TextStyle(color: Color(0xFFFFD54F))),
                const SizedBox(height: 14),
                if (active.isDone)
                  _btn('의뢰 완료 (보상 받기)', const Color(0xFF43A047), () {
                    QuestLog.instance.complete();
                    GameAudio.coin();
                  })
                else
                  const Text('아직 목표를 달성하지 못했네.',
                      style: TextStyle(color: Colors.white54)),
              ],
            );
          }
          final next = QuestLog.instance.nextAvailable;
          if (next == null) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('자네 덕에 마을이 평화롭네. 모든 의뢰를 마쳤어!',
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(next.title,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(next.desc, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 10),
              Text('보상: 골드 ${next.rewardGold} · 경험치 ${next.rewardXp}',
                  style: const TextStyle(color: Color(0xFFFFD54F))),
              const SizedBox(height: 14),
              _btn('의뢰 수락', const Color(0xFF6D4C41), () {
                QuestLog.instance.accept(next);
              }),
            ],
          );
        },
      ),
    );
  }
}

// ----------------- 상점 -----------------
class ShopPanel extends StatefulWidget {
  final BonfireGameInterface game;
  const ShopPanel({super.key, required this.game});

  @override
  State<ShopPanel> createState() => _ShopPanelState();
}

class _ShopPanelState extends State<ShopPanel> {
  static const wCost = [80, 180, 320];
  static const aCost = [80, 180, 320];

  void _buy(int cost, VoidCallback apply) {
    if (Wanted.instance.money.value < cost) return;
    Wanted.instance.money.value -= cost;
    apply();
    Profile.instance.save();
    GameAudio.coin();
    setState(() {});
  }

  GtaPlayer? get _player {
    final p = widget.game.player;
    return p is GtaPlayer ? p : null;
  }

  @override
  Widget build(BuildContext context) {
    final p = Profile.instance;
    final wt = p.weaponTier.value, at = p.armorTier.value;
    return _Frame(
      title: '상점 · 대장간',
      child: Column(
        children: [
          _goldBar(),
          const SizedBox(height: 8),
          // 무기
          _row(
            '무기: ${Profile.weaponNames[wt]}',
            wt < 3 ? '→ ${Profile.weaponNames[wt + 1]} (공격력 +9)' : '최고 등급',
            wt < 3 ? wCost[wt] : null,
            () => _buy(wCost[wt], () {
              p.weaponTier.value = wt + 1;
              _player?.applyStats();
            }),
          ),
          // 방어구
          _row(
            '방어구: ${Profile.armorNames[at]}',
            at < 3 ? '→ ${Profile.armorNames[at + 1]} (체력 +35)' : '최고 등급',
            at < 3 ? aCost[at] : null,
            () => _buy(aCost[at], () {
              p.armorTier.value = at + 1;
              _player?.applyStats();
            }),
          ),
          // 활(원거리)
          _row(
            '활 (원거리 공격)',
            p.hasBow ? '이미 보유 · F / 우측 버튼' : '마법 화살을 쏠 수 있다',
            p.hasBow ? null : 150,
            () => _buy(150, () => p.skills.add('bow')),
          ),
          // 물약
          _row(
            '생명 물약',
            '체력 60 회복',
            30,
            () => _buy(30, () => _player?.heal(60)),
          ),
        ],
      ),
    );
  }

  Widget _row(String title, String sub, int? cost, VoidCallback onBuy) {
    final afford = cost != null && Wanted.instance.money.value >= cost;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                Text(sub, style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
          if (cost == null)
            const Text('—', style: TextStyle(color: Colors.white38))
          else
            ElevatedButton(
              onPressed: afford ? onBuy : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6D4C41),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.white12,
              ),
              child: Text('$cost G'),
            ),
        ],
      ),
    );
  }
}

// ----------------- 설정 -----------------
class SettingsPanel extends StatefulWidget {
  const SettingsPanel({super.key});
  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  @override
  Widget build(BuildContext context) {
    final p = Profile.instance;
    return _Frame(
      title: '설정',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('배경음 음량', style: TextStyle(color: Colors.white70)),
          Slider(
            value: p.bgmVol.value,
            onChanged: (v) => setState(() {
              p.bgmVol.value = v;
              GameAudio.setBgmVolume(v);
            }),
            onChangeEnd: (_) => p.save(),
          ),
          const Text('효과음 음량', style: TextStyle(color: Colors.white70)),
          Slider(
            value: p.sfxVol.value,
            onChanged: (v) => setState(() => p.sfxVol.value = v),
            onChangeEnd: (_) => p.save(),
          ),
          const SizedBox(height: 10),
          const Text('난이도', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Row(
            children: List.generate(3, (i) {
              const names = ['쉬움', '보통', '어려움'];
              final sel = p.difficulty.value == i;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(names[i]),
                  selected: sel,
                  onSelected: (_) => setState(() {
                    p.difficulty.value = i;
                    p.save();
                  }),
                ),
              );
            }),
          ),
          const SizedBox(height: 18),
          _btn('진행도 초기화', const Color(0xFFB71C1C), () {
            Profile.instance.reset();
            setState(() {});
          }),
        ],
      ),
    );
  }
}

Widget _btn(String label, Color color, VoidCallback onTap) => SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ),
    );

// ----------------- 상호작용 안내 -----------------
class InteractPrompt extends StatelessWidget {
  const InteractPrompt({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: Interaction.instance.prompt,
      builder: (_, label, __) {
        if (label == null) return const SizedBox.shrink();
        return SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 120),
              child: GestureDetector(
                onTap: () => Interaction.instance.activate(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFD54F)),
                  ),
                  child: Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
