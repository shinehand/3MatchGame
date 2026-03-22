# Flow Development 2026-03-21

## 목적

- 상세 기획안 기준으로 개발팀이 지금 바로 반영할 항목과 다음 라운드 항목을 분리한다.

## 이번 라운드에서 반영한 것

- 홈 메인 CTA를 `시작`으로 단일화
- 홈에서 `스테이지 라인`, `설정` 버튼 노출
- 전용 스테이지 선택 씬 추가
- 스테이지 선택 씬에서 스토리 라인과 현재 추천 스테이지 정보 노출
- 스테이지 라인 씬에 밴드 진행 노드와 선택 스테이지 자동 포커스 추가
- 홈 정보 카드에 진행도와 설정 상태 노출
- 설정 오버레이 신설
- 사운드 on/off 저장
- 햅틱 on/off 저장
- 저장된 설정을 홈과 인게임에 적용
- 스테이지 클리어 후 `다음 스테이지` 또는 `홈으로` 선택 가능
- `31-100` 구간 테마 배경 매핑 확장
- 스테이지 카드 프레임을 `current / cleared / finale / locked` 상태로 차별화

## 현재 저장 정의

- 홈의 `시작`은 마지막으로 선택한 스테이지가 강조된 스테이지 선택 씬으로 들어가는 의미다.
- 실제 진입은 스테이지 선택 씬에서 카드를 누른 순간 결정된다.
- 중간 턴 저장과 보드 스냅샷 저장은 이번 범위에 포함하지 않는다.

## 다음 구현 우선순위

### P1

- 오버레이 액션 규칙 정규화
- 이유: 시작, 일시정지, 클리어, 실패의 버튼 의미를 더 단단히 잠가야 한다.

### P1

- 스테이지 선택 상세 정보 보강
- 이유: 목표, 테마, 튜토리얼 여부, 추천 흐름을 선택 전에 보여줄 필요가 있다.

### P2

- 결과 오버레이 보상 정보 강화
- 이유: 별 획득과 해금 피드백이 아직 최소 수준이다.

### P2

- 튜토리얼 1회성 저장 검토
- 이유: 반복 플레이 시 피로도를 줄일 수 있다.

### P3

- 개발 잔존 구조 정리
- 이유: 숨겨진 디버그 버튼과 제품 플로우를 더 분리해야 한다.

## 영향 파일

- 홈/설정: `/Users/shinehandmac/Documents/puzzle/scenes/main.tscn`, `/Users/shinehandmac/Documents/puzzle/scripts/main.gd`
- 전용 스테이지 선택: `/Users/shinehandmac/Documents/puzzle/scenes/stage_select.tscn`, `/Users/shinehandmac/Documents/puzzle/scripts/stage_select.gd`
- 저장 구조: `/Users/shinehandmac/Documents/puzzle/scripts/game_session.gd`
- 인게임 설정 반영: `/Users/shinehandmac/Documents/puzzle/scripts/gameplay.gd`

## 검증

- `godot --headless --path . --import`
- `./scripts/validate_gameplay.sh`
- 홈에서 설정 변경 후 인게임 진입 수동 확인
