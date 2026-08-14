# Plunder Ending Cutscene — A Darker Coda

**Status:** approved, pending implementation plan.

## Goal

Eleventh content-expansion installment: a new, dark/atmospheric cutscene playing after Chapter 5 (the plunder ending) reaches any of its 4 terminal nodes, reusing the Prologue cold-open's cutscene engine rather than duplicating it — this is the "used twice, worth generalizing" point, so the reusable player is genuinely extracted, not copy-pasted.

**Real finding before designing content:** Chapter 5 (12 nodes) is deliberately unlike every other chapter — zero coin/reputation effects anywhere, no NPCs, pure internal reflection, a short poetic coda to the plunder branch. Padding it with more dialogue nodes would dilute the effect its own brevity creates. **Confirmed with the user: the ending cutscene itself is this installment's substantial new content — Chapter 5's existing dialogue content is not touched at all.**

**Confirmed with the user, tone:** tonal/atmospheric only — no new plot events, no confirmed outcome for Farrukh, consistent with Chapter 5's own established "character arc, not plot resolution" design (and this game's broader precedent of leaving the debt/mystery deliberately unresolved). The cutscene mirrors whichever of the 4 terminal variants was reached only in the sense of shared mood — it does not branch into 4 separate cutscenes; one shared, generic sequence works for all of them, since all 4 endings share the same underlying moral ambiguity in different flavors.

## Architecture: generalizing the cutscene engine

The Prologue's `PrologueCutscene.gd` hardcoded its content path and next-scene path as `const`s. This pass extracts the reusable logic into a new, generic `scenes/cutscene/Cutscene.gd`, with those two values converted to `@export var content_path: String` and `@export var next_scene_path: String` — everything else (the duration formula, the fade `Tween`, the Skip button, the letterbox `stretch_mode`, the `[center]` BBCode caption wrapping) stays byte-identical.

- `scenes/prologue_cutscene/PrologueCutscene.tscn` **keeps its existing path** (so `MainMenu.gd`'s reference and every existing test's `preload()` stay valid) but its attached script changes to point at the new `scenes/cutscene/Cutscene.gd`, with `content_path`/`next_scene_path` explicitly set in the scene file to the exact same values the old hardcoded consts held (`res://content/cutscenes/prologue_intro.json` / `res://scenes/main/Main.tscn`) — zero behavior change for the Prologue path, verified by the existing test suite passing unmodified in spirit (though the test file itself needs updating to reference the new script location — see Testing below).
- `scenes/prologue_cutscene/PrologueCutscene.gd` is deleted — its logic now lives in `Cutscene.gd`.
- A new `scenes/ending_cutscene/EndingCutscene.tscn` is created, using the same `Cutscene.gd` script, with `content_path = "res://content/cutscenes/plunder_ending_outro.json"` and `next_scene_path = "res://scenes/main_menu/MainMenu.tscn"` (returning to the main menu after the true ending — the natural landing spot, matching how a finished playthrough already leaves `MapButton` enabled).

## Architecture: triggering a cutscene after a true chapter ending

Today, `ChapterView._save_and_finish()` computes `resolved_next_chapter_id` and, if it's `null` (a true ending, no further chapter), simply `return`s — the game just stops advancing, leaving the final node's text on screen. This pass adds a new manifest-level field, `post_ending_cutscene_path`, read into a new `ChapterView` instance variable (`post_ending_cutscene_path`, set inside `load_chapter_by_id()` the same way `next_chapter_id`/`farrukh_wear_stage` already are). When `_save_and_finish()` resolves to a null next-chapter-id **and** this field is set (non-null, non-empty), it navigates to that scene via `get_tree().change_scene_to_file(...)` instead of just returning.

`content/chapters/manifest.json`'s `chapter_05_plunder_ending` entry gains `"post_ending_cutscene_path": "res://scenes/ending_cutscene/EndingCutscene.tscn"`. No other manifest entry changes — every other chapter's true endings (Chapter 8's two philosophical-choice terminals) are unaffected, since they have no such field and the code path falls through to the existing `return` behavior unchanged.

## Architecture: generalizing the art-generation script

`tools/pixellab/generate_cutscene_panels.py` currently hardcodes its panel-config path and output directory as Prologue-specific constants. This pass adds `--config` and `--output-dir` CLI arguments (defaulting to the Prologue's own existing values, so the existing bare invocation `python tools/pixellab/generate_cutscene_panels.py` keeps working exactly as before, unchanged) so the same script generates the new ending panels via `python tools/pixellab/generate_cutscene_panels.py --config tools/pixellab/plunder_ending_cutscene_panels.json`. Both cutscenes' art lands in the same `assets/cutscenes/` directory (matching how backgrounds and portraits already share one directory each across multiple chapters), distinguished by filename prefix.

## The content: 6 panels, `plunder_ending_outro.json`

Deliberately shorter than the Prologue's 11 — a coda, not a scene-setting prequel. Sparse, fragment-style captions rather than the Prologue's expository historical prose, matching the darker/quieter register. No named figures, no new plot events — pure mood, drawing directly on imagery and motifs Chapter 5's own text already established (watching a stranger's/his own hands, watching the road behind, the road's indifference, becoming "some other kind of man, not yet named"):

1. *Image:* the road west at full dusk, no caravan, alone. *Caption:* "The company thinned first. Then the light."
2. *Image:* a single small campfire against a vast dark landscape. *Caption:* "A fire that answered to no one but himself."
3. *Image:* close on a pair of hands, turning a coin over slowly. *Caption:* "He watched his own hands the way he'd once watched a stranger's."
4. *Image:* the empty road behind, long shadows, something ambiguous at the edge of visibility. *Caption:* "Nothing followed. He no longer trusted the difference."
5. *Image:* a vast night sky over the empty road, stars indifferent. *Caption:* "The sky kept its own accounting, indifferent to his."
6. *Image:* a long, distorted shadow stretching ahead of a lone figure on the road. *Caption:* "Some men, walking, arrive as strangers to themselves before they arrive anywhere else."

Same 400x168 letterbox format and manuscript-miniature `STYLE_CLAUSE`/outline/shading as the Prologue's panels — visual consistency with the rest of the game's art, `detail="highly detailed"` matching the current baseline. The darker mood comes entirely from the descriptions (night, shadow, isolation) and captions, not from any change to the technical generation parameters.

## Testing

- **Generic engine logic**, in a renamed `tests/unit/test_cutscene.gd` (was `test_prologue_cutscene.gd`): the existing 4 pure-logic tests (duration clamping/scaling, panel-display), updated to `preload()` the new `scenes/cutscene/Cutscene.gd`/`.tscn` paths — otherwise unchanged, since the underlying logic is byte-identical.
- **Prologue-specific content**, moved to a new dedicated `tests/unit/test_prologue_intro_content.gd`: the existing "11 panels, each with a caption and image path" structure test, unchanged in content, just relocated to match this project's per-chapter-content-test-file convention.
- **New ending-cutscene content**, in a new `tests/unit/test_plunder_ending_cutscene_content.gd`: an equivalent structure test for the new 6-panel `plunder_ending_outro.json`.
- **New manifest-field wiring**, in `tests/unit/test_chapter_view.gd`, using this project's existing fixture pattern (`tests/fixtures/manifest_fixture.json`): a new fixture entry reusing the already-existing terminal dialogue fixture (`dialogue_fixture_b.json`) with `"post_ending_cutscene_path"` set to a fixture-only path, verifying `chapter_view.post_ending_cutscene_path` is read correctly from the manifest. This tests the *field-reading*, not the actual scene transition — consistent with this project's established precedent (confirmed via `test_main_menu.gd`) of never unit-testing a real `change_scene_to_file()` call; the actual transition is verified live instead, the same way the Prologue cutscene's `MainMenu` wiring was.
- **Live verification**: run the actual game, reach any of Chapter 5's 4 terminal endings (fastest path: load `chapter_05_plunder_ending` directly and walk to a terminal), confirm the new dark cutscene plays with visible letterbox bars, its own 6 panels and captions, a working Skip button, and lands back on the main menu when finished or skipped. Take at least one screenshot as evidence, using this project's established `xprop`-based screenshot technique.
- The full existing suite (314 tests as of the last merge to `master`) must grow by exactly **2** new tests to **316**: the existing 4 generic-logic tests and 1 Prologue-content test are only *relocated* (no count change), and the new work adds exactly 1 new manifest-field test (`test_chapter_view.gd`) and 1 new ending-cutscene content-structure test (`test_plunder_ending_cutscene_content.gd`). No failures, no regressions to the Prologue cutscene's own already-passing behavior.

## What this pass does not do

- Does not add any new dialogue node to Chapter 5's own content — its existing 12 nodes, 4 terminals, and zero-effects character stay completely untouched.
- Does not branch the cutscene by which of the 4 terminal variants was reached — one shared sequence for all of them.
- Does not confirm any new plot outcome for Farrukh — stays tonal/atmospheric only, per the user's explicit direction.
- Does not add sound/music — this game has no audio system, and the cutscene stays silent, same as the Prologue's.
- Does not change any other chapter's manifest entry or ending behavior — only `chapter_05_plunder_ending` gains `post_ending_cutscene_path`.
