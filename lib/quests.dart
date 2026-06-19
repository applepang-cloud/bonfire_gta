import 'package:flutter/foundation.dart';

import 'profile.dart';
import 'wanted.dart';

enum QuestType { killBandit, killMonster, collectGold }

class QuestDef {
  final String id;
  final String title;
  final String desc;
  final QuestType type;
  final int target;
  final int rewardGold;
  final int rewardXp;
  const QuestDef(this.id, this.title, this.desc, this.type, this.target,
      this.rewardGold, this.rewardXp);
}

/// 스토리를 이루는 의뢰 사슬.
const kQuests = <QuestDef>[
  QuestDef('q1', '마을의 평화', '길목을 막은 산적 3명을 처치하라.',
      QuestType.killBandit, 3, 60, 40),
  QuestDef('q2', '숲의 위협', '마을을 노리는 괴물 4마리를 베어라.',
      QuestType.killMonster, 4, 100, 70),
  QuestDef('q3', '기사의 자금', '장비를 갖추도록 골드 200을 모아라.',
      QuestType.collectGold, 200, 80, 60),
  QuestDef('q4', '도적단 소탕', '산적 6명을 더 처치해 도적단을 흩어라.',
      QuestType.killBandit, 6, 150, 110),
  QuestDef('q5', '변경의 수호자', '괴물 8마리를 처치해 변경을 지켜라.',
      QuestType.killMonster, 8, 250, 180),
];

class QuestState {
  final QuestDef def;
  int count;
  QuestState(this.def, this.count);
  bool get isDone => def.type == QuestType.collectGold
      ? Wanted.instance.money.value >= def.target
      : count >= def.target;
  int get progress => def.type == QuestType.collectGold
      ? Wanted.instance.money.value.clamp(0, def.target)
      : count.clamp(0, def.target);
}

class QuestLog {
  QuestLog._();
  static final QuestLog instance = QuestLog._();

  final ValueNotifier<QuestState?> active = ValueNotifier(null);
  // active 변화를 HUD가 다시 그리도록 톡톡 치는 카운터.
  final ValueNotifier<int> tick = ValueNotifier(0);

  /// 아직 완료하지 않은 다음 의뢰.
  QuestDef? get nextAvailable {
    for (final q in kQuests) {
      if (!Profile.instance.questsDone.contains(q.id)) return q;
    }
    return null;
  }

  void accept(QuestDef d) {
    active.value = QuestState(d, 0);
    _bump();
  }

  void onKill(QuestType type) {
    final a = active.value;
    if (a != null && a.def.type == type && !a.isDone) {
      a.count++;
      _bump();
    }
  }

  /// 완료 처리 → 보상 지급.
  void complete() {
    final a = active.value;
    if (a == null || !a.isDone) return;
    Profile.instance.questsDone.add(a.def.id);
    Wanted.instance.addGold(a.def.rewardGold);
    Profile.instance.addXp(a.def.rewardXp);
    active.value = null;
    _bump();
  }

  void _bump() => tick.value++;
}
