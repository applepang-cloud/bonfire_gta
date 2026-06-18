import 'dart:math';

import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'city_map.dart';
import 'director.dart';
import 'hud.dart';
import 'player.dart';
import 'wanted.dart';

/// GTA풍 탑다운 오픈월드 — Bonfire 게임 화면.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int _round = 0;

  void _respawn() {
    Wanted.instance.resetForRespawn();
    setState(() => _round++);
  }

  @override
  Widget build(BuildContext context) {
    final rng = Random(20260619 + _round);
    final world = CityWorld(tile: 16, w: 64, h: 64, rng: rng);

    return Scaffold(
      backgroundColor: const Color(0xFF1c2a1c),
      body: BonfireWidget(
        key: ValueKey(_round),
        playerControllers: [
          Joystick(
            directional: JoystickDirectional(
              spriteBackgroundDirectional:
                  Sprite.load('joystick/joystick_background.png'),
              spriteKnobDirectional: Sprite.load('joystick/joystick_knob.png'),
              size: 90,
              isFixed: false,
            ),
            actions: [
              JoystickAction(
                actionId: PlayerAction.attack,
                sprite: Sprite.load('joystick/joystick_attack.png'),
                size: 70,
                margin: const EdgeInsets.only(bottom: 36, right: 36),
              ),
            ],
          ),
          Keyboard(
            config: KeyboardConfig(
              directionalKeys: [
                KeyboardDirectionalKeys.arrows(),
                KeyboardDirectionalKeys.wasd(),
              ],
              acceptedKeys: [LogicalKeyboardKey.space],
            ),
          ),
        ],
        player: GtaPlayer(world.playerSpawn),
        map: world.buildMap(),
        components: [
          ...world.decorations,
          WorldDirector(world.roadPoints, rng),
        ],
        cameraConfig: CameraConfig(
          moveOnlyMapArea: true,
          zoom: getZoomFromMaxVisibleTile(context, 16, 22),
          initPosition: world.playerSpawn,
        ),
        backgroundColor: const Color(0xFF1c2a1c),
        overlayBuilderMap: {
          'hud': (_, __) => const Hud(),
          'hint': (_, __) => const ControlsHint(),
          'keyhint': (_, __) => const ActionKeyLabel(),
          'minimap': (_, game) => MiniMap(
                game: game,
                size: Vector2.all(130),
                margin: const EdgeInsets.only(bottom: 12, right: 12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24, width: 2),
                backgroundColor: Colors.black.withValues(alpha: 0.55),
                tileColor: const Color(0xFF3b5e3b),
                tileCollisionColor: const Color(0xFF2a4d66),
                playerColor: Colors.yellowAccent,
                enemyColor: Colors.redAccent,
                zoom: 0.55,
              ),
          'busted': (_, __) => BustedOverlay(onRespawn: _respawn),
        },
        initialActiveOverlays: const [
          'hud',
          'hint',
          'keyhint',
          'minimap',
          'busted'
        ],
      ),
    );
  }
}
