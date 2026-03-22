# Game Brief

## 프로젝트

- 이름: Animal Pop Match
- 장르: 모바일 매치3 퍼즐 게임
- 엔진: Godot 4
- 플랫폼: Android 우선, landscape 고정
- 레퍼런스: `Candy Crush Saga` 계열의 직관적인 스왑형 퍼즐

## 게임 한 줄 설명

- 귀여운 동물 블록을 스와이프해 3개 이상 매치하고, 스테이지 목표를 달성하는 캐주얼 퍼즐 게임

## 핵심 가설

- 1분 안팎의 짧은 플레이에서도 성취감이 느껴지는 스테이지 구조를 만든다.
- 사탕 대신 동물 얼굴 블록을 사용해 더 강한 캐릭터성과 수집 욕구를 만든다.
- 스와이프 조작, 연쇄 매치, 귀여운 리액션으로 반복 플레이 동기를 만든다.

## 코어 방향

- 기본 규칙: 인접한 블록을 스왑해 같은 종류 3개 이상 매치
- 감정 키워드: 귀여움, 경쾌함, 만족감, 연쇄 폭발의 쾌감
- 플레이 템포: 빠르게 이해되고, 한 수가 즉시 시각 피드백으로 이어져야 함
- 화면 구성: landscape 기준으로 퍼즐 보드와 목표/HUD가 동시에 잘 보여야 함

## 핵심 차별점

- 블록을 단순 색상이 아니라 `동물 캐릭터`로 표현
- 매치 시 동물별 표정 변화와 간단한 반응 애니메이션 제공
- 스테이지 클리어 보상 화면에서도 동물 캐릭터를 적극 사용

## MVP 범위

- 동물 블록 5종
- 기본 매치3 스왑 규칙
- 연쇄 매치 처리
- 목표형 스테이지 3개
- 이동 수 제한
- 승리/패배 화면
- 기본 HUD

## 당장 필요한 결정

- 코어 퍼즐 메커닉
- 첫 3개 스테이지의 난이도 곡선
- HUD에 반드시 보여야 하는 정보
- 동물 5종의 최종 콘셉트
- 특수 블록의 MVP 포함 여부

## 연결 문서

- 전체 개요: [game-plan-overview.md](/Users/shinehandmac/Documents/puzzle/docs/game/game-plan-overview.md)
- 상세 규칙: [game-design.md](/Users/shinehandmac/Documents/puzzle/docs/game/game-design.md)
- 첫 화면부터 첫 스테이지: [first-stage-flow.md](/Users/shinehandmac/Documents/puzzle/docs/game/first-stage-flow.md)
- 스테이지 제작 방식: [stage-production-guide.md](/Users/shinehandmac/Documents/puzzle/docs/game/stage-production-guide.md)
