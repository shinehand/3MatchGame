# Animal Pop Match 전체 기획 개요

## 1. 문서 목적

- 이 문서는 `Animal Pop Match`의 전체 방향을 한 번에 이해하기 위한 상위 기획 문서다.
- 세부 규칙은 `game-design.md`, 첫 화면부터 첫 스테이지 진입 흐름은 `first-stage-flow.md`, 레벨 제작 방식은 `stage-production-guide.md`를 기준으로 본다.

## 2. 게임 정의

- 장르: 모바일 스테이지형 매치3 퍼즐
- 플랫폼: Android 우선
- 화면 방향: landscape 고정
- 핵심 레퍼런스: `Candy Crush Saga`, `Royal Match`, `Toon Blast`
- 핵심 차별점: 사탕 대신 `귀여운 동물 얼굴 블록`을 전면에 사용
- 스토리 콘셉트: 아프리카 밀림에서 밀렵꾼에게 붙잡힌 동물들을 퍼즐로 구출하는 캠페인

## 3. 게임 경험 목표

- 첫 10초 안에 `무슨 게임인지` 이해된다.
- 첫 30초 안에 `스와이프 -> 매치 -> 낙하 -> 목표 진행`의 만족감을 준다.
- 첫 스테이지 클리어 전까지 `목표`, `이동 수`, `특수 블록`, `장애물`의 의미를 자연스럽게 학습시킨다.
- 한 턴의 피드백은 짧고 선명해야 하며, 큰 매치는 눈에 띄는 보상을 줘야 한다.
- 플레이어는 `동물을 풀어 준다`는 감정적 목적을 느껴야 한다.

## 4. 제품 구조

### 핵심 플레이 루프

1. 홈 화면 진입
2. `플레이` 버튼 선택
3. 가장 최근 스테이지 또는 Stage 1 진입
4. 스테이지 목표와 이동 수 확인
5. 스와이프 매치 진행
6. 목표 달성 시 클리어, 실패 시 재도전
7. 다음 스테이지 또는 홈으로 복귀

### 메타 루프 초안

- 스테이지 클리어
- 다음 스테이지 해금
- 누적 별 개수 또는 진행도 저장
- 밴드 단위 구조 임무 진행
- 구역별 구조 완료와 최종 코끼리 구출 서사 축적
- 이후 업데이트에서 스테이지 선택 화면과 보상 구조 추가

## 5. 스토리 캠페인 구조

- 배경은 `아프리카 밀림`
- 적대 세력은 `밀렵꾼 일당`
- 퍼즐 목표는 `잡힌 동물을 풀어 주는 행동`으로 해석한다.
- 10스테이지마다 하나의 정글 구역을 돌파하는 구조로 본다.
- 100스테이지 전체는 `거대한 코끼리 구출 작전`으로 수렴한다.
- 상세 스토리는 [story-campaign.md](/Users/shinehandmac/Documents/puzzle/docs/game/story-campaign.md)를 기준으로 본다.

## 6. 주요 시스템

### 보드 시스템

- 8x8 보드
- 인접 블록 스왑
- 3개 이상 매치
- 낙하, 리필, 자동 연쇄
- 데드 보드 발생 시 셔플

### 목표 시스템

- 동물 수집 목표
- 점수 목표
- 장애물 제거 목표
- 복합 목표

### 특수 블록 시스템

- 4매치: 줄 제거
- 5매치: 3x3 폭발
- 특수 블록 연쇄 발동 지원

### 장애물 시스템

- 현재 포함: 덤불
- 덤불은 매치된 칸과 인접 칸의 충격으로 제거
- 스테이지 중반 이후 목표와 난이도 장치로 사용

## 7. 화면 구조

### 현재 기준 화면

- 홈 화면
- 스테이지 시작 오버레이
- 플레이 화면
- 클리어 오버레이
- 실패 오버레이

### 이후 확장 화면

- 스테이지 선택
- 설정
- 튜토리얼 전용 팝업

## 8. 화면 우선순위

- 현재 가장 먼저 완성해야 할 화면은 `홈 -> 첫 스테이지 시작 -> 첫 플레이 -> 클리어/실패` 흐름이다.
- 이후에 스테이지 선택, 저장, 메타 화면을 붙인다.

## 9. 난이도 구조

- Easy: 수집 목표 위주, 등장 블록 가중치로 난이도 완화
- Normal: 복수 목표, 특수 블록 유도
- Hard: 점수 + 장애물 + 복합 목표
- 캠페인 규모: 총 100스테이지
- 운영 단위: 10스테이지씩 하나의 밴드로 관리
- 난이도 상승 방식: 새 메커닉 추가보다 `목표 조합`, `보드 모양`, `덤불 밀도`, `이동 수`, `점수 목표`를 점진적으로 올린다.
- 밴드별 스토리 상승 방식: `입구 구조 -> 야영지 침투 -> 대형 우리 돌파 -> 코끼리 구출`

## 10. 아트 방향 요약

- 블록은 `동물 얼굴 스티커` 느낌
- 배경은 `아프리카 밀림`이지만 보드 가독성을 해치지 않게 단순화
- 이펙트는 둥글고 귀여운 팝감
- 정보보다 장식이 튀지 않게 보드 가독성을 최우선

## 11. 개발에 바로 필요한 기준

- 홈 화면에서 가장 중요한 CTA는 `플레이`
- 첫 세션에서는 Stage 1로 즉시 진입할 수 있어야 한다.
- 스테이지 데이터는 하드코딩이 아니라 카탈로그 기반으로 관리한다.
- 새 스테이지는 `목표`, `이동 수`, `블록 풀`, `가중치`, `장애물`, `튜토리얼 문구`를 한 세트로 정의한다.
- 밴드 단위로 `구역 이름`, `스토리 목적`, `미니 피날레`, `구조 대상`을 같이 정의한다.

## 12. 연결 문서

- 상세 규칙: [game-design.md](/Users/shinehandmac/Documents/puzzle/docs/game/game-design.md)
- 스토리 캠페인: [story-campaign.md](/Users/shinehandmac/Documents/puzzle/docs/game/story-campaign.md)
- 첫 화면부터 첫 스테이지: [first-stage-flow.md](/Users/shinehandmac/Documents/puzzle/docs/game/first-stage-flow.md)
- 스테이지 제작 방식: [stage-production-guide.md](/Users/shinehandmac/Documents/puzzle/docs/game/stage-production-guide.md)
- 100스테이지 곡선: [level-progression-100.md](/Users/shinehandmac/Documents/puzzle/docs/game/level-progression-100.md)
- 100스테이지 명세: [stage-map-spec-001-100.md](/Users/shinehandmac/Documents/puzzle/docs/game/stage-map-spec-001-100.md)
- 100스테이지 아트 진행: [level-visual-progression.md](/Users/shinehandmac/Documents/puzzle/docs/art/level-visual-progression.md)
- 100스테이지 데이터 구조: [stage-data-architecture.md](/Users/shinehandmac/Documents/puzzle/docs/dev/stage-data-architecture.md)
- 백로그: [backlog.md](/Users/shinehandmac/Documents/puzzle/docs/game/backlog.md)
