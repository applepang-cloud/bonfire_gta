# Bonfire GTA — Top-down Open-World RPG

GTA풍 탑다운 오픈월드 RPG. Flutter + [Bonfire](https://github.com/RafaelBarbosatec/bonfire) 엔진(3.17)으로 제작했고,
Bonfire 공식 예제에 포함된 리소스를 그대로 사용했습니다.

## ▶ Play
**https://applepang-cloud.github.io/bonfire_gta/**

- 이동: `WASD` / 방향키 (모바일: 좌측 조이스틱)
- 공격: `Space` (모바일: 우측 검 버튼)

## 게임 메커닉
- 절차적 도시(MatrixMap): 도로 격자 · 잔디 블록 · 연못 · 나무/건물/전리품
- **수배(Wanted) 시스템**: 시민·경찰을 공격하면 별(★)이 오르고 경찰이 추격, 시간이 지나면 진정
- 갱단 추격전, 근접 전투, 돈/회복 물약 수집, BUSTED → 리스폰
- HUD(돈·처치·체력·수배별) + 미니맵

## Build
```bash
flutter pub get
flutter build web --base-href /bonfire_gta/
```

## Credits
- Engine: [Bonfire](https://github.com/RafaelBarbosatec/bonfire) (MIT) by Rafael Barbosa
- Art: Bonfire example assets
