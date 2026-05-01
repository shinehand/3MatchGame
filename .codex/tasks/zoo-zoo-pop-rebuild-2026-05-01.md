# Zoo-Zoo Pop 게임화 재기획 태스크

## 배경

현재 구현은 매치3 규칙과 데이터 구조는 작동하지만, 화면이 게임 UI가 아니라 개발용 폼처럼 보인다. 사용자는 GUI, 이펙트, 애니메이션, 화면 플로우 전체가 프로토타입 수준에도 미치지 못한다고 판단했다. 따라서 단순 색상 교체가 아니라 `게임 화면 설계 -> UI 아트 -> 애니/VFX -> 개발 반영 -> QA` 순서로 재정렬한다.

## 팀 편성

### Planning Team

- 기획 1: 전체 플로우/화면 구조
- 기획 2: 게임 피드백/재미/보상 루프
- 기획 3: 레벨/경제/메타/QA 기준

### Art Team

- UI 아트 담당: 화면별 레이아웃, 버튼, HUD, 팝업, 색/타이포/아이콘 규칙
- 애니/VFX 담당: 레이어 구조, 블록 애니메이션, 특수 블록, 콤보, 결과 연출

### Development Team

- 개발 담당: Godot 씬/스크립트 구조 정리, UI/VFX 적용, 검증 자동화

### 추가 보충 필요 인원

- Sound/Haptic 담당: 효과음, BGM, 햅틱 패턴의 상용 퀄리티 조정
- QA 담당: 대표 단말/해상도/스테이지 수동 검수

## 1차 산출물

- [마스터 플로우/화면 기획서](/Users/shinehandmac/Github/3MatchGame/docs/game/zoo-zoo-pop-master-flow-screen-spec.md)
- [UI 아트 스펙](/Users/shinehandmac/Github/3MatchGame/docs/art/zoo-zoo-pop-ui-art-spec.md)
- [애니메이션/VFX 스펙](/Users/shinehandmac/Github/3MatchGame/docs/art/zoo-zoo-pop-animation-vfx-spec.md)
- [개발 적용 로드맵](/Users/shinehandmac/Github/3MatchGame/docs/dev/zoo-zoo-pop-rebuild-implementation-plan.md)

## 1차 개발 목표

- 홈 화면을 개발용 카드 묶음이 아니라 게임 타이틀 화면으로 재구성한다.
- 게임플레이에 VFX 전용 상위 레이어를 두고, 매치/특수/콤보 효과를 보드 위에 재생한다.
- 결과 화면은 텍스트 보고서가 아니라 별, 보상, 다음 행동이 중심인 게임 결과 팝업으로 재구성한다.
- Stage Popup과 Pre-Booster를 도입할 수 있도록 화면/코드 구조를 준비한다.

## 완료 기준

- `zsh scripts/validate_gameplay.sh` 통과
- 홈, 스테이지, 게임, 결과 화면의 캡처가 문서 스펙과 비교 가능해야 한다.
- 매치/특수/콤보 효과가 보드 타일 내부에 갇히지 않고 상위 VFX 레이어에서 재생되어야 한다.
- 첫 화면에서 3초 이내에 장르, 브랜드, 목표 행동이 읽혀야 한다.
