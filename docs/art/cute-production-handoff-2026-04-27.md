# Cute Production Handoff 2026-04-27

## What is already working

- `assets/animals/*_block_v2` is the strongest visual foundation.
- SVG HUD/meta pieces already establish a shippable rounded casual UI base.
- `assets/generated/redesign/*` proves mascot-face overlays can fit the block-first world.
- Current docs consistently want `sticker-like animal faces + quiet pastel UI`.

## Top visual gaps

### 1. Style split
- Best in project: clean sticker blocks.
- Weakest in project: blurry painterly concept/full-scene art.
- Rule: final production should follow the block style, not the blurry scene concepts.

### 2. Character appeal is not systematized
- Cute faces exist, but there is no locked `hero cast` sheet for blocks, mascots, goals, overlays, and stage cards.
- Chick and frog need stronger species-defining shapes at small sizes.
- Cat mouth/whisker details are at risk of disappearing below `48px`.

### 3. HUD is readable but not yet lovable
- Current HUD/frame work is functional, but still feels like a clean shell.
- Missing delight layer: paw/star accents, tiny mascot reactions, goal-complete sparkle states, button press squash.

### 4. Feedback moments are under-arted
- Matching, wrong move, blocker hit, near-goal, goal-clear, combo escalation, and stage-clear reward moments need a unified cute FX set.
- Special blocks still risk reading like symbols pasted over faces instead of character-first powerups.

### 5. Overlay emotion needs a stronger reward loop
- Success/fail faces exist as isolated concepts, but not as a reusable expression system.
- Clear, retry, and finale should feel like distinct emotional beats, not the same popup with different text.

## Production-ready cute pass

## A. Lock the cast first

Use one shared face language across blocks, home mascot, goals, stage cards, and overlays.

### Core cast
- **Rabbit**: brand lead, tutorial host, most friendly.
- **Cat**: playful/high-energy reward face.
- **Chick**: tiny cheerful support/readability accent.
- **Bear**: soft comfort/failure recovery face.
- **Frog**: quirky silhouette anchor.

### Face rules
- Thick clean outline.
- Big eyes with one consistent highlight shape.
- Blush/cheek language shared across cast.
- Mouth strokes thick enough to survive `32px`.
- Species identity must come from silhouette first, color second.
- Face fill should occupy about `72%~78%` of the tile interior.

### Small-size readability fixes
- **Chick**: enlarge beak by `10%~15%`, strengthen orange contrast, make top tuft chunkier.
- **Frog**: push eye bumps outward/upward; make mouth wider.
- **Cat**: thicken whisker dots/mouth lines; slightly sharpen ear silhouette.

## B. Make HUD charming without hurting clarity

### HUD tone
- Keep the existing rounded card system.
- Add only small charm accents: paw cutouts, stitched stars, tiny leaf confetti, soft shine.
- Numbers stay highest-contrast element.

### HUD charm kit
- `goal_chip_face_reaction` variants: neutral / happy / complete.
- `moves_badge_low` state: warmer color + gentle wobble cue.
- `pause_button_pressed` with visible squash/downshadow.
- `goal_panel_complete` sparkle ring.
- Tiny mascot helper sticker for tutorial-only panels.

## C. Treat feedback as character acting

### Key gameplay moments
- **Select**: clean ring/glow that does not wash out the face.
- **Valid swap**: micro squash/stretch.
- **Invalid swap**: quick sideways bump + tiny dizzy/star puff.
- **Match pop**: face smiles/blinks, then burst of star/heart/leaf shapes.
- **Combo escalation**: badge words plus brighter confetti color ramp.
- **Blocker hit**: leaf burst with a cute chipped-sticker look, not sharp debris.

### Special block rule
- Row/col/bomb identity should sit in a corner badge or halo.
- Never cover more than `20%~25%` of the face.
- Character face remains the primary read.

## D. Overlays should feel like collectible sticker rewards

### Success overlay
- Hero face large and joyful.
- 1 big emotional read + stars + one bright CTA.
- Use cat or rabbit first.

### Failure overlay
- Soft sympathy, never gloomy.
- Bear is best default.
- Keep palette light; retry button must feel safe and immediate.

### Finale overlay
- Feels special via crown/ribbon/star shower, not darker rendering.
- Reuse same cast and line language.

## Asset priority order

### P1 — Character lock pack
Ship first because it aligns every other surface.
- `docs/art/species-model-sheet` equivalent reference
- Final block faces for 5 animals
- Matching goal-chip face crops
- Home mascot hero pose/crop set
- Overlay success/fail/finale face set

### P2 — Feedback/FX pack
Most value for game feel after character lock.
- selection ring
- invalid move puff
- blocker hit leaves
- match burst
- combo badges
- near-goal / goal-complete pulses

### P3 — HUD charm states
- moves low-state badge
- goal complete card state
- pressed/hover button polish
- tutorial ribbon/helper sticker

### P4 — Meta progression charm
- stage card state facelift
- clearer star reward set
- mascot cameo on current/finale cards

### P5 — Background cleanup
- simplify/flatten any blurry painterly scenes
- preserve only quiet pastel support shapes behind board/UI

## Concrete specs

## File and format
- Characters/overlays: `PNG`, transparent, master at `1024x1024`.
- Blocks: master at `256x256`, must survive export tests at `32/48/64px`.
- HUD/FX frames/badges: `SVG` when shape-based, `PNG` only when expression painting matters.

## Acceptance checks
- Species readable in `0.5s` at `48px`.
- Face still legible with selected, powered, and matched states applied.
- Background never becomes the highest-contrast element.
- Success/fail/finale silhouettes/emotions distinguishable without text.

## Prompt starters

### 1. Final mascot/block face sheet
```text
cute mobile match-3 animal face sprite sheet, sticker-like 2D game art, rabbit bear cat chick frog, front-facing faces only, thick clean outline, soft pastel palette, bold readable silhouettes, large eyes, tiny blush cheeks, simple mouth shapes, highly readable at small mobile sizes, transparent background, polished casual game asset, vector-like clarity, no body, no text, no painterly blur
```

### 2. Success overlay hero face
```text
cute mobile puzzle game victory mascot, rabbit or cat face only, joyful smile, sparkling eyes, sticker-like 2D illustration, thick clean outline, rounded cheeks, star confetti accents, pastel yellow pink blue palette, transparent background, readable at small size, polished casual game reward art, no body, no text, no painterly shading
```

### 3. Failure overlay hero face
```text
cute mobile puzzle game retry mascot, bear face only, slightly worried but lovable expression, gentle eyebrows, soft brown and cream palette, sticker-like 2D illustration, thick clean outline, rounded silhouette, transparent background, encouraging mood, readable at small size, no body, no text, no dark drama
```

### 4. FX sheet
```text
cute casual mobile puzzle FX sheet, star burst, heart pop, leaf burst, tiny dizzy puff, soft combo sparkle, rounded sticker-like effects, bright pastel colors, clean vector-like edges, transparent background, readable on top of animal tiles, no sharp shards, no realistic particles, no text
```

## Tiny wiring note for dev
- When new face states arrive, prefer swapping whole-face sprites for `success/fail/goal-complete` moments instead of stacking heavy glows over the same neutral face.

## Terse summary
- Keep the clean block style, discard blurry painterly direction, lock one shared mascot face system, then spend the next art pass on feedback and HUD delight.

## Single most valuable art-production task
- Create and lock the final **5-animal character model sheet + small-size-tested face set** for blocks, goals, mascots, and overlays.
