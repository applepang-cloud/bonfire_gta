import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'wanted.dart';

/// 저장 가능한 플레이어 진행도 + 설정. localStorage(shared_preferences)에 보존.
class Profile {
  Profile._();
  static final Profile instance = Profile._();

  // 진행도
  final ValueNotifier<int> level = ValueNotifier(1);
  final ValueNotifier<int> xp = ValueNotifier(0);
  final ValueNotifier<int> weaponTier = ValueNotifier(0); // 0~3
  final ValueNotifier<int> armorTier = ValueNotifier(0); // 0~3
  final Set<String> skills = {}; // 'bow'
  final Set<String> questsDone = {};

  // 설정
  final ValueNotifier<double> bgmVol = ValueNotifier(0.30);
  final ValueNotifier<double> sfxVol = ValueNotifier(0.80);
  final ValueNotifier<int> difficulty = ValueNotifier(1); // 0 쉬움 1 보통 2 어려움

  SharedPreferences? _prefs;

  int get xpToNext => 50 + (level.value - 1) * 45;
  double get atkBonus => weaponTier.value * 9 + (level.value - 1) * 3;
  double get hpBonus => armorTier.value * 35 + (level.value - 1) * 18;
  bool get hasBow => skills.contains('bow');

  double get enemyDmgMul => const [0.7, 1.0, 1.4][difficulty.value];
  double get enemyHpMul => const [0.8, 1.0, 1.3][difficulty.value];

  static const weaponNames = ['낡은 검', '강철 검', '기사의 검', '룬 검'];
  static const armorNames = ['천 갑옷', '가죽 갑옷', '사슬 갑옷', '판금 갑옷'];

  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final s = _prefs!.getString('knight_save');
      if (s != null) {
        final m = jsonDecode(s) as Map<String, dynamic>;
        level.value = (m['level'] ?? 1) as int;
        xp.value = (m['xp'] ?? 0) as int;
        weaponTier.value = (m['weapon'] ?? 0) as int;
        armorTier.value = (m['armor'] ?? 0) as int;
        skills
          ..clear()
          ..addAll(((m['skills'] as List?) ?? const []).cast<String>());
        questsDone
          ..clear()
          ..addAll(((m['quests'] as List?) ?? const []).cast<String>());
        Wanted.instance.money.value = (m['gold'] ?? 0) as int;
        bgmVol.value = ((m['bgmVol'] ?? 0.30) as num).toDouble();
        sfxVol.value = ((m['sfxVol'] ?? 0.80) as num).toDouble();
        difficulty.value = (m['difficulty'] ?? 1) as int;
      }
    } catch (_) {
      // 저장 로드 실패해도 기본값으로 진행.
    }
  }

  void save() {
    try {
      _prefs?.setString(
        'knight_save',
        jsonEncode({
          'level': level.value,
          'xp': xp.value,
          'weapon': weaponTier.value,
          'armor': armorTier.value,
          'skills': skills.toList(),
          'quests': questsDone.toList(),
          'gold': Wanted.instance.money.value,
          'bgmVol': bgmVol.value,
          'sfxVol': sfxVol.value,
          'difficulty': difficulty.value,
        }),
      );
    } catch (_) {}
  }

  /// 경험치 획득 → 레벨업 처리.
  void addXp(int v) {
    xp.value += v;
    while (xp.value >= xpToNext) {
      xp.value -= xpToNext;
      level.value += 1;
    }
    save();
  }

  void reset() {
    level.value = 1;
    xp.value = 0;
    weaponTier.value = 0;
    armorTier.value = 0;
    skills.clear();
    questsDone.clear();
    Wanted.instance.money.value = 0;
    save();
  }
}
