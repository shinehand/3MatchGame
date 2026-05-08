# Project Animal Match FTUE & Rescue Book Spec

작성일: 2026-05-02
목적: 첫 10레벨 온보딩과 `Rescue Book` 메타 루프를 개발 가능한 수준으로 고정한다.

## 1. 설계 목표

- 첫 세션은 `Level 5 클리어 + 첫 컬렉션 카드 해금 + 다음 동물 예고`로 끝난다.
- Level 1-10은 학습과 신뢰 확보 구간이다. 하트 소모, 전면 광고, IAP 직접 팝업은 금지한다.
- MVP 12종 로스터는 보드 스킨이 아니라 해금, 토큰, 표정, 장착, 이벤트로 이어지는 장기 동기다. 글로벌 런칭에서는 컬렉션/이벤트 예비 동물 6종을 더해 18종까지 확장한다.

## 2. FTUE 1-10 상세 플로우

| Level | 학습 목표 | 허용 시스템 | 금지 시스템 | 성공 후 보상/다음 동기 |
| --- | --- | --- | --- | --- |
| 1 | 첫 스와이프, 목표 칩 이해 | 추천 스왑 1회, 기본 매치 | 실패 패널, 하트, 광고, IAP | 별, 코인 소량, 토끼 토큰 |
| 2 | 복수 목표 진행감 | 목표 칩으로 날아가는 수집 연출 | 광고, IAP | 토끼/곰 토큰, Level 3 특수 블록 예고 |
| 3 | 4매치 Line Runner | 줄 제거 특수 블록 1회 유도 | 폭탄/무지개 강제 설명 | Line Runner 배지 튜토리얼 완료 |
| 4 | 첫 덤불과 첫 컬렉션 카드 | 덤불 1개, Rescue Book 첫 진입 | 하트 소모, 판매 팝업 | 토끼 카드 완전 해금 |
| 5 | 첫 세션 보상 묶음 | 스타터 미션 오픈 | 전면 광고, 직접 IAP | 1일차 스타터 보상, 다음 동물 예고 |
| 6 | 좁은 보드 판독 | frog 목표 또는 카메오 | 신규 시스템 2개 동시 설명 | 개구리 카드 잠금 해제 예고 |
| 7 | 5매치/Rainbow 맛보기 | 5매치 유도, 무지개 설명 | 피버 강제 설명 | Rainbow Treat 체험 기억 |
| 8 | Combo/Fever 첫 경험 | Combo Gauge, 피버 1회 목표 | 결제 제안 | Fever 기록 배지 |
| 9 | 이동 수 부족 감정 연출 | worried 표정, 무료 재도전 | 하트 소모, 광고 | 실패해도 페널티 없음 |
| 10 | 초반 밴드 마감 | 복합 목표, 다음 지역 예고 | 전면 광고, IAP | Starter Missions 고정 노출 |

## 3. FTUE 상태 데이터

권장 데이터 파일: `data/ftue_steps.json`

```json
[
  {
    "step_id": "ftue_first_swap",
    "stage_id": 1,
    "trigger": "stage_start",
    "complete_condition": "valid_match_count>=1",
    "repeat_policy": "once_per_install",
    "message_key": "ftue.first_swap"
  },
  {
    "step_id": "ftue_line_runner",
    "stage_id": 3,
    "trigger": "first_4_match_candidate",
    "complete_condition": "special_created:row_or_col",
    "repeat_policy": "until_complete",
    "message_key": "ftue.line_runner"
  }
]
```

## 4. Rescue Book 구조

### 4.1 화면 구성

```text
RescueBook
├── Header: 해금 수, 총 토큰, 다음 보상
├── AnimalGrid: MVP 12종 카드, 런칭 확장 18종까지 대응
├── DetailPanel: 선택 동물 정보
├── ExpressionPreview: idle/smile/fever 미리보기
└── RewardTrack: 우정 레벨 1-5
```

### 4.2 동물 카드 데이터

권장 데이터 파일: `data/animals.json`

```json
{
  "animal_id": "rabbit",
  "unlock_stage": 4,
  "display_name_key": "animal.rabbit.name",
  "personality_key": "animal.rabbit.personality",
  "token_sources": ["stage_goal", "starter_mission", "collection_event"],
  "friendship_rewards": [
    { "level": 1, "reward_type": "profile_icon", "reward_id": "rabbit_icon_basic" },
    { "level": 2, "reward_type": "expression", "reward_id": "rabbit_smile_plus" }
  ]
}
```

### 4.3 저장 데이터

```json
{
  "collection": {
    "rabbit": {
      "unlocked": true,
      "token_balance": 24,
      "friendship_level": 1,
      "equipped_cosmetic": "rabbit_icon_basic",
      "new_badge": false
    }
  }
}
```

## 5. 보상 규칙

- 목표 동물이 포함된 스테이지를 클리어하면 해당 동물 토큰을 지급한다.
- MVP 런타임 지급은 첫 클리어 기준 첫 번째 목표 동물 1종에 `+3 tokens`를 지급하고, `stage_id + animal_id` claim key로 중복 지급을 막는다.
- 실패 시 토큰은 지급하지 않는다. 단, 이벤트 미션은 `attempt` 보상을 별도로 둘 수 있다.
- Level 4 첫 카드 해금은 고정 보상이다.
- 우정 레벨 보상은 초반에는 cosmetic 중심으로 둔다.
- 스킬 성능 보상은 소프트 런칭 지표 확인 전까지 보류한다.

## 6. 진입점

| 진입점 | 노출 시점 | 요구 |
| --- | --- | --- |
| 홈 버튼 | Level 4 이후 | 항상 접근 가능 |
| 결과 화면 | 토큰 획득 또는 신규 해금 | `보기` CTA |
| 스타터 미션 | Level 5 이후 | 보상 수령 후 자동 안내 |
| 이벤트 배너 | Level 12 이후 | 대표 동물 카드로 연결 |

## 7. 분석 이벤트

| 이벤트 | 트리거 | 필수 파라미터 |
| --- | --- | --- |
| `ftue_step_view` | 안내 노출 | `step_id`, `stage_id`, `trigger`, `variant_id` |
| `ftue_step_complete` | 조건 완료 | `step_id`, `stage_id`, `elapsed_ms`, `input_count` |
| `animal_unlock` | 카드 해금 | `animal_id`, `source`, `stage_id` |
| `animal_token_gain` | 토큰 획득 | `animal_id`, `amount`, `source`, `stage_id` |
| `collection_view` | Rescue Book 진입 | `entry_point`, `unlocked_count`, `new_badge_count` |
| `animal_friendship_level_up` | 우정 레벨 상승 | `animal_id`, `level_before`, `level_after`, `reward_id` |

## 8. 개발 완료 기준

- 신규 유저가 Level 5까지 진행하면 Rescue Book 첫 카드 해금을 경험한다.
- Level 1-10에서 하트 소모, 전면 광고, IAP 팝업이 발생하지 않는다.
- Rescue Book은 MVP 12종을 모두 표시하고, 글로벌 런칭 확장 18종까지 잠김/해금/신규 상태를 구분할 수 있다.
- 앱 재시작 후 토큰, 우정 레벨, 신규 배지가 유지된다.
- `ftue_step_*`, `animal_*`, `collection_view` 이벤트가 디버그 로그에 남는다.
