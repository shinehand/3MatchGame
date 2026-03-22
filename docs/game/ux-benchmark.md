# Match-3 UX Benchmark

## 목적

`Animal Pop Match`를 단순 보드 데모가 아니라 실제 게임처럼 느끼게 만들기 위해 주요 3매치 게임의 UX 패턴을 정리한다.

## 벤치마크 대상

- `Candy Crush Saga`
- `Royal Match`
- `Toon Blast`

## 공통 패턴

- 레벨 시작 전에 `목표`, `이동 수`, `핵심 장애물/규칙`을 먼저 보여준다.
- 플레이 중 가장 눈에 띄는 값은 `남은 이동 수`와 `현재 목표 진행도`다.
- 목표는 긴 문장 대신 `아이콘 + 숫자` 형태로 빠르게 읽히게 만든다.
- 스와이프 입력이 기본이며, 잘못된 입력은 약한 반동으로 즉시 피드백한다.
- 큰 매치와 연쇄는 강한 보상 연출과 기대감을 만든다.
- 레벨 실패와 성공은 보드 위에서 바로 닫히는 팝업으로 연결된다.

## Candy Crush Saga에서 참고할 점

- 목표 전달이 빠르다.
- 이동 수와 목표 상태가 보드 밖에서도 바로 읽힌다.
- 특수 조각과 장애물로 레벨별 개성이 강하다.
- 데일리 보상, 이벤트, 리더보드처럼 `메타 레이어`가 두텁다.

## Royal Match에서 참고할 점

- HUD가 크고 단순해 한눈에 읽힌다.
- 목표 아이콘과 숫자가 강하게 분리되어 있다.
- 레벨 실패/성공 후 재시도 흐름이 빠르다.
- 장애물과 보상 상자가 많아 한 턴의 기대치가 높다.

## Toon Blast에서 참고할 점

- 입력과 반응이 매우 빠르다.
- UI 정보량을 줄이고 핵심 목표만 강조한다.
- 스테이지 목표와 보상 구조가 직관적이다.
- 한 턴의 액션이 짧고 탄성이 강해 손맛이 좋다.

## 현재 프로젝트와의 차이

- 이전 상태는 `보드 규칙`은 있었지만 `레벨 UX`가 약했다.
- 목표가 텍스트 위주라 빠르게 읽히지 않았다.
- 난이도 설계와 보드 출현 규칙이 분리되지 않았다.
- 시작/클리어/실패 흐름이 게임 UI보다 개발 데모에 가까웠다.

## 이번 반영 방향

- `StageCatalog`로 난이도와 레벨 데이터를 분리한다.
- 목표를 `Goal Chip` 형태로 바꿔 빠르게 읽히게 한다.
- Stage 시작/성공/실패를 오버레이로 고정한다.
- Stage 1은 `Easy`, Stage 2는 `Normal`, Stage 3은 `Hard` 구조로 명시한다.
- 쉬운 스테이지는 출현 블록 수와 가중치로 난이도를 조정한다.

## 다음 벤치마크 반영 우선순위

1. `특수 블록` 추가
2. `장애물 1종` 추가
3. `레벨 선택 화면` 추가
4. `클리어 보상/실패 재도전` 연출 강화
5. `사운드와 햅틱` 추가

## 참고 소스

- Candy Crush Saga Google Play: https://play.google.com/store/apps/details?id=com.king.candycrushsaga
- Royal Match Google Play: https://play.google.com/store/apps/details?id=com.dreamgames.royalmatch
- Toon Blast Google Play: https://play.google.com/store/apps/details?id=net.peakgames.toonblast
