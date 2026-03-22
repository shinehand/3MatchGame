# Image Generation Strategy

## 목적

- `Animal Pop Match`의 아트 고도화를 위해 현재 사용할 수 있는 이미지 생성 방식을 비교하고, 실제 제작 파이프라인을 고정한다.

## 현재 확인된 방식

### 1. Gemini

- 현재 저장소에서는 `컨셉 탐색`과 `프롬프트 정리` 용도로 이미 사용 중이다.
- 장점
- 빠른 스타일 탐색
- 카피와 컨셉 키워드 정리에 강함
- 현재 계정 기준 웹 이미지 생성 사용 가능 기록 존재
- 단점
- 로컬 재현성과 반복 생산성이 약하다.
- 실제 게임 자산 패키지 생산 파이프라인으로 바로 붙이기 어렵다.
- 판단
- `컨셉 탐색용 1차 도구`로 유지

### 2. Local Stable Diffusion

- 현재 프로젝트에 이미 연결돼 있고 실제 자산 생성 기록이 남아 있다.
- 장점
- 현재 환경에서 바로 사용 가능
- 추가 과금 없이 반복 생성 가능
- seed, 모델, 프롬프트를 고정해 자산 일관성 관리 가능
- 동물 블록, 배경, 이펙트처럼 반복 제작이 많은 작업에 유리
- 단점
- UI 프레임처럼 정확한 구조물은 후처리가 필요하다.
- 모델에 따라 품질 편차가 있다.
- 판단
- `인게임 자산 기본 생산 도구`로 채택

### 3. OpenAI Image API

- 장점
- 텍스트와 이미지 입력을 함께 다루는 편집 워크플로가 강하다.
- 한 장의 고품질 키아트, 수정 작업, 정교한 편집에 유리하다.
- 공식 문서상 생성과 편집 엔드포인트가 모두 제공된다.
- 단점
- API 키와 비용이 필요하다.
- 현재 프로젝트 기본 파이프라인으로는 아직 연결돼 있지 않다.
- 판단
- `어려운 편집`, `마케팅 키아트`, `로컬 SD 실패 케이스 보완용` 보조 도구로 적합

### 4. FLUX / ComfyUI 계열

- 장점
- 스타일 고정, 노드형 워크플로, 반복 자동화에 유리하다.
- 향후 자산 양이 커질 때 확장성이 있다.
- 단점
- 현재 저장소에는 바로 쓰는 파이프라인이 없다.
- 도입 비용과 워크플로 설계 비용이 있다.
- 판단
- `후속 확장 후보`

### 5. Adobe Firefly / 디자인툴 편집형 방식

- 장점
- 배경 제거, 부분 수정, 후처리, 디자이너 협업에 유리
- 단점
- 게임 자산 대량 생성의 기본 엔진으로는 적합하지 않다.
- 판단
- `후처리 보조 도구`

## 프로젝트 기준 평가

### 가장 중요한 평가 축

1. 동물 얼굴 블록 스타일 일관성
2. 작은 화면 가독성
3. 반복 생산 비용
4. 수정과 재생산 속도
5. 개발 연결 용이성

### 결론

- `최적 기본 방식`
- `Gemini로 스타일 탐색/프롬프트 정리 -> Local Stable Diffusion으로 실제 자산 생성 -> SVG 또는 수동 후처리로 UI/배지 정리`

- `보조 방식`
- OpenAI Image API는 로컬 SD로 해결이 안 되는 고난도 수정, 키아트, 마케팅 비주얼에 한정해 사용

- `지금 도입 보류`
- FLUX/ComfyUI는 자산 볼륨이 더 커지거나 ControlNet식 고정 레이아웃이 꼭 필요해질 때 검토

## 자산별 권장 생성 방식

### 동물 블록

- 기본: Local SD
- 후처리: 리사이즈, 대비 조정, 필요 시 SVG 보조선 제작

### 배경

- 기본: Local SD
- 규칙: 보드 중앙부 비우기, 밴드 단위 변주

### 이펙트/장애물

- 기본: Local SD
- 규칙: 작은 크기에서 식별 가능한 스티커형

### 버튼/카드/팝업 프레임

- 기본: SVG/벡터 수동 제작
- 이유: UI 구조물은 정밀도와 반복성이 중요함

### 홈 마스코트와 결과 오버레이 얼굴

- 기본: Local SD 초안 + 수동 정리
- 보조: 필요 시 OpenAI Image API로 표정 변형/클린업

## Art Team 실행 규칙

1. Gemini는 아이디어 확정 전까지만 사용
2. 실제 게임 자산은 Local SD를 기본으로 생성
3. UI 프레임은 이미지 생성보다 벡터 제작을 우선
4. 결과물은 패키지 단위로 개발에 전달
5. 하나의 패키지마다 프롬프트, 모델, 해상도, 후처리 규칙을 같이 기록

## 외부 공식 참고

- OpenAI GPT Image 1 docs: [developers.openai.com/api/docs/models/gpt-image-1](https://developers.openai.com/api/docs/models/gpt-image-1)
- Google Gemini image generation docs: [ai.google.dev/gemini-api/docs/image-generation](https://ai.google.dev/gemini-api/docs/image-generation)
- Stability AI API overview: [platform.stability.ai](https://platform.stability.ai/)
- Black Forest Labs docs: [docs.bfl.ai](https://docs.bfl.ai/)
