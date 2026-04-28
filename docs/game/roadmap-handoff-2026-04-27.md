# 3MatchGame Roadmap Handoff — 2026-04-27

## Current snapshot

### Grounded status
- `./scripts/validate_gameplay.sh` **passed** on 2026-04-27.
- Core loop is healthy: swipe/tap swap, match resolution, cascades, refill, blockers, special pieces, score, goals, fail/clear overlays.
- Meta shell is no longer prototype-only: home, stage line, 100-stage JSON catalog, save/unlock/stars, soft tutorials, pause, sound/haptics settings all exist.
- Art integration is materially ahead of the older March audits: themed stage cards, route nodes, ribbons, mascots, combo art, goal chips, backgrounds, overlays are already wired.

### What feels strongest now
1. **Playable campaign spine exists** (`main -> stage_select -> gameplay -> result -> next stage`).
2. **Data-driven production is ready** (`stage_catalog.gd`, validators, 100 stages, band rules).
3. **Alpha gate foundations exist** (headless validation, scene-load smoke, manual QA checklist).

### Biggest remaining gaps
1. **Moment-to-moment payoff still plateaus too early.** Core logic works, but big matches and close-call turns still do not escalate into truly memorable emotional beats.
2. **Character fantasy is present in assets but not fully expressed in play feedback.** The game reads cute, but the animals do not yet feel like they are being actively rescued on each success beat.
3. **Alpha readiness is not locked until device/manual gates and release packaging are formalized.** Validation exists, but release confidence still depends on human follow-through.

---

## Top 3 next tasks

## 1) Gameplay Juice Pass: make every good move feel rewarding
**Why now**
- Highest leverage on retention and perceived quality.
- The core loop is already stable enough to polish rather than rebuild.

**Scope**
- Add stronger payoff for: 4/5 matches, combo chains, blocker clears, goal completion, final 5 moves, stage clear star reveal.
- Replace “state update only” moments with short readable celebration beats.
- Improve failure readability so the player knows what almost worked.

**Acceptance criteria**
- 4-match, 5-match, combo x2+, blocker clear, and goal complete each have a distinct visual + audio identity.
- Last-5-moves state adds clear tension without obscuring the board.
- Clear overlay includes a staged star-pop or equivalent reward beat.
- Failure overlay clearly surfaces the missed goal and one actionable retry hint.
- No regression in `./scripts/validate_gameplay.sh`.

**Dependencies**
- Existing `feedback.gd` and `gameplay.gd` hooks.
- Art support for any missing micro-assets only if current SVG/PNG set is insufficient.

**Suggested files**
- `scripts/gameplay.gd`
- `scripts/feedback.gd`
- `scripts/block_tile.gd`
- `scenes/gameplay.tscn`

---

## 2) Character Rescue Presentation Pass: make the animals the stars
**Why now**
- The repo already has mascots, overlays, badges, and themed UI; the next step is to connect that art to gameplay emotion.
- This is the clearest path from “competent prototype” to “cute game people remember.”

**Scope**
- Add lightweight rescue reactions when a goal animal is completed.
- Refine tile-state readability so selection/special/blocker overlays never fight the animal face.
- Reduce text-heaviness in result and stage surfaces where a mascot/status graphic can carry meaning faster.

**Acceptance criteria**
- Completing an animal goal triggers a readable rescue reaction (pop, jump, badge burst, or mascot response).
- Selected/special/blocker tiles remain readable at a glance on both portrait and landscape layouts.
- Home, stage select, and result overlays present a consistent mascot-driven visual language.
- Representative screenshots from home, stage select, active gameplay, clear, and fail look like one coherent product family.

**Dependencies**
- Task 1’s event hooks are helpful but not strictly required.
- May require a small art packet for rescue reaction frames/badges if current assets are insufficient.

**Suggested files**
- `scripts/block_tile.gd`
- `scripts/goal_chip.gd`
- `scripts/gameplay.gd`
- `scenes/gameplay.tscn`
- `scenes/main.tscn`
- `scenes/stage_select.tscn`

---

## 3) Alpha Lock Pass: formalize release confidence
**Why now**
- Once fun/readability improve, the project needs a hard “shippable alpha” gate instead of an informal checklist.
- This is the task that turns progress into a trustworthy build candidate.

**Scope**
- Finish release keystore/export preset wiring.
- Convert representative manual QA into a reusable alpha checklist with results capture.
- Run and record device verification for Stage 1, 11, 25, 50, 75, 100.

**Acceptance criteria**
- Release keystore is separated from debug and documented.
- Android export preset is reproducible from repo instructions.
- `./scripts/validate_gameplay.sh` passes before every alpha candidate.
- Manual QA results are recorded for Stage 1, 11, 25, 50, 75, 100, including sound/haptics/orientation checks.
- Any alpha blocker is tracked in one doc instead of living only in chat memory.

**Dependencies**
- No major code dependency, but Tasks 1-2 should land first so QA is evaluating the intended experience.
- Device access for Android confirmation.

**Suggested files**
- `export_presets.cfg`
- `docs/pm/productization-alpha-plan-2026-03-19.md`
- `docs/qa/qa-gate-2026-03-19.md`
- `README.md`

---

## Recommendation
Start with **Task 1: Gameplay Juice Pass**.

It gives the biggest immediate jump in perceived fun, unlocks clearer art direction for Task 2, and makes the later alpha QA pass worth running against a stronger build.
