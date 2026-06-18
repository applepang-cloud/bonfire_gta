# 변경의 기사 (A Knight of the Frontier)

중세 판타지 탑다운 오픈월드 액션 RPG. Flutter + [Bonfire](https://github.com/RafaelBarbosatec/bonfire) 엔진(3.17).
위쳐풍의 변경 마을을 누비며 산적과 괴물을 베고, 집집마다 사는 가족을 만나는 게임.

## ▶ Play
**https://applepang-cloud.github.io/bonfire_gta/**

- 이동: `WASD` / 방향키 (모바일: 좌측 조이스틱)
- 공격: `우 Shift` (모바일: 우측 검 버튼) — "얍!" 기합과 함께
- 집 문으로 들어가면 가족이 사는 내부로. 무기를 들면 놀라 물러서고, 때리면 맞서 싸운다.

## 특징
- **절차적 중세 마을**: 굽이치는 흙길, 강, 숲, 직접 그린 중세 가옥(빨강/초록/초가 지붕)
- **진입 가능한 집 + 가족 반응**: 문 센서로 내부 전환, 침입자에게 놀라거나 분노
- **악명(Wanted) 시스템**: 마을 사람·경비병을 해치면 악명★이 오르고 경비병이 추격
- **다양한 NPC/몬스터 대사**: 마을 사람·산적·괴물·경비병·가족이 머리 위로 끊임없이 대사
- **사운드**: 중세풍 BGM 루프, 검 휘두름/타격/획득 효과음, 한국어 공격 음성("얍!/이얍!/하압!")
- HUD(골드·처치·악명·체력) + 미니맵, 스토리 인트로, BUSTED/리스폰

## 리소스
- 캐릭터/지형: Bonfire 예제 에셋(knight, goblin, orc, critter, 지형 타일 등)
- 가옥·인테리어 타일: `tool/make_sprites.js`로 직접 생성한 픽셀아트
- 오디오: `tool/make_audio.js`(효과음/BGM) + Windows SAPI Heami(한국어 음성)

## Build & Deploy
```bash
flutter pub get
flutter build web --base-href /bonfire_gta/   # 또는 ./deploy.ps1
```

## Credits
- Engine: [Bonfire](https://github.com/RafaelBarbosatec/bonfire) (MIT) · Flame
- 일부 아트: Bonfire example assets
