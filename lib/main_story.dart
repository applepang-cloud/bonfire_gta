import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';

import 'profile.dart';

enum StoryTarget { none, questGiver, cave }

class StoryBeat {
  final String title;
  final String objective;
  final StoryTarget target;
  const StoryBeat(this.title, this.objective, this.target);
}

/// GTA식 메인 스토리 진행. 단계는 Profile.storyStep 에 저장된다.
class MainStory {
  MainStory._();
  static final MainStory instance = MainStory._();

  /// 현재 목표의 월드 좌표(overworld). 씬이 매번 설정. 화살표/비콘이 참조.
  final ValueNotifier<Vector2?> marker = ValueNotifier(null);

  static const beats = <StoryBeat>[
    StoryBeat('수상한 소문', '촌장에게 들러 변경의 동굴 소문을 들어라.', StoryTarget.questGiver),
    StoryBeat('동굴 조사', '동쪽 동굴로 들어가 정체를 밝혀라.', StoryTarget.cave),
    StoryBeat('1층의 무리', '동굴 1층의 깡패 무리를 헤치고 더 깊이 내려가라.', StoryTarget.cave),
    StoryBeat('2층의 두목', '동굴 2층 깊은 곳의 두목을 처치하라.', StoryTarget.cave),
    StoryBeat('귀환 보고', '촌장에게 돌아가 소식을 전하라.', StoryTarget.questGiver),
    StoryBeat('변경의 영웅', '마을은 평화를 되찾았다. 자유로이 모험하라.', StoryTarget.none),
  ];

  ValueNotifier<int> get step => Profile.instance.storyStep;
  StoryBeat get current => beats[step.value.clamp(0, beats.length - 1)];
  bool get finished => step.value >= beats.length - 1;

  void advance() {
    if (step.value < beats.length - 1) {
      step.value++;
      Profile.instance.save();
    }
  }

  /// 특정 트리거가 현재 단계와 맞으면 진행.
  void trigger(StoryTrigger t) {
    switch (t) {
      case StoryTrigger.talkedQuestGiver:
        if (current.target == StoryTarget.questGiver) advance();
        break;
      case StoryTrigger.enteredCave:
        if (step.value == 1) advance();
        break;
      case StoryTrigger.descended:
        if (step.value == 2) advance();
        break;
      case StoryTrigger.bossDown:
        if (step.value == 3) advance();
        break;
    }
  }
}

enum StoryTrigger { talkedQuestGiver, enteredCave, descended, bossDown }
