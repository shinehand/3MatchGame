# Project Animal Match Level Progression Content Bible

## 목적

이 문서는 100스테이지 콘텐츠를 조정하거나 새 스테이지를 추가하는 에이전트가 사용하는 레벨 기획 기준이다. `data/stages/*.json`을 직접 수정하기 전, 각 구간의 학습 목표, 동물 풀, 난이도 파형, 금지 조건, QA 확인 항목을 여기에서 확인한다.

## 공통 원칙

- 스테이지 데이터는 10개 단위 밴드로 관리한다.
- 한 스테이지의 활성 동물 풀은 5-6종을 기본으로 한다. Stage 1-3은 4종까지 허용한다.
- 새 동물은 보드에 투입하기 전 최소 3스테이지 동안 UI/목표/컬렉션에서 먼저 예고한다.
- 하드, 피날레, 마스터 성격의 스테이지는 4개 이상 연속 배치하지 않는다.
- 실패율을 올릴 때는 이동 수만 줄이지 않고 목표 밀도, 장애물 위치, 동물 pool, 특수 블록 필요성을 함께 조정한다.
- 초반 10레벨은 하트 소모, 전면 광고, IAP 팝업을 금지한다.

## 난이도 태그

| tag | 용도 | 권장 빈도 |
| --- | --- | --- |
| `tutorial` | 새 조작/규칙 학습 | Stage 1-10 중심 |
| `recovery` | 어려운 레벨 직후 완충 | hard/finale 뒤 1개 이상 |
| `score_focus` | 점수 목표 중심 | 각 밴드 1-2개 |
| `collection_focus` | 동물 수집 목표 중심 | 각 밴드 3-5개 |
| `blocker_focus` | 덤불/장애물 중심 | Stage 4 이후 |
| `combo_focus` | 특수 블록/연쇄 유도 | Stage 7 이후 |
| `mixed_goal` | 복수 목표 | Stage 11 이후 |
| `hard` | 실패율 상승 지점 | 5-8스테이지마다 1개 |
| `finale` | 밴드 마무리 테스트 | 각 밴드 마지막 1개 |
| `master` | 후반 고난도 종합 | Stage 71 이후 제한 사용 |

## Stage 1-10 상세 FTUE

| stage | 목적 | 동물 풀 | 메커닉 | 목표/난이도 | 금지 |
| ---: | --- | --- | --- | --- | --- |
| 1 | 첫 스와이프와 3매치 | rabbit, bear, cat, chick | 기본 매치 | rabbit 수집, 넉넉한 이동 수 | 실패, 광고, 결제 |
| 2 | 낙하/리필 이해 | rabbit, bear, cat, chick | 기본 매치 | 복수 동물 수집 | 광고, 결제 |
| 3 | 4매치 첫 경험 | rabbit, bear, cat, chick, dog | line special | 쉬운 4매치 유도 | 광고, 결제 |
| 4 | 첫 장애물/Rescue Book 예고 | rabbit, bear, cat, chick, dog | blocker intro | 덤불 1개, 첫 카드 | 광고, 결제 |
| 5 | 첫 세션 보상 | rabbit, bear, cat, chick, dog | line special | 클리어 후 첫 컬렉션 완성 | 광고, 결제 |
| 6 | 목표 칩 읽기 강화 | rabbit, bear, cat, chick, dog | 목표 UI | 두 목표 동시 추적 | 광고, 결제 |
| 7 | 5매치/Rainbow Herd 예고 | rabbit, bear, cat, chick, dog | rainbow intro | 5매치 가능 배치 | 광고, 결제 |
| 8 | 콤보 게이지 첫 충전 | rabbit, bear, cat, chick, dog | combo gauge | 2연쇄 이상 유도 | 광고, 결제 |
| 9 | 첫 가벼운 압박 | rabbit, bear, cat, chick, dog | blocker + combo | 이동 수 여유 감소 | 광고, 결제 |
| 10 | 초반 종합 테스트 | rabbit, bear, cat, chick, dog, frog | mixed goal | 실패 가능성 낮은 finale | 광고, 결제 |

## 밴드별 콘텐츠 바이블

| band | roster_group | 주 학습 | 동물/로스터 운영 | 난이도 파형 | QA 포인트 |
| --- | --- | --- | --- | --- | --- |
| 1-10 | `forest_early` | 기본 매치, line, 첫 장애물, 첫 컬렉션 | rabbit/bear/cat/chick 중심, dog/frog 예고 | tutorial -> recovery -> finale | 수익화 비노출, 첫 카드 해금 |
| 11-20 | `trap_trail` | 복수 목표, 장애물 주변 매치 | frog/dog 본격 투입 | normal -> hard -> recovery -> finale | 장애물 목표와 동물 목표 동시 카운트 |
| 21-30 | `camp_outer` | 비대칭 보드, 수집 압박 | panda/pig 투입 | normal 2 -> hard -> recovery 반복 | 보드 마스크와 리필 안정성 |
| 31-40 | `rescue_route` | 특수 블록 조합 | penguin/fox 투입 | combo_focus 증가 | 특수+특수 조합 순서 |
| 41-50 | `river_crossing` | 좁은 게이트, 목표 우선순위 | 초중반 해금 동물 회전, lion 예고 준비 | hard 후 recovery 필수 | 풀 반복 경고, 이동 수 과압박 |
| 51-60 | `camp_inner` | lion 예고/투입, 피버 효용 | lion 투입 시작 | fever 테스트, hard 1-2개 | lion fallback/최종 에셋 상태 |
| 61-70 | `deep_jungle` | 복합 목표와 장애물 밀도 | lion 포함 5-6종 회전 | mixed_goal 중심 | 목표/장애물 동시 완료 순서 |
| 71-80 | `escape_prep` | 마스터리 준비 | elephant 예고 | hard/finale 대비 recovery | 새 동물 예고와 보드 미투입 확인 |
| 81-90 | `elephant_route` | elephant 투입, 대형 장애물 | elephant 투입 시작 | blocker_focus + hard | elephant fallback/장애물 피해 |
| 91-100 | `final_rescue` | 전체 규칙 종합 | 12종 중 5-6종 선택 | finale/master 제한 사용 | Stage 100 클리어/실패 양쪽 플로우 |

## 동물 해금/예고 규칙

| 동물 | 보드 투입 시점 | 예고 시점 | 금지 조건 |
| --- | --- | --- | --- |
| rabbit/bear/cat/chick | Stage 1 | 시작 화면 | 없음 |
| dog | Stage 3-5 | Stage 2 결과/목표 칩 | Stage 1 pool 금지 |
| frog | Stage 10-12 | Stage 8-9 | tutorial 과밀 금지 |
| panda/pig | Stage 21-25 | Stage 18-20 | Stage 20 이전 목표 금지 |
| penguin/fox | Stage 31-35 | Stage 28-30 | 같은 색/실루엣 풀 중복 주의 |
| lion | Stage 51 이후 | Stage 45-50 | Stage 51 이전 pool/target 금지 |
| elephant | Stage 81 이후 | Stage 75-80 | Stage 81 이전 pool/target 금지 |
| 13-18번 컬렉션 동물 | 현재 alpha 보드 미투입. 시즌 1 확장 후보는 koala(101-110) -> hamster(111-120) -> deer(121-130) -> seal(131-140) -> sheep(141-150) -> turtle(151-160) | Rescue Book/Event | `board_enabled` 전 stage JSON 금지 |

## 목표 설계 가이드

### Collection 목표

- 초반에는 단일 동물 1종만 목표로 둔다.
- Stage 6 이후 2종 목표를 허용한다.
- Stage 21 이후 목표 수량은 동물 가중치와 함께 조정한다.
- 목표 동물이 pool에 없거나 가중치가 0이면 validator error다.

### Score 목표

- score 목표는 단독으로 쓰기보다 수집 목표와 함께 보조 목표로 둔다.
- `score_focus` 레벨은 특수 블록 생성 기회를 충분히 제공한다.
- 피버 테스트 구간에서는 score 목표가 피버 체감을 확인하기 좋다.

### Blocker 목표

- 첫 덤불은 Stage 4에서 낮은 체력/낮은 수량으로 도입한다.
- 장애물 밀집도는 보드 중앙보다 가장자리부터 올린다.
- 좁은 보드와 고체력 장애물을 같은 초반 레벨에 겹치지 않는다.

## 난이도 조정 레버

| 레버 | 난이도 상승 | 부작용 | 우선순위 |
| --- | --- | --- | --- |
| 이동 수 감소 | 즉시 상승 | 불공정 체감 | 낮음 |
| 목표 수량 증가 | 명확한 상승 | 반복감 | 중간 |
| 동물 pool 6종 | 매치 확률 하락 | 답답함 | 중간 |
| 장애물 중앙 배치 | 경로 차단 | 초반 이탈 | 높음, 후반용 |
| 좁은 보드 마스크 | 전략성 증가 | 운 의존 증가 | 중간 |
| 특수 블록 필요 목표 | 숙련도 테스트 | 설명 부족 시 실패 | 높음, 튜토리얼 후 |
| 가중치 편향 | 목표 체감 조정 | 숨은 조작감 | 신중 |

## 레벨 작성 체크리스트

1. `spawn_profile.pool`은 4-6종 안에 있는가?
2. 모든 목표 동물이 `spawn_profile.pool`에 있는가?
3. `spawn_profile.weights`에 pool 동물이 모두 정의되어 있는가?
4. 해금 전 동물이 pool 또는 target에 들어가지 않았는가?
5. 새 메커닉은 이전 1-2스테이지에서 예고되었는가?
6. hard/finale/master가 4개 이상 연속되지 않는가?
7. 어려운 레벨 직후 recovery 레벨이 있는가?
8. Level 1-10에 광고/IAP/하트 소모 조건이 들어가지 않았는가?
9. 보드 마스크가 리필 불가능한 고립 셀을 만들지 않는가?
10. QA smoke 대상 스테이지는 수동 체크리스트에 포함되어 있는가?
11. 13-18번 컬렉션 동물은 `board_expansion_order`와 `board_candidate_min_stage`가 있더라도 `board_enabled=false`인 동안 pool/target/weights/buddy에 들어가지 않는가?

## 데이터 필드 확장 후보

```json
{
  "difficulty_tag": ["collection_focus", "recovery"],
  "teaches": ["line_special"],
  "previews": ["frog"],
  "forbidden_monetization": true,
  "recommended_smoke": false
}
```

이 필드는 바로 필수화하지 않는다. `PAM-DEV-057`에서 validator와 함께 도입한다.

## 개발/QA 완료 기준

- Stage 1-10은 이 문서의 FTUE 표와 충돌하지 않는다.
- 각 10스테이지 밴드에는 학습 목표와 roster_group이 명확히 매핑되어 있다.
- `lion`과 `elephant`는 지정 전 스테이지에서 pool/target에 들어가지 않는다.
- 13-18번 컬렉션 동물은 `board_enabled` 전 stage JSON에 들어가지 않는다.
- 밸런스 검증은 pool 크기, 해금 순서, hard 연속, recovery 배치를 검사할 수 있다.
- QA는 Stage 1, 5, 10, 20, 첫 hard, 51, 81, 100을 smoke 기준으로 우선 확인한다.
