# Planning Refinement Execution

## 목표

- 기획 문서를 현재 구현 기준으로 재정렬하고, 아트와 개발이 같은 기준으로 움직일 수 있게 만든다.

## 이미 충분한 영역

- 코어 퍼즐 규칙
- 100스테이지 캠페인 구조
- 구조 서사 방향
- 첫 세션 UX 목표

## 우선 해결할 충돌

1. 이동 수 규칙 충돌
- [stage-production-guide.md](/Users/shinehandmac/Documents/puzzle/docs/game/stage-production-guide.md)의 Hard `15~16`
- [level-progression-100.md](/Users/shinehandmac/Documents/puzzle/docs/game/level-progression-100.md)의 후반 `18~19`

2. 덤불 도입 규칙 충돌
- 제작 가이드는 Easy 비포함
- 실제 스펙은 초반 Easy에 덤불 포함

3. 튜토리얼 범위 부족
- 실제 구현은 Stage 1만 온보딩
- 목표는 Stage 11, 25, 45, 65, 85, 95에 밴드 전환 학습 장치 포함

4. 현재 흐름 문서 부정확
- 설정은 아직 플레이스홀더
- 홈/이어하기/스테이지 선택/일시정지 흐름을 다시 정의해야 함

## 이번 라운드 산출물

### 1. 기준선 문서 갱신

- [game-design.md](/Users/shinehandmac/Documents/puzzle/docs/game/game-design.md)
- [game-plan-overview.md](/Users/shinehandmac/Documents/puzzle/docs/game/game-plan-overview.md)
- [implementation-review-2026-03-18.md](/Users/shinehandmac/Documents/puzzle/docs/game/implementation-review-2026-03-18.md)

### 2. 튜토리얼 설계서 신설

- Stage 1 온보딩
- 밴드 전환 튜토리얼 11, 25, 45, 65, 85, 95
- 각 지점별 목표, 문구 길이, UI 강조 위치, 종료 조건

### 3. 흐름 문서 재정리

- 현재 흐름
- 목표 흐름
- 예외 처리

### 4. 밸런스 규칙 단일화

- 이동 수
- 덤불 도입 시점
- 복합 목표 허용 규칙

### 5. 스테이지 데이터 운영 필드 잠금

- `tutorial`
- `story_beat`
- `rescue_target`
- `theme_key`
- `band_gate`

## Planning Team 작업 순서

1. Systems Planner
- 현재 구현과 데이터 필드를 맞춘다.
2. Flow Planner
- 현재/목표 흐름 분리 문서 작성
3. Balance Planner
- 이동 수, 덤불, 복합 목표 기준 통합
4. Story Planner
- 밴드 전환 카피와 구조 의미를 짧은 문장으로 정리

## 완료 기준

- 문서 간 규칙 충돌 제거
- 아트팀이 튜토리얼 지점과 화면별 문구를 바로 사용할 수 있음
- 개발팀이 데이터/흐름 명세만 보고 구현 착수 가능
