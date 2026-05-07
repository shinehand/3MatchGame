# Project Animal Match Core Loop Agent Review

작성자: Planning Agent 1 - Core Loop & Systems Planner
범위: 현재 기획/개발/아트 문서를 검토해 개발 착수 가능한 코어 루프와 시스템 기준을 보강한다.

## 1. 현재 강점

- 기본 루프가 명확하다: 스테이지 목표 확인 -> 스와이프 -> 매치/낙하/리필 -> 연쇄 -> 보상/실패 선택으로 모바일 매치3의 기대 흐름을 갖췄다.
- 특수 블록 3종과 조합표가 이미 있어 초반 구현 목표가 선명하다.
- 전체 로스터 12종과 스테이지별 출현 풀 5-6종을 분리해 수집감과 매치 확률을 동시에 지키려는 방향이 좋다.
- 기술 문서가 JSON 스테이지, `StageCatalog`, 상태 흐름, `BoardExpressionScheduler`, 아틀라스/풀링 최적화 기준을 이미 제시한다.
- 아트/VFX 문서가 0.1-0.2초 단위 반응 속도, 파티클 제한, 표정 동시 재생 수 제한을 명시해 글로벌 저사양 모바일 대응 기준이 있다.

## 2. 기획 공백과 충돌

- 피버 지속 시간이 `8초 또는 3턴`으로 혼재한다. 매치3는 연쇄 시간과 기기 성능에 따라 초 단위 체감이 흔들리므로 MVP는 `3회 플레이어 이동` 기준으로 고정해야 한다.
- 스테이지 데이터 용어가 충돌한다. 백로그/QA는 `spawn_profile.pool`, 기술 문서는 `animal_pool`/`spawn_weights`를 쓴다. 개발 전 canonical schema와 호환 읽기 규칙을 확정해야 한다.
- 동물별 스킬이 캐릭터성 수준에 머문다. 발동 조건, 횟수 제한, UI 표시, 밸런스 예산, QA 기준이 없어 구현 시 랜덤한 보너스 묶음이 될 위험이 있다.
- 특수 블록 생성 위치, 동시 매치 우선순위, 특수+특수 조합 처리 순서, 장애물 피해 규칙이 테스트 가능한 형태로 부족하다.
- 실패 후 재도전/광고/부스터 흐름은 있으나, 어떤 상황을 `아깝게 실패`로 판정할지와 결과 팝업 데이터가 정의되지 않았다.
- 초반 레벨 학습 목표는 있으나, 각 시스템이 몇 레벨에서 처음 등장하고 어떤 QA 시나리오로 검증될지 연결이 약하다.

## 3. 업그레이드 코어 루프 제안

### 3.1 세션 루프

1. `StageIntro`: 목표, 이동 수, 난이도 태그, 출현 동물 풀, 추천 부스터를 표시한다.
2. `BoardSeed`: 초기 보드는 자동 매치 없이 시작하고, 유효 스왑이 최소 1개 있어야 한다.
3. `PlayerMove`: `Idle`에서만 입력을 받고, 매치가 성립하지 않는 스왑은 되돌리며 이동 수를 소모하지 않는다.
4. `ResolveTurn`: 유효 스왑 후 이동 수를 1 소모하고, 매치 -> 특수 생성/발동 -> 목표/점수/피버 충전 -> 낙하 -> 리필 -> 연쇄를 보드가 안정될 때까지 처리한다.
5. `EndTurnCheck`: 모든 연쇄가 끝난 뒤 목표 완료, 이동 수 0, 셔플 필요 여부, 피버 시작 여부를 판정한다.
6. `Result`: 클리어면 별/코인/다음 스테이지로 이동하고, 실패면 near-miss 판정에 따라 무료 재도전, 광고 추가 이동, 보유 부스터, 코인 구매 순서로 제안한다.

### 3.2 개발 기준 상태 흐름

```text
StageIntro -> BoardSeed -> Idle -> Swapping -> ResolvingMatches
-> ApplyingSpecials -> CollectingGoals -> Falling -> Refilling
-> CheckingCascade -> EndTurnCheck -> Idle/StageClear/StageFail
```

- 입력 허용 상태는 `Idle`뿐이다.
- 특수 블록과 피버 효과는 `ResolveTurn` 안의 effect queue로 처리한다.
- 클리어 판정은 연쇄가 모두 끝난 뒤 1회 실행한다. 단, 목표 완료 연출은 중간에 누적 표시할 수 있다.
- 셔플은 이동 수를 소모하지 않으며, 셔플 후 즉시 매치와 무수 루프가 없어야 한다.

## 4. 특수 블록, 피버, 동물 스킬 개선안

### 4.1 특수 블록

- 생성 우선순위: `Rainbow Herd` > `Paw Bomb` > `Line Runner` > 일반 매치.
- 생성 위치: 마지막으로 움직인 타일을 우선하고, 불가능하면 매치 그룹 중심을 사용한다.
- 처리 우선순위: 특수+특수 조합 > 단일 특수 발동 > 일반 매치 제거.
- 장애물 피해: Line Runner는 경로상 덤불에 1 피해, Paw Bomb은 범위 내 1 피해, Rainbow Herd는 선택 동물 제거 후 인접 목표/장애물에만 보조 피해를 준다.
- 조합 효과는 별도 effect queue 항목으로 만들어 중복 제거와 VFX 순서를 테스트 가능하게 한다.

### 4.2 Zoo-Zoo Fever

- MVP 기준: 게이지 100 도달 후 다음 `3회 플레이어 이동` 동안 발동한다. 8초 타이머는 VFX 연출 상한으로만 둔다.
- 충전량: 일반 매치 그룹 +8, 4매치/특수 생성 +12, 특수 발동 +15, 연쇄 2단 이상은 단계당 +5를 추가한다.
- 발동 시점: 현재 연쇄가 모두 끝난 뒤 시작한다. 피버 중 다시 100을 넘으면 남은 턴에 +1턴만 추가하고 최대 4턴으로 제한한다.
- MVP 보너스: 점수 2배, 목표 동물 매치 시 목표 수집량 +1. 랜덤 폭발은 밸런스 변동이 커서 P2 이후로 미룬다.
- HUD 요구: 게이지, 남은 피버 턴, 피버 중 목표 보너스가 한눈에 보여야 한다.

### 4.3 동물 스킬

- MVP는 스테이지마다 `Rescue Buddy` 1종만 활성화한다. 보드에 등장하는 모든 동물이 스킬을 동시에 갖지 않는다.
- 스킬은 `stage_id`, `buddy_animal`, `skill_id`, `charges_required`, `max_uses`로 데이터화한다.
- 발동은 기본 `자동 1회`로 시작한다. 수동 버튼은 UI/튜토리얼 비용이 커서 soft launch 이후 판단한다.
- 밸런스 예산은 세 부류로 나눈다.
  - 판독 보조: 고양이/여우. 힌트 강조만 제공하고 보드를 직접 제거하지 않는다.
  - 해결 보조: 곰/개구리/코끼리. 폭탄 범위, 장애물 피해처럼 제한된 상황에서만 작동한다.
  - 경제/피버 보조: 병아리/판다/돼지/펭귄/사자/강아지. 게이지, 점수, 보상, 하드 레벨 보조로 분산한다.
- 스킬 QA 기준: 한 스테이지에서 기본 1회, 하드 레벨 최대 2회까지 허용하고, 클리어율을 5%p 이상 흔들면 수치 재조정한다.

## 5. Development / Art / QA 인계 요구사항

### Development

- `animal_pool`/`spawn_weights`를 canonical schema로 삼고, 기존 `spawn_profile.pool`이 있으면 읽기 호환만 제공한다.
- `FeverController`, `SpecialEffectQueue`, `AnimalSkillController`의 책임을 `gameplay.gd` 내부 함수 또는 독립 스크립트로 명확히 나눈다.
- 자동 테스트 또는 검증 fixture에 최소 6개 케이스를 추가한다: 4매치, L/T매치, 5매치, 특수+특수 조합, 피버 3턴 종료, Rescue Buddy 1회 발동.
- 모든 변경은 `./scripts/validate_stage_data.sh`, `./scripts/validate_stage_balance.sh`, `./scripts/validate_gameplay.sh` 또는 씬 로드 검증 결과를 보고한다.

### Art

- 12종 기본 블록, `Line Runner` 방향 배지, `Paw Bomb` 배지, `Rainbow Herd` 배지의 1차 파일명과 safe area를 확정한다.
- 표정은 `blink`, `smile`, `match`, `fever`, `worried` 순서로 제작하고, 개발 fallback과 같은 상태명을 사용한다.
- VFX는 `vfx_line_runner_horizontal`, `vfx_line_runner_vertical`, `vfx_paw_bomb`, `vfx_rainbow_herd`, `vfx_fever_start`, `vfx_fever_match`, `vfx_fever_end` id로 납품한다.
- 저사양용 축소안도 함께 준다: 파티클 수, trail 길이, flash 사용 여부를 각 VFX별로 명시한다.

### QA

- 스테이지 1, 5, 10, 20, 첫 하드 레벨, 81, 100을 smoke set으로 고정한다.
- 각 smoke stage에서 목표 동물이 pool/weights에 포함되는지, 첫 수가 있는지, 클리어/실패 팝업이 정상인지 확인한다.
- 특수 블록 조합 6종, 피버 3턴, Rescue Buddy 발동/미발동, 이동 수 0 near-miss 판정을 별도 체크리스트로 검증한다.
- 모바일 portrait/landscape에서 목표 UI, 피버 HUD, 표정/VFX가 서로 가리지 않는지 스크린샷으로 남긴다.
- 반려 시에는 `재현 stage_id`, `seed 또는 board 상태`, `입력 순서`, `기대 결과`, `실제 결과`를 반드시 포함한다.

## 6. 백로그 추가 제안 5개

### PAM-DEV-050: 스테이지 스키마 canonical 정리

- 대상: `docs/dev/project-animal-match-technical-architecture.md`, `scripts/stage_catalog.gd`, `scripts/stage_data_validator.gd`, `data/stages/*.json`
- 내용: `animal_pool`/`spawn_weights`를 표준으로 확정하고 `spawn_profile.pool` 호환 읽기와 validator 경고를 추가한다.
- 검증: stage data/balance 검증 통과, 목표 동물이 pool/weights에 누락되지 않음.

### PAM-DEV-051: SpecialEffectQueue와 조합 테스트

- 대상: `scripts/gameplay.gd`, 필요 시 `scripts/special_effect_queue.gd`, gameplay 검증 fixture
- 내용: 특수 생성 우선순위, 특수+특수 조합, 장애물 피해, VFX 순서를 effect queue로 고정한다.
- 검증: 특수 조합 6종이 중복 제거 없이 1회씩 처리된다.

### PAM-DEV-052: FeverController MVP 구현

- 대상: `scripts/gameplay.gd`, HUD 관련 씬/스크립트, `scripts/fx_layer.gd`
- 내용: 게이지 충전, 3턴 지속, 목표 수집량 +1, 점수 2배, 남은 턴 HUD를 구현한다.
- 검증: 피버 발동/연장/종료가 이동 수와 연쇄 처리에 끼어들지 않는다.

### PAM-DEV-053: Rescue Buddy 동물 스킬 시스템

- 대상: `scripts/gameplay.gd`, 필요 시 `scripts/animal_skill_controller.gd`, stage JSON
- 내용: 스테이지별 `buddy_animal`, `skill_id`, charge, max use를 읽고 자동 1회 스킬을 발동한다.
- 검증: 동일 스테이지에서 최대 횟수 초과 발동이 없고, 스킬 없는 stage는 기존 플레이와 동일하다.

### PAM-DEV-054: 결과/실패 near-miss 플로우

- 대상: `scripts/gameplay.gd`, 결과 팝업 씬/스크립트, QA 체크리스트
- 내용: 목표 잔여량, 남은 이동 수, 부스터/광고 제안 조건을 결과 데이터로 분리한다.
- 검증: 이동 수 0 실패, 목표 1개 부족 실패, 클리어, 재도전 선택이 모두 상태를 깨지 않고 동작한다.
