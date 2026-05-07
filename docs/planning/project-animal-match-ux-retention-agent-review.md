# Project Animal Match UX Retention Agent Review

## 0. 검토 범위

- 역할: Planning Agent 3, UX Retention & Player Motivation Planner
- 목적: 온보딩, 동물 수집, 표정 애니메이션, 실패 후 복귀, 이벤트, 라이브 운영을 리텐션 관점에서 보강한다.
- 기준 문서:
  - `docs/project-animal-match-agent-start-here.md`
  - `docs/project-animal-match-agent-output-index.md`
  - `docs/game/project-animal-match-core-design.md`
  - `docs/game/first-stage-flow.md`
  - `docs/game/ux-benchmark.md`
  - `docs/game/zoo-zoo-pop-master-flow-screen-spec.md`
  - `docs/art/project-animal-match-visual-style-guide.md`
  - `docs/art/project-animal-match-animation-vfx.md`
  - `docs/ops/project-animal-match-business-operations.md`
  - `docs/pm/project-animal-match-master-development-plan.md`
  - `docs/dev/project-animal-match-implementation-backlog.md`
  - `docs/dev/project-animal-match-animal-expression-system.md`
  - `docs/qa/project-animal-match-development-gates.md`

## 1. 현재 강점

### 1.1 코어 루프와 즉시 피드백 기준이 명확하다

현재 기획은 스와이프, 매치, 낙하, 리필, 특수 블록, 피버, 결과 팝업까지 매치3의 기본 재미를 짧은 세션 안에 배치하고 있다. `한 수의 결과는 0.2초 안에 시각적으로 반응`한다는 기준과 0.1-0.35초 단위의 Tween/VFX 규칙은 모바일 리텐션에 필요한 손맛을 만들기 좋은 토대다.

### 1.2 초반 난이도와 수익화 절제 원칙이 이미 있다

Level 1-5는 실패 가능성을 낮추고, Level 1-10은 하트 소모와 광고/결제를 제한한다는 방향이 잡혀 있다. 이는 D1 리텐션을 지키는 핵심 원칙이다. 특히 실패 후 제안 순서가 `무료 재도전 -> 보상형 광고 -> 보유 부스터 -> 코인/IAP`로 정의되어 있어 과도한 초반 압박을 피할 수 있다.

### 1.3 12종 로스터와 스테이지별 5-6종 풀 분리가 적절하다

전체 로스터 12종은 수집감과 라이브 운영 여지를 만들고, 한 스테이지 풀을 5-6종으로 제한하는 규칙은 보드 가독성과 매치 확률을 지킨다. 글로벌 모바일에서 동물 캐릭터는 언어 의존도가 낮아 현지화 부담을 줄이는 장점도 있다.

### 1.4 표정 애니메이션의 제작량과 성능 제한이 현실적이다

`idle`, `blink`, `smile`, `match`, `fever`, `worried` 상태가 정의되어 있고, 1차 구현을 full-frame이 아닌 atlas region, 눈/입 overlay, Tween fallback으로 잡은 점이 좋다. idle blink 동시 4개 제한은 저사양 모바일 성능과 보드 판독성을 함께 지키는 안전장치다.

### 1.5 운영 문서가 소프트 런칭 지표 중심으로 작성되어 있다

운영 문서에는 D1/D3/D7/D30 리텐션, rewarded ad opt-in, level fail/quit, crash-free sessions가 들어 있다. PM 문서의 소프트 런칭 성공 기준도 D1 35%, D7 12%, Level 1-10 이탈률 20% 이하로 제시되어 있어 이후 실험과 원격 설정의 판단 기준으로 삼기 좋다.

## 2. 리텐션 리스크

### 2.1 첫 세션의 감정 목표가 아직 약하다

현재 첫 스테이지 흐름은 `플레이 -> 목표 확인 -> 첫 매치` 진입에는 충분하지만, 첫 세션이 끝났을 때 플레이어가 무엇을 얻었는지 명확히 남기는 장치는 부족하다. Stage 1 클리어가 단순 성공 팝업으로 끝나면 캐릭터 애착, 수집 욕구, 다음 세션 복귀 명분이 약해진다.

### 2.2 동물 수집이 이벤트 소재에 머물 위험이 있다

문서에는 12종 로스터, 동물별 성격, 스킬, 표정, 기간 한정 수집 이벤트가 있으나, 상시 메타 루프가 아직 명확하지 않다. 컬렉션이 상시 화면, 해금 순서, 성장 보상, 장착/표현, 이벤트 연결로 이어지지 않으면 12종 로스터가 보드 스킨 이상의 의미를 갖기 어렵다.

### 2.3 표정 애니메이션이 보드 내부 피드백에 갇힐 수 있다

현재 표정 시스템은 선택, 매치, 피버, 실패 직전 위주로 잘 설계되어 있다. 다만 홈, 컬렉션, 결과, 실패 후 재도전, 이벤트 보상 화면까지 연결되지 않으면 동물의 감정 표현이 리텐션 자산으로 확장되지 못한다.

### 2.4 실패 후 수익화가 세분화되지 않으면 반감이 생긴다

실패 후 광고와 IAP 제안 원칙은 있으나, 실패 유형별 분기 기준이 더 필요하다. `아깝게 실패`, `전략 실패`, `첫 실패`, `반복 실패`, `하드 레벨 실패`를 구분하지 않으면 같은 팝업이 반복되어 유저가 조작당한다고 느낄 수 있다.

### 2.5 이벤트와 라이브 운영의 노출 우선순위가 아직 부족하다

데일리 보상, 시즌 패스, 기간 한정 수집 이벤트는 정의되어 있지만, 홈/월드맵/결과 화면에서 어떤 이벤트를 언제 보여줄지, 초보 유저에게 언제 열지, 원격 설정으로 어떤 값을 바꿀지 더 정확해야 한다. 이벤트가 너무 빨리 열리면 온보딩을 방해하고, 너무 늦으면 D1-D3 복귀 동기가 약해진다.

### 2.6 분석 이벤트가 리텐션 원인 분석에는 부족하다

기존 분석 이벤트는 레벨 시작/성공/실패, 광고, IAP, 시즌 XP 등 핵심 운영 지표를 포함한다. 그러나 온보딩 노출/완료, 첫 특수 블록, 첫 피버, 컬렉션 해금, 실패 팝업 선택, 이벤트 진입/이탈 같은 동기 전환 지점을 더 촘촘히 기록해야 한다.

## 3. 온보딩 업그레이드

### 3.1 첫 10레벨의 역할을 명확히 나눈다

| 구간 | 목표 | UX 요구 |
| --- | --- | --- |
| Level 1 | 첫 매치와 목표 칩 이해 | 하드 튜토리얼 없이 추천 스왑 1개를 부드럽게 강조한다. 실패, 광고, 하트 소모는 없다. |
| Level 2 | 목표 수집 진행감 | 매치된 목표 동물이 목표 칩으로 날아가는 연출을 확실히 보여준다. |
| Level 3 | 4매치와 Line Runner | 4매치가 자연스럽게 보이는 보드 배치를 1회 제공하고, 특수 배지 의미를 1문장으로 안내한다. |
| Level 4 | 컬렉션 첫 해금 | 클리어 후 첫 동물 카드가 `Rescue Book`에 들어가는 장면을 보여준다. |
| Level 5 | 첫 세션 보상 묶음 | 별, 코인, 동물 토큰, 다음 해금 예고를 한 화면에서 정리한다. |
| Level 6-7 | 장애물과 부스터 예고 | 장애물은 1종만 쓰고, 부스터는 판매가 아니라 기능 예고로만 노출한다. |
| Level 8 | Fever 경험 | 게이지 충전과 발동을 최소 1회 경험할 수 있게 목표량과 이동 수를 조정한다. |
| Level 9 | 실패 직전 감정 연출 | 이동 수 3 이하에서 목표 동물 일부만 `worried`를 짧게 보여준다. |
| Level 10 | 첫 장기 목표 제시 | 7일 스타터 미션, 컬렉션 다음 보상, 월드맵 다음 지역을 함께 예고한다. |

### 3.2 온보딩은 소프트 튜토리얼을 유지한다

- 강제 입력은 Level 1의 첫 추천 스왑 1회까지만 허용한다.
- 이미 유효 매치를 2회 이상 성공한 플레이어에게는 같은 설명을 반복하지 않는다.
- 튜토리얼 문구는 `아이콘 + 짧은 문장`으로 제한하고, 글로벌 현지화를 위해 문자열 키 길이 제한을 둔다.
- Level 1-10에서는 전면 광고, 결제 팝업, 하트 부족 팝업을 금지한다.
- 첫 실패가 Level 1-10에서 발생하면 하트 소모 없이 `무료 재도전`을 기본 CTA로 둔다.

### 3.3 첫 세션의 종료 목표를 만든다

첫 세션의 권장 목표는 `Level 5 클리어 + 첫 컬렉션 카드 해금 + 다음 동물 예고`다. 플레이어가 앱을 닫아도 다음 세션에서 돌아올 이유가 남아야 한다.

필수 첫 세션 보상:

| 시점 | 보상 | 목적 |
| --- | --- | --- |
| Level 1 클리어 | 별 1-3개, 코인 소량 | 기본 성취감 |
| Level 2 클리어 | 목표 동물 토큰 | 수집 규칙 예고 |
| Level 4 클리어 | 첫 컬렉션 카드 해금 | 캐릭터 소유감 |
| Level 5 클리어 | 스타터 미션 1일차 보상 | 다음 접속 동기 |

## 4. 동물 수집/메타 루프 제안

### 4.1 상시 컬렉션 화면: Rescue Book

`Rescue Book`은 12종 동물을 한눈에 보여주는 상시 컬렉션 화면이다. 보드에는 스테이지별 5-6종만 나오더라도, 컬렉션에서는 전체 로스터와 다음 해금 목표를 보여줘야 한다.

각 동물 카드 구성:

| 항목 | 설명 |
| --- | --- |
| 기본 정보 | 동물 이름, 성격 한 줄, 대표 색, 해금 상태 |
| 표정 미리보기 | `idle`, `blink`, `smile`, `match`, `fever`, `worried` 중 2-3개를 짧게 순환 |
| 구조 토큰 | 해당 동물 목표를 달성하거나 이벤트에서 얻는 누적 수집값 |
| 우정 레벨 | 1-5단계. 보상은 주로 cosmetic, 프로필 배지, 이벤트 XP 보너스 중심 |
| 장착 요소 | 보드 스킨, 결과 화면 리액션, 프로필 아이콘, 피버 테두리 색 |
| 다음 보상 | 다음 레벨까지 필요한 토큰과 받을 보상을 명확히 표시 |

### 4.2 상시 메타 루프

```text
스테이지 플레이
-> 목표 동물 구조 토큰 획득
-> Rescue Book 카드 성장
-> 표정/스킨/프로필/이벤트 보상 해금
-> 홈/결과/보드에서 장착 표현
-> 다음 스테이지와 이벤트로 복귀
```

이 루프는 레벨 클리어를 방해하지 않고 결과 화면의 보상 정보로 자연스럽게 붙어야 한다. 수집 보상은 초반에는 전투력보다 표현 보상 위주로 제공한다.

### 4.3 해금 페이싱

| 해금 시점 | 내용 | 의도 |
| --- | --- | --- |
| 시작 | 4종 기본 노출 | 첫 보드 판독성 유지 |
| Level 4 | 첫 카드 완전 해금 | 수집 시스템 이해 |
| Level 8 | 5-6번째 동물 해금 | Fever와 연결 |
| Level 12-20 | 나머지 기본 로스터 순차 해금 | D1-D3 복귀 목표 |
| 이벤트 | 특정 동물 스킨/표정 변형 | 라이브 운영 동기 |

`lion`, `elephant`는 로스터 완성감이 크므로 초반부터 잠김 상태로 보여주되, 플레이 가능 풀에는 밸런스가 정리된 뒤 순차 투입한다.

### 4.4 동물별 스킬은 늦게, 낮은 압력으로 연다

동물별 구조 스킬은 차별화 포인트지만, 첫 10레벨에 넣으면 학습량이 과하다. 권장 해금은 Level 15 이후이며, 처음에는 자동 패시브 또는 이벤트 보너스로만 소개한다.

가드레일:

- 특정 동물 미보유 때문에 일반 레벨 클리어가 막히면 안 된다.
- 우정 레벨 보상은 확률형 유료 뽑기가 아니라 플레이 누적 보상으로 시작한다.
- 스킬 효과는 레벨 난이도 밸런스를 무너뜨리지 않도록 원격 설정으로 조정 가능해야 한다.

## 5. 표정 애니메이션의 리텐션 활용

### 5.1 화면별 표정 역할

| 화면 | 표정 활용 | 제한 |
| --- | --- | --- |
| 홈 | 대표 동물 2-3종이 3-5초 간격으로 blink/smile | CTA를 가리지 않는다. |
| Stage Popup | 목표 동물이 짧게 smile | 시작 전 정보 판독이 우선이다. |
| Gameplay | 선택, 매치, 피버, 이동 수 부족에만 반응 | idle blink는 동시 4개 이하 유지 |
| Victory | 구조된 목표 동물이 match/smile 리액션 | 보상 숫자보다 과하게 크지 않게 한다. |
| Failure | 남은 목표 동물이 worried 후 격려 smile | 비난/좌절 표현 금지 |
| Rescue Book | 해금 동물의 표정 미리보기 | 배터리/성능을 위해 비활성 탭에서는 정지 |
| Event | 주인공 동물의 특수 smile/fever 변형 | 일반 보드 판독성을 해치지 않는다. |

### 5.2 실패 감정 연출 원칙

실패 화면의 동물은 플레이어를 탓하지 않는다. `worried`는 실패 직전의 긴장감을 만드는 0.5-0.8초 짧은 루프로만 쓰고, 실패 팝업에서는 `아깝다`, `다시 하면 가능하다`는 감정으로 전환한다.

권장 흐름:

```text
이동 수 3 이하
-> 목표 동물 1-3개만 worried
-> 실패 판정
-> 남은 목표 요약
-> 목표 동물 worried 1회
-> smile 또는 응원 제스처
-> 재도전/광고/부스터 선택
```

## 6. 실패/재도전/광고/IAP UX 가드레일

### 6.1 실패 유형을 분류한다

| 실패 유형 | 조건 | 기본 제안 |
| --- | --- | --- |
| Near Miss | 남은 목표가 1-2개이거나 목표 진행률 80% 이상 | `+3 moves` 보상형 광고 또는 코인 계속하기 |
| Strategic Miss | 남은 목표가 많고 이동 수 운영 실패 | 무료 재도전, 추천 부스터 설명 |
| First Fail | 해당 레벨 첫 실패 | 재도전 CTA 우선, 광고/IAP 약하게 표시 |
| Repeat Fail | 같은 레벨 2회 이상 실패 | 무료 부스터 1개 또는 쉬운 힌트 제공 |
| Hard Level Fail | 하드 레벨 실패 | 부스터 번들 제안 가능, 재도전 CTA는 계속 1순위 |

### 6.2 노출 순서와 금지 규칙

- Level 1-10: 하트 소모, 전면 광고, IAP 팝업, 코인 부족 팝업 금지.
- Level 11-15: 하트 시스템과 보상형 광고를 제한적으로 소개하되 IAP는 직접 제안하지 않는다.
- Level 16 이후: Near Miss 또는 Hard Level Fail에서만 IAP/코인 제안을 허용한다.
- 실패 팝업의 1순위 CTA는 항상 `재도전` 또는 `계속하기`여야 한다.
- `지도`, `닫기`, `재도전` 같은 비구매 선택지를 숨기거나 작게 만들어서는 안 된다.
- 보상형 광고는 opt-in만 허용하며 자동 재생하지 않는다.
- 광고 실패, 네트워크 실패, 구매 실패는 하트와 코인을 소모하지 않는다.
- 같은 실패 화면에서 보상형 광고는 1회만 제안한다.
- 결제 상품은 가격, 통화, 구성품, 구매 복구/영수증 상태가 명확해야 한다.

### 6.3 추가 이동 제안 조건

`Extra Moves` 제안은 플레이어가 성공 가능성을 납득할 수 있을 때만 보여준다.

필수 조건:

- stage_id가 11 이상이다.
- 현재 실패가 튜토리얼 설명 부족으로 발생한 상태가 아니다.
- 남은 목표 수 또는 장애물 체력이 원격 설정 기준 이하이다.
- 같은 레벨에서 연속 3회 이상 같은 유료 제안을 반복하지 않는다.
- 광고 또는 코인으로 얻는 이동 수는 명확히 표시한다. 기본값은 `+3 moves` 광고, `+5 moves` 코인/IAP다.

## 7. 이벤트와 라이브 운영 업그레이드

### 7.1 라이브 운영 레이어

| 레이어 | 해금 시점 | 목적 | 예시 |
| --- | --- | --- | --- |
| Daily Reward | Level 5 이후 | D1 복귀 | 7일 출석판, 2배 보상 광고 |
| Starter Missions | Level 5 이후 | 첫 주 목표 | 3개 레벨 클리어, 4매치 5회, 토끼 토큰 20개 |
| Collection Event | Level 12 이후 | 동물 애착 | `Fox Festival`, `Rabbit Rescue Week` |
| Season Pass | Level 20 이후 | 장기 목표 | 28일 XP 트랙, 스킨/부스터 보상 |
| Weekend Challenge | Level 25 이후 | 숙련자 재방문 | 하드 레벨 3개 연속 클리어 |

### 7.2 이벤트 노출 우선순위

- 첫 세션에는 이벤트 배너보다 `플레이`와 `컬렉션 첫 해금`을 우선한다.
- Level 5 이후 홈 하단에 Starter Missions를 연다.
- Level 12 이후 월드맵 또는 결과 화면에서 Collection Event를 1회 소개한다.
- 이벤트 팝업은 첫 노출 이후 홈 배너/아이콘으로 축소한다.
- 이벤트 종료 24시간 전에는 결과 화면에서 한 번만 리마인드한다.

### 7.3 원격 설정 후보

| 키 | 기본값 | 용도 |
| --- | --- | --- |
| `ftue_variant` | `soft_v1` | 튜토리얼 노출 방식 A/B |
| `heart_spend_start_level` | `11` | 하트 소모 시작 레벨 |
| `iap_offer_start_level` | `16` | IAP 직접 제안 시작 레벨 |
| `rewarded_continue_moves` | `3` | 광고 계속하기 이동 수 |
| `coin_continue_moves` | `5` | 코인 계속하기 이동 수 |
| `near_miss_goal_threshold` | `2` | Near Miss 판정 남은 목표 수 |
| `near_miss_progress_threshold` | `0.8` | Near Miss 판정 진행률 |
| `starter_mission_unlock_level` | `5` | 스타터 미션 해금 |
| `collection_event_unlock_level` | `12` | 수집 이벤트 해금 |
| `season_pass_unlock_level` | `20` | 시즌 패스 해금 |
| `event_featured_animal_id` | `fox` | 주간 이벤트 대표 동물 |
| `interstitial_min_level` | `16` | 전면 광고 최소 레벨 |
| `interstitial_cooldown_minutes` | `10` | 전면 광고 쿨다운 |

### 7.4 롤백 기준

운영 변경 후 아래 중 하나라도 발생하면 원격 설정을 즉시 롤백한다.

| 지표 | 롤백 기준 |
| --- | --- |
| D1 retention | 기존 대비 3%p 이상 하락 |
| Level 1-10 quit rate | 기존 대비 5%p 이상 상승 |
| stage fail rate | 해당 밴드 목표치보다 10%p 이상 상승 |
| rewarded ad opt-in | 노출 증가에도 수락률 5%p 이상 하락 |
| purchase refund/error | 결제 오류 또는 환불 문의 급증 |
| crash-free sessions | 99% 미만 |

## 8. 정확한 분석 요구사항

기존 운영 문서의 이벤트는 유지하되, 아래 이벤트와 파라미터를 추가한다. 모든 이벤트는 공통 파라미터 `app_version`, `build_number`, `device_os`, `locale`, `country`, `session_id`, `user_id_or_install_id`, `remote_config_version`을 포함한다.

### 8.1 온보딩 이벤트

| 이벤트 | 트리거 | 필수 파라미터 |
| --- | --- | --- |
| `ftue_step_view` | 튜토리얼/안내 노출 | `step_id`, `stage_id`, `trigger`, `variant_id`, `attempt_count` |
| `ftue_step_complete` | 안내 조건 완료 | `step_id`, `stage_id`, `elapsed_ms`, `input_count`, `hint_count` |
| `ftue_step_skip` | 안내 닫기/자동 생략 | `step_id`, `reason`, `stage_id`, `elapsed_ms` |
| `first_match_complete` | 최초 유효 매치 완료 | `stage_id`, `moves_used`, `animal_id`, `match_size` |
| `first_special_create` | 최초 특수 블록 생성 | `stage_id`, `special_type`, `moves_used` |
| `first_fever_start` | 최초 피버 발동 | `stage_id`, `moves_used`, `gauge_source` |

### 8.2 컬렉션 이벤트

| 이벤트 | 트리거 | 필수 파라미터 |
| --- | --- | --- |
| `collection_view` | Rescue Book 진입 | `entry_point`, `unlocked_count`, `new_badge_count` |
| `animal_unlock` | 동물 카드 해금 | `animal_id`, `source`, `stage_id`, `token_balance` |
| `animal_token_gain` | 토큰 획득 | `animal_id`, `amount`, `source`, `stage_id`, `event_id` |
| `animal_friendship_level_up` | 우정 레벨 상승 | `animal_id`, `level_before`, `level_after`, `reward_id` |
| `animal_cosmetic_equip` | 스킨/표정/프로필 장착 | `animal_id`, `cosmetic_id`, `cosmetic_type`, `entry_point` |
| `animal_expression_preview` | 컬렉션 표정 미리보기 | `animal_id`, `expression_id`, `entry_point` |

### 8.3 실패/광고/IAP 이벤트

| 이벤트 | 트리거 | 필수 파라미터 |
| --- | --- | --- |
| `fail_offer_show` | 실패 팝업 제안 노출 | `stage_id`, `fail_type`, `attempt_count`, `goals_remaining`, `progress_ratio`, `offer_type` |
| `fail_offer_select` | 실패 팝업 선택 | `stage_id`, `fail_type`, `offer_type`, `cost_type`, `cost_amount` |
| `fail_offer_dismiss` | 실패 팝업 닫기 | `stage_id`, `fail_type`, `dismiss_action`, `elapsed_ms` |
| `retry_start` | 재도전 시작 | `stage_id`, `attempt_count`, `source`, `heart_spent` |
| `extra_moves_grant` | 추가 이동 지급 | `stage_id`, `source`, `moves_amount`, `transaction_id` |
| `ad_reward_fail` | 광고 실패/중단 | `placement`, `stage_id`, `reward_type`, `ad_network`, `error_code` |
| `iap_purchase_fail` | 구매 실패 | `product_id`, `placement`, `error_code`, `price`, `currency` |
| `iap_purchase_cancel` | 구매 취소 | `product_id`, `placement`, `price`, `currency` |
| `iap_restore_complete` | 구매 복구 완료 | `restored_product_count`, `platform` |

### 8.4 이벤트/운영 이벤트

| 이벤트 | 트리거 | 필수 파라미터 |
| --- | --- | --- |
| `remote_config_exposure` | 원격 설정 적용 | `config_key`, `variant_id`, `config_value_hash` |
| `event_impression` | 이벤트 배너/팝업 노출 | `event_id`, `event_type`, `placement`, `featured_animal_id` |
| `event_join` | 이벤트 시작/참여 | `event_id`, `event_type`, `entry_point` |
| `event_progress` | 이벤트 목표 진행 | `event_id`, `progress_before`, `progress_after`, `source` |
| `event_reward_claim` | 이벤트 보상 수령 | `event_id`, `reward_id`, `reward_type`, `reward_amount` |
| `starter_mission_complete` | 스타터 미션 완료 | `mission_id`, `day_index`, `reward_id`, `elapsed_since_install_hours` |

### 8.5 데이터 품질 요구

- 같은 `transaction_id`를 가진 보상 지급 이벤트는 중복 보상으로 처리하지 않는다.
- 네트워크 오프라인 상태에서는 이벤트를 로컬 큐에 저장하고, 다음 세션에서 순서대로 전송한다.
- `level_start`, `level_complete`, `level_fail`, `retry_start`는 stage_id와 attempt_count가 서로 맞아야 한다.
- `ad_reward_complete`와 `extra_moves_grant`는 광고 보상형 계속하기에서 1:1로 연결되어야 한다.
- A/B 테스트 이벤트에는 반드시 `variant_id`와 `remote_config_version`이 포함되어야 한다.

## 9. 정확한 백로그 요구사항

아래 카드는 현재 `PAM-DEV-010`, `PAM-DEV-020`, `PAM-DEV-030`, `PAM-DEV-031`, `PAM-DEV-032`, `PAM-QA-040` 이후 추가해야 할 권장 백로그다. 본 문서는 요구사항을 정의하며, 실제 백로그 파일 수정은 별도 작업으로 분리한다.

### PAM-UX-050: FTUE 1-10레벨 동기 설계 확정

- 소유: Planning Agent
- 대상 문서: `docs/game/project-animal-match-core-design.md`, `docs/game/first-stage-flow.md`
- 작업:
  - Level 1-10의 학습 목표, 금지 수익화, 첫 컬렉션 해금 시점을 확정한다.
  - `ftue_step_id` 목록과 문자열 키를 정의한다.
- 완료 기준:
  - Level 1-10에서 어떤 안내가 언제 나오고 언제 생략되는지 표로 확인 가능하다.

### PAM-DEV-050: FTUE 상태와 분석 이벤트 구현

- 소유: Development Agent
- 대상 파일 후보: `scripts/gameplay.gd`, `scripts/stage_catalog.gd`, 신규 `scripts/analytics_service.gd`, 신규 `data/ftue_steps.json`
- 선행: PAM-UX-050
- 완료 기준:
  - `ftue_step_view`, `ftue_step_complete`, `first_match_complete`, `first_special_create`, `first_fever_start`가 중복 없이 기록된다.
  - Level 1-10에서 광고/IAP/하트 소모가 발생하지 않는다.
- 검증:
  - `./scripts/validate_gameplay.sh`
  - 분석 이벤트 디버그 로그 샘플 확인

### PAM-DEV-060: Rescue Book 데이터 모델과 저장 구현

- 소유: Development Agent
- 대상 파일 후보: 신규 `scripts/collection_state.gd`, 신규 `data/animals.json`, 저장 데이터 모듈
- 선행: PAM-DEV-010
- 완료 기준:
  - 12종 동물의 해금 상태, 토큰, 우정 레벨, 장착 cosmetic을 저장/로드한다.
  - 저장 데이터가 없거나 구버전이어도 기본 상태로 안전하게 마이그레이션한다.
- 검증:
  - 신규 저장, 앱 재시작, 구버전 저장 fallback 테스트

### PAM-DEV-061: Rescue Book UI 구현

- 소유: Development Agent + Art Agent
- 대상 파일 후보: 신규 `scenes/collection_screen.tscn`, 신규 `scripts/collection_screen.gd`
- 선행: PAM-DEV-060
- 완료 기준:
  - 12종 카드가 잠김/해금/신규 상태를 표시한다.
  - 해금 동물은 표정 미리보기를 성능 제한 안에서 보여준다.
  - 홈, 결과 화면, 이벤트 배너에서 진입 가능하다.
- 검증:
  - portrait/landscape, 작은 화면, 현지화 문자열 길이 확인

### PAM-DEV-070: 실패 유형 분류와 제안 정책 구현

- 소유: Development Agent + Planning Agent
- 대상 파일 후보: `scripts/gameplay.gd`, 신규 `scripts/fail_offer_policy.gd`, 원격 설정 모듈
- 완료 기준:
  - Near Miss, Strategic Miss, First Fail, Repeat Fail, Hard Level Fail이 구분된다.
  - Level 1-10에서는 수익화 제안이 차단된다.
  - 보상형 광고와 코인/IAP 계속하기가 원격 설정 기준으로 노출된다.
- 검증:
  - 레벨별 실패 상태 강제 시뮬레이션
  - 광고 실패, 구매 취소, 네트워크 실패 처리

### PAM-DEV-080: 라이브 이벤트 템플릿과 원격 설정 연결

- 소유: Development Agent + Ops Agent
- 대상 파일 후보: 신규 `data/events/*.json`, 신규 `scripts/live_event_service.gd`, 원격 설정 모듈
- 완료 기준:
  - Daily Reward, Starter Missions, Collection Event, Season Pass의 해금 레벨과 노출 위치가 데이터로 제어된다.
  - 이벤트 종료/미시작/오프라인 상태에서 안전한 fallback을 제공한다.
- 검증:
  - 날짜 변경, 타임존, 오프라인, 원격 설정 누락 테스트

### PAM-ANA-090: 분석 이벤트 계약 검증기 추가

- 소유: Technical Lead + QA Agent
- 대상 파일 후보: 신규 `scripts/validate_analytics_contract.gd`, 신규 `data/analytics_events.json`
- 완료 기준:
  - 필수 이벤트명과 필수 파라미터 누락을 검증한다.
  - 이벤트 샘플 로그가 스키마와 일치한다.
- 검증:
  - `godot --headless` 기반 계약 검증 또는 프로젝트 표준 검증 스크립트 추가

## 10. 정확한 QA 요구사항

기존 Gate 1-6에 아래 검증 축을 추가한다. 실제 QA 게이트 문서 수정은 별도 작업으로 분리한다.

### Gate 7. FTUE/첫 세션 리텐션

| 항목 | 승인 기준 |
| --- | --- |
| 첫 진입 | 신규 설치 후 3탭 이내 Stage 1 진입 |
| 첫 매치 | Stage 1 시작 후 30초 이내 첫 유효 매치 가능 |
| 반복 설명 | 같은 튜토리얼이 완료 후 다시 뜨지 않음 |
| 초반 수익화 | Level 1-10에서 하트 소모, 전면 광고, IAP 팝업 없음 |
| 첫 보상 | Level 5 이내 컬렉션 또는 스타터 미션 보상 1회 경험 |
| 현지화 | 한국어/영어/일본어 pseudo-localization에서 버튼과 목표 칩 텍스트 겹침 없음 |

### Gate 8. 컬렉션/메타 루프

| 항목 | 승인 기준 |
| --- | --- |
| 12종 표시 | Rescue Book에 12종이 모두 표시되고 잠김/해금 상태가 구분됨 |
| 저장 | 토큰, 우정 레벨, 장착 상태가 앱 재시작 후 유지됨 |
| 보상 | 스테이지 보상과 컬렉션 토큰 지급이 중복 지급되지 않음 |
| 성능 | 컬렉션 표정 미리보기가 비활성 탭에서 정지함 |
| 진입 | 홈, 결과 화면, 이벤트에서 컬렉션 진입/복귀가 가능함 |

### Gate 9. 실패/광고/IAP 공정성

| 항목 | 승인 기준 |
| --- | --- |
| 실패 분류 | 강제 실패 케이스에서 Near Miss와 Strategic Miss가 다르게 분기됨 |
| 비구매 선택 | 실패 팝업에서 재도전/지도/닫기 선택지가 항상 보임 |
| 광고 보상 | 광고 완료 후 추가 이동이 1회만 지급됨 |
| 광고 실패 | 광고 로드 실패/중단 시 하트, 코인, 이동 수가 잘못 소모되지 않음 |
| 구매 실패 | 구매 취소/실패/복구가 상태를 꼬이게 하지 않음 |
| 반복 압박 | 같은 레벨 3회 실패 시 같은 IAP 팝업을 반복 강제하지 않음 |

### Gate 10. 라이브 운영/분석

| 항목 | 승인 기준 |
| --- | --- |
| 원격 설정 | 설정 누락 시 기본값으로 안전하게 동작 |
| 이벤트 상태 | 미시작/진행 중/종료/오프라인 상태가 각각 올바른 UI를 표시 |
| 이벤트 보상 | 보상 수령은 idempotent하게 처리되어 중복 수령되지 않음 |
| 분석 이벤트 | 필수 이벤트와 파라미터가 누락 없이 디버그 로그에 기록됨 |
| A/B 노출 | `remote_config_exposure`가 variant별로 1회 이상 기록됨 |
| 롤백 | 원격 설정 변경 후 이전 기본값으로 복귀 가능 |

## 11. 우선순위 결론

1. Level 1-10 온보딩을 `학습`, `첫 보상`, `첫 컬렉션`, `첫 복귀 목표`로 재정의한다.
2. 12종 로스터는 단순 보드 에셋이 아니라 `Rescue Book` 상시 메타 루프에 연결한다.
3. 표정 애니메이션은 보드 피드백뿐 아니라 홈, 컬렉션, 승리, 실패, 이벤트 화면까지 확장한다.
4. 실패 후 제안은 실패 유형과 레벨 구간에 따라 다르게 보여주고, 초반 수익화는 강하게 차단한다.
5. 라이브 운영은 해금 레벨, 원격 설정, 분석 이벤트, 롤백 기준을 한 묶음으로 구현해야 한다.
