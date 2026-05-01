# GPT Image Production Plan 2026-04-30

## 목적

이 문서는 `3MatchGame`의 현재 아트 자산을 OpenAI GPT Image 계열 모델로 고도화하기 위한 실행 기준이다.
목표는 새 그림을 무작정 많이 뽑는 것이 아니라, 현재 게임의 `sticker-like animal faces + quiet pastel UI` 방향을 잠그고 작은 모바일 화면에서 읽히는 자산을 생산하는 것이다.

## 공식 문서 확인 결과

- OpenAI Image API는 텍스트 프롬프트 기반 생성과 기존 이미지 편집을 지원한다.
- 최신 문서 기준 GPT Image 계열의 최신 모델은 `gpt-image-2`이며, 이미지 생성과 편집을 지원한다.
- 단발 생성/편집은 Image API가 적합하고, 반복 대화형 편집 흐름은 Responses API가 적합하다.
- 품질, 크기, 포맷, 압축, 배경 투명 여부를 조정할 수 있다. 투명 배경은 모델 지원 여부에 따라 달라진다.
- GPT Image 모델 사용에는 조직 인증이 필요할 수 있다.

참조:
- OpenAI Image generation guide: https://developers.openai.com/api/docs/guides/image-generation
- OpenAI Images API reference: https://developers.openai.com/api/reference/resources/images
- GPT Image 2 model page: https://developers.openai.com/api/docs/models/gpt-image-2

## 현재 프로젝트 자산 판단

현재 저장소에는 아래 자산 계층이 이미 있다.

- 동물 블록: `assets/animals/*_block.png`, `assets/animals/*_block_v2.png`
- 홈/오버레이 마스코트: `assets/generated/redesign/*.png`
- 이펙트: `assets/effects/*`, `assets/ui/effects/*`
- HUD/메타 UI: `assets/ui/hud/*`, `assets/ui/meta/*`, `assets/ui/theme/*`
- 밴드 배경: `assets/backgrounds/bands/*`

가장 효과가 큰 GPT 이미지 적용 지점은 아래 순서다.

1. Character lock pack
   - 5종 동물 얼굴을 같은 화풍으로 재정렬한다.
   - 블록, 목표 칩, 홈 마스코트, 성공/실패 오버레이가 같은 캐릭터 체계로 보이게 한다.
2. Feedback FX pack
   - 매치 팝, 목표 완료, 덤불 제거, 콤보, 실패 리트라이 감정 이펙트를 만든다.
3. Overlay emotion pack
   - 성공, 실패, 피날레 오버레이의 표정과 보상감을 강화한다.
4. HUD charm pack
   - 목표 완료 카드, 낮은 이동 수 배지, 튜토리얼 도움 스티커를 추가한다.
5. Background cleanup
   - 배경은 보드보다 튀지 않는 보조 역할로 유지한다.

## 생성 원칙

- 투명 PNG를 우선한다.
- 텍스트는 이미지에 넣지 않는다. 모든 문구는 Godot UI 텍스트로 관리한다.
- 동물 얼굴은 32px, 48px, 64px 축소에서도 종이 구분되어야 한다.
- 특수 블록 배지는 얼굴의 20~25% 이상을 가리지 않는다.
- 기존의 흐릿한 풀씬 컨셉보다 깨끗한 스티커형 블록 스타일을 기준으로 한다.
- 생성 결과는 바로 원본 자산에 덮어쓰지 않고 `assets/generated/gpt/` 또는 `output/imagegen/`에서 검수한다.

## 준비 조건

현재 로컬 셸에는 `OPENAI_API_KEY`가 설정되어 있지 않다.
실제 생성 전에는 아래가 필요하다.

```zsh
export OPENAI_API_KEY="..."
```

API 키는 채팅에 붙여넣지 말고 로컬 환경변수로만 설정한다.

## 권장 실행 위치

중간 산출:

```text
output/imagegen/gpt-cute-pass-2026-04-30/
```

검수 후 프로젝트 편입:

```text
assets/generated/gpt/
```

최종 교체 후보:

```text
assets/animals/
assets/effects/
assets/generated/redesign/
assets/ui/effects/
```

## 1차 배치 프롬프트

아래 프롬프트는 API 키 준비 후 `imagegen` CLI의 `generate-batch`에 넣을 1차 후보이다.

```jsonl
{"prompt":"Create a clean sprite-sheet style reference image with five front-facing cute animal faces for a mobile match-3 game: rabbit, bear, cat, chick, frog. Each face should be sticker-like, centered, isolated, with thick clean outlines, large readable eyes, shared cheek/blush language, simple mouth shapes, and strong species silhouettes. Transparent background. No text, no watermark, no bodies, no painterly blur.","use_case":"stylized-concept","style":"polished casual mobile game asset, vector-like sticker illustration","composition":"five separate face icons arranged on an invisible grid with generous spacing","palette":"soft pastel colors with high small-size readability","constraints":"transparent background; no text; no watermark; faces must remain readable at 32px and 48px","negative":"realistic fur, painterly blur, thin facial lines, clutter, shadows that reduce transparency","size":"1024x1024","quality":"high","background":"transparent","output_format":"png","n":2}
{"prompt":"Create a cute casual mobile puzzle FX sheet: match pop burst, goal-complete sparkle ring, blocker-hit leaf burst, invalid-move dizzy puff, combo celebration sparkle. Rounded sticker-like effects with clean vector-like edges. Transparent background. No text, no watermark.","use_case":"stylized-concept","style":"polished 2D casual game FX, bright but restrained","composition":"five separate effect clusters arranged on an invisible grid with generous spacing","palette":"pastel yellow, mint, coral, sky blue, warm leaf green","constraints":"transparent background; no text; no watermark; effects must not obscure animal faces when overlaid","negative":"sharp shards, realistic particles, heavy glow, smoky blur, clutter","size":"1024x1024","quality":"high","background":"transparent","output_format":"png","n":2}
{"prompt":"Create three large mascot face assets for a cute mobile match-3 result overlay: joyful rabbit or cat victory face, gentle bear retry face, special finale celebration face with crown and star shower. Sticker-like front-facing faces only, thick clean outline, expressive eyes, transparent background. No text, no watermark.","use_case":"stylized-concept","style":"polished casual game reward art, vector-like sticker illustration","composition":"three separate mascot faces arranged on an invisible grid with room for cropping","palette":"soft pastel UI-friendly colors, cheerful and readable","constraints":"transparent background; no text; no watermark; each emotion must be recognizable without text","negative":"dark drama, painterly blur, full body, cluttered background, tiny facial details","size":"1024x1024","quality":"high","background":"transparent","output_format":"png","n":2}
{"prompt":"Create a cute HUD charm asset sheet for a mobile match-3 game: low-moves warm badge accent, goal-complete sparkle badge, tiny tutorial helper sticker, pressed button shine, stage-clear star reward pop. Clean rounded sticker style, transparent background. No text, no watermark.","use_case":"stylized-concept","style":"polished mobile UI game asset sheet, vector-like edges","composition":"five separate UI charm assets arranged on an invisible grid","palette":"pastel yellow, coral, mint, cream, soft blue with readable contrast","constraints":"transparent background; no text; no watermark; assets must work on top of existing Godot UI cards","negative":"large text, heavy gradients, harsh bloom, realistic metal, clutter","size":"1024x1024","quality":"high","background":"transparent","output_format":"png","n":2}
```

## 실행 예시

API 키가 준비되면 아래 방식으로 실행한다.

```zsh
mkdir -p tmp/imagegen output/imagegen/gpt-cute-pass-2026-04-30

python3 /Users/shinehandmac/.codex/skills/imagegen/scripts/image_gen.py generate-batch \
  --model gpt-image-2 \
  --input tmp/imagegen/gpt_cute_pass_2026_04_30.jsonl \
  --out-dir output/imagegen/gpt-cute-pass-2026-04-30 \
  --concurrency 2 \
  --force
```

비용과 품질을 먼저 가볍게 확인하려면 `quality`를 `low`로 낮춘 별도 배치를 먼저 돌린다.

## 검수 기준

1. 32px, 48px, 64px 축소 미리보기에서 종 구분이 되는가
2. 투명 배경이 올바르게 유지되는가
3. 현재 UI 팔레트와 충돌하지 않는가
4. 선택 glow, 특수 배지, 덤불 오버레이와 겹쳐도 얼굴이 살아 있는가
5. 성공, 실패, 피날레 표정이 텍스트 없이 구분되는가
6. Godot에서 import 후 `zsh scripts/validate_gameplay.sh`가 통과하는가

## 통합 순서

1. 생성 결과를 `output/imagegen/`에 둔다.
2. 좋은 후보만 `assets/generated/gpt/`로 복사한다.
3. 이미지 시트라면 개별 PNG로 잘라낸다.
4. Godot import를 확인한다.
5. 우선 오버레이와 FX부터 새 자산을 연결한다.
6. 블록 얼굴 교체는 마지막에 진행한다. 블록은 게임 가독성 영향이 가장 크므로 검수 후 교체한다.
7. `zsh scripts/validate_gameplay.sh`를 실행한다.

## 결론

GPT 이미지 생성으로 고도화할 수 있다. 다만 이 프로젝트에서는 배경보다 캐릭터 얼굴, 목표 완료 리액션, 클리어/실패 오버레이, 매치 이펙트에 먼저 쓰는 편이 효과가 가장 크다.

## 2026-04-30 실행 메모

- `gpt-image-2` 12종 1차 배치 프롬프트는 `tmp/gpt_image_asset_pass_2026_04_30.jsonl`에 준비했다.
- 실제 API 호출은 `Billing hard limit has been reached` 응답으로 차단되었다.
- 결제 한도 조정 후 같은 JSONL 배치를 재실행하면 된다.
- 임시 대체 작업으로 기존 `*_block_v2` 자산을 기반으로 선명한 홈/결과 오버레이/FX PNG를 `assets/generated/polish/`에 생성해 연결했다.
- ChatGPT 웹 앱에서 동물 얼굴 스프라이트 시트를 생성하고 원본을 `assets/generated/chatgpt/animal_face_sheet_chatgpt.png`로 보관했다.
- 생성 시트를 5개 256px 타일로 분리해 `assets/generated/chatgpt/*_block_chatgpt.png`로 저장했고, 게임 보드와 홈 화면의 동물 블록 리소스에 연결했다.
- 이어서 GUI/게임 이펙트 시트를 `assets/generated/chatgpt/effects_sheet_chatgpt.png`로 보관하고, `fx_match_burst_chatgpt.png`, `fx_combo_pop_chatgpt.png`, `fx_combo_great_chatgpt.png`를 실제 보드 매치/콤보 연출에 연결했다.
