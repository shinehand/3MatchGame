# Project Animal Match Rescue Buddy Skill Spec

작성일: 2026-05-02
목적: 동물별 구조 스킬을 모든 동물 동시 발동이 아닌 스테이지별 `Rescue Buddy` 1종 자동 발동 시스템으로 설계한다.

## 1. MVP 원칙

- 한 스테이지에는 Rescue Buddy 1종만 활성화한다.
- 발동은 자동으로 시작한다. 수동 버튼은 소프트 런칭 이후 판단한다.
- 기본 발동 횟수는 1회, 하드/피날레는 최대 2회까지 허용한다.
- 스킬은 클리어 필수 조건이 아니라 실패 완화와 캐릭터 애착 강화 장치다.
- 모든 스킬은 원격 설정 또는 stage JSON 수치로 조정 가능해야 한다.

## 2. Stage 데이터 필드

권장 필드:

```json
{
  "buddy": {
    "animal": "rabbit",
    "skill_id": "quick_refill",
    "charge_rule": "match_goal_animal",
    "charges_required": 3,
    "max_uses": 1
  }
}
```

정규화 후 런타임 필드:

```gdscript
stage["buddy_animal"]
stage["buddy_skill_id"]
stage["buddy_charge_rule"]
stage["buddy_charges_required"]
stage["buddy_max_uses"]
```

## 3. 동물별 스킬 테이블

| 동물 | Skill ID | 발동 조건 | 효과 | 제한 | 우선 해금 |
| --- | --- | --- | --- | --- | --- |
| 토끼 | `quick_refill` | 목표 동물 매치 3회 | 리필 후 목표 동물 1개 추가 생성 시도 | active pool 안에서만 | Stage 4+ |
| 곰 | `soft_bomb_plus` | Paw Bomb 생성 또는 발동 | 다음 Paw Bomb 범위 내 장애물 1개 추가 피해 | 스테이지당 1회 | Stage 12+ |
| 고양이 | `smart_hint` | 2턴 동안 매치 실패/무효 입력 없음 | 목표에 가까운 유효 수 1개 강조 | 보드 제거 없음 | Stage 15+ |
| 병아리 | `combo_peep` | 콤보 2 이상 | 피버 게이지 소량 추가 | 피버 중 미발동 | Stage 8+ |
| 개구리 | `leap_clear` | 덤불 인접 매치 | 인접 덤불 1개 추가 피해 | 덤불 없으면 미발동 | Stage 16+ |
| 강아지 | `loyal_fetch` | 목표 1-2개 남은 Near Miss | 목표 동물 1개를 보드에 우선 생성 | 실패 판정 전 1회 | Stage 20+ |
| 판다 | `calm_fever` | 피버 시작 | 피버 종료 후 게이지 10 유지 | 연속 중첩 없음 | Stage 24+ |
| 돼지 | `coin_sniff` | 클리어 | 코인 보상 +5% | 클리어 전 영향 없음 | Stage 25+ |
| 펭귄 | `cascade_slide` | 낙하 후 연쇄 발생 | 해당 연쇄 점수 +10% | 1턴 1회 | Stage 31+ |
| 여우 | `sly_route` | 이동 수 3 이하 | 목표 관련 추천 수 강조 | 자동 제거 없음 | Stage 41+ |
| 사자 | `brave_start` | 하드/피날레 시작 | 시작 부스터 1개 후보 제안 | 무료 자동 지급 아님 | Stage 51+ |
| 코끼리 | `mighty_push` | 피날레/덤불 고밀도 | 범위 효과가 덤불에 +1 피해 | 보스/피날레 제한 | Stage 81+ |

## 4. Charge Rule

| Rule | 설명 |
| --- | --- |
| `match_goal_animal` | 목표 동물 매치가 발생할 때 충전 |
| `create_special` | 특수 블록 생성 시 충전 |
| `trigger_special` | 특수 블록 발동 시 충전 |
| `clear_blocker` | 장애물 피해/제거 시 충전 |
| `cascade_step` | 연쇄 단계가 2 이상일 때 충전 |
| `near_fail` | 이동 수 3 이하 또는 실패 직전 조건 |
| `stage_clear` | 클리어 순간 1회 평가 |

## 5. UI/HUD

- Stage Popup에서 Rescue Buddy 동물, 스킬명, 짧은 설명을 보여 준다.
- Gameplay HUD에는 작은 buddy icon과 충전 상태만 표시한다.
- 자동 발동 시 동물 표정 `smile` 또는 `fever`와 짧은 텍스트를 보여 준다.
- 충전이 안 되는 스킬은 진행바 대신 조건 아이콘을 쓴다.

## 6. QA 기준

- 같은 스테이지에서 `max_uses`를 초과해 발동하지 않는다.
- 스킬이 없는 스테이지는 기존 플레이와 동일하다.
- 스킬 발동으로 이동 수가 잘못 소모되지 않는다.
- 보드에 없는 동물을 스킬이 생성하려고 하면 active pool 기준으로 fallback한다.
- `lion`, `elephant` 스킬은 해금 전 스테이지에서 나타나지 않는다.

## 7. 분석 이벤트

| 이벤트 | 트리거 | 필수 파라미터 |
| --- | --- | --- |
| `buddy_skill_charge` | 충전 발생 | `stage_id`, `animal_id`, `skill_id`, `charge_rule`, `charge_count` |
| `buddy_skill_ready` | 발동 가능 | `stage_id`, `animal_id`, `skill_id`, `turn_index` |
| `buddy_skill_trigger` | 실제 발동 | `stage_id`, `animal_id`, `skill_id`, `effect_type`, `uses_left` |
| `buddy_skill_blocked` | 조건 불충족 | `stage_id`, `animal_id`, `skill_id`, `reason` |

## 8. 구현 순서

1. `StageCatalog`가 `buddy` 필드를 정규화한다.
2. `AnimalSkillController` 또는 `gameplay.gd` 내부 controller 영역에서 charge/use 상태를 관리한다.
3. rabbit/chick/cat 중 1개 스킬만 먼저 구현한다.
4. QA fixture로 max use, no-buddy stage, locked animal stage를 검증한다.
5. 나머지 동물 스킬은 데이터와 fallback만 먼저 넣고, 실제 효과는 순차 구현한다.
