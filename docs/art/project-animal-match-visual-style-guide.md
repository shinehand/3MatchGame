# Project Animal Match Visual Style Guide

## 1. 비주얼 방향

`Project Animal Match`의 화면은 밝고 선명해야 한다. 배경은 부드럽고 낮은 대비로 두며, 퍼즐 블록과 목표 UI는 작은 모바일 화면에서도 즉시 읽히도록 고대비 실루엣을 사용한다.

## 2. MVP 보드 기준 동물 12종

보드 런타임 로스터는 12종으로 시작하되, 한 스테이지에 동시에 나오는 동물은 5-6종으로 제한한다. 글로벌 런칭 콘텐츠는 컬렉션/이벤트 예비 동물 6종을 더해 18종까지 준비하고, 시즌 운영에서는 24종까지 확장한다. 이렇게 해야 수집감은 커지고, 매치 확률과 보드 가독성은 무너지지 않는다.

| 동물 | 성격 | 외형 특징 | 대표 색 | 애니메이션 포인트 |
| --- | --- | --- | --- | --- |
| 토끼 | 빠르고 긍정적 | 긴 귀, 둥근 볼, 작은 앞니 | `#FFB7C8` | 귀가 살짝 튀고 빠른 blink |
| 고양이 | 영리하고 새침함 | 삼각 귀, 큰 눈, 수염 3줄 | `#FFD166` | 눈웃음, 수염 흔들림 |
| 곰 | 든든하고 느긋함 | 둥근 귀, 큰 코, 넓은 얼굴 | `#B9855A` | 느린 미소, 코 반짝임 |
| 병아리 | 활발하고 귀여움 | 작은 부리, 동그란 몸, 머리 깃 | `#FFE45E` | 부리 열림, 머리 깃 bounce |
| 개구리 | 장난스럽고 탄력 있음 | 튀어나온 눈, 넓은 입 | `#5FD39B` | 눈이 위아래로 통통 움직임 |
| 여우 | 똑똑하고 화려함 | 뾰족한 귀, 흰 볼, 풍성한 꼬리 모티프 | `#FF8A4C` | 한쪽 눈 찡긋, 얕은 미소 |
| 강아지 | 친근하고 명랑함 | 접힌 귀, 둥근 코, 혀 포인트 | `#7EC8FF` | 혀 살짝 내밀기, 귀 흔들림 |
| 판다 | 느긋하고 포근함 | 흑백 눈 패치, 둥근 얼굴 | `#F5F7FA` | 느린 blink, 볼 눌림 |
| 돼지 | 낙천적이고 풍성함 | 동그란 코, 작은 귀, 분홍 볼 | `#FF9FB8` | 코 통통, 밝은 웃음 |
| 펭귄 | 차분하고 귀여움 | 흰 배, 남색 머리, 작은 부리 | `#4D6BFF` | 좌우 흔들림, 짧은 blink |
| 사자 | 용감하고 당당함 | 둥근 갈기, 큰 눈썹, 따뜻한 미소 | `#F2A23A` | 갈기 glow, 자신감 있는 미소 |
| 코끼리 | 든든하고 상징적 | 큰 귀, 짧은 코, 부드러운 눈 | `#9AA7B8` | 귀 펄럭임, 느린 blink |

## 3. 이미지 생성 프롬프트

공통 프롬프트:

```text
cute mobile match-3 puzzle animal face icon, rounded sticker shape, clean vector-like 3D cartoon style, soft bevel, expressive eyes, simple silhouette, high readability at small size, pastel game art, transparent background, centered composition, no text, no watermark
```

동물별 추가 프롬프트:

| 동물 | 추가 프롬프트 |
| --- | --- |
| 토끼 | `pink rabbit, long soft ears, tiny buck teeth, cheerful smile` |
| 고양이 | `golden cat, triangle ears, three whiskers on each side, clever playful expression` |
| 곰 | `warm brown bear, round ears, large soft nose, calm friendly face` |
| 병아리 | `yellow chick, tiny orange beak, fluffy head feather, bright curious eyes` |
| 개구리 | `green frog, big raised eyes, wide smile, bouncy playful look` |
| 여우 | `orange fox, sharp ears, white cheek fur, sly cute smile, fluffy tail badge motif` |
| 강아지 | `sky blue puppy, floppy ears, round nose, tiny tongue, friendly loyal expression` |
| 판다 | `soft panda, black eye patches, round fluffy face, calm cozy smile` |
| 돼지 | `pink piglet, round snout, tiny ears, rosy cheeks, optimistic happy face` |
| 펭귄 | `navy penguin, white belly face shape, tiny orange beak, gentle clever eyes` |
| 사자 | `golden lion cub, soft round mane, brave friendly smile, warm confident eyes` |
| 코끼리 | `baby elephant, large soft ears, short trunk, gentle kind eyes, sturdy cute face` |

네거티브 프롬프트:

```text
realistic fur, scary face, thin line details, busy background, text, logo, watermark, tiny unreadable features, dark gritty lighting
```

## 4. UI/UX 설계

### 퍼즐 판

- 셀은 같은 크기의 정사각형을 유지한다.
- 동물 얼굴은 셀 내부의 78-86%를 차지한다.
- 특수 블록 표시는 동물 얼굴을 가리지 않는 상단/하단 작은 배지로 둔다.
- 선택 상태는 두꺼운 glow보다 짧은 scale-up과 외곽 링으로 표현한다.

### 버튼

- 터치 영역은 최소 48dp 이상으로 둔다.
- 주요 버튼은 노랑/민트 계열, 위험 또는 닫기는 코랄/레드 계열을 사용한다.
- 버튼 텍스트는 짧게 유지하고, 반복 기능은 아이콘을 함께 사용한다.

### 팝업

- 결과 팝업은 별, 목표 달성, 보상, 다음 행동 순서로 정보 위계를 둔다.
- 실패 팝업은 비난 문구보다 `조금만 더!` 계열의 재도전 감정을 준다.
- 결제/광고 팝업은 보상량과 소모 자원을 한눈에 비교 가능해야 한다.

## 5. 에셋 제작 파이프라인

1. AI 이미지 생성: 동물별 4-8개 후보를 만든다.
2. 선별: 작은 화면 64px 미리보기에서 실루엣과 표정이 읽히는 후보만 남긴다.
3. 정리: 배경 제거, 색상 보정, 외곽선 두께 통일.
4. 리사이즈: 원본 1024px, 게임용 256px, 저사양용 128px export.
5. 스프라이트 시트: 기본 얼굴과 눈/입 오버레이를 우선 분리하고, 필요한 동물만 full-frame 표정 프레임을 추가한다.
6. Godot import: filtering, compression, atlas grouping 규칙을 동일하게 적용.
7. 검증: 실제 보드 7x7/8x8에서 겹침, 흐림, 색상 혼동을 확인.

## 6. 동물 표정/애니메이션 에셋 계획

### 6.1 기본 표정 세트

모든 동물은 최소 6개 상태를 가진다.

| 상태 | 용도 | 권장 프레임 |
| --- | --- | --- |
| `idle` | 기본 대기 | 1 |
| `blink` | 눈깜빡임 | 3 |
| `smile` | 선택/기분 좋은 반응 | 2-3 |
| `match` | 매치 성공 직전 | 3-4 |
| `fever` | 피버 중 하이라이트 | 2-3 |
| `worried` | 실패 직전/이동 수 부족 | 2 |

### 6.2 제작 방식

- 1차 구현은 `기본 얼굴 + 눈/입 오버레이` 방식을 우선한다.
- 귀, 코, 갈기처럼 동물별 개성이 강한 부분은 full-frame 보조 프레임을 허용한다.
- 모든 동물의 blink 타이밍이 동시에 맞지 않도록, Godot에서 랜덤 지연을 둔다.
- 작은 보드에서는 idle 애니메이션보다 선택, 매치, 피버 반응을 우선한다.

### 6.3 스프라이트 시트 구성

- 행: 동물 id
- 열: `idle`, `blink_01`, `blink_02`, `blink_03`, `smile_01`, `smile_02`, `match_01`, `match_02`, `match_03`, `fever_01`, `fever_02`, `worried_01`, `worried_02`
- 기본 해상도: 256x256
- 저사양 해상도: 128x128
- atlas 최대 크기: 2048x2048 단위로 분리

## 7. 파일명 규칙

### 7.1 1차 Godot 런타임 기본 블록

현재 Godot 런타임은 `assets/generated/candy/{id}_candy_block.png`를 기본 블록 텍스처로 로드한다. MVP 보드 로스터는 이 규칙을 유지하고, `lion`, `elephant`도 전용 기본 블록 PNG를 사용한다. 코드의 명시 fallback은 에셋 누락 시 보드를 깨뜨리지 않는 방어 경로로만 유지한다.

```text
assets/generated/candy/rabbit_candy_block.png
assets/generated/candy/bear_candy_block.png
assets/generated/candy/cat_candy_block.png
assets/generated/candy/chick_candy_block.png
assets/generated/candy/frog_candy_block.png
assets/generated/candy/dog_candy_block.png
assets/generated/candy/panda_candy_block.png
assets/generated/candy/pig_candy_block.png
assets/generated/candy/penguin_candy_block.png
assets/generated/candy/fox_candy_block.png
assets/generated/candy/lion_candy_block.png
assets/generated/candy/elephant_candy_block.png
```

### 7.2 표정/아틀라스 확장 파일

- 기본 표정 프레임: `animal_{id}_normal.png`
- 눈깜빡임: `animal_{id}_blink_{01..03}.png`
- 웃음: `animal_{id}_smile_{01..03}.png`
- 매치 표정: `animal_{id}_match_{01..04}.png`
- 피버 표정: `animal_{id}_fever_{01..03}.png`
- 걱정 표정: `animal_{id}_worried_{01..02}.png`
- 특수 배지: `badge_{line|bomb|rainbow}.png`
- 아틀라스: `atlas_animals_base.png`, `atlas_animals_fever.png`

예시:

```text
animal_rabbit_normal.png
animal_rabbit_blink_01.png
animal_rabbit_blink_02.png
animal_rabbit_blink_03.png
animal_rabbit_smile_01.png
animal_rabbit_match_01.png
animal_rabbit_fever_01.png
animal_rabbit_worried_01.png
badge_line_horizontal.png
badge_bomb_paw.png
badge_rainbow_herd.png
```

## 8. 컬러 팔레트

| 용도 | 색상 |
| --- | --- |
| 배경 하늘 | `#DDF5FF` |
| 초원/성공감 | `#8DE3B0` |
| 주요 CTA | `#FFD85A` |
| 보조 CTA | `#63D7C6` |
| 경고/실패 | `#FF6B6B` |
| 피버 강조 | `#A78BFA` |
| 텍스트 진한색 | `#26384D` |
| 패널 밝은색 | `#FFFFFF` |
| 패널 그림자 | `#9CB7C9` |

## 9. 가시성 원칙

- 같은 채도의 파스텔만 반복하지 않는다.
- 동물 12종은 색상, 얼굴형, 귀/눈/입 형태를 모두 다르게 둔다.
- 보드에 동시에 등장하는 동물은 5-6종으로 제한해 작은 화면의 식별성을 지킨다.
- 목표 칩은 현재 보드 블록과 같은 아이콘을 쓰되, 수량 숫자는 진한색과 흰 외곽으로 분리한다.
- 피버 상태에서도 보드 판독성이 떨어지지 않도록 배경 이펙트 투명도는 35% 이하로 제한한다.
