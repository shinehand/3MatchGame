# Project Animal Match System Rules Matrix

작성일: 2026-05-02
목적: 주요 시스템 규칙을 조건, 입력 데이터, 출력, QA 기준으로 정리해 개발자가 구현 조건을 바로 확인하게 한다.

## 1. Stage/Board

| 규칙 | 입력 | 출력 | 예외 | QA |
| --- | --- | --- | --- | --- |
| 활성 동물 풀 | `spawn_profile.pool` | 보드 생성 후보 | Stage 1-3은 4종 허용 | pool 4-6종 |
| spawn weight | `spawn_profile.weights` | 랜덤 생성 확률 | 목표 동물은 weight 우대 | 목표 동물 누락 금지 |
| roster group | `roster_group` | 밴드별 동물/테마 추적 | 누락 시 기본값 금지, validator 오류 | 100개 stage 모두 존재 |
| board mask | `board_mask` | 활성 셀 | 0/1 외 문자 금지 | active cell 1개 이상 |
| blockers | `blockers`, `targets.blockers` | 장애물 배치/목표 | 비활성 셀 배치 금지 | 목표 수 <= 배치 수 |

## 2. Turn Resolve

| 단계 | 조건 | 처리 | 금지 |
| --- | --- | --- | --- |
| Input | `state == Idle` | 스와이프/선택 허용 | resolve 중 입력 |
| Swap | 인접 2칸 | 임시 교환 | 비활성 셀 교환 |
| Match Check | 3개 이상 | 유효 이동, 이동 수 -1 | 무효 스왑 이동 수 소모 |
| Effect Queue | 특수 포함 | 조합 -> 단일 특수 -> 일반 제거 | 중복 제거 2회 |
| Goals | 제거 후 | 수집/점수/덤불 갱신 | 리필 전 클리어 팝업 |
| Fall/Refill | 빈 칸 존재 | 낙하/생성 | 낙하 중 새 입력 |
| End Turn | 보드 안정 | 클리어/실패/셔플/피버 판정 | 연쇄 중 결과 팝업 |

## 3. Special Blocks

| 생성 | 조건 | 우선순위 | 효과 |
| --- | --- | --- | --- |
| Line Runner | 4개 일직선 | 1 | 행 또는 열 제거 |
| Paw Bomb | L/T자 | 2 | 3x3 제거 |
| Rainbow Herd | 5개 이상 일직선 | 3 | 교환 동물 전체 제거 |

처리 순서:

1. 특수+특수 조합
2. 단일 특수 발동
3. 일반 매치 제거

QA 기준:

- 자동 headless fixture는 row+column, row+row, column+column, row+bomb, column+bomb, bomb+bomb clear set과 rainbow 우선순위를 검증한다.
- Stage 31 runtime smoke는 row+column, row+row, column+column, row+bomb, column+bomb, bomb+bomb 6종 실제 `_resolve_swap` 경로의 이동 수 1회 소모, 점수 증가, 장애물 제거, `is_busy` 복귀를 검증한다.
- FxLayer smoke는 6종 특수 조합의 조합별 label, shaped flash/beam, explosive echo ring, child count, cleanup을 검증한다.
- Stage 31 수동 QA는 6종 조합의 VFX 체감과 낙하/리필 연결을 확인한다.

## 4. Fever

| 항목 | MVP 규칙 |
| --- | --- |
| 발동 | Combo Gauge 6칸 충전 후 현재 연쇄 종료 시 |
| 지속 | 다음 3회 플레이어 이동 |
| 연장 | MVP에서는 재발동 시 3턴으로 재설정, 중첩 보너스 없음 |
| 보너스 | 점수 2배, 목표 동물 수집 +1 |
| 보류 | 랜덤 발바닥 폭발 |
| UI | Combo Gauge, 남은 턴, 피버 보너스 표시 |

## 5. Rescue Buddy

| 항목 | MVP 규칙 |
| --- | --- |
| 활성 수 | 스테이지당 1종 |
| 발동 방식 | 자동 발동. 기본 1회, hard/finale의 반복 충전 스킬은 최대 2회 |
| 데이터 | 원본 `buddy.animal/skill_id/charge_rule/charges_required/max_uses`, 런타임 `buddy_animal/buddy_skill_id/buddy_charge_rule/buddy_charges_required/buddy_max_uses` |
| 금지 | 스킬 미보유로 일반 레벨 클리어 불가 |
| QA | max use 초과 발동 금지 |

## 6. FTUE Gating

| 구간 | 수익화 | 튜토리얼 | 메타 |
| --- | --- | --- | --- |
| Level 1-3 | 모두 금지 | 기본 매치, 4매치 | 토큰 예고 |
| Level 4-5 | 모두 금지 | 덤불, 컬렉션 | Rescue Book 첫 해금 |
| Level 6-10 | 모두 금지 | rainbow, combo/fever | Starter Missions |
| Level 11-15 | 광고 제한 소개 | 점수/하트 설명 | 수집 이벤트 예고 |
| Level 16+ | Near Miss 중심 제안 | 반복 설명 없음 | 이벤트/시즌 확장 |

## 7. Fail Offer Policy

| 실패 유형 | 조건 | 1순위 CTA | 2순위 CTA | 금지 |
| --- | --- | --- | --- | --- |
| First Fail | 해당 stage 첫 실패 | 무료 재도전 | 힌트 | IAP 강제 |
| Near Miss | 남은 목표 1-2 또는 진행률 80%+; `near_miss_goal_threshold`/`near_miss_progress_threshold`로 조정 | 광고 +3 moves | 코인 +5 moves | 자동 광고 |
| Strategic Miss | 남은 목표 많음 | 재도전 | 추천 부스터 설명 | 결제 압박 |
| Repeat Fail | 같은 stage 2회+ 실패 | 무료 부스터/힌트 | 재도전 | 같은 IAP 반복 |
| Hard Fail | hard/master/finale 실패 | 재도전 | 부스터 번들 | 닫기 숨김 |

## 8. Analytics Contract

| 시스템 | 필수 이벤트 |
| --- | --- |
| App/Stage | `app_launch`, `stage_start`, `stage_complete`, `stage_fail`, `booster_used`, `special_combo_trigger` |
| Fever | `combo_fever_start`, `combo_fever_end` |
| Rescue Buddy | `buddy_skill_charge`, `buddy_skill_ready`, `buddy_skill_trigger`, `buddy_skill_blocked` |
| Collection | `rescue_book_open`, `animal_unlock` now; `animal_token_gain`, `animal_friendship_level_up` planned with reward implementation |
| Fail Offer | `offer_impression` now; selection/dismiss events planned with UI action wiring |
| Live Ops | `remote_config_exposure`, `live_event_impression`, `event_join`, `event_progress`, `event_reward_claim`; reward claims are idempotent per `event_id + reward_id`; event status supports upcoming/active/ended/disabled/offline |

## 9. QA Smoke Set

- Stage 1: 첫 매치, 하드 튜토리얼 없음.
- Stage 5: 첫 컬렉션 보상.
- Stage 10: 초반 밴드 마감.
- Stage 20: 점수/덤불/수집 복합.
- Stage 31: row/column/bomb 특수 조합과 cascade_slide Buddy smoke.
- Stage 51: 후반 blocker 압박과 brave_start Buddy smoke.
- Stage 81: elephant 해금/후반 동기.
- Stage 100: 피날레, 결과, 메타 보상.
- Rescue Buddy smoke: Stage 4/5/8/16/18/20/24/25/31/41/51/81 첫 등장 스킬을 validator 기준으로 확인한다.
