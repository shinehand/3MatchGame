# Project Animal Match Business Model & Live Operations

## 1. 목표

`Project Animal Match`는 초반 유지율을 해치지 않는 선에서 하트, 부스터, 보상형 광고, 시즌 이벤트를 결합한다. 소프트 런칭에서는 매출 극대화보다 레벨 난이도, 광고 수용도, 재방문 동기를 먼저 검증한다.

## 2. BM 설계

### 2.1 하트 시스템

- 기본 하트: 5개
- 실패 시 하트 1개 소모
- 회복 시간: 30분당 1개
- 초반 10레벨까지는 하트 소모를 비활성화하거나 실패 2회 후부터 적용한다.
- 하트 부족 시 선택지:
  - 기다리기
  - 보상형 광고로 1개 회복
  - 코인으로 5개 충전
  - 무제한 하트 30분 번들 구매

### 2.2 아이템 판매

| 아이템 | 효과 | 판매 위치 |
| --- | --- | --- |
| Hammer | 선택한 블록 1개 제거 | 실패 직전, 게임 중 |
| Line Brush | 선택 행 또는 열 제거 | 하드 레벨 진입 전 |
| Shuffle Bell | 보드 재섞기 | 가능한 수가 적을 때 |
| Rainbow Treat | 선택 동물 전체 제거 | 고난도 레벨 번들 |
| Extra Moves | 실패 후 이동 수 +5 | 실패 팝업 |

### 2.3 광고

- 보상형 광고:
  - 실패 후 추가 이동 수 +3
  - 하트 1개 회복
  - 일일 보상 2배
  - 무료 부스터 상자
- 전면 광고:
  - 초반 15레벨 이전에는 사용하지 않는다.
  - 클리어 직후가 아니라 스테이지 선택 복귀 후 낮은 빈도로 사용한다.
- 광고 제거:
  - 전면 광고 제거
  - 보상형 광고 보상은 유지하되 `무료 즉시 수령`로 전환할지 소프트 런칭에서 검증한다.

## 3. 이벤트 시스템

### 3.1 데일리 보상

- 7일 출석판
- 1-3일: 코인/소형 부스터
- 4-6일: 하트/중형 부스터
- 7일: Rainbow Treat 또는 30분 무제한 하트

### 3.2 시즌 패스

- 시즌 기간: 28일
- 진행 방식: 스테이지 클리어, 콤보 달성, 동물 수집으로 pass XP 획득
- 무료 트랙: 코인, 하트, 기본 부스터
- 프리미엄 트랙: 희귀 동물 스킨, 대형 부스터, 무제한 하트

### 3.3 기간 한정 동물 수집 이벤트

- 특정 동물 블록 수집량을 누적해 보상 지급
- 예: `Fox Festival`, `Rabbit Rescue Week`
- 기존 레벨을 재사용하되 이벤트 목표를 overlay로 추가한다.
- 이벤트 난이도는 일반 유저가 무료로 60-70%까지 도달 가능하게 설계한다.
- 런칭 로스터 12종 중 매주 1-2종을 주인공으로 세워 표정 스킨, 피버 이펙트 색상, 프로필 배지를 보상으로 제공한다.

## 4. 데이터 분석

### 4.1 핵심 지표

- DAU, WAU, MAU
- D1/D3/D7/D30 retention
- ARPU, ARPDAU, ARPPU
- payer conversion
- rewarded ad impressions / opt-in rate
- level start, clear, fail, quit
- crash-free sessions

### 4.2 로그 이벤트

| 이벤트 | 필수 파라미터 |
| --- | --- |
| `app_first_open` | app_version, device_os, locale, country |
| `tutorial_step_complete` | step_id, elapsed_time |
| `level_start` | stage_id, attempt_count, heart_count, booster_selected |
| `level_complete` | stage_id, moves_left, score, stars, cascades, specials_used |
| `level_fail` | stage_id, moves_used, goals_remaining, fail_reason |
| `level_quit` | stage_id, moves_left, goals_remaining |
| `booster_use` | booster_id, stage_id, source |
| `ad_offer_show` | placement, stage_id, offer_type |
| `ad_reward_complete` | placement, reward_type, reward_amount |
| `iap_purchase_start` | product_id, price, currency, placement |
| `iap_purchase_complete` | product_id, price, currency |
| `heart_spent` | stage_id, heart_before, heart_after |
| `season_xp_gain` | source, amount, season_id |

### 4.3 분석 관점

- 초반 이탈: Level 1-10에서 fail/quit가 급증하는 지점
- 난이도: stage_id별 fail rate, 평균 시도 횟수, 남은 이동 수
- 수익화: 실패 후 광고 수락률과 구매 전환율
- 경제: 코인 수급/소모 비율, 부스터 보유량 과잉 또는 부족
- 성능: 기기별 crash rate, loading time, frame drop

## 5. 업데이트 전략

### 5.1 레벨 공급

- 글로벌 런칭 전: 100레벨 확보
- 런칭 후: 2주마다 20레벨 추가
- 월 1회 신규 장애물 또는 새 목표 타입 도입

### 5.2 라이브 운영 프로세스

1. 월요일: 지난주 지표 리뷰와 문제 레벨 선정
2. 화요일: 밸런스 수정안 작성 및 내부 플레이
3. 수요일: 원격 설정 또는 데이터 패치 QA
4. 목요일: 제한 배포 또는 A/B 테스트 시작
5. 금요일: 지표 확인 후 유지/롤백 결정

### 5.3 원격 설정 후보

- 하트 회복 시간
- 실패 후 추가 이동 수 제안량
- 보상형 광고 보상량
- 레벨별 move_limit 보정
- 이벤트 목표량
- 전면 광고 빈도

## 6. 운영 원칙

- 초반 학습 구간은 광고와 결제를 최소화한다.
- 레벨 실패가 결제 유도 지점이 될 수는 있지만, 불공정한 난수로 실패를 만들지 않는다.
- 모든 수익화 변경은 retention과 fail rate를 함께 보고 판단한다.
- 동물 수집 이벤트는 캐릭터 애착을 강화하는 방향이어야 하며, 단순 반복 노동으로 느껴지면 안 된다.
