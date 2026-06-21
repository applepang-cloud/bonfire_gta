import 'package:flutter/services.dart';

/// 마우스 클릭 → 플레이어 액션 연결(플레이어가 등록).
class PlayerActions {
  PlayerActions._();
  static final PlayerActions instance = PlayerActions._();
  void Function()? melee;
  void Function()? ranged;
}

/// 메뉴(패널/선택지)가 열렸을 때 키 입력을 라우팅.
class MenuKeys {
  MenuKeys._();
  static final MenuKeys instance = MenuKeys._();
  void Function(LogicalKeyboardKey)? handler;
  void dispatch(LogicalKeyboardKey k) => handler?.call(k);
}
