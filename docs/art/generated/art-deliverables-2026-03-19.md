# Art Deliverables 2026-03-19

## 목적

- 제품화 알파 1차 아트 산출물을 기록한다.

## 이번 산출물

### UI Theme Core

- [button_primary.svg](/Users/shinehandmac/Documents/puzzle/assets/ui/theme/button_primary.svg)
- [button_secondary.svg](/Users/shinehandmac/Documents/puzzle/assets/ui/theme/button_secondary.svg)
- [button_pressed.svg](/Users/shinehandmac/Documents/puzzle/assets/ui/theme/button_pressed.svg)
- [panel_card.svg](/Users/shinehandmac/Documents/puzzle/assets/ui/theme/panel_card.svg)
- [popup_frame.svg](/Users/shinehandmac/Documents/puzzle/assets/ui/theme/popup_frame.svg)
- [topbar_frame.svg](/Users/shinehandmac/Documents/puzzle/assets/ui/theme/topbar_frame.svg)

### HUD Set

- [goal_chip_frame.svg](/Users/shinehandmac/Documents/puzzle/assets/ui/hud/goal_chip_frame.svg)
- [moves_badge.svg](/Users/shinehandmac/Documents/puzzle/assets/ui/hud/moves_badge.svg)
- [score_badge.svg](/Users/shinehandmac/Documents/puzzle/assets/ui/hud/score_badge.svg)
- [pause_icon.svg](/Users/shinehandmac/Documents/puzzle/assets/ui/hud/pause_icon.svg)

### Meta UI

- [stage_card_frame.svg](/Users/shinehandmac/Documents/puzzle/assets/ui/meta/stage_card_frame.svg)
- [stage_lock.svg](/Users/shinehandmac/Documents/puzzle/assets/ui/meta/stage_lock.svg)

### Band Background Variants

- [bg_band_01_sub.svg](/Users/shinehandmac/Documents/puzzle/assets/backgrounds/bands/bg_band_01_sub.svg)
- [bg_band_02_main.svg](/Users/shinehandmac/Documents/puzzle/assets/backgrounds/bands/bg_band_02_main.svg)

### Local SD Concepts

- [home_mascot_rabbit_v1_flat.png](/Users/shinehandmac/Documents/puzzle/assets/generated/redesign/home_mascot_rabbit_v1_flat.png)
- [home_mascot_chick_v1_flat.png](/Users/shinehandmac/Documents/puzzle/assets/generated/redesign/home_mascot_chick_v1_flat.png)
- [overlay_success_cat_v1_flat.png](/Users/shinehandmac/Documents/puzzle/assets/generated/redesign/overlay_success_cat_v1_flat.png)
- [overlay_fail_bear_v1_flat.png](/Users/shinehandmac/Documents/puzzle/assets/generated/redesign/overlay_fail_bear_v1_flat.png)

### State and Campaign Support

- [goal_complete_badge.svg](/Users/shinehandmac/Documents/puzzle/assets/ui/hud/goal_complete_badge.svg)
- [goal_near_complete_badge.svg](/Users/shinehandmac/Documents/puzzle/assets/ui/hud/goal_near_complete_badge.svg)
- [stage_current_badge.svg](/Users/shinehandmac/Documents/puzzle/assets/ui/meta/stage_current_badge.svg)
- [stage_finale_badge.svg](/Users/shinehandmac/Documents/puzzle/assets/ui/meta/stage_finale_badge.svg)
- [combo_pop.svg](/Users/shinehandmac/Documents/puzzle/assets/ui/effects/combo_pop.svg)
- [combo_great.svg](/Users/shinehandmac/Documents/puzzle/assets/ui/effects/combo_great.svg)
- [rescue_ribbon.svg](/Users/shinehandmac/Documents/puzzle/assets/ui/meta/rescue_ribbon.svg)

## 생성 방식

### 벡터 UI 자산

- 방식: 수동 SVG 제작
- 이유: 버튼, 카드, 팝업, HUD 프레임은 정밀도와 반복성이 더 중요하다.

### Local SD 컨셉 이미지

- 모델: `dreamshaper_8`
- 출력: `1024x1024`

#### Home mascot rabbit

- Seed: `3137655987`
- Prompt:

```text
cute mobile puzzle game mascot, rabbit face only, block-first style, sticker-like 2d illustration, thick clean outline, pastel pink ears, big friendly eyes, rounded cheeks, centered portrait, simple soft cream background, cheerful and readable, polished game asset concept, no body, no text
```

#### Success overlay cat

- Seed: `3718690846`
- Prompt:

```text
cute mobile puzzle game success overlay mascot, smiling cat face only, sticker-like 2d illustration, thick clean outline, warm orange and cream palette, star accents, joyful expression, centered portrait, simple pastel background, readable at small size, polished game art concept, no body, no text
```

#### Fail overlay bear

- Seed: `3716065705`
- Prompt:

```text
cute mobile puzzle game fail overlay mascot, bear face only, block-first sticker style, rounded cheeks, slightly worried but lovable expression, thick clean outline, warm brown and cream palette, centered portrait, simple pastel background, readable at small size, polished game art concept, no body, no text
```

#### Home mascot chick

- Seed: `4171801030`
- Prompt:

```text
cute mobile puzzle game home mascot, chick face only, block-first sticker style, bright yellow and cream palette, huge sparkling eyes, rounded silhouette, cheerful expression, thick clean outline, centered portrait, soft pastel background, readable at small size, polished game art concept, no body, no text
```

## 판단

- UI 코어 자산은 벡터 방식이 가장 적합했다.
- 일러스트성 마스코트와 감정형 오버레이 초안은 Local SD가 빠르게 방향을 확인하는 데 유효했다.
- Planning Team 피드백 기준으로 `상태 변화`, `서사 전달`, `캠페인 진행감`을 보강하는 리소스를 추가했다.
- 개발팀에서 홈, 스테이지 카드, 플레이 HUD, 오버레이에 1차 씬 적용을 진행했다.
- 검증: `./scripts/validate_gameplay.sh` 통과
- 다음 라운드는 `홈 마스코트 추가 1종`, `밴드 배경 21-30`, `HUD 상태 오버레이 실제 연결` 순서가 적절하다.
