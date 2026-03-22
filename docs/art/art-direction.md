# Art Direction

## 프로젝트 방향

- 게임명: Animal Pop Match
- 장르: 귀여운 동물 테마의 매치3 퍼즐
- 플랫폼: 모바일 landscape
- 우선순위: 가독성, 터치 명확성, 작은 화면에서도 정보 밀도 유지
- 감정 키워드: 귀여움, 말랑함, 산뜻함, 경쾌함, 시원한 팝감

## 전체 무드

- 밝고 깨끗한 캐주얼 애니메이션풍
- 디테일은 많지 않지만 표정과 색 대비가 확실한 스타일
- 사탕처럼 반짝이기보다 `동물 얼굴 스티커` 같은 친근한 질감
- 배경은 부드럽고, 퍼즐 보드는 선명하게 분리

## 메인 색상 체계

- 배경 하늘: `#DFF4FF`
- 보드 배경: `#7FD1FF` 또는 `#6CC3F4`
- 강조 노랑: `#FFD95A`
- 강조 핑크: `#FF8FB1`
- 강조 민트: `#7EE3C5`
- 텍스트 진한색: `#29445A`
- 성공/클리어 강조: `#FFE27A`

## 버튼/패널 스타일

- 버튼은 둥근 모서리, 두꺼운 외곽선, 살짝 볼륨감 있는 2단 톤
- 목표 패널은 카드형 박스 구조
- 패널 그림자는 짙지 않게, 아래쪽 짧은 드롭 섀도만 사용
- 작은 모바일 화면에서도 숫자와 아이콘이 먼저 보이게 구성

## 퍼즐 오브젝트 시각 언어

- 블록은 정사각형 타일 안에 동물 얼굴이 꽉 차게 들어간다.
- 몸 전체보다 `얼굴 중심`이 읽기 쉽기 때문에 MVP는 얼굴형 위주로 간다.
- 매치 시 표정 변화가 있어야 하므로 눈/입이 단순하고 크게 보여야 한다.

## 표현 규칙

- UI는 고대비 유지
- 아이콘은 단순한 실루엣 우선
- 동물 종류는 색상 하나에만 의존하지 않고 귀/얼굴형/입모양으로도 구분
- 배경은 정보를 방해하지 않도록 채도와 디테일을 낮춘다.
- 에셋이 없으면 색 블록과 텍스트 플레이스홀더로 대체

## 파일/에셋 원칙

- 기본 출력 형식: PNG
- 블록 기본 작업 크기: `256x256`
- HUD 아이콘 기본 작업 크기: `128x128`
- 보드용 결과물은 필요 시 아틀라스로 묶는다.

## 현재 연결된 배경/이펙트 방향

- 배경: 파스텔 하늘, 초원, 작은 꽃, 보드 중앙은 비워 가독성 유지
- 매치 이펙트: 노란 별 모양 버스트, 둥근 꽃잎형 실루엣, 과도하게 날카롭지 않은 팝감
- 장애물: 둥근 잎 실루엣의 스티커형 덤불
- 특수 블록 표시는 동물 얼굴을 가리지 않도록 작고 선명한 배지 형태 유지

## 연결 문서

- 씬별 아트 컨셉: [scene-art-concept.md](/Users/shinehandmac/Documents/puzzle/docs/art/scene-art-concept.md)
- 씬 레이아웃 보드: [scene-layout-boards.md](/Users/shinehandmac/Documents/puzzle/docs/art/scene-layout-boards.md)
- 블록 퍼스트 씬 설계: [block-first-scene-design.md](/Users/shinehandmac/Documents/puzzle/docs/art/block-first-scene-design.md)
- 동물 블록 명세: [animal-blocks.md](/Users/shinehandmac/Documents/puzzle/docs/art/animal-blocks.md)
- HUD/UI 명세: [ui-hud.md](/Users/shinehandmac/Documents/puzzle/docs/art/ui-hud.md)
