# Project Animal Match Animal Roster & Animation Matrix

## 목적

이 문서는 동물 수 확장, 보드 출현 제한, 표정 애니메이션 제작 범위, 개발 구현 계약을 한곳에 묶는 기획 기준이다. 아트팀은 어떤 동물을 어떤 성격과 움직임으로 만들지 확인하고, 개발팀은 어떤 `animal_id`와 `expression_id`를 지원해야 하는지 확인하며, QA팀은 어떤 상태를 반드시 검수해야 하는지 확인한다.

## 로스터 운영 원칙

- 보드 플레이 안정성을 위해 한 스테이지의 `animal_pool`은 5-6종으로 유지한다.
- 수집감과 라이브 운영 확장성을 위해 전체 동물 수는 보드 출현 수보다 크게 운영한다.
- 현재 Godot 런타임과 validator의 1차 보드 로스터는 12종이다.
- 글로벌 런칭 콘텐츠 목표는 `보드 동물 12종 + 컬렉션/이벤트 예비 동물 6종`으로 총 18종을 준비한다.
- 시즌 운영 1차 목표는 총 24종이다. 13-24번 동물은 바로 보드에 넣지 않고 Rescue Book, 이벤트, 꾸미기 보상으로 먼저 노출한다.
- 신규 동물이 보드에 들어갈 때는 색상, 실루엣, 눈/귀/입 형태가 기존 5-6종 풀과 겹치지 않는지 먼저 검증한다.

## 로스터 단계

| 단계 | 수량 | 용도 | 구현 상태 | 기준 |
| --- | ---: | --- | --- | --- |
| MVP runtime | 12 | 실제 보드 블록, 스테이지 목표, Rescue Buddy 후보 | 현재 코드 기준 | `scripts/gameplay.gd`, `scripts/stage_data_validator.gd` |
| Launch collection | 18 | Rescue Book 카드, 이벤트 예고, 소프트 런칭 보상 | 기획/아트 준비 | 보드 투입 전 컬렉션으로 먼저 검증 |
| Live season | 24 | 시즌 패스, 기간 한정 수집, 신규 에피소드 | 운영 확장 | 원격 설정과 이벤트 데이터로 노출 |

## 12종 보드 로스터 매트릭스

| animal_id | 이름 | 해금 밴드 | 시각 역할 | 성격 | 핵심 실루엣 | 대표 애니메이션 | Buddy 후보 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `rabbit` | 토끼 | Stage 1 | 분홍/빠른 반응 | 첫 친구, 낙천적 | 긴 귀 | 귀 bounce, 빠른 blink | 첫 Rescue Buddy 1순위 |
| `bear` | 곰 | Stage 1 | 갈색/무게감 | 든든함 | 둥근 귀와 큰 코 | 느린 smile, 코 sparkle | 보호/회복형 |
| `cat` | 고양이 | Stage 1 | 노랑/영리함 | 새침하고 똑똑함 | 삼각 귀, 수염 | wink, 수염 twitch | 힌트/라인형 |
| `chick` | 병아리 | Stage 1 | 노랑/가벼움 | 활발함 | 작은 부리와 깃 | 부리 open, 깃 bounce | 작은 폭발형 |
| `frog` | 개구리 | Stage 11 | 초록/탄력 | 장난스러움 | 튀어나온 눈 | 눈 pop, 통통 jump | 셔플/점프형 |
| `dog` | 강아지 | Stage 11 | 하늘/친근함 | 명랑함 | 접힌 귀, 코 | 귀 flap, 혀 smile | 목표 수집형 |
| `panda` | 판다 | Stage 21 | 흑백/포근함 | 느긋함 | 눈 패치 | 느린 blink, 볼 squash | 보호막/완충형 |
| `pig` | 돼지 | Stage 21 | 분홍/풍성함 | 낙천적 | 둥근 코 | 코 pop, 활짝 smile | 코인/보상형 |
| `penguin` | 펭귄 | Stage 31 | 남색/차분함 | 침착함 | 흰 배, 작은 부리 | 좌우 wobble | 얼음/줄 제거형 |
| `fox` | 여우 | Stage 31 | 주황/화려함 | 재치 있음 | 뾰족 귀, 흰 볼 | wink, 꼬리 badge pulse | 콤보 강화형 |
| `lion` | 사자 | Stage 51 | 금색/리더감 | 용감함 | 둥근 갈기 | 갈기 glow, 당당한 smile | 피버 충전형 |
| `elephant` | 코끼리 | Stage 81 | 회청/든든함 | 상냥함 | 큰 귀, 짧은 코 | 귀 flap, 느린 blink | 대형 장애물 제거형 |

## 컬렉션/이벤트 예비 동물 6종

이 6종은 글로벌 런칭 전 아트 콘셉트와 Rescue Book 카드로 먼저 준비한다. 보드 투입은 validator와 밸런스 검증이 확장된 뒤 진행한다.

| animal_id 후보 | 이름 | 우선 노출 | 보드 투입 조건 |
| --- | --- | --- | --- |
| `koala` | 코알라 | 소프트 런칭 로그인 보상 | 회색 계열이 코끼리와 구분되는 얼굴형 확보 |
| `hamster` | 햄스터 | Starter Mission 보상 | 돼지/곰과 둥근 실루엣 충돌 방지 |
| `deer` | 사슴 | 시즌 1 카드 | 뿔이 작은 보드에서도 읽히는지 검증 |
| `seal` | 물범 | 겨울 이벤트 | 펭귄과 남색/흰색 조합 충돌 방지 |
| `sheep` | 양 | 친구 초대 보상 | 구름형 털 외곽선 가독성 확보 |
| `turtle` | 거북 | 느긋한 회복 이벤트 | 개구리와 초록색 충돌 방지 |

## 표현 상태 계약

MVP 개발은 아래 6개 `expression_id`만 필수로 지원한다. 추가 감정은 overlay 플래그로 처리하고, 엔진 구현이 확장되기 전까지는 기존 6개 상태로 매핑한다.

| expression_id | 필수 여부 | 발동 조건 | 길이 | 우선순위 | fallback |
| --- | --- | --- | --- | ---: | --- |
| `idle` | 필수 | 기본 대기 | 상시 | 0 | 정지 이미지 |
| `blink` | 필수 | idle scheduler | 0.12-0.18s | 1 | Y scale 0.82 후 복귀 |
| `smile` | 필수 | 선택, 힌트, 목표 근접 | 0.20-0.30s | 2 | scale 1.06 + 밝기 증가 |
| `match` | 필수 | 제거 직전 | 0.16-0.22s | 3 | scale-up 후 fade |
| `fever` | 필수 | 피버 중 목표/특수 타일 | 0.45-0.60s loop | 2 | rim light + pulse |
| `worried` | 필수 | 이동 수 3 이하, 실패 직전 | 0.50-0.80s | 2 | 2px shake + 채도 감소 |

## Overlay 플래그

| overlay_id | 용도 | MVP 매핑 |
| --- | --- | --- |
| `buddy_ready` | Rescue Buddy 충전 완료 | `smile` + 작은 badge pulse |
| `buddy_cast` | Rescue Buddy 발동 | `fever` 1회 재생 |
| `new_card` | Rescue Book 신규 카드 | 카드 UI에서만 glow |
| `favorite` | 장착/선호 동물 표시 | 보드가 아니라 컬렉션 UI에서만 사용 |

## 동물별 애니메이션 디렉션

| animal_id | blink | smile | match | fever | worried | buddy_cast |
| --- | --- | --- | --- | --- | --- | --- |
| `rabbit` | 귀가 1px 내려오며 빠르게 감김 | 귀가 위로 튀고 볼 밝아짐 | 귀 bounce 후 pop | 귀 끝 rim light | 귀가 살짝 처짐 | 귀로 목표 한 줄을 가리킴 |
| `bear` | 느린 눈감기 | 입꼬리와 코 sparkle | 코가 반짝인 뒤 pop | 몸통이 묵직하게 pulse | 눈썹이 내려감 | 앞발 stamp shockwave |
| `cat` | 한쪽 눈 먼저 감김 | wink + 수염 흔들림 | 수염 sparkle | 눈 하이라이트 반복 | 귀가 뒤로 눕는 느낌 | 발톱 slash line |
| `chick` | 작은 눈을 빠르게 감음 | 부리가 살짝 열림 | 머리 깃 bounce | 부리와 깃 glow | 부리가 아래로 닫힘 | 작은 알 burst |
| `frog` | 눈이 아래로 내려감 | 넓은 입 smile | 눈 pop 후 제거 | 몸이 통통 튐 | 입이 작아짐 | 점프 landing burst |
| `dog` | 양쪽 눈 부드럽게 감김 | 혀가 살짝 보임 | 귀 flap 후 pop | 꼬리 badge pulse | 귀가 처짐 | 목표 칩으로 달려가는 trail |
| `panda` | 가장 느린 blink | 볼 squash | 둥글게 눌렸다 pop | 흑백 rim contrast | 눈 패치가 아래로 눌림 | 대나무형 보호 pulse |
| `pig` | 코와 함께 blink | 코 pop + 볼 붉어짐 | 코 sparkle 후 pop | 코가 리듬감 있게 pulse | 코가 아래로 처짐 | 코인/하트 sparkle |
| `penguin` | 짧고 단정한 blink | 좌우 wobble | 작은 slide 후 pop | 차가운 푸른 rim | 몸을 움츠림 | 얼음 trail line |
| `fox` | wink 중심 | 새침한 미소 | 꼬리 badge flash | 주황 glow + 눈 sparkle | 귀가 낮아짐 | 콤보 불꽃 trail |
| `lion` | 눈썹이 함께 움직임 | 자신감 있는 smile | 갈기 flash 후 pop | 갈기 전체 glow | 갈기가 살짝 가라앉음 | 피버 게이지 roar pulse |
| `elephant` | 귀가 천천히 접힘 | 코가 짧게 올라감 | 귀 flap 후 pop | 큰 귀 rim light | 코가 아래로 내려감 | 코로 장애물 sweep |

## 제작량 기준

### MVP 최소 패키지

동물 12종 각각 아래 파일을 준비한다.

```text
animal_{id}_normal.png
animal_{id}_blink_01.png
animal_{id}_blink_02.png
animal_{id}_blink_03.png
animal_{id}_smile_01.png
animal_{id}_smile_02.png
animal_{id}_match_01.png
animal_{id}_match_02.png
animal_{id}_match_03.png
animal_{id}_fever_01.png
animal_{id}_fever_02.png
animal_{id}_worried_01.png
animal_{id}_worried_02.png
```

동물당 13프레임, 12종 기준 156프레임이다. 1차 구현에서는 눈/입 overlay를 재사용해 실제 full-frame 제작량을 줄인다.

### Atlas 구성

- `atlas_animals_base_01.png`: rabbit, bear, cat, chick, frog, dog
- `atlas_animals_base_02.png`: panda, pig, penguin, fox, lion, elephant
- `atlas_animals_overlay_eye.png`: 공통 눈/깜빡임 overlay
- `atlas_animals_overlay_mouth.png`: 공통 웃음/걱정 overlay
- 최대 atlas 크기: 2048x2048
- 셀 기준: 256x256, 저사양 옵션 128x128

## 개발 구현 계약

### 데이터 후보

```json
{
  "animal_id": "rabbit",
  "display_name": "토끼",
  "unlock_stage": 1,
  "roster_tier": "mvp_runtime",
  "board_enabled": true,
  "collection_enabled": true,
  "animation_profile": "rabbit_v1",
  "buddy_skill_id": "rabbit_line_rescue"
}
```

### Animation profile 후보

```json
{
  "profile_id": "rabbit_v1",
  "animal_id": "rabbit",
  "states": {
    "idle": { "frames": ["normal"], "loop": true },
    "blink": { "frames": ["blink_01", "blink_02", "blink_03"], "duration": 0.16 },
    "smile": { "frames": ["smile_01", "smile_02"], "duration": 0.24 },
    "match": { "frames": ["match_01", "match_02", "match_03"], "duration": 0.18 },
    "fever": { "frames": ["fever_01", "fever_02"], "duration": 0.50, "loop": true },
    "worried": { "frames": ["worried_01", "worried_02"], "duration": 0.60 }
  }
}
```

### 코드 연결

- `scripts/gameplay.gd`의 `ANIMAL_IDS`는 MVP 보드 로스터 12종과 일치해야 한다.
- `scripts/stage_data_validator.gd`의 유효 동물 목록은 `board_enabled == true` 동물만 허용한다.
- 컬렉션 전용 동물은 보드 validator에 들어가기 전까지 stage JSON의 `animal_pool`에 쓰지 않는다.
- `scripts/block_tile.gd`의 `set_expression()`은 알 수 없는 expression을 받으면 `idle`로 안전하게 fallback한다.
- expression scheduler는 `is_busy == false`와 `stage_state == "playing"` 조건을 유지한다.

## QA 검수 기준

| 검수 항목 | 통과 기준 |
| --- | --- |
| 12종 식별성 | 64px 미리보기에서 모든 동물이 이름 없이 구분된다. |
| Blink 동시성 | 보드 전체에서 동시에 blink하는 타일이 4개를 넘지 않는다. |
| Match 우선순위 | 제거 직전 `match`가 `blink`, `smile`, `worried`보다 우선한다. |
| Fever 판독성 | 피버 중에도 목표 동물과 일반 동물 구분이 가능하다. |
| Worried 남용 방지 | 이동 수 3 이하에서만 짧게 보이고 상시 불안해 보이지 않는다. |
| 컬렉션 확장 | 13-18번 동물이 보드 풀에 들어가지 않아도 Rescue Book 카드로 표시된다. |

## 완료 조건

- MVP 보드 동물 12종과 Launch collection 18종의 역할이 구분되어 있다.
- 모든 MVP 동물에 `blink`, `smile`, `match`, `fever`, `worried` 표현 방향이 정의되어 있다.
- 신규 동물은 컬렉션 노출과 보드 투입 조건이 분리되어 있다.
- 개발 에이전트가 데이터 모델, atlas, validator, expression API 연결 범위를 확인할 수 있다.
- QA 에이전트가 12종 식별성, 동시 애니메이션 제한, 우선순위 충돌을 검수할 수 있다.
