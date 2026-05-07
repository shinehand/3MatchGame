# Project Animal Match Animation & VFX Development Document

## 1. 연출 목표

한 번의 스와이프가 즉시 반응하고, 매치와 연쇄가 짧고 강한 보상으로 이어지게 만든다. 모든 연출은 모바일 저사양 기기에서도 안정적으로 돌아가야 한다.

## 2. Tween 연출

| 상황 | 시간 | Easing | 설명 |
| --- | --- | --- | --- |
| 유효 스왑 이동 | 0.12s | `TRANS_BACK`, `EASE_OUT` | 살짝 튕기며 자리 교환 |
| 무효 스왑 복귀 | 0.09s + 0.09s | `TRANS_SINE`, `EASE_IN_OUT` | 갔다가 바로 되돌아오며 약한 shake |
| 매치 pop scale-up | 0.07s | `TRANS_QUAD`, `EASE_OUT` | 제거 직전 1.12배 확대 |
| 매치 fade-out | 0.10s | `TRANS_QUAD`, `EASE_IN` | 알파 0, scale 0.82 |
| 낙하 | 칸당 0.045s, 최대 0.22s | `TRANS_BACK`, `EASE_OUT` | 아래에 닿을 때 탄성 |
| 새 블록 생성 | 0.14s | `TRANS_BOUNCE`, `EASE_OUT` | 위에서 내려오며 등장 |
| 목표 칩 증가 | 0.16s | `TRANS_BACK`, `EASE_OUT` | 숫자와 아이콘 짧은 펄스 |
| 피버 게이지 충전 | 0.18s | `TRANS_CUBIC`, `EASE_OUT` | 게이지가 부드럽게 증가 |

## 3. VFX 리스트

### 3.1 기본 매치

- `vfx_match_pop`: 작은 별/발자국 파티클 6-10개
- `vfx_score_spark`: 점수 방향으로 이동하는 작은 빛
- `vfx_goal_collect`: 목표 칩 방향으로 날아가는 미니 동물 아이콘

### 3.2 특수 블록

- `vfx_line_runner_horizontal`: 행 방향으로 빠르게 지나가는 발자국 trail
- `vfx_line_runner_vertical`: 열 방향으로 빠르게 지나가는 발자국 trail
- `vfx_paw_bomb`: 중심에서 둥근 발바닥 shockwave 확장
- `vfx_rainbow_herd`: 선택 동물 색상의 리본이 보드 전체를 훑음
- `vfx_special_combo`: 두 특수 블록 연결 시 짧은 흰색 flash와 확대 ring, 조합별 짧은 라벨(`크로스!`, `가로 러시!`, `세로 러시!`, `가로 폭탄!`, `세로 폭탄!`, `더블 폭탄!`)

### 3.3 Fever

- `vfx_fever_start`: 보드 가장자리에서 무지개 테두리 점등
- `vfx_fever_idle`: 배경 투명도 25-35%의 느린 색상 흐름
- `vfx_fever_match`: 일반 pop보다 파티클 1.5배, 사운드 pitch 상승
- `vfx_fever_end`: 테두리 빛이 중앙으로 모이며 종료

## 4. Shader 활용

- 선택 블록: 외곽선 색과 두께를 shader parameter로 제어
- 특수 블록: badge 대신 shimmer mask를 추가할 수 있게 준비
- 피버 상태: 동물 얼굴에 과한 색 변형을 주지 않고 rim light만 적용
- 장애물 제거: leaf dissolve shader를 0.2초 이하로 사용

## 5. 반응형 피드백

### 5.1 콤보 단계

| 단계 | 연출 |
| --- | --- |
| Combo 2 | `Nice!` 텍스트, 작은 scale pulse |
| Combo 3 | `Great!` 텍스트, 보드 1px shake |
| Combo 4 | `Amazing!` 텍스트, 보드 2px shake, 추가 파티클 |
| Combo 5+ | `Zoo-Zoo Rush!` 텍스트, 짧은 slow-mo 0.08s |

### 5.2 화면 흔들림

- 일반 매치: 흔들림 없음
- 4매치 발동: 1px, 0.08s
- Paw Bomb: 2px, 0.12s
- Rainbow Herd: 2px, 0.16s
- 전체 보드 제거: 3px 이하, 0.18s

### 5.3 동물 표정

- 기본: idle smile
- 선택: 눈 반짝임 또는 귀 살짝 상승
- 매치: 활짝 웃는 표정
- 피버: 눈 하이라이트와 볼 붉어짐
- 실패 직전: 걱정 표정은 1초 이하로 짧게 사용

## 6. 동물 표정 애니메이션 계획

### 6.1 공통 상태

| 상태 | 발동 조건 | 길이 | 반복 | 목적 |
| --- | --- | --- | --- | --- |
| `idle` | 기본 대기 | 상시 | 고정 | 보드 판독성 유지 |
| `blink` | 무작위 대기 중 | 0.12-0.18s | 비반복 | 살아 있는 느낌 |
| `smile` | 선택, 목표 근접, 힌트 | 0.20-0.30s | 비반복 | 귀여운 반응 |
| `match` | 제거 직전 | 0.16-0.22s | 비반복 | 성공 보상 |
| `fever` | 피버 중 | 0.45-0.60s | 반복 | 고조감 |
| `worried` | 이동 수 3 이하, 실패 팝업 전 | 0.50-0.80s | 짧은 반복 | 위기감 |

### 6.2 눈깜빡임

- 기본 간격: 2.8-6.0초 랜덤
- 동시 재생 제한: 보드 전체에서 최대 4개 타일
- 프레임 구성: `open -> half -> closed -> open`
- 시간: 0.04s, 0.05s, 0.05s, 0.04s
- 금지 상황: 낙하 중, 제거 중, 특수 블록 발동 중에는 blink를 새로 시작하지 않는다.

### 6.3 웃음/선택 반응

- 선택된 타일은 1.06배 scale-up과 `smile` 표정을 함께 재생한다.
- 같은 동물이 목표 칩에 포함되어 있으면 목표 칩도 0.12s pulse를 맞춘다.
- 고양이/여우는 한쪽 눈 찡긋, 곰/판다는 느린 눈웃음처럼 동물별 차이를 둔다.

### 6.4 매치 성공 표정

- 제거 전 0.16초 동안 `match` 표정을 먼저 보여 준다.
- 그 뒤 scale pop과 fade-out을 실행한다.
- 특수 블록 생성에 사용되는 마지막 스왑 블록은 제거하지 않고 `smile -> special_create` 순서로 전환한다.

### 6.5 피버 표정

- 피버 중 보드 전체 동물을 계속 움직이면 산만하므로, 활성 표정은 선택/매치/목표 동물 중심으로 제한한다.
- 일반 타일은 눈 하이라이트와 rim light만 적용한다.
- 목표 동물과 특수 블록은 `fever` 표정을 0.5초 loop로 재생한다.

### 6.6 제작량 관리

- 12종 전체에 full-frame 애니메이션을 전부 만들지 않는다.
- 공통 눈/입 overlay atlas를 우선 만들고, 동물별 귀/코/갈기 같은 특징만 보조 프레임을 추가한다.
- 1차 제작 목표는 동물당 13프레임 이하다.
- 우선순위는 `blink -> smile -> match -> fever -> worried` 순서다.

## 7. 사운드 연동

| 타이밍 | 사운드 | 설명 |
| --- | --- | --- |
| 스와이프 시작 | `sfx_swap_soft` | 손가락 입력 직후 |
| 유효 스왑 완료 | `sfx_swap_lock` | 두 블록 위치 확정 |
| 매치 제거 시작 | `sfx_pop_01` | scale-up 직후 |
| 연쇄 2단 | `sfx_pop_02` | pitch +3% |
| 연쇄 3단 이상 | `sfx_combo_rise` | pitch 단계 상승 |
| 특수 블록 생성 | `sfx_special_create` | badge 등장과 동시 |
| 특수 블록 발동 | `sfx_special_burst` | 첫 제거 frame |
| 목표 완료 | `sfx_goal_done` | 목표 칩 pulse와 동시 |
| 피버 시작 | `sfx_fever_start` | 화면 테두리 점등 직후 |
| 클리어 | `sfx_stage_clear` | 결과 팝업 직전 |

## 8. 구현 우선순위

1. 유효/무효 스왑 Tween
2. 매치 pop과 낙하 bounce
3. 동물 blink/smile 표정 시스템
4. 특수 블록 줄 제거/폭탄/무지개 VFX
5. 목표 칩 수집 연출
6. 콤보 텍스트와 단계별 사운드
7. Zoo-Zoo Fever 전체 연출

## 9. 성능 제한

- 파티클은 기본 매치당 10개 이하, 특수 블록당 40개 이하를 기본값으로 둔다.
- 동시에 활성화되는 screen flash는 1개만 허용한다.
- VFX 노드는 pool로 재사용한다.
- 저사양 옵션에서는 blur, additive overdraw, 긴 trail을 줄인다.
- idle 표정 애니메이션은 동시에 4개 타일 이하로 제한한다.
- full-frame 표정 전환보다 atlas region 변경과 눈/입 overlay를 우선 사용한다.
