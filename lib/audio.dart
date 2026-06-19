import 'dart:math';

import 'package:flame_audio/flame_audio.dart';

import 'profile.dart';

/// 게임 오디오 — BGM 루프 + 효과음 + 한국어 음성("얍!").
/// 에셋은 tool/make_audio.js(효과음) + SAPI Heami(음성)로 생성, assets/audio/ 에 위치.
class GameAudio {
  static final _rng = Random();
  static bool enabled = true;
  static bool _bgmStarted = false;
  static bool _ready = false;

  static const _files = [
    'bgm.wav',
    'swing.wav',
    'hit.wav',
    'coin.wav',
    'alarm.wav',
    'voice_yap1.wav',
    'voice_yap2.wav',
    'voice_yap3.wav',
    'voice_gasp.wav',
    'voice_intruder.wav',
  ];

  static Future<void> preload() async {
    if (_ready) return;
    try {
      await FlameAudio.audioCache.loadAll(_files);
      _ready = true;
    } catch (_) {
      // 오디오 로드 실패해도 게임은 계속.
    }
  }

  /// 사용자 제스처(시작 버튼) 후 호출 — 웹 자동재생 정책 대응.
  static void startBgm() {
    if (_bgmStarted || !enabled) return;
    _bgmStarted = true;
    try {
      FlameAudio.bgm.play('bgm.wav', volume: Profile.instance.bgmVol.value);
    } catch (_) {}
  }

  static void setBgmVolume(double v) {
    try {
      FlameAudio.bgm.audioPlayer.setVolume(v);
    } catch (_) {}
  }

  static void _play(String f, double v) {
    if (!enabled) return;
    try {
      FlameAudio.play(f, volume: v * Profile.instance.sfxVol.value);
    } catch (_) {}
  }

  static void swing() => _play('swing.wav', 0.6);
  static void hit() => _play('hit.wav', 0.7);
  static void coin() => _play('coin.wav', 0.7);
  static void alarm() => _play('alarm.wav', 0.6);

  /// 공격 기합("얍!"/"이얍!"/"하압!") 무작위.
  static void kiai() {
    const v = ['voice_yap1.wav', 'voice_yap2.wav', 'voice_yap3.wav'];
    _play(v[_rng.nextInt(v.length)], 0.9);
  }

  static void gasp() => _play('voice_gasp.wav', 0.85);
  static void intruder() => _play('voice_intruder.wav', 0.9);

  static void toggle() {
    enabled = !enabled;
    try {
      if (enabled) {
        FlameAudio.bgm.resume();
      } else {
        FlameAudio.bgm.pause();
      }
    } catch (_) {}
  }
}
