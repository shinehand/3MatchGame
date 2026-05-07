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

## Gate 8. Rescue Book/메타 루프

- Rescue Book에 MVP 12종 동물이 모두 표시되고 잠김/해금 상태가 구분된다.
- 글로벌 런칭 컬렉션 확장 시 18종까지 스크롤/탭/그리드가 깨지지 않는다.
- 토큰, 우정 레벨, 장착 상태가 앱 재시작 후 유지된다.
- 스테이지 보상과 컬렉션 토큰 지급이 중복 지급되지 않는다.
- 비활성 탭에서는 표정 미리보기가 정지한다.
- 홈, 결과 화면, 이벤트에서 컬렉션 진입과 복귀가 가능하다.

## Gate 9. 실패/광고/IAP 공정성

- 강제 실패 케이스에서 Near Miss와 Strategic Miss가 다르게 분기된다.
- 실패 팝업에서 재도전, 지도, 닫기 같은 비구매 선택지가 항상 보인다.
- 광고 완료 후 추가 이동은 1회만 지급된다.
- 광고 로드 실패/중단 시 하트, 코인, 이동 수가 잘못 소모되지 않는다.
- 구매 취소/실패/복구가 게임 상태를 꼬이게 하지 않는다.
- 같은 레벨 3회 실패 시 같은 IAP 팝업을 반복 강제하지 않는다.

## Gate 10. 라이브 운영/분석

- 원격 설정 누락 시 기본값으로 안전하게 동작한다.
- 이벤트 미시작/진행 중/종료/오프라인 상태가 각각 올바른 UI를 표시한다.
- 이벤트 보상 수령은 idempotent하게 처리되어 중복 수령되지 않는다.
- 필수 분석 이벤트와 파라미터가 디버그 로그에 누락 없이 기록된다.
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
반려 이슈:
재확인 필요:
```
