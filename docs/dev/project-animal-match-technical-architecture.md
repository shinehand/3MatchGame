# Project Animal Match Technical Architecture

## 1. 목표

Godot 4.x에서 모바일 매치3 퍼즐을 안정적으로 운영하기 위한 데이터, 알고리즘, 씬 구조, 최적화 기준을 정의한다. 기본 구현 언어는 GDScript로 둔다.

## 2. 데이터 모델링

### 2.1 레벨 JSON

레벨 운영 데이터는 JSON으로 관리한다. 이미 존재하는 `data/stages/stages_001_010.json` 같은 파일 구조를 유지하되, 글로벌 운영을 고려해 스키마를 명확히 한다.

```json
{
  "id": 1,
  "name": "Stage 1",
  "band": "1-10",
  "roster_group": "forest_early",
  "difficulty": "Easy",
  "theme_key": "meadow_1",
  "moves": 12,
  "board_mask": ["11111111", "11111111", "11111111", "11111111", "11111111", "11111111", "11111111", "11111111"],
  "targets": { "collect": { "rabbit": 10 }, "score": 0, "blockers": 0 },
  "spawn_profile": {
    "pool": ["rabbit", "bear", "cat", "chick"],
    "weights": { "rabbit": 5, "bear": 2, "cat": 2, "chick": 2 }
  },
  "blockers": [],
  "mechanics": { "enabled": ["row_special", "col_special", "bomb_special"] },
  "tutorial": "토끼를 10개 모으세요."
}
```

원본 JSON의 canonical 필드는 `spawn_profile.pool`과 `spawn_profile.weights`다. `StageCatalog._normalize_stage()`는 런타임에서 쓰기 쉽도록 이를 각각 `animal_pool`, `spawn_weights`로 정규화한다. 문서나 validator에서 `animal_pool`을 말할 때는 “정규화된 런타임 필드(원본: `spawn_profile.pool`)”를 뜻한다.

`spawn_profile.pool`은 전체 동물 로스터가 아니라 해당 스테이지에 실제로 출현하는 활성 풀이다. MVP 보드 로스터는 12종, 글로벌 런칭 컬렉션 목표는 18종, 시즌 운영 확장 목표는 24종으로 두되, 매치 확률과 가독성을 위해 한 스테이지의 활성 풀은 기본 5-6종, 튜토리얼 구간은 4-5종까지 허용한다. 컬렉션 전용 동물은 `board_enabled == true`가 되기 전까지 stage JSON의 `spawn_profile.pool`에 넣지 않는다.

`roster_group`은 같은 밴드 안에서 사용하는 동물 출현/해금 묶음을 추적하기 위한 메타데이터다. 런타임은 `StageCatalog._normalize_stage()`에서 값을 읽고, 누락 시 밴드 기준 기본값으로 보정한다.

| band | roster_group | 용도 |
| --- | --- | --- |
| `1-10` | `forest_early` | 초반 학습과 기본 4-6종 확장 |
| `11-20` | `trap_trail` | 덫 흔적 구간, 점수/덤불 도입 |
| `21-30` | `camp_outer` | 야영지 외곽, 비대칭 마스크 도입 |
| `31-40` | `rescue_route` | 복수 구조 루트와 복합 목표 |
| `41-50` | `river_crossing` | 강가 구역, 좁은 게이트 압박 |
| `51-60` | `camp_inner` | 야영지 내부, 고밀도 장애물 |
| `61-70` | `deep_jungle` | 깊은 밀림, 전문가 루트 판독 |
| `71-80` | `escape_prep` | 탈출 준비, 마스터리 테스트 |
| `81-90` | `elephant_route` | 코끼리 수송 경로 추적 |
| `91-100` | `final_rescue` | 최종 구출 피날레 |

### 2.2 Godot Resource

반복 사용되는 정적 정의는 Resource로 분리한다.

- `AnimalDefinition`: id, display_name_key, texture, match_texture, fever_texture, expression_atlas, animation_profile, base_score
- `SpecialBlockDefinition`: id, trigger_type, effect_shape, vfx_id, sfx_id
- `BoosterDefinition`: id, cost, effect, target_rule
- `StageBandDefinition`: band, theme, background, unlock_condition
- `AnimalRosterGroup`: id, animal_ids, unlock_stage, event_tag

### 2.3 동물 표정 애니메이션 데이터

동물 수가 늘어나도 코드가 동물별 분기로 부풀지 않도록, 표정 애니메이션은 데이터 기반으로 관리한다.

```json
{
  "animal_id": "rabbit",
  "expression_profile": {
    "idle": { "frames": ["idle"], "fps": 1, "loop": false },
    "blink": { "frames": ["blink_01", "blink_02", "blink_03"], "fps": 18, "loop": false, "cooldown_range": [2.8, 6.0] },
    "smile": { "frames": ["smile_01", "smile_02"], "fps": 12, "loop": false },
    "match": { "frames": ["match_01", "match_02", "match_03"], "fps": 20, "loop": false },
    "fever": { "frames": ["fever_01", "fever_02"], "fps": 8, "loop": true },
    "worried": { "frames": ["worried_01", "worried_02"], "fps": 6, "loop": true }
  }
}
```

권장 구현:

- `BlockTile`은 현재 animal_id와 expression_state만 가진다.
- `AnimalExpressionController`가 atlas region과 frame timing을 계산한다.
- idle blink는 모든 타일이 각자 Timer를 갖지 않고, 보드 단위 scheduler가 랜덤 타일 2-4개만 선택해 실행한다.
- 매치/피버/실패 표정은 게임 상태 이벤트에서 명시적으로 요청한다.

### 2.4 저장 데이터

- 진행도: 마지막 클리어 stage_id, 별 수, 누적 코인
- 소모품: 하트, 부스터 수량, 광고 보상 쿨다운
- 설정: 사운드, 햅틱, 언어
- 분석 보조: 튜토리얼 완료 여부, 첫 구매 여부

## 3. 매치3 알고리즘

### 3.1 상태 흐름

```text
Idle -> Swapping -> ResolvingMatches -> Falling -> Refilling -> CheckingCascade -> Idle
```

입력은 `Idle`에서만 받는다. 연쇄 처리 중 추가 입력을 막아 상태 꼬임을 방지한다.

### 3.2 매치 판정

1. 보드 전체를 행 단위로 스캔해 같은 animal_id가 3개 이상 연속되는 구간을 찾는다.
2. 열 단위로 같은 스캔을 수행한다.
3. 가로/세로 결과를 합쳐 중복 셀을 제거한다.
4. 교차 지점과 길이를 보고 특수 블록 생성 타입을 결정한다.
5. 생성 위치는 마지막 스왑 위치를 우선하고, 불가능하면 매치 그룹 중심을 사용한다.

### 3.3 특수 블록 판정

- 4개 일직선: `line_horizontal` 또는 `line_vertical`
- L/T자: `paw_bomb`
- 5개 이상 일직선: `rainbow_herd`
- 특수 블록이 제거 그룹에 포함되면 일반 제거보다 먼저 효과 큐에 등록한다.

### 3.4 낙하와 리필

1. 각 열을 아래에서 위로 순회한다.
2. 빈 칸이 있으면 위쪽의 가장 가까운 블록을 아래로 이동시킨다.
3. 위쪽이 비면 spawn row에서 새 블록을 생성한다.
4. 새 블록 생성은 `spawn_weights`와 직전 보드 상태를 기준으로 즉시 3매치가 과도하게 생기지 않도록 제한한다.
5. 낙하 Tween이 끝난 뒤 다음 매치 검사를 수행한다.

### 3.5 셔플

셔플 조건:

- 가능한 유효 스왑이 0개
- 보드 마스크와 장애물 때문에 자동 연쇄가 끝없이 반복되는 비정상 상태

절차:

1. 고정 장애물과 locked cell은 유지한다.
2. 일반 블록만 리스트로 수집한다.
3. 무작위 재배치 후 즉시 매치가 있으면 다시 섞는다.
4. 가능한 유효 스왑이 1개 이상인지 검사한다.
5. 최대 20회 실패하면 일부 블록을 강제 교체해 유효 수를 만든다.

## 4. 노드 구조

```text
Main
├── GameSession
├── StageCatalog
├── SceneRouter
└── Gameplay
    ├── HudLayer
    ├── BoardRoot
    │   ├── GridContainer
    │   │   └── Cell nodes
    │   └── BlockLayer
    ├── AnimalExpressionController
    ├── BoardExpressionScheduler
    ├── FxLayer
    ├── PopupLayer
    └── AudioFeedback
```

## 5. Signal 설계

| 발신 | 시그널 | 수신 | 목적 |
| --- | --- | --- | --- |
| Cell | `cell_pressed(cell_pos)` | BoardController | 선택 시작 |
| Cell | `cell_swiped(cell_pos, direction)` | BoardController | 스왑 요청 |
| BoardController | `move_consumed(remaining_moves)` | HUD | 이동 수 갱신 |
| MatchResolver | `matches_resolved(match_groups)` | BoardController, HUD, FxLayer | 제거/점수/VFX |
| SpecialBlock | `special_triggered(effect_data)` | BoardController, FxLayer | 특수 효과 발동 |
| BoardExpressionScheduler | `expression_requested(block_id, expression_id)` | AnimalExpressionController | blink/smile 등 표정 재생 |
| FeverController | `fever_started(duration)` | HUD, FxLayer, AudioFeedback | 피버 시작 |
| GoalTracker | `goal_completed(goal_id)` | HUD, AudioFeedback | 목표 달성 |
| StageController | `stage_completed(result)` | PopupLayer, GameSession | 클리어 |
| StageController | `stage_failed(result)` | PopupLayer | 실패 |

## 6. 모바일 최적화

### 6.1 Draw Call

- 동물 블록은 가능하면 하나의 atlas texture로 묶는다.
- 특수 배지는 별도 Sprite2D를 남발하지 않고 shader parameter 또는 atlas region으로 처리한다.
- UI 패널은 9-patch와 공통 theme resource를 사용한다.

### 6.2 메모리

- 블록 노드는 매번 생성/삭제하지 않고 pool로 재사용한다.
- 파티클은 동시에 활성화 가능한 수를 제한한다.
- 스테이지 전환 시 이전 배경, 임시 VFX, 팝업 참조를 해제한다.
- 표정 애니메이션은 동물별 개별 노드 증식을 피하고 atlas region 변경 또는 overlay sprite 1-2개로 처리한다.

### 6.3 CPU

- 매치 검사는 보드 전체 스캔을 기본으로 하되, 연쇄 중에는 변경된 행/열 중심으로 최적화할 수 있다.
- 애니메이션이 진행 중일 때 입력과 추가 resolve를 큐로 분리한다.
- 분석 로그는 프레임 중간에 직접 전송하지 않고 batch queue에 넣는다.
- idle blink는 동시에 4개 타일 이하만 재생해 CPU와 draw update를 제한한다.

## 7. 검증 기준

- 레벨 JSON schema validation이 통과한다.
- 100개 레벨이 모두 로드된다.
- 각 레벨에서 가능한 첫 수가 최소 1개 존재한다.
- 특수 블록 조합별 자동 테스트가 통과한다.
- 저사양 기준 기기에서 콤보 5단계 연출 중 30fps 아래로 떨어지지 않는다.
- Android/iOS debug build가 각각 설치 후 첫 스테이지까지 진입한다.
