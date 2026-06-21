import 'dart:math';

import 'package:bonfire/bonfire.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audio.dart';
import 'boss.dart';
import 'choice.dart';
import 'day_night.dart';
import 'director.dart';
import 'dungeon.dart';
import 'events.dart';
import 'faction.dart';
import 'hud.dart';
import 'input.dart';
import 'interior.dart';
import 'main_story.dart';
import 'panels.dart';
import 'player.dart';
import 'quests.dart';
import 'story.dart';
import 'story_arrow.dart';
import 'ui_bus.dart';
import 'village_map.dart';
import 'wanted.dart';

/// 중세 판타지 오픈월드 — 마을/집/던전을 오가는 Bonfire 게임 화면.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int _epoch = 0;
  int _villageSeed = 20260619;
  String _scene = 'overworld'; // overworld | house | dungeon1 | dungeon2
  Vector2? _overworldSpawn;
  int _houseSeed = 0;
  Vector2 _houseReturn = Vector2.zero();
  Vector2 _dungeonReturn = Vector2.zero();
  int _dungeonSeed = 7;
  bool _storyShown = false;

  @override
  void initState() {
    super.initState();
    GameAudio.preload();
    // 모든 스프라이트를 미리 디코드해 초반 끊김(렉) 완화.
    () async {
      try {
        await Flame.images.loadAllImages();
      } catch (_) {}
    }();
    GameEvents.instance.request.addListener(_onSceneRequest);
    UiBus.instance.panel.addListener(_onPanel);
    MenuKeys.instance.handler = _handleMenuKey;
  }

  @override
  void dispose() {
    GameEvents.instance.request.removeListener(_onSceneRequest);
    UiBus.instance.panel.removeListener(_onPanel);
    MenuKeys.instance.handler = null;
    super.dispose();
  }

  /// 메뉴/선택지 키보드 조작.
  void _handleMenuKey(LogicalKeyboardKey k) {
    final choice = ChoiceBus.instance.request.value;
    if (choice != null) {
      if (k == LogicalKeyboardKey.digit1) {
        ChoiceBus.instance.resolve(0);
      } else if (k == LogicalKeyboardKey.digit2) {
        ChoiceBus.instance.resolve(1);
      } else if (k == LogicalKeyboardKey.digit3) {
        ChoiceBus.instance.resolve(2);
      } else if (k == LogicalKeyboardKey.escape) {
        ChoiceBus.instance.resolve(-1);
      }
      return;
    }
    final panel = UiBus.instance.panel.value;
    if (panel == Panel.none) return;
    if (k == LogicalKeyboardKey.escape) {
      UiBus.instance.close();
      return;
    }
    if (panel == Panel.quest &&
        (k == LogicalKeyboardKey.enter ||
            k == LogicalKeyboardKey.numpadEnter)) {
      final a = QuestLog.instance.active.value;
      if (a != null) {
        if (a.isDone) QuestLog.instance.complete();
      } else {
        final n = QuestLog.instance.nextAvailable;
        if (n != null) QuestLog.instance.accept(n);
      }
      return;
    }
    if (panel == Panel.test) {
      const dests = ['overworld', 'house', 'dungeon1', 'dungeon2'];
      int? i;
      if (k == LogicalKeyboardKey.digit1) i = 0;
      if (k == LogicalKeyboardKey.digit2) i = 1;
      if (k == LogicalKeyboardKey.digit3) i = 2;
      if (k == LogicalKeyboardKey.digit4) i = 3;
      if (i != null) _teleport(dests[i]);
    }
  }

  void _onPanel() {
    if (UiBus.instance.panel.value == Panel.quest) {
      MainStory.instance.trigger(StoryTrigger.talkedQuestGiver);
    }
  }

  void _onSceneRequest() {
    final req = GameEvents.instance.request.value;
    if (req == null) return;
    GameEvents.instance.request.value = null;
    final prev = _scene;
    setState(() {
      switch (req.scene) {
        case 'house':
          _scene = 'house';
          _houseSeed = req.seed;
          _houseReturn = req.spawn;
          break;
        case 'dungeon1':
          _scene = 'dungeon1';
          _dungeonReturn = req.spawn;
          _dungeonSeed = req.seed;
          MainStory.instance.trigger(StoryTrigger.enteredCave);
          break;
        case 'dungeon2':
          _scene = 'dungeon2';
          _dungeonSeed = req.seed;
          MainStory.instance.trigger(StoryTrigger.descended);
          break;
        default: // overworld
          if (prev == 'dungeon2') {
            MainStory.instance.trigger(StoryTrigger.bossDown);
          }
          _scene = 'overworld';
          _overworldSpawn = req.spawn;
      }
      _epoch++;
    });
    if (req.scene == 'dungeon1') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _caveChoice());
    }
  }

  void _caveChoice() {
    ChoiceBus.instance.show(ChoiceRequest(
      speaker: '동굴 깡패',
      prompt: '"여기서부턴 우리 구역이다. 어쩔 테냐?"',
      options: [
        ChoiceOption('맞선다 — 검을 뽑는다', () {
          FactionState.instance.alert(Faction.cave);
        }),
        ChoiceOption('통행료를 낸다 (50 G)', () {
          if (Wanted.instance.money.value >= 50) {
            Wanted.instance.money.value -= 50;
            FactionState.instance.calm(Faction.cave);
          } else {
            FactionState.instance.alert(Faction.cave);
          }
        }),
        ChoiceOption('산적과 한패라 둘러댄다', () {
          // 동굴은 산적과 사이가 나쁘다 → 들통나 더 화남.
          FactionState.instance.alert(Faction.cave);
          FactionState.instance.alert(Faction.bandit);
        }),
      ],
      onTimeout: () {
        FactionState.instance.alert(Faction.cave); // 무답 → 공격
      },
    ));
  }

  void _respawn() {
    Wanted.instance.resetForRespawn();
    FactionState.instance.reset();
    BossState.instance.end();
    setState(() {
      _scene = 'overworld';
      _overworldSpawn = null;
      _villageSeed += 7;
      _epoch++;
    });
  }

  void _startGame() {
    GameState.running = true;
    GameAudio.startBgm();
    setState(() => _storyShown = true);
  }

  /// 테스트: 장소 즉시 이동.
  static final Vector2 _villageCenter = Vector2(336, 512); // 대략 마을 중심
  void _teleport(String dest) {
    UiBus.instance.close();
    BossState.instance.end();
    setState(() {
      switch (dest) {
        case 'house':
          _scene = 'house';
          _houseSeed = 42;
          _houseReturn = _villageCenter;
          break;
        case 'dungeon1':
          _scene = 'dungeon1';
          _dungeonReturn = _villageCenter;
          _dungeonSeed = 7;
          break;
        case 'dungeon2':
          _scene = 'dungeon2';
          _dungeonReturn = _villageCenter;
          _dungeonSeed = 7;
          break;
        default:
          _scene = 'overworld';
          _overworldSpawn = null;
      }
      _epoch++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget game;
    switch (_scene) {
      case 'house':
        game = _buildInterior(context);
        break;
      case 'dungeon1':
        game = _buildDungeon(context, 1);
        break;
      case 'dungeon2':
        game = _buildDungeon(context, 2);
        break;
      default:
        game = _buildOverworld(context);
    }
    return Scaffold(
      backgroundColor: const Color(0xFF101a10),
      body: Listener(
        onPointerDown: _onPointerDown,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: game),
            if (!_storyShown)
              Positioned.fill(child: StoryIntro(onStart: _startGame)),
          ],
        ),
      ),
    );
  }

  // 마우스 좌클릭=근접, 우클릭=원거리.
  void _onPointerDown(PointerDownEvent e) {
    if (!_storyShown) return;
    if (e.kind != PointerDeviceKind.mouse) return;
    if (UiBus.instance.panel.value != Panel.none ||
        ChoiceBus.instance.request.value != null) {
      return;
    }
    if (e.buttons == kSecondaryButton) {
      PlayerActions.instance.ranged?.call();
    } else if (e.buttons == kPrimaryButton) {
      PlayerActions.instance.melee?.call();
    }
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
              // 메뉴/선택지 키보드 조작
              LogicalKeyboardKey.digit1,
              LogicalKeyboardKey.digit2,
              LogicalKeyboardKey.digit3,
              LogicalKeyboardKey.digit4,
              LogicalKeyboardKey.enter,
              LogicalKeyboardKey.numpadEnter,
              LogicalKeyboardKey.escape,
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
            size: Vector2.all(140),
            margin: const EdgeInsets.only(bottom: 12, right: 12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24, width: 2),
            backgroundColor: Colors.black.withValues(alpha: 0.55),
            tileColor: const Color(0xFF3b5e3b),
            tileCollisionColor: const Color(0xFF6b4a2b),
            playerColor: Colors.yellowAccent,
            enemyColor: Colors.redAccent,
            zoom: 0.5,
          ),
      'busted': (_, __) => BustedOverlay(onRespawn: _respawn),
      'boss': (_, __) => const BossBar(),
      'settingsBtn': (_, __) => const SettingsButton(),
      'prompt': (_, __) => const InteractPrompt(),
      'choice': (_, __) => const ChoiceOverlay(),
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
                case Panel.test:
                  return TestPanel(onGo: _teleport);
                case Panel.none:
                  return const SizedBox.shrink();
              }
            },
          ),
    };
  }

  static const _owKeys = [
    'hud', 'hint', 'keyhint', 'minimap', 'busted', 'boss',
    'settingsBtn', 'prompt', 'choice', 'panel', //
  ];
  static const _indoorKeys = [
    'hud', 'keyhint', 'busted', 'boss',
    'settingsBtn', 'prompt', 'choice', 'panel', //
  ];

  Widget _buildOverworld(BuildContext context) {
    final world = VillageWorld(tile: 16, w: 64, h: 64, rng: Random(_villageSeed));
    final spawn = _overworldSpawn ?? world.playerSpawn;
    WorldInfo.instance.isBlocked = world.isWaterAt; // 물 끼임 복구 활성

    // 메인 스토리 목표 위치 설정.
    final beat = MainStory.instance.current;
    Vector2? marker;
    switch (beat.target) {
      case StoryTarget.questGiver:
        marker = world.questGiverPos;
        break;
      case StoryTarget.cave:
        marker = world.caveEntrance;
        break;
      case StoryTarget.none:
        marker = null;
    }
    MainStory.instance.marker.value = marker;

    return BonfireWidget(
      key: ValueKey('ow_$_epoch'),
      playerControllers: _controllers(),
      player: GtaPlayer(spawn),
      map: world.buildMap(),
      components: [
        ...world.decorations,
        if (marker != null) Beacon(marker),
        StoryArrow(),
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
      initialActiveOverlays: _owKeys,
    );
  }

  Widget _buildInterior(BuildContext context) {
    WorldInfo.instance.isBlocked = null;
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
      initialActiveOverlays: _indoorKeys,
    );
  }

  Widget _buildDungeon(BuildContext context, int floor) {
    WorldInfo.instance.isBlocked = null;
    final d = Dungeon(
      floorNum: floor,
      seed: _dungeonSeed,
      overworldReturn: _dungeonReturn,
    );
    return BonfireWidget(
      key: ValueKey('dg${floor}_$_epoch'),
      playerControllers: _controllers(),
      player: GtaPlayer(d.playerSpawn),
      map: d.buildMap(),
      components: d.components,
      hudComponents: [CaveDark()],
      cameraConfig: CameraConfig(
        moveOnlyMapArea: true,
        zoom: getZoomFromMaxVisibleTile(context, 16, 18),
        initPosition: d.playerSpawn,
      ),
      backgroundColor: const Color(0xFF05040a),
      overlayBuilderMap: _overlays(),
      initialActiveOverlays: _indoorKeys,
    );
  }
}
