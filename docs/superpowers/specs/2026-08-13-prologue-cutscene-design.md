# Prologue Cold-Open Cutscene

**Status:** approved, pending implementation plan.

## Goal

A new, standalone cinematic sequence — 11 illustrated panels with captions, auto-advancing with fade transitions, skippable — that plays once every time "New Game" is pressed, before the interactive Prologue begins. This is the game's first genuinely new UI subsystem since the journey map: no cutscene/slideshow player exists anywhere in the codebase today (confirmed via search).

**Confirmed with the user across several rounds:**
- A true cold-open **prequel** — the world *before* Farrukh appears — not a picture-book retelling of the interactive Prologue's own already-written beats (`n01`-`n12`). New substance, not restated content.
- **Cinematic** presentation: auto-advancing panels timed to each caption's length, with fade transitions between panels, and a **Skip** button always available.
- Plays on **every** "New Game" press (no persistent "seen it" flag) — simplest option, and the Skip button already covers repeat playthroughs.
- A new **wider letterbox aspect ratio**, visually distinct from every other chapter's 320x180 background — signals "this is a different kind of scene," not just another location image.
- A battle/plunder beat, added at the user's explicit request, depicting a **generic, unnamed raid** (not the specific, already-referenced Battle of Nasa that Sarakhs's Bahram describes by name in Chapter 7) — keeps this cutscene clear of contradicting his account.

## The 11 panels

Each panel is a single wide illustrated scene (no attempt at portraying named historical rulers — Mahmud, Mas'ud, and the Caliph stay unshown, consistent with the art pipeline's established competence at locations/scenes, not likenesses) with a caption underneath, in order:

1. **Ghazni, the capital.** *Image:* a grand Ghaznavid capital skyline at dawn, minarets and mudbrick towers rising from a fortified hill city, wide establishing view. *Caption:* "By the year 1035, Ghazni was the seat of an empire built, in a single generation, on the conquests of one king - a capital whose wealth had outgrown the mountains that once made it obscure."
2. **The empire's reach.** *Image:* a busy caravan road stretching to the horizon, merchants and pack animals of many peoples, mountains in the distance. *Caption:* "Its roads reached further than any single army could hold them: Turkic soldiers, Persian clerks, Arab law, and merchants who spoke whichever tongue paid best that season."
3. **The throne.** *Image:* an imperial palace courtyard, empty throne dais visible through an archway, guards standing at a respectful distance. *Caption:* "Five years before, the throne had passed from father to son by force rather than by the old king's own wish - a settled matter by now, but not a forgotten one."
4. **The frontier provinces.** *Image:* a remote frontier watchtower on a dusty ridge, a thinned patrol passing below, the land beyond looking unwatched. *Caption:* "Along the frontier provinces, further from the capital's wealth than any map cared to show, the empire's grip had already begun to loosen, one small season at a time."
5. **A shopfront in Ghazni.** *Image:* a modest merchant's shopfront in a capital bazaar, awnings and stacked goods, ordinary daily commerce. *Caption:* "In Ghazni itself, ordinary life went on the way it always had - a shopfront, a ledger, a merchant's son who did not yet know how much of either he would inherit."
6. **The ledger.** *Image:* a merchant's hand closing a ledger book on a wooden counter, a lamp burning low, a folded paper tucked half-hidden beneath it. *Caption:* "The merchant kept accounts like any other man of his trade. Not every paper in that ledger, though, was the kind a man showed his own clerk without being asked twice."
7. **Riders massing.** *Image:* Turkmen horsemen gathering on an open steppe at dusk, a line of riders silhouetted against the sky. *Caption:* "Further west, along the Khorasan road, Turkmen horsemen had been testing the frontier's patience for longer than anyone in Ghazni had thought worth mentioning."
8. **The raid.** *Image:* a chaotic skirmish at a frontier garrison wall, soldiers fighting in disarray, horsemen riding off in the background with sacks and bundles of plunder. *Caption:* "It did not stay a testing for long. A garrison caught short, a stretch of road left unguarded for one afternoon too many - and men who had never worn a uniform rode off with whatever the wagons had been carrying."
9. **Word on the road.** *Image:* a caravan crossing open desert at speed, a lone rider peeling off from the group toward the horizon. *Caption:* "Word of it moved the way word always did out here - caravan to caravan, faster than any courier the Sultan himself employed, arriving everywhere at once and nowhere official."
10. **Ghazni, unaware.** *Image:* a capital city street at dusk, shops closing their shutters, lamplight beginning to show in windows, ordinary and calm. *Caption:* "None of it had reached Ghazni yet. The city closed its shops at the same hour it always did, unaware that a season was about to turn."
11. **The shopfront, evening.** *Image:* a quiet merchant's shopfront interior at evening, a single lamp lit, an empty stool beside a stacked ledger. *Caption:* "In a shopfront no grander than any other on its street, a merchant's cough had just begun to worsen."

Panel 11 deliberately stops short of restating the interactive Prologue's own opening line (`n01_naming`'s "Farrukh ibn Hasan al-Nishapuri had lived nineteen years...") — it sets up the illness beat (`n02_rumor_illness`) without repeating anything the player is about to read seconds later.

## Architecture

**New scene:** `scenes/prologue_cutscene/PrologueCutscene.tscn` + `.gd`. Node tree:
- `Control` (root, full rect)
  - `ColorRect "Backdrop"` (full rect, solid black) — provides the letterbox bar color
  - `TextureRect "PanelImage"` (full rect, `stretch_mode = 5` `KEEP_ASPECT_CENTERED`, `expand_mode = 1`) — the 2.38:1 image is narrower than the 1.78:1 viewport is tall relative to its width, so fitting it without cropping leaves visible black bars top and bottom: the letterbox effect, achieved through stretch mode rather than manually drawn bars.
  - `ColorRect "CaptionBar"` (anchored to the bottom, semi-transparent black) — the subtitle-bar backing
  - `RichTextLabel "CaptionLabel"` (inside `CaptionBar`, centered, `bbcode_enabled = false`) — `RichTextLabel` rather than `Label` specifically so it inherits `BorrowedFortuneTheme`'s existing `RichTextLabel` font-size/color overrides for free, consistent with `ChapterView`'s own narration text, even though this scene needs no glossary/BBCode features itself.
  - `Button "SkipButton"` (top-right corner, always visible) — inherits the project's theme automatically like every other button in the game.

**Content data:** `content/cutscenes/prologue_intro.json` — a flat array of 11 `{"image_path": "res://assets/cutscenes/prologue_intro_NN.png", "caption": "..."}` objects, loaded via the same raw `FileAccess`/`JSON.parse_string()` pattern every other content file in this project uses.

**Panel display:** mirrors `ChapterView._update_background()`'s exact established idiom for loading pixellab-generated art — `Image.load_from_file(path)` (never `load()`/`preload()`, which never completes in this environment for freshly-dropped assets) wrapped in `ImageTexture.create_from_image()`, with the same null-check-and-bail defensiveness.

**Auto-advance timing:** a `Timer` (one-shot) started with a duration computed by a pure, directly-testable static function:

```gdscript
const WORDS_PER_MINUTE := 180.0
const MINIMUM_PANEL_SECONDS := 4.0
const MAXIMUM_PANEL_SECONDS := 12.0

static func compute_panel_duration_seconds(caption: String) -> float:
	var word_count := caption.split(" ", false).size()
	var estimated := (word_count / WORDS_PER_MINUTE) * 60.0
	return clamp(estimated, MINIMUM_PANEL_SECONDS, MAXIMUM_PANEL_SECONDS)
```

180 words/minute is a commonly-cited comfortable reading speed for on-screen captions; the floor and ceiling keep any single panel from flashing by too fast or dragging too long regardless of caption length.

**Fade transitions:** on `Timer` timeout, a `Tween` fades `PanelImage`'s `modulate:a` to `0.0` over `FADE_DURATION_SECONDS := 0.6`, then a `tween_callback` swaps to the next panel's image/caption/timer, then fades back to `1.0`.

**Finishing:** when the timer fires on the last panel (index 10), or the Skip button is pressed at any point, `_finish()` calls `get_tree().change_scene_to_file("res://scenes/main/Main.tscn")` — exactly what `MainMenu._on_new_game_pressed()` currently does directly.

**MainMenu wiring change:** `_on_new_game_pressed()` (currently navigating straight to `Main.tscn` after clearing the save pointer) is retargeted to navigate to `PrologueCutscene.tscn` instead; the cutscene itself navigates onward to `Main.tscn` when finished. `_on_continue_pressed()` is untouched — resuming a save must never replay the intro.

## Art pipeline

New generation script `tools/pixellab/generate_cutscene_panels.py` + config `tools/pixellab/cutscene_panels.json` (the 11 image descriptions above), following the exact pattern of `generate_backgrounds.py`: imports `pixflux_client.py` unchanged, reuses its existing `STYLE_CLAUSE` (the same "manuscript miniature" flat-shaded, single-color-outline look every other background already uses — this cutscene stays visually part of the same game, not a jarringly different art style), `detail="highly detailed"` (matching the current post-quality-upgrade baseline for all other art in the game).

**Dimensions: 400x168** (2.38:1) — reused verbatim from the existing `menu_banner_short` asset, a dimension already proven to work with pixflux's real API constraints (≤400px, divisible by 4 on both axes) rather than a new, unverified size.

Output files: `assets/cutscenes/prologue_intro_01.png` through `_11.png`.

## Testing

**Covered by GUT**, in a new `tests/unit/test_prologue_cutscene.gd`:
- The real `content/cutscenes/prologue_intro.json` has exactly 11 panels, each with a non-empty `caption` and an `image_path` matching the `res://assets/cutscenes/prologue_intro_NN.png` naming convention.
- `compute_panel_duration_seconds()` clamps a very short caption to `MINIMUM_PANEL_SECONDS`, clamps a very long caption to `MAXIMUM_PANEL_SECONDS`, and returns the actual word-count-scaled value (not clamped) for a caption in between.
- Displaying the first panel sets the caption label's text and starts the advance timer with the correct, formula-computed duration.

**Not covered by GUT, verified live instead** (matching this project's own established precedent — `test_main_menu.gd` tests button enabled/disabled state but has never asserted a button's `change_scene_to_file` navigation target, and this project has no prior instance of testing a scene transition in headless GUT): the Skip button's actual click-through-to-Main.tscn behavior, the fade-transition visuals, and the full 11-panel playthrough's real pacing/look. The implementer verifies these via a live, running-game check (screenshot or manual play), the same way the journey map and menu-theme banner work were verified.

## What this pass does not do

- Does not add any sound/music — this game has no audio system anywhere (confirmed via search), and this cutscene stays silent, consistent with the rest of the game.
- Does not add a persistent "seen the intro" flag — it plays every time "New Game" is pressed, by the user's own choice.
- Does not touch the interactive Prologue's own 14 dialogue nodes (`n01`-`n12`) at all — no overlap, no rewritten content.
- Does not attempt to depict Mahmud, Mas'ud, or the Caliph as figures — every panel stays a location/scene shot.
- Does not depict the specific, already-referenced Battle of Nasa — the raid panel (8) is deliberately generic and unnamed.
