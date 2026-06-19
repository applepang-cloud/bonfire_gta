import 'dart:math';

import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audio.dart';
import 'day_night.dart';
import 'director.dart';
import 'events.dart';
import 'hud.dart';
import 'interior.dart';
import 'panels.dart';
import 'player.dart';
import 'story.dart';
import 'ui_bus.dart';
import 'village_map.dart';
import 'wanted.dart';

/// 중세 판타지 오픈월드 — 마을(오버월드)과 집 내부를 오가는 Bonfire 게임 화면.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int _epoch = 0;
  int _villageSeed = 20260619;
  String _scene = 'overworld';
  Vector2? _overworldSpawn; // 마을로 돌아올 때 위치
  int _houseSeed = 0;
  Vector2 _houseReturn = Vector2.zero();
  bool _storyShown = false;

  @override
  void initState() {
    super.initState();
    GameAudio.preload();
    GameEvents.instance.request.addListener(_onSceneRequest);
  }

  @override
  void dispose() {
    GameEvents.instance.request.removeListener(_onSceneRequest);
    super.dispose();
  }

  void _onSceneRequest() {
    final req = GameEvents.instance.request.value;
    if (req == null) return;
    GameEvents.instance.request.value = null; // 소비
    setState(() {
      if (req.scene == 'house') {
        _scene = 'house';
        _houseSeed = req.seed;
        _houseReturn = req.spawn;
      } else {
        _scene = 'overworld';
        _overworldSpawn = req.spawn;
      }
      _epoch++;
    });
  }

  void _respawn() {
    Wanted.instance.resetForRespawn();
    setState(() {
      _scene = 'overworld';
      _overworldSpawn = null;
      _villageSeed += 7; // 새 마을
      _epoch++;
    });
  }

  void _startGame() {
    GameState.running = true;
    GameAudio.startBgm();
    setState(() => _storyShown = true);
  }

  @override
  Widget build(BuildContext context) {
    final game =
        _scene == 'house' ? _buildInterior(context) : _buildOverworld(context);

    return Scaffold(
      backgroundColor: const Color(0xFF101a10),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: game),
          if (!_storyShown) Positioned.fill(child: StoryIntro(onStart: _startGame)),
        ],
      ),
    );
  }

  List<PlayerController> _controllers() => [
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
            JoystickAction(
              actionId: PlayerAction.attackRange,
              sprite: Sprite.load('joystick/joystick_attack_range.png'),
              size: 54,
              margin: const EdgeInsets.only(bottom: 116, right: 44),
            ),
          ],
        ),
        Keyboard(
          config: KeyboardConfig(
            directionalKeys: [
              KeyboardDirectionalKeys.arrows(),
              KeyboardDirectionalKeys.wasd(),
            ],
            acceptedKeys: [
              LogicalKeyboardKey.shiftRight,
              LogicalKeyboardKey.keyE,
              LogicalKeyboardKey.keyF,
            ],
          ),
        ),
      ];

  Map<String, Widget Function(BuildContext, BonfireGame)> _overlays() {
    return {
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
            tileCollisionColor: const Color(0xFF6b4a2b),
            playerColor: Colors.yellowAccent,
            enemyColor: Colors.redAccent,
            zoom: 0.55,
          ),
      'busted': (_, __) => BustedOverlay(onRespawn: _respawn),
      'settingsBtn': (_, __) => const SettingsButton(),
      'prompt': (_, __) => const InteractPrompt(),
      'panel': (_, game) => ValueListenableBuilder<Panel>(
            valueListenable: UiBus.instance.panel,
            builder: (_, p, __) {
              switch (p) {
                case Panel.quest:
                  return const QuestPanel();
                case Panel.shop:
                  return ShopPanel(game: game);
                case Panel.settings:
                  return const SettingsPanel();
                case Panel.none:
                  return const SizedBox.shrink();
              }
            },
          ),
    };
  }

  static const _overlayKeys = [
    'hud',
    'hint',
    'keyhint',
    'minimap',
    'busted',
    'settingsBtn',
    'prompt',
    'panel',
  ];

  Widget _buildOverworld(BuildContext context) {
    final rng = Random(_villageSeed);
    final world = VillageWorld(tile: 16, w: 64, h: 64, rng: rng);
    final spawn = _overworldSpawn ?? world.playerSpawn;

    return BonfireWidget(
      key: ValueKey('ow_$_epoch'),
      playerControllers: _controllers(),
      player: GtaPlayer(spawn),
      map: world.buildMap(),
      components: [
        ...world.decorations,
        WorldDirector(world.roadPoints, Random()),
      ],
      hudComponents: [DayNight()],
      cameraConfig: CameraConfig(
        moveOnlyMapArea: true,
        zoom: getZoomFromMaxVisibleTile(context, 16, 22),
        initPosition: spawn,
      ),
      backgroundColor: const Color(0xFF1c2a1c),
      overlayBuilderMap: _overlays(),
      initialActiveOverlays: _overlayKeys,
    );
  }

  Widget _buildInterior(BuildContext context) {
    final interior =
        Interior(tile: 16, seed: _houseSeed, returnSpawn: _houseReturn);

    return BonfireWidget(
      key: ValueKey('in_$_epoch'),
      playerControllers: _controllers(),
      player: GtaPlayer(interior.playerSpawn),
      map: interior.buildMap(),
      components: interior.components,
      cameraConfig: CameraConfig(
        moveOnlyMapArea: true,
        zoom: getZoomFromMaxVisibleTile(context, 16, 16),
        initPosition: interior.playerSpawn,
      ),
      backgroundColor: const Color(0xFF0d0a08),
      overlayBuilderMap: _overlays(),
      initialActiveOverlays: const [
        'hud',
        'keyhint',
        'busted',
        'settingsBtn',
        'prompt',
        'panel',
      ],
    );
  }
}
