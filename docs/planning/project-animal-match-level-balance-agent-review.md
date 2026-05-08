# Project Animal Match 레벨 밸런스/진행 리뷰

작성 역할: Planning Agent 2 - Level Balance & Progression Planner
작성일: 2026-05-02
대상: Godot 4.x, 글로벌 모바일, 100스테이지 캠페인

## 1. 현재 강점

- `data/stages/*.json`는 100개 스테이지를 10개 밴드로 분리하고, `band`, `roster_group`, `theme_key`, `board_mask`, `targets`, `spawn_profile`, `mechanics`, `tutorial`을 가진 데이터 주도 구조로 정리되어 있다.
- `scripts/stage_catalog.gd`가 원본 JSON의 중첩 구조를 런타임용 평면 필드(`target_collect`, `animal_pool`, `spawn_weights`)로 정규화하므로, 게임플레이 코드가 비교적 단순한 스테이지 딕셔너리를 받을 수 있다.
- `scripts/stage_data_validator.gd`에는 이미 12종 로스터(`rabbit`, `bear`, `cat`, `chick`, `frog`, `dog`, `panda`, `pig`, `penguin`, `fox`, `lion`, `elephant`)와 10개 `roster_group`이 정의되어 있다.
- 현재 검증 기준으로 `./scripts/validate_stage_data.sh`와 `./scripts/validate_stage_balance.sh`가 통과한다.
- 스테이지별 활성 동물 풀은 현재 4-6종 범위 안에 들어오며, 목표 동물은 풀에 포함되어 있다.
- 100레벨 진행 문서는 새 메커닉 추가 없이 `목표 조합`, `보드 모양`, `덤불 밀도`, `이동 수`, `목표 수치`로만 난이도를 올리는 방향을 명확히 잡고 있다.
- 초반 `stages_001_010.json`은 4종에서 시작해 5-6종으로 넓히는 흐름, 보드 마스크 축소, 덤불 0-2개, 점수 목표 소량 노출까지 포함해 실제 튜토리얼 데이터의 형태를 갖추고 있다.

## 2. 밸런스 리스크

- 12종 로스터 방향은 문서와 validator에 존재하지만, 현재 전체 스테이지 풀에는 10종만 등장한다. `lion`, `elephant`는 아직 어느 스테이지의 `spawn_profile.pool`에도 없다.
- `dog`, `panda`, `pig`, `penguin`, `fox`는 Stage 7-10에 조기 등장한 뒤 후반 90개 스테이지에서 거의 사라진다. 현재 Stage 11-100은 대부분 `rabbit/bear/cat/chick/frog` 5종 반복이라 수집감과 진행감이 약하다.
- 초반 문서 기준은 `Stage 11: 점수 목표 정식 도입`인데, 현재 데이터는 Stage 3, 8, 9, 10에 이미 점수 목표를 사용한다. 이 상태를 유지하려면 Stage 3은 "보너스성 점수 노출", Stage 11은 "정식 점수 게이트"로 구분해야 한다.
- `mechanics.enabled`가 Stage 1부터 `row_special`, `col_special`, `bomb_special`을 포함한다. 학습 해금 문서의 Stage 3/7 해금 흐름과 맞추려면 실제 생성 허용 시점과 튜토리얼 문구가 일치해야 한다.
- `difficulty`가 Stage 41-100에서 전부 `Hard`로 고정되어 있어, 후반부 안에서도 일반/하드/피날레의 리듬이 보이지 않는다. 모바일 퍼즐에서는 장시간 하드 연속보다 `Normal -> Hard -> Recovery -> Hard -> Finale` 파형이 유지율에 유리하다.
- 현재 balance validator는 밴드별 이동 수와 덤불 수 범위는 확인하지만, 로스터 해금, 동물 풀 회전, 특수 블록 해금, 목표 수치 대비 이동 수, 점수 목표 도입 시점은 검사하지 않는다.
- 목표 수집량과 점수 목표가 밴드별로 증가하지만, 활성 셀 수와 장애물 밀도 대비 목표 난이도 지표가 없다. 후반 좁은 보드에서 `score + collect + blockers`가 동시에 걸리면 체감 난이도가 급상승할 수 있다.

## 3. 100레벨 진행 업그레이드

기존 10밴드 구조는 유지하되, 각 밴드에 `주 학습`, `로스터 진행`, `난이도 파형`, `검증 포인트`를 추가한다.

| 밴드 | 설계 목표 | 동물 풀 방향 | 난이도 파형 |
| --- | --- | --- | --- |
| 1-10 | 기본 스와이프, 수집, 첫 덤불, 특수 블록 맛보기 | 기본 4종 + frog/dog 제한 노출. 6종 풀은 Stage 10 같은 밴드 마감에만 허용 | Easy 중심, Stage 10만 미니 피날레 |
| 11-20 | 점수 목표 정식 도입, 덤불 관리 시작 | panda 정식 합류, 기존 5종과 교대 | Easy 2개, Normal 6개, Hard 2개 |
| 21-30 | 비대칭 마스크와 복수 수집 | pig 정식 합류, 목표 동물 2종 빈도 증가 | Normal 중심, 25/30 게이트 |
| 31-40 | 수집 2종 + 점수 + 덤불 복합 | penguin 합류, 연쇄/점수형 풀 운영 | Normal 6개, Hard 4개 |
| 41-50 | 좁은 게이트형 보드, 점수 압박 | fox 합류, 힌트/판독성 테마 | Normal 3개, Hard 5개, Finale 2개 |
| 51-60 | 야영지 내부, 고밀도 장애물 | lion 합류, 하드 레벨 리더 테마 | Recovery 2개, Hard 6개, Finale 2개 |
| 61-70 | 전문가 루트 판독, 복합 목표 숙련 | lion 재사용 + elephant 예고 카메오 금지 또는 스토리 전용 노출 | Normal 2개, Hard 6개, Master 2개 |
| 71-80 | 탈출 준비, 좁은 루트 마스터리 | 10종 이상 해금 상태에서 5-6종 회전 | Recovery 2개, Hard 6개, Finale 2개 |
| 81-90 | 코끼리 수송 경로, 최종권 압박 | elephant 정식 합류, elephant 목표 첫 사용 | Hard 6개, Master 3개, Finale 1개 |
| 91-100 | 최종 구조, 모든 규칙 종합 | 전체 12종 중 스테이지별 6종만 선택. lion/elephant를 피날레 축으로 사용 | Hard 5개, Master 3개, Finale 2개 |

추가 원칙:

- 10개 밴드의 마지막 1-2개 스테이지는 다음 밴드의 보드 압박을 미리 보여 주되, 새 동물과 새 압박을 같은 스테이지에서 동시에 처음 보여 주지 않는다.
- 하드 레벨 직후에는 같은 메커닉을 더 넓은 보드나 높은 목표 가중치로 복습하는 회복 레벨을 둔다.
- Stage 10, 20, 30, ... 100은 `boss_stage` 또는 `finale` 태그를 붙여 PM/QA가 별도 승인 대상으로 추적한다.
- 점수 목표는 Stage 3에서 낮은 수치로 "맛보기"를 허용할 수 있으나, Stage 11부터 `score_focus` 태그를 붙여 정식 게이트로 관리한다.

## 4. 동물 해금 및 활성 풀 규칙

### 4.1 전체 로스터

런칭 로스터는 아래 12종으로 고정한다.

`rabbit`, `bear`, `cat`, `chick`, `frog`, `dog`, `panda`, `pig`, `penguin`, `fox`, `lion`, `elephant`

### 4.2 해금 단계

| 해금 시점 | 신규 동물 | 목적 |
| --- | --- | --- |
| Stage 1 | rabbit, bear, cat, chick | 기본 색/동물 판독, 수집 목표 |
| Stage 4 | frog | 첫 덤불과 좁은 보드 대응 |
| Stage 7 | dog | 5매치/Rainbow 학습 보조 |
| Stage 11 | panda | 점수 목표 정식 도입과 긴 호흡 |
| Stage 21 | pig | 보상/수집감 확장 |
| Stage 31 | penguin | 연쇄/점수형 밴드 연결 |
| Stage 41 | fox | 좁은 보드 판독과 힌트 테마 |
| Stage 51 | lion | 하드 레벨 리더, 후반 진입 신호 |
| Stage 81 | elephant | 최종 구조 목표, 피날레 감정 축 |

### 4.3 스테이지별 활성 풀

- 일반 원칙: 한 스테이지의 `spawn_profile.pool`은 5-6종이다.
- 튜토리얼 예외: Stage 1-3은 4종, Stage 4-6은 5종을 권장한다.
- Stage 7-10은 특수 블록 학습 구간이므로 5종을 기본으로 하고, 6종은 Stage 10 같은 밴드 마감에서만 허용한다.
- Hard/Master/Finale 태그가 붙은 스테이지는 6종을 허용하되, 목표 동물 가중치를 낮추면 안 된다.
- 새 동물이 처음 등장하는 스테이지에서는 그 동물을 목표로 삼거나, 목표가 아니라면 weight 1 카메오로만 넣고 다음 3스테이지 안에 정식 목표로 사용한다.
- 이미 해금된 동물도 매 스테이지에 모두 넣지 않는다. 전체 로스터는 수집/이벤트/맵에서 보여 주고, 실제 보드에는 5-6종만 회전 출현시킨다.

### 4.4 가중치 규칙

- 단일 수집 목표: 목표 동물 weight는 전체 평균보다 최소 1.5배 높게 둔다.
- 복수 수집 목표: 목표 동물끼리 weight 차이는 1 이내로 둔다.
- 점수 중심/하드 레벨: 모든 동물 weight를 2-3 사이로 평준화하되, 수집 목표가 있으면 목표 동물만 +1 한다.
- 신규 동물 첫 등장: 튜토리얼 목적이면 weight 3 이상, 카메오 목적이면 weight 1로 제한한다.
- 풀에 없는 동물의 `spawn_profile.weights` 키는 validator에서 오류로 처리한다.

## 5. 튜토리얼 및 난이도 게이트 개선

- Stage 1: 첫 수집. 풀 4종, 이동 수 12, 덤불 없음, 목표 동물 weight 5 이상.
- Stage 2: 복수 수집. 목표 2종을 보여 주되 점수/덤불은 아직 금지.
- Stage 3: 4매치 학습. 점수 목표를 유지한다면 낮은 보너스성 수치로 두고 튜토리얼 문구에 "줄 제거"를 우선한다.
- Stage 4: 첫 덤불. 덤불 1개, 풀 5종, 덤불이 비활성 셀이나 막다른 위치에 있으면 실패.
- Stage 7: 5매치/Rainbow 학습. 새 동물 추가보다 5매치 성공률을 우선하므로 풀은 5종 권장.
- Stage 8: Combo Gauge 첫 노출. 점수 목표와 동시에 쓰되, 장애물은 2개 이하로 제한한다.
- Stage 10: 초반 밴드 마감. 6종 풀 허용, score + collect + blockers 조합 허용, 단 목표 동물 weight는 4 이상 유지한다.
- Stage 11: 점수 목표 정식 도입. 이후 score 목표가 있는 스테이지에는 `score_focus` 또는 `mixed_goal` 태그를 붙인다.
- Stage 20/30/40: 각 밴드 종료 전 QA가 3회 플레이 기준으로 "첫 3수 안에 목표 이해", "특수 블록 최소 1회 체감", "실패 시 원인 납득"을 확인한다.
- Stage 50 이후: 하드 레벨이 3개 이상 연속되면 다음 1개는 회복 레벨로 둔다. 회복 레벨은 동일 밴드 이동 수 범위 안에서 덤불 수를 하한으로 낮추거나 목표 동물 weight를 높인다.

난이도 태그는 기존 `difficulty` 하나로만 관리하지 말고 `tags`에 보조 정보를 둔다.

- `tutorial`: Stage 1-10 핵심 학습.
- `score_focus`: 점수 목표가 주요 압박.
- `blocker_focus`: 덤불 제거가 주요 압박.
- `mixed_goal`: 수집 + 점수 + 덤불 복합.
- `recovery`: 직전 하드 압박을 완화하는 복습.
- `finale`: 밴드 마지막 구조/보스성 스테이지.
- `master`: 후반부 고난도 판독 스테이지.

## 6. 정확한 validator 요구사항

`scripts/stage_data_validator.gd`와 `scripts/validate_stage_balance.gd`는 다음 항목을 오류 또는 경고로 분리해 검사해야 한다.

### 6.1 StageDataValidator 필수 오류

- 스테이지 id는 1-100 연속이어야 한다.
- 원본 JSON은 `targets.collect`, `targets.score`, `targets.blockers`, `spawn_profile.pool`, `spawn_profile.weights` 구조를 가져야 한다. 정규화 이후 필드만 검사하면 원본 데이터 오류를 놓칠 수 있다.
- `VALID_ANIMALS`는 정확히 12종이어야 하며, 정의되지 않은 동물이 목표/풀/가중치에 있으면 오류다.
- `VALID_ROSTER_GROUPS`는 10개 밴드와 1:1로 매칭되어야 한다.
- `spawn_profile.pool` 크기는 Stage 1-3은 4, Stage 4-6은 5, Stage 7-100은 5-6이어야 한다. 단 `tags`에 `finale`, `hard`, `master` 중 하나가 없는 Stage 7-10은 5종을 권장 경고로 처리한다.
- 모든 `targets.collect` 동물은 `spawn_profile.pool`과 `spawn_profile.weights`에 포함되어야 한다.
- 모든 `spawn_profile.pool` 동물은 양수 weight를 가져야 한다.
- `spawn_profile.weights`에 풀 밖 동물이 있으면 오류다.
- 첫 해금 전 동물이 풀이나 목표에 등장하면 오류다. 예: `lion`은 Stage 51 이전, `elephant`는 Stage 81 이전에 보드 풀에 넣지 않는다.
- 새 동물이 처음 등장한 뒤 3스테이지 안에 목표 또는 튜토리얼 문구로 설명되지 않으면 경고다.
- `mechanics.enabled`는 해금 시점과 맞아야 한다. Stage 1-2는 기본 매치만, Stage 3부터 줄 제거, Stage 7부터 rainbow, Stage 8부터 combo gauge를 허용한다.
- `target_blockers`는 실제 `blockers.size()`보다 클 수 없고, 모든 blocker는 활성 셀 위에 있어야 한다.
- `tutorial`은 Stage 1-10과 신규 동물 첫 등장 스테이지에서 비어 있으면 오류다.

### 6.2 StageBalanceValidator 필수 오류

- 밴드별 이동 수와 덤불 수는 현재 `BAND_RULES` 범위를 유지한다.
- 밴드별 active cell 범위를 함께 검사한다. 권장 범위는 1-10: 48-64, 11-30: 40-56, 31-100: 40-52다.
- `band` 문자열과 id 범위가 일치해야 한다.
- 각 10스테이지 밴드는 정확히 10개 스테이지를 가져야 한다.
- 각 밴드 마지막 스테이지는 `finale` 또는 `boss_stage` 태그를 가져야 한다.
- 한 밴드 안에서 같은 `spawn_profile.pool` 조합이 4회 이상 반복되면 경고다.
- Stage 11-100 전체에서 모든 해금 동물이 최소 5회 이상 풀에 등장해야 한다. `lion`과 `elephant`는 해금 이후 각각 최소 8회 이상 등장해야 한다.
- Hard/Master/Finale 스테이지가 4개 이상 연속되면 경고다.
- score 목표가 있는 스테이지는 `score_focus` 또는 `mixed_goal` 태그를 가져야 한다.

### 6.3 검증 명령

개발자는 스테이지 데이터 또는 validator를 수정한 뒤 반드시 아래 명령을 실행한다.

```bash
./scripts/validate_stage_data.sh
./scripts/validate_stage_balance.sh
```

로스터 코드나 게임플레이 로딩까지 건드렸다면 추가로 아래 명령을 실행한다.

```bash
./scripts/validate_gameplay.sh
```

## 7. 정확한 backlog 요구사항

`docs/dev/project-animal-match-implementation-backlog.md`에는 아래 요구를 반영해야 한다.

- `PAM-DEV-010` 완료 기준에 `gameplay.gd`, `stage_data_validator.gd`, stage JSON, fallback texture 경로가 모두 12종을 동일 순서로 인식한다는 조건을 추가한다.
- `PAM-DEV-020` 작업 범위를 "풀 크기 5-6 제한"에서 "해금 단계, 첫 등장 튜토리얼, 풀 회전, weight 규칙"까지 확장한다.
- 신규 카드 `PAM-DEV-022: 동물 해금/풀 회전 validator 강화`를 추가한다.
  - 대상 파일: `scripts/stage_data_validator.gd`, `scripts/validate_stage_balance.gd`, `data/stages/*.json`
  - 완료 기준: 모든 동물이 해금 이후 반복 등장하고, `lion`/`elephant`가 후반 밴드에서 실제 풀과 목표에 포함된다.
  - 검증: `./scripts/validate_stage_data.sh`, `./scripts/validate_stage_balance.sh`
- 신규 카드 `PAM-DEV-023: 튜토리얼 해금과 mechanics.enabled 정렬`을 추가한다.
  - 대상 파일: `data/stages/*.json`, `scripts/stage_data_validator.gd`
  - 완료 기준: Stage 1-10 튜토리얼 문구, `mechanics.enabled`, 실제 특수 블록 생성 가능 시점이 같은 규칙을 따른다.
- 신규 카드 `PAM-DEV-024: 난이도 태그와 회복 레벨 파형 도입`을 추가한다.
  - 대상 파일: `data/stages/*.json`, `scripts/validate_stage_balance.gd`
  - 완료 기준: 각 밴드에 `recovery`, `score_focus`, `blocker_focus`, `mixed_goal`, `finale`, `master` 태그가 필요한 곳에 들어가고, 하드 연속 경고가 동작한다.
- 데이터 수정 카드는 반드시 "대상 파일: 해당 `data/stages/stages_XXX_YYY.json` 한 묶음"으로 쪼갠다. 여러 에이전트가 같은 JSON을 동시에 수정하지 않도록 10스테이지 밴드 단위로 소유권을 나눈다.

## 8. 개발자 구현 우선순위

1. `lion`, `elephant` 전용 기본 블록 에셋은 닫혔으므로, 코드/validator는 12종 직접 Texture2D 로드를 유지하고 후속은 실제 디바이스 보드 판독성과 표정 atlas QA로 분리한다.
2. Stage 1-10의 풀 크기와 `mechanics.enabled`를 튜토리얼 게이트에 맞춘다.
3. Stage 11-100의 반복 5종 풀을 밴드별 5-6종 회전 풀로 재작성한다.
4. validator에 해금 순서, 풀 밖 weight, 밴드별 active cell, finale 태그, 하드 연속 경고를 추가한다.
5. `./scripts/validate_stage_data.sh`와 `./scripts/validate_stage_balance.sh`를 모든 데이터 PR의 필수 통과 조건으로 둔다.
