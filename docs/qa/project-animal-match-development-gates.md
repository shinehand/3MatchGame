# Project Animal Match Development Gates

## 목적

기획 보고서를 실제 개발로 옮긴 뒤 QA 에이전트가 승인/반려를 판단하는 기준을 정의한다.

## 공통 게이트

모든 개발 작업은 다음 항목을 보고해야 한다.

- 작업 카드 id
- 변경 파일
- 실행한 검증 명령
- 통과/실패 결과
- 남은 리스크

## Gate 1. 문서 일치

- `docs/project-animal-match-agent-start-here.md`의 현재 결정 사항과 충돌하지 않는다.
- `docs/planning/project-animal-match-decision-register.md`의 Locked 결정과 충돌하지 않는다.
- `docs/planning/project-animal-match-system-rules-matrix.md`의 입력/출력/예외 조건과 구현이 일치한다.
- `docs/planning/project-animal-match-analytics-remote-config-spec.md`의 필수 이벤트/파라미터와 충돌하지 않는다.
- `docs/planning/project-animal-match-animal-roster-animation-matrix.md`의 보드 12종/컬렉션 18종 구분과 구현 데이터가 일치한다.
- `docs/planning/project-animal-match-level-progression-content-bible.md`의 Stage 1-10 FTUE와 밴드별 난이도 파형을 위반하지 않는다.
- 작업 결과가 `docs/dev/project-animal-match-implementation-backlog.md`의 완료 기준을 만족한다.
- 새 규칙이 생기면 관련 기획/기술/QA 문서가 함께 갱신된다.

## Gate 2. 스테이지 데이터

- `data/stages/*.json`이 모두 로드된다.
- 각 스테이지의 `spawn_profile.pool`은 기본 5-6종이다.
- 튜토리얼 구간은 4-5종을 허용한다.
- 목표 동물은 반드시 pool과 weights에 포함된다.
- 검증 명령:

```sh
./scripts/validate_stage_data.sh
./scripts/validate_stage_balance.sh
```

## Gate 3. 12종 로스터

- `rabbit`, `bear`, `cat`, `chick`, `frog`, `dog`, `panda`, `pig`, `penguin`, `fox`, `lion`, `elephant`가 코드와 validator에서 같은 기준으로 존재한다.
- 에셋이 없는 동물은 명시 fallback으로 표시된다.
- 목표 UI와 결과 UI에서 동물명이 누락되지 않는다.

## Gate 4. 표정 애니메이션

- 대기 중 blink는 동시에 최대 4개 타일이다.
- `is_busy == true`일 때 새 idle expression이 시작되지 않는다.
- 타일 선택 시 smile 반응이 보인다.
- 매치 제거 직전 match 반응이 보인다.
- 이동 수 부족 또는 실패 직전 worried 반응이 과하지 않게 보인다.
- 표정 연출이 스와이프, 낙하, 리필, 특수 블록 발동을 막지 않는다.

## Gate 4A. 특수 블록 조합

- 특수+특수 조합은 일반 매치보다 먼저 처리된다.
- 4매치는 방향에 맞는 row/column 특수를 만들고, 5매치는 rainbow 특수를 만든다.
- row+column, row+row, column+column, row+bomb, column+bomb, bomb+bomb 6종은 중복 제거 없이 1회씩 처리된다.
- 특수 조합 경로 위의 chained special과 인접 장애물 피해가 scene smoke에서 검증된다.
- Stage 31 row+column 특수 조합은 실제 `_resolve_swap` runtime smoke에서 이동 수 1회 소모, 점수 증가, 장애물 제거, `is_busy` 복귀를 검증한다.
- rainbow+special은 특수+특수 큐보다 rainbow resolution 경로를 우선한다.

## Gate 5. 모바일 UI

- portrait와 landscape에서 보드가 잘리지 않는다.
- 동물 얼굴과 특수 배지가 서로 가리지 않는다.
- 목표 칩 숫자와 동물 아이콘이 작은 화면에서도 구분된다.
- 피버/표정/VFX가 겹쳐도 목표 UI가 읽힌다.

## Gate 6. 성능

- 일반 매치 파티클은 10개 이하, 특수 블록 파티클은 40개 이하를 기준으로 한다.
- idle expression은 atlas region 변경 또는 단일 Tween 위주로 처리한다.
- 동물별 개별 Timer를 64개 타일 전체에 붙이지 않는다.
- 저사양 기준에서 콤보 5단계 연출 중 체감 입력 지연이 없어야 한다.

## Gate 7. FTUE/첫 세션 리텐션

- 신규 설치 후 3탭 이내 Stage 1에 진입할 수 있다.
- Stage 1 시작 후 30초 이내 첫 유효 매치가 가능하다.
- 완료한 튜토리얼 설명이 같은 계정/기기에서 반복 노출되지 않는다.
- Level 1-10에서 하트 소모, 전면 광고, IAP 팝업이 나오지 않는다.
- Level 5 이내 첫 컬렉션 카드 또는 스타터 미션 보상을 경험한다.
- 한국어/영어/일본어 pseudo-localization에서 목표 칩과 버튼 텍스트가 겹치지 않는다.

## Gate 7A. Stage Popup / 시작 부스터

- 스테이지 노드를 누르면 gameplay로 바로 전환되지 않고 Stage Popup이 먼저 열린다.
- Stage Popup은 목표, 이동 수, 난이도/테마, 보상, 시작 부스터 3종, `START` 버튼을 보여 준다.
- Rescue Buddy가 있는 스테이지는 Stage Popup에 Buddy 동물명, 스킬명, 충전 조건, 짧은 효과 설명을 보여 주고, Buddy가 없는 스테이지는 빈 Buddy 영역을 보여 주지 않는다.
- 시작 부스터 3종은 아이콘과 선택 상태를 가지며, 선택 결과가 `GameSession.selected_pre_boosters`에 저장된다.
- Gameplay 시작 시 선택 부스터는 한 번만 소비되고 보드에는 `rainbow`, `row/col`, `bomb` 특수 블록이 각각 배치된다.
- `stage_start`는 `selected_boosters`와 `start_boosters_applied`를 기록하고, 각 시작 부스터는 `booster_used`의 `source = pre_stage`로 기록된다.
- Stage Popup 열기/닫기 애니메이션과 모바일 터치감은 실제 기기 또는 시뮬레이터에서 최종 확인한다.

## Gate 8. Rescue Book/메타 루프

- Rescue Book에 MVP 12종 동물이 모두 표시되고 잠김/해금 상태가 구분된다.
- 글로벌 런칭 컬렉션 확장 시 18종까지 스크롤/탭/그리드가 깨지지 않는다.
- 토큰, 우정 레벨, 장착 상태가 앱 재시작 후 유지된다.
- 스테이지 보상과 컬렉션 토큰 지급이 중복 지급되지 않는다.
- 비활성 탭에서는 표정 미리보기가 정지한다.
- 홈, 결과 화면, 이벤트에서 컬렉션 진입과 복귀가 가능하다.

## Gate 8A. Rescue Buddy 분석

- Buddy 충전, 준비, 발동, 차단은 `buddy_skill_charge`, `buddy_skill_ready`, `buddy_skill_trigger`, `buddy_skill_blocked`로 실제 런타임에서 기록된다.
- Stage 4 `quick_refill`은 목표 동물 매치 충전 후 1회 발동하고, max use 이후 차단 이벤트를 남긴다.
- Stage 5 `soft_bomb_plus`, Stage 8 `combo_peep`, Stage 16 `smart_hint`, Stage 18 `leap_clear`, Stage 24 `calm_fever`, Stage 25 `coin_sniff`, Stage 31 `cascade_slide`, Stage 41 `sly_route`, Stage 51 `brave_start`, Stage 81 `mighty_push`는 scene smoke에서 실제 상태 변화와 `buddy_skill_trigger`를 검증한다.
- Stage 20 `loyal_fetch`는 실패 직전 구조 이동을 줄 때 `buddy_skill_trigger`를 남기며 scene smoke에서 검증된다.
- Stage 4/5/8/16/18/20/24/25/31/41/51/81 첫 등장 Buddy 스테이지는 `recommended_smoke`로 수동 QA 진입점을 유지한다.

## Gate 9. 실패/광고/IAP 공정성

- 강제 실패 케이스에서 Near Miss와 Strategic Miss가 다르게 분기된다.
- 실패 팝업에서 재도전, 지도, 닫기 같은 비구매 선택지가 항상 보인다.
- Near Miss 실패 팝업의 `+3 이동 받고 계속` CTA는 실제로 overlay를 닫고 이동 3회를 지급해 플레이 상태로 복귀한다.
- 결과/실패 overlay runtime smoke는 Stage 1 클리어 보상/CTA와 Stage 25 near-miss 실패 offer/analytics를 검증한다.
- 광고 완료 후 추가 이동은 1회만 지급된다.
- 광고 로드 실패/중단 시 하트, 코인, 이동 수가 잘못 소모되지 않는다.
- 구매 취소/실패/복구가 게임 상태를 꼬이게 하지 않는다.
- 같은 레벨 3회 실패 시 같은 IAP 팝업을 반복 강제하지 않는다.

## Gate 10. 라이브 운영/분석

- 원격 설정 누락 시 기본값으로 안전하게 동작한다.
- 이벤트 미시작/진행 중/종료/오프라인 상태가 홈/스테이지 선택 칩, 홈 상세, 결과 오버레이, 컬렉션 상세에서 사용자-facing 문구로 표시된다.
- 원격 설정 적용은 세션별 `remote_config_exposure`로 기록되고, `variant_id`, `config_key`, `config_value_hash`가 비어 있지 않다.
- 이벤트 보상 수령은 idempotent하게 처리되어 중복 수령되지 않는다.
- 홈 이벤트 상세 overlay에서 이벤트 참여와 보상 수령 상태가 저장되고, 미션형 이벤트 보상은 wallet 지급값으로 집계된다.
- 혼합 이벤트 보상은 `reward_type=mixed`와 `reward_breakdown`으로 골드/토큰/부스터 구성 요소가 누락 없이 기록된다.
- 필수 분석 이벤트와 파라미터가 디버그 로그에 누락 없이 기록된다.
- 자동 scene smoke가 런타임에서 실제 기록된 분석 이벤트의 필수 파라미터 누락, `remote_config_exposure`, 이벤트 기간/오프라인 상태, 사용자-facing 상태 문구, `event_join`, `event_progress`, `event_reward_claim` idempotency 회귀를 잡는다.
- 라이브 이벤트 노출은 `home`, `stage_select`, `result_overlay`, `collection` placement별 노출면 또는 기록 경로를 가진다.
- A/B 테스트 노출은 `remote_config_exposure` 이벤트로 variant별 1회 이상 기록된다.
- 원격 설정 변경 후 이전 기본값으로 롤백 가능하다.

## Gate 11. 동물 로스터/애니메이션 에셋

- MVP 보드 12종은 64px 미리보기에서 이름 없이 구분된다.
- 13-18번 컬렉션 전용 동물은 `board_enabled` 전까지 stage JSON의 `spawn_profile.pool`에 들어가지 않는다.
- 모든 MVP 보드 동물은 `idle`, `blink`, `smile`, `match`, `fever`, `worried` 상태를 표시하거나 fallback으로 대체된다.
- `match` 표현은 제거 직전 우선순위가 가장 높고, `blink`나 `worried`가 이를 덮지 않는다.
- `fever` 표현 중에도 목표 UI, 특수 배지, 이동 수 HUD가 읽힌다.
- atlas/overlay 에셋 누락 시 게임이 멈추지 않고 기본 블록 텍스처로 fallback한다.
- 컬렉션 표정 미리보기는 화면 밖 카드 또는 비활성 탭에서 재생되지 않는다.

## 승인 보고 형식

```text
QA 결과: 승인 또는 반려
대상 작업 카드:
확인 환경:
검증 명령:
주요 확인:
No-device readiness:
Device-blocked items:
Evidence logs:
반려 이슈:
재확인 필요:
```
