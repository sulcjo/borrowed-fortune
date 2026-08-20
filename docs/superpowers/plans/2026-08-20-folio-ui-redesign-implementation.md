# Folio UI Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace `ChapterView`'s absolute-offset layout with a container-driven manuscript-folio composition, and establish the project-wide display and rendering foundation it sits on.

**Architecture:** Five container regions (prose column, place inset, choice list, margin column, colophon) replace 33 absolute pixel offsets. Scale arithmetic lives in a new pure-logic `engine/` class so it is unit-testable without a scene tree, following the project's existing split where `engine/` is `RefCounted` logic and `scenes/` renders it. The glossary popup retires into an always-present margin.

**Tech Stack:** Godot 4.3, GDScript, GUT (vendored at `addons/gut/`).

**Spec:** `docs/superpowers/specs/2026-08-20-folio-ui-redesign-design.md`

## Global Constraints

- **Godot 4.3.** Run everything through `godot` (on PATH at `/home/sulcjo/.local/bin/godot`).
- **Priming: the documented command does not work cleanly here.** GUT cannot resolve
  `class_name` symbols until `.godot/global_script_class_cache.cfg` exists, and
  `.godot/` is gitignored, so a fresh worktree or clone has none. What was actually
  observed:
  - `godot --headless --path . --editor --quit` on an **empty** `.godot/imported`
    fails first with a wall of `Unable to open file: res://.godot/imported/*.ctex`
    errors on GUT's own icons and fonts, then aborts (exit 134) without writing a
    usable cache. The main checkout also shows `imported count: 0`, so it is likely
    to fail there too.
  - The fix used here was to copy a populated cache from a worktree that had been
    opened in the editor before: `cp -r <other-worktree>/.godot/imported/. .godot/imported/`
    plus `global_script_class_cache.cfg`, `uid_cache.bin` and `scene_groups_cache.cfg`.
    The import hashes are derived from `res://` paths, which are identical between
    worktrees, so they transfer.
  - **After adding any new `class_name`**, re-run
    `godot --headless --path . --editor --quit`. With `.godot/imported` populated it
    still aborts at teardown (exit 134, zero ERROR lines) but *does* write the new
    class into the cache first, which is all that is needed. Ignore the abort.
  - Symptom if skipped: `Parse Error: Identifier "FolioMetrics" not declared in the
    current scope`, followed by GUT reporting `Nothing was run`.
- **Full test suite:** `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`
- **Single file:** `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/<file>.gd -gexit`
- **Theme is generated, never hand-edited.** Edit `engine/theme/BorrowedFortuneTheme.gd`, then regenerate: `godot --headless --path . -s tools/build_theme.gd`. Commit the regenerated `theme/borrowed_fortune_theme.tres` alongside the source change.
- **Reference resolution is 1280×720.** All pixel figures in this plan are at that reference.
- **Narration font metrics:** `RichTextLabel` `normal_font_size = 22`, EB Garamond — roughly 10px average character width, ~31px line box. Any arithmetic uses these.
- **12 known-stale content assertions** already fail across `test_farah_dialogue_content.gd` (2), `test_nishapur_dialogue_content.gd` (3), `test_teginabad_dialogue_content.gd` (5), `test_sarakhs_dialogue_content.gd` (2). They are unrelated to this work. Do not fix them; do not count them as regressions.
- **Immutability and naming** per the project's coding style: `snake_case` functions, `UPPER_SNAKE_CASE` constants, no mutation of passed-in dictionaries.

---

### Task 1: Display and rendering foundation

Adds the `[display]` and `[rendering]` sections that do not currently exist. Without these the folio cannot scale and the pixel art stays blurred.

**Files:**
- Modify: `project.godot`
- Test: `tests/unit/test_project_display_settings.gd` (create)

**Interfaces:**
- Consumes: nothing.
- Produces: project settings `display/window/size/viewport_width` (int 1280), `display/window/size/viewport_height` (int 720), `display/window/stretch/mode` (String `"canvas_items"`), `display/window/stretch/aspect` (String `"expand"`), `rendering/textures/canvas_textures/default_texture_filter` (int 0).

- [ ] **Step 1: Write the failing test**

Create `tests/unit/test_project_display_settings.gd`:

```gdscript
extends GutTest

# The folio expands to fill the window, so the project must declare a reference
# viewport and a canvas_items stretch mode. Before this task project.godot had no
# [display] section at all, which is why ChapterView's 33 offsets drifted.

func test_reference_viewport_is_1280x720():
	assert_eq(int(ProjectSettings.get_setting("display/window/size/viewport_width")), 1280)
	assert_eq(int(ProjectSettings.get_setting("display/window/size/viewport_height")), 720)

func test_stretch_mode_scales_canvas_items():
	assert_eq(str(ProjectSettings.get_setting("display/window/stretch/mode")), "canvas_items")

func test_stretch_aspect_expands_so_a_wider_window_shows_more_page():
	assert_eq(str(ProjectSettings.get_setting("display/window/stretch/aspect")), "expand")

func test_canvas_texture_filter_is_nearest_so_pixel_art_is_not_blurred():
	# 0 == CANVAS_ITEM_TEXTURE_FILTER_NEAREST. The backgrounds are 320x180 and the
	# portraits 200x200; the default linear filter interpolates them 4-6x.
	assert_eq(int(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter")), 0)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_project_display_settings.gd -gexit`

Expected: FAIL — all four tests. `ProjectSettings.get_setting()` returns `null` for every one of these keys, so `int(null)` is `0` and `str(null)` is `"<null>"`.

- [ ] **Step 3: Add the settings**

Append to `project.godot`. Section order in the file is alphabetical by convention — put `[display]` after `[application]` and `[rendering]` at the end:

```ini
[display]

window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"

[rendering]

textures/canvas_textures/default_texture_filter=0
```

- [ ] **Step 4: Run test to verify it passes**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_project_display_settings.gd -gexit`

Expected: PASS — 4 tests, 5 asserts.

- [ ] **Step 5: Commit**

```bash
git add project.godot tests/unit/test_project_display_settings.gd
git commit -m "feat: declare the display reference viewport and nearest texture filter"
```

---

### Task 2: FolioMetrics — inset scale and prose width

Pure arithmetic, no scene tree. The inset is pixel art and must land on integer multiples of 320×180; because the folio expands to the window, the scale has to be chosen per node rather than fixed.

**Files:**
- Create: `engine/theme/FolioMetrics.gd`
- Test: `tests/unit/test_folio_metrics.gd` (create)

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `FolioMetrics.PLACE_BASE_WIDTH` → `int` 320
  - `FolioMetrics.PLACE_BASE_HEIGHT` → `int` 180
  - `FolioMetrics.NARRATION_MAX_WIDTH` → `int` 720
  - `FolioMetrics.narration_width(available_width: float) -> float`
  - `FolioMetrics.choose_place_scale(character_count: int, available_width: float, available_height: float, gutter: float, char_width: float, line_height: float) -> int`

- [ ] **Step 1: Write the failing test**

Create `tests/unit/test_folio_metrics.gd`:

```gdscript
extends GutTest

# Metrics for the 1280x720 reference at RichTextLabel normal_font_size = 22:
# roughly 10px average character width, ~31px line box in EB Garamond.
const CHAR_W := 10.0
const LINE_H := 31.0
const GUTTER := 12.0

func test_narration_width_is_capped_so_prose_never_runs_to_a_punishing_measure():
	assert_eq(FolioMetrics.narration_width(2000.0), 720.0)

func test_narration_width_takes_what_is_available_when_under_the_cap():
	assert_eq(FolioMetrics.narration_width(440.0), 440.0)

func test_a_short_node_gets_a_large_inset():
	# 120 characters has room to spare beside a 2x or 3x inset.
	var scale := FolioMetrics.choose_place_scale(120, 1060.0, 600.0, GUTTER, CHAR_W, LINE_H)
	assert_gt(scale, 1, "a short node should not be forced down to 1x")

func test_the_1135_character_prologue_node_drops_to_1x():
	# At 2x the inset is 640 wide, leaving ~408px of prose: ~26 lines, ~806px tall,
	# which does not fit 600px. At 1x it leaves ~728px: ~15 lines, ~476px. Fits.
	var scale := FolioMetrics.choose_place_scale(1135, 1060.0, 600.0, GUTTER, CHAR_W, LINE_H)
	assert_eq(scale, 1)

func test_scale_never_falls_below_one_even_when_nothing_fits():
	var scale := FolioMetrics.choose_place_scale(99999, 1060.0, 100.0, GUTTER, CHAR_W, LINE_H)
	assert_eq(scale, 1, "1x is the floor - the inset is never dropped entirely")

func test_scale_is_bounded_by_the_width_actually_available():
	# 400px of width cannot host a 2x (640px) inset at any text length.
	var scale := FolioMetrics.choose_place_scale(10, 400.0, 600.0, GUTTER, CHAR_W, LINE_H)
	assert_eq(scale, 1)

func test_chosen_scale_always_yields_an_exact_integer_multiple_of_the_source():
	for characters in [10, 300, 800, 1135, 2400]:
		var scale := FolioMetrics.choose_place_scale(characters, 1060.0, 600.0, GUTTER, CHAR_W, LINE_H)
		assert_eq(FolioMetrics.PLACE_BASE_WIDTH * scale % FolioMetrics.PLACE_BASE_WIDTH, 0,
			"scale %d must be an exact multiple for %d characters" % [scale, characters])
		assert_gt(scale, 0)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_folio_metrics.gd -gexit`

Expected: FAIL — the parser cannot resolve the identifier `FolioMetrics`; the class does not exist.

- [ ] **Step 3: Write the implementation**

Create `engine/theme/FolioMetrics.gd`:

```gdscript
extends RefCounted
class_name FolioMetrics

# The place art is pixel art at a fixed source size, so it may only be drawn at
# integer multiples - a fractional upscale makes the pixels shimmer unevenly.
const PLACE_BASE_WIDTH := 320
const PLACE_BASE_HEIGHT := 180

# Roughly 72 characters per line at normal_font_size = 22. Past this a line of
# prose is tiring to track back from on a wide display.
const NARRATION_MAX_WIDTH := 720

# Largest inset we would ever draw, regardless of room: beyond 3x the art starts
# dominating a page whose point is the prose.
const MAX_PLACE_SCALE := 3

static func narration_width(available_width: float) -> float:
	return min(available_width, float(NARRATION_MAX_WIDTH))

# Picks the largest integer scale whose leftover width still lets the node's text
# fit the available height. Falls back to 1x, which is always drawn even if the
# text then has to scroll - dropping the art entirely would leave a hole in the page.
static func choose_place_scale(
	character_count: int,
	available_width: float,
	available_height: float,
	gutter: float,
	char_width: float,
	line_height: float
) -> int:
	for scale in range(MAX_PLACE_SCALE, 1, -1):
		var inset_width := float(PLACE_BASE_WIDTH * scale)
		var prose_width := narration_width(available_width - inset_width - gutter)
		if prose_width <= 0.0:
			continue
		if _text_height(character_count, prose_width, char_width, line_height) <= available_height:
			return scale
	return 1

static func _text_height(character_count: int, prose_width: float, char_width: float, line_height: float) -> float:
	var characters_per_line := maxf(1.0, floorf(prose_width / char_width))
	var lines := ceilf(float(character_count) / characters_per_line)
	return lines * line_height
```

- [ ] **Step 4: Run test to verify it passes**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_folio_metrics.gd -gexit`

Expected: PASS — 7 tests.

- [ ] **Step 5: Commit**

```bash
git add engine/theme/FolioMetrics.gd tests/unit/test_folio_metrics.gd
git commit -m "feat: add FolioMetrics for integer inset scaling and prose width"
```

---

### Task 3: Theme variations for the folio regions

Additive only. The old `PortraitCard` and `DialogueParchment` variations stay until Task 8 removes them, so the scene keeps rendering throughout.

**Files:**
- Modify: `engine/theme/BorrowedFortuneTheme.gd`
- Modify: `theme/borrowed_fortune_theme.tres` (regenerated, never hand-edited)
- Test: `tests/unit/test_borrowed_fortune_theme.gd`

**Interfaces:**
- Consumes: existing constants `PARCHMENT_FILL`, `GOLD`, `INK_TEXT`, `BUTTON_FILL_NORMAL`.
- Produces: theme type variations `Folio` (base `Panel`), `Roundel` (base `Panel`), `Colophon` (base `Label`), `GlossNote` (base `Label`), `Rubric` (base `Button`). New constants `RUBRIC_RED`, `MUTED_INK`.

- [ ] **Step 1: Write the failing test**

Append to `tests/unit/test_borrowed_fortune_theme.gd`:

```gdscript
func test_folio_variation_is_a_parchment_panel():
	var theme := BorrowedFortuneTheme.build()
	assert_eq(theme.get_type_variation_base("Folio"), &"Panel")
	var panel_style: StyleBoxFlat = theme.get_stylebox("panel", "Folio")
	assert_eq(panel_style.bg_color, BorrowedFortuneTheme.PARCHMENT_FILL)

func test_roundel_variation_is_a_fully_rounded_panel_for_figure_medallions():
	var theme := BorrowedFortuneTheme.build()
	assert_eq(theme.get_type_variation_base("Roundel"), &"Panel")
	var panel_style: StyleBoxFlat = theme.get_stylebox("panel", "Roundel")
	assert_gt(panel_style.corner_radius_top_left, 8, "a roundel must read as circular, not boxed")

func test_colophon_variation_uses_muted_ink():
	var theme := BorrowedFortuneTheme.build()
	assert_eq(theme.get_type_variation_base("Colophon"), &"Label")
	assert_eq(theme.get_color("font_color", "Colophon"), BorrowedFortuneTheme.MUTED_INK)

func test_gloss_note_variation_uses_muted_ink():
	var theme := BorrowedFortuneTheme.build()
	assert_eq(theme.get_type_variation_base("GlossNote"), &"Label")
	assert_eq(theme.get_color("font_color", "GlossNote"), BorrowedFortuneTheme.MUTED_INK)

func test_rubric_choice_variation_is_unfilled_red_text_not_a_button_block():
	var theme := BorrowedFortuneTheme.build()
	assert_eq(theme.get_type_variation_base("Rubric"), &"Button")
	assert_eq(theme.get_color("font_color", "Rubric"), BorrowedFortuneTheme.RUBRIC_RED)
	var normal_style: StyleBoxFlat = theme.get_stylebox("normal", "Rubric")
	assert_false(normal_style.draw_center, "a rubricated line is written on the page, not boxed on it")

func test_rubric_keeps_the_existing_focus_ring_for_the_later_controls_work():
	var theme := BorrowedFortuneTheme.build()
	var focus_style: StyleBoxFlat = theme.get_stylebox("focus", "Rubric")
	assert_eq(focus_style.border_color, BorrowedFortuneTheme.FOCUS_RING)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_borrowed_fortune_theme.gd -gexit`

Expected: FAIL — six new tests. `get_type_variation_base()` returns `&""` for undefined variations, and `BorrowedFortuneTheme.MUTED_INK` / `RUBRIC_RED` do not exist yet.

- [ ] **Step 3: Add the constants**

In `engine/theme/BorrowedFortuneTheme.gd`, after the existing `SCROLLBAR_GRABBER_PRESSED` constant:

```gdscript
const RUBRIC_RED := Color("#7a1f14")
const MUTED_INK := Color("#6b5a44")
```

- [ ] **Step 4: Add the variation builders**

In the same file, register the new builders inside `build()` — add these four calls immediately after the existing `_apply_panel_style(theme)` line:

```gdscript
	_apply_folio_variation(theme)
	_apply_roundel_variation(theme)
	_apply_marginalia_variations(theme)
	_apply_rubric_variation(theme)
```

Then add the builders themselves, after `_apply_panel_style()`:

```gdscript
static func _apply_folio_variation(theme: Theme) -> void:
	theme.set_type_variation("Folio", "Panel")
	var box := StyleBoxFlat.new()
	box.bg_color = PARCHMENT_FILL
	box.border_color = GOLD
	box.set_border_width_all(1)
	theme.set_stylebox("panel", "Folio", box)

static func _apply_roundel_variation(theme: Theme) -> void:
	theme.set_type_variation("Roundel", "Panel")
	var box := StyleBoxFlat.new()
	box.bg_color = BUTTON_FILL_NORMAL
	box.border_color = GOLD
	box.set_border_width_all(1)
	# Large enough that any roundel we draw reads as a circle rather than a
	# rounded box; Godot clamps the radius to half the shorter side.
	box.set_corner_radius_all(256)
	theme.set_stylebox("panel", "Roundel", box)

static func _apply_marginalia_variations(theme: Theme) -> void:
	theme.set_type_variation("Colophon", "Label")
	theme.set_color("font_color", "Colophon", MUTED_INK)
	theme.set_font_size("font_size", "Colophon", 14)

	theme.set_type_variation("GlossNote", "Label")
	theme.set_color("font_color", "GlossNote", MUTED_INK)
	theme.set_font_size("font_size", "GlossNote", 13)

static func _apply_rubric_variation(theme: Theme) -> void:
	theme.set_type_variation("Rubric", "Button")

	var flat := StyleBoxFlat.new()
	flat.draw_center = false
	flat.border_color = GOLD
	flat.border_width_left = 2
	flat.content_margin_left = 8
	flat.content_margin_top = 2
	flat.content_margin_bottom = 2

	var hover := flat.duplicate()
	hover.draw_center = true
	hover.bg_color = Color(GOLD.r, GOLD.g, GOLD.b, 0.12)

	theme.set_stylebox("normal", "Rubric", flat)
	theme.set_stylebox("hover", "Rubric", hover)
	theme.set_stylebox("pressed", "Rubric", hover)
	theme.set_stylebox("disabled", "Rubric", flat)
	theme.set_stylebox("focus", "Rubric", _focus_stylebox())

	theme.set_color("font_color", "Rubric", RUBRIC_RED)
	theme.set_color("font_hover_color", "Rubric", RUBRIC_RED)
	theme.set_color("font_pressed_color", "Rubric", RUBRIC_RED)
	theme.set_color("font_focus_color", "Rubric", RUBRIC_RED)
	theme.set_font_size("font_size", "Rubric", 20)
```

- [ ] **Step 5: Regenerate the theme resource**

Run: `godot --headless --path . -s tools/build_theme.gd`

Expected: prints `Theme saved to res://theme/borrowed_fortune_theme.tres`.

- [ ] **Step 6: Run test to verify it passes**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_borrowed_fortune_theme.gd -gexit`

Expected: PASS — the six new tests plus the nine pre-existing ones.

- [ ] **Step 7: Commit**

```bash
git add engine/theme/BorrowedFortuneTheme.gd theme/borrowed_fortune_theme.tres tests/unit/test_borrowed_fortune_theme.gd
git commit -m "feat: add folio, roundel, colophon and rubric theme variations"
```

---

### Task 4: Replace the ChapterView scene tree

The atomic change. The new tree carries every region up front so later tasks only wire behavior into nodes that already exist. All 18 hard-coded test paths are repointed here, and behavior is preserved 1:1 — the background becomes a bounded inset, the portrait cards become roundels, the status readout becomes the colophon, but each still just shows what it showed before. No new behavior in this task.

**Files:**
- Modify: `scenes/chapter_view/ChapterView.tscn` (full replacement)
- Modify: `scenes/chapter_view/ChapterView.gd:3-11` (`@onready` paths), `:96-101` (`_render_current_node` choice loop), `:113` (`_update_status_readout` target), `:127` (`_update_background` target), `:141-146` (`_update_portraits` targets)
- Test: `tests/unit/test_chapter_view.gd`, `tests/unit/test_chapter_view_portraits.gd`, `tests/unit/test_chapter_view_background.gd`

**Interfaces:**
- Consumes: theme variations `Folio`, `Roundel`, `Colophon`, `Rubric` from Task 3.
- Produces: node paths `Folio/TextColumn/HeadBlock/PlaceInset`, `Folio/TextColumn/HeadBlock/NarrationLabel`, `Folio/TextColumn/ChoicesContainer`, `Folio/TextColumn/Colophon`, `Folio/MarginColumn/NpcRoundel/NpcPortrait`, `Folio/MarginColumn/FarrukhRoundel/FarrukhPortrait`, `Folio/MarginColumn/GlossNotes`.

- [ ] **Step 1: Write the failing test**

Add to `tests/unit/test_chapter_view.gd`. This is the assertion that would have caught the original overflow:

```gdscript
func test_choice_list_is_tall_enough_for_every_choice_it_holds():
	# Four choices is the real maximum across all 229 nodes - Pushang's
	# n09_the_officers_demand. The old layout pinned this container to 76px, which
	# four buttons at font_size 18 plus stylebox margins cannot fit. Built directly
	# rather than loaded from the chapter so the test does not depend on story edits
	# keeping that node at exactly four choices.
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.dialogue_engine.load_tree([{
		"id": "n09",
		"text": "An officer at the gate named a sum.",
		"choices": [
			{"text": "Pay what he asks.", "next_id": "n09", "effects": {}},
			{"text": "Argue him down to something smaller.", "next_id": "n09", "effects": {}},
			{"text": "Refuse outright.", "next_id": "n09", "effects": {}},
			{"text": "Offer him something quieter, off the list.", "next_id": "n09", "effects": {}},
		],
	}], "n09")
	chapter_view._render_current_node()

	var choices_container: VBoxContainer = chapter_view.get_node("Folio/FolioMargin/Page/TextColumn/ChoicesContainer")
	assert_eq(choices_container.get_child_count(), 4, "all four choices must be present")

	var children_height := 0.0
	for child in choices_container.get_children():
		children_height += child.get_combined_minimum_size().y
	assert_gte(choices_container.get_combined_minimum_size().y, children_height,
		"the container must be at least as tall as the choices it holds")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_chapter_view.gd -gexit`

Expected: FAIL — `get_node("Folio/FolioMargin/Page/TextColumn/ChoicesContainer")` returns `null`; the node does not exist yet.

- [ ] **Step 3: Replace the scene tree**

Replace the whole of `scenes/chapter_view/ChapterView.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scenes/chapter_view/ChapterView.gd" id="1"]

[node name="ChapterView" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1")

[node name="Folio" type="Panel" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
theme_type_variation = &"Folio"

[node name="FolioMargin" type="MarginContainer" parent="Folio"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
theme_override_constants/margin_left = 28
theme_override_constants/margin_top = 24
theme_override_constants/margin_right = 28
theme_override_constants/margin_bottom = 20

[node name="Page" type="HBoxContainer" parent="Folio/FolioMargin"]
layout_mode = 2
theme_override_constants/separation = 20

[node name="TextColumn" type="VBoxContainer" parent="Folio/FolioMargin/Page"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/separation = 8

[node name="HeadBlock" type="HBoxContainer" parent="Folio/FolioMargin/Page/TextColumn"]
layout_mode = 2
size_flags_vertical = 3
theme_override_constants/separation = 12

[node name="PlaceInset" type="TextureRect" parent="Folio/FolioMargin/Page/TextColumn/HeadBlock"]
layout_mode = 2
size_flags_vertical = 0
expand_mode = 1
stretch_mode = 5

[node name="NarrationLabel" type="RichTextLabel" parent="Folio/FolioMargin/Page/TextColumn/HeadBlock"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
bbcode_enabled = true
fit_content = true
scroll_active = true

[node name="ChoicesRule" type="HSeparator" parent="Folio/FolioMargin/Page/TextColumn"]
layout_mode = 2

[node name="ChoicesContainer" type="VBoxContainer" parent="Folio/FolioMargin/Page/TextColumn"]
layout_mode = 2
theme_override_constants/separation = 4

[node name="ColophonRule" type="HSeparator" parent="Folio/FolioMargin/Page/TextColumn"]
layout_mode = 2

[node name="Colophon" type="Label" parent="Folio/FolioMargin/Page/TextColumn"]
layout_mode = 2
theme_type_variation = &"Colophon"

[node name="MarginColumn" type="VBoxContainer" parent="Folio/FolioMargin/Page"]
layout_mode = 2
custom_minimum_size = Vector2(160, 0)
theme_override_constants/separation = 10

[node name="NpcRoundel" type="Panel" parent="Folio/FolioMargin/Page/MarginColumn"]
layout_mode = 2
custom_minimum_size = Vector2(96, 96)
size_flags_horizontal = 4
theme_type_variation = &"Roundel"

[node name="NpcPortrait" type="TextureRect" parent="Folio/FolioMargin/Page/MarginColumn/NpcRoundel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 4.0
offset_top = 4.0
offset_right = -4.0
offset_bottom = -4.0
mouse_filter = 2
expand_mode = 1
stretch_mode = 5

[node name="FarrukhRoundel" type="Panel" parent="Folio/FolioMargin/Page/MarginColumn"]
layout_mode = 2
custom_minimum_size = Vector2(72, 72)
size_flags_horizontal = 4
theme_type_variation = &"Roundel"

[node name="FarrukhPortrait" type="TextureRect" parent="Folio/FolioMargin/Page/MarginColumn/FarrukhRoundel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 4.0
offset_top = 4.0
offset_right = -4.0
offset_bottom = -4.0
mouse_filter = 2
expand_mode = 1
stretch_mode = 5

[node name="GlossNotes" type="VBoxContainer" parent="Folio/FolioMargin/Page/MarginColumn"]
layout_mode = 2
theme_override_constants/separation = 8
```

The four `offset_*` values inside each roundel are the portrait's inset from its
own frame — a child filling its parent minus a 4px border, not a position on the
screen. They do not drift with window size.

- [ ] **Step 4: Repoint the script**

**First, verify the real tree rather than the `.tscn` you just wrote.** A path wrong
by one segment yields a `null` and then a confusing "Invalid call on base Nil"
somewhere else entirely. Write `tools/print_chapter_view_tree.gd`:

```gdscript
extends SceneTree

func _init() -> void:
	var view = load("res://scenes/chapter_view/ChapterView.tscn").instantiate()
	get_root().add_child(view)
	view.print_tree_pretty()
	quit(0)
```

Run: `godot --headless --path . -s tools/print_chapter_view_tree.gd`

Check the printed tree against all seven paths below before writing them into the
script. Delete the throwaway script afterwards — do not commit it.

In `scenes/chapter_view/ChapterView.gd`, replace the `@onready` block (lines 3–11) with:

```gdscript
const _PAGE := "Folio/FolioMargin/Page"

@onready var narration_label: RichTextLabel = get_node("%s/TextColumn/HeadBlock/NarrationLabel" % _PAGE)
@onready var choices_container: VBoxContainer = get_node("%s/TextColumn/ChoicesContainer" % _PAGE)
@onready var colophon: Label = get_node("%s/TextColumn/Colophon" % _PAGE)
@onready var place_inset: TextureRect = get_node("%s/TextColumn/HeadBlock/PlaceInset" % _PAGE)
@onready var npc_roundel: Panel = get_node("%s/MarginColumn/NpcRoundel" % _PAGE)
@onready var npc_portrait: TextureRect = get_node("%s/MarginColumn/NpcRoundel/NpcPortrait" % _PAGE)
@onready var farrukh_roundel: Panel = get_node("%s/MarginColumn/FarrukhRoundel" % _PAGE)
@onready var farrukh_portrait: TextureRect = get_node("%s/MarginColumn/FarrukhRoundel/FarrukhPortrait" % _PAGE)
@onready var gloss_notes: VBoxContainer = get_node("%s/MarginColumn/GlossNotes" % _PAGE)
```

The `margin_popup` variable is removed along with its node. In `_on_narration_meta_clicked()`, drop the final `margin_popup.show_entries(entries)` line for now — Task 7 replaces the whole function. Keep the `unlock()` loop so the save format is unaffected.

Rename the three render helpers and their call sites in `_render_current_node()`:

- `_update_status_readout()` → `_update_colophon()`, and its final line becomes `colophon.text = " · ".join(parts)`
- `_update_background()` → `_update_place_inset()`, and its three assignments to `background.texture` become `place_inset.texture`
- In `_update_portraits()`, `npc_portrait_card` becomes `npc_roundel` and `farrukh_portrait_card` becomes `farrukh_roundel`

Give the generated choice buttons the rubric look — in the `_render_current_node()` loop, after `button.text = choices[i]["text"]`:

```gdscript
		button.theme_type_variation = &"Rubric"
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
```

- [ ] **Step 5: Repoint the 18 test assertions**

Mechanical find-and-replace across the three test files. Old path → new path:

| Old | New |
|---|---|
| `DialogueParchment/NarrationLabel` | `Folio/FolioMargin/Page/TextColumn/HeadBlock/NarrationLabel` |
| `StatusReadout` | `Folio/FolioMargin/Page/TextColumn/Colophon` |
| `Background` | `Folio/FolioMargin/Page/TextColumn/HeadBlock/PlaceInset` |
| `NpcPortraitCard/NpcPortrait` | `Folio/FolioMargin/Page/MarginColumn/NpcRoundel/NpcPortrait` |
| `NpcPortraitCard` | `Folio/FolioMargin/Page/MarginColumn/NpcRoundel` |
| `FarrukhPortraitCard/FarrukhPortrait` | `Folio/FolioMargin/Page/MarginColumn/FarrukhRoundel/FarrukhPortrait` |
| `FarrukhPortraitCard` | `Folio/FolioMargin/Page/MarginColumn/FarrukhRoundel` |

In `tests/unit/test_chapter_view.gd`, also change the four `var status_readout: Label = ...` declarations to `var colophon: Label = ...` and update their uses. Where a test names `_update_background`, rename the call to `_update_place_inset`. In `tests/unit/test_chapter_view_background.gd`, rename the variable `background` to `place_inset` for clarity.

Leave the two `MarginPopup` assertions alone for now — Task 7 deletes them with the scene.

- [ ] **Step 6: Run the full suite**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`

Expected: the new choice-height test passes and all repointed tests pass. The two `MarginPopup` tests still pass — the scene file still exists, it is simply no longer instanced inside ChapterView, so remove the `chapter_view.get_node("MarginPopup")` assertion in `test_chapter_view.gd` if it fails; the standalone popup-rendering test is untouched. Failures should be limited to the 12 known-stale content assertions.

- [ ] **Step 7: Commit**

```bash
git add scenes/chapter_view/ChapterView.tscn scenes/chapter_view/ChapterView.gd tests/unit/test_chapter_view.gd tests/unit/test_chapter_view_portraits.gd tests/unit/test_chapter_view_background.gd
git commit -m "refactor: rebuild ChapterView as a container-driven folio"
```

---

### Task 5: Wire the inset scale

The inset currently sizes itself to whatever the container gives it. This binds it to `FolioMetrics` so it lands on integer multiples and yields width to long prose.

**Files:**
- Modify: `scenes/chapter_view/ChapterView.gd` (`_update_place_inset`)
- Test: `tests/unit/test_chapter_view_background.gd`

**Interfaces:**
- Consumes: `FolioMetrics.choose_place_scale()`, `FolioMetrics.PLACE_BASE_WIDTH`, `FolioMetrics.PLACE_BASE_HEIGHT` from Task 2.
- Produces: nothing new for later tasks.

- [ ] **Step 1: Write the failing test**

Append to `tests/unit/test_chapter_view_background.gd`.

**These tests must pass dimensions in explicitly.** In a `--headless` GUT run no
frame is drawn, so container layout never happens and `page.size` is `(0, 0)`.
A test that lets the code measure would exercise the fallback branch and prove
nothing about the arithmetic. `FolioMetrics`' own unit tests cover the maths;
these cover the *wiring*, so they feed known numbers.

```gdscript
func _view_with_text(text: String):
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.dialogue_engine.load_tree([{"id": "n01", "text": text, "choices": []}], "n01")
	# A stand-in texture at the real source size - _resize_place_inset() returns
	# early when the texture is null.
	var image := Image.create_empty(
		FolioMetrics.PLACE_BASE_WIDTH, FolioMetrics.PLACE_BASE_HEIGHT, false, Image.FORMAT_RGBA8
	)
	image.fill(Color.RED)
	chapter_view.place_inset.texture = ImageTexture.create_from_image(image)
	return chapter_view

func test_place_inset_is_sized_to_an_integer_multiple_of_the_source_art():
	var chapter_view = _view_with_text("Short.")
	chapter_view._resize_place_inset(1060.0, 600.0)
	var width := chapter_view.place_inset.custom_minimum_size.x
	assert_gt(width, 0.0, "the inset must be given an explicit size")
	assert_eq(int(width) % FolioMetrics.PLACE_BASE_WIDTH, 0,
		"inset width %d must be a whole multiple of %d" % [int(width), FolioMetrics.PLACE_BASE_WIDTH])

func test_place_inset_keeps_the_source_aspect_ratio():
	var chapter_view = _view_with_text("Short.")
	chapter_view._resize_place_inset(1060.0, 600.0)
	var scale := chapter_view.place_inset.custom_minimum_size.x / float(FolioMetrics.PLACE_BASE_WIDTH)
	assert_eq(chapter_view.place_inset.custom_minimum_size.y, FolioMetrics.PLACE_BASE_HEIGHT * scale)

func test_a_short_node_gets_a_larger_inset_than_the_1135_character_prologue_node():
	var short_view = _view_with_text("Short.")
	short_view._resize_place_inset(1060.0, 600.0)

	# The real prologue n12_departure length. Built as a string of the right size
	# rather than read from disk so the test does not break if the prose is edited.
	var long_view = _view_with_text("x".repeat(1135))
	long_view._resize_place_inset(1060.0, 600.0)

	assert_gt(short_view.place_inset.custom_minimum_size.x, long_view.place_inset.custom_minimum_size.x,
		"long prose must claw width back from the inset")
	assert_eq(long_view.place_inset.custom_minimum_size.x, float(FolioMetrics.PLACE_BASE_WIDTH),
		"the 1135-character node should land on 1x")

func test_inset_collapses_when_the_chapter_has_no_place_art():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.dialogue_engine.load_tree([{"id": "n01", "text": "Short.", "choices": []}], "n01")
	chapter_view.place_inset.texture = null
	chapter_view._resize_place_inset(1060.0, 600.0)
	assert_eq(chapter_view.place_inset.custom_minimum_size, Vector2.ZERO)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_chapter_view_background.gd -gexit`

Expected: FAIL — `_resize_place_inset()` does not exist, so the call errors out.

- [ ] **Step 3: Size the inset from FolioMetrics**

In `scenes/chapter_view/ChapterView.gd`, add to the end of `_update_place_inset()`:

```gdscript
	_resize_place_inset()

# Average character width and line height for the narration font. Taken from the
# theme's RichTextLabel normal_font_size of 22 in EB Garamond; passed into
# FolioMetrics so that engine/ stays free of scene-tree types.
const _NARRATION_CHAR_WIDTH := 10.0
const _NARRATION_LINE_HEIGHT := 31.0
const _HEAD_BLOCK_GUTTER := 12.0

# Dimensions are parameters, not measurements, so this is testable without a
# rendered frame: in a headless run container layout never happens and every
# measured size is zero. Callers in the live scene pass nothing and get the
# measured values; tests pass known numbers.
func _resize_place_inset(available_width: float = -1.0, available_height: float = -1.0) -> void:
	if place_inset.texture == null:
		place_inset.custom_minimum_size = Vector2.ZERO
		return
	if available_width < 0.0:
		available_width = _measured_available_width()
	if available_height < 0.0:
		available_height = _measured_available_height()
	var character_count: int = str(dialogue_engine.current_node().get("text", "")).length()
	var scale := FolioMetrics.choose_place_scale(
		character_count,
		available_width,
		available_height,
		_HEAD_BLOCK_GUTTER,
		_NARRATION_CHAR_WIDTH,
		_NARRATION_LINE_HEIGHT
	)
	place_inset.custom_minimum_size = Vector2(
		FolioMetrics.PLACE_BASE_WIDTH * scale,
		FolioMetrics.PLACE_BASE_HEIGHT * scale
	)

func _measured_available_width() -> float:
	var page: Control = get_node(_PAGE)
	var margin_column: Control = get_node("%s/MarginColumn" % _PAGE)
	var width := page.size.x - margin_column.custom_minimum_size.x
	# Before the first frame every rect is zero; fall back to the reference page.
	return width if width > 0.0 else float(FolioMetrics.NARRATION_MAX_WIDTH)

func _measured_available_height() -> float:
	var head_block: Control = get_node("%s/TextColumn/HeadBlock" % _PAGE)
	var height := head_block.size.y
	return height if height > 0.0 else float(FolioMetrics.PLACE_BASE_HEIGHT)
```

- [ ] **Step 4: Run test to verify it passes**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_chapter_view_background.gd -gexit`

Expected: PASS — 4 tests. The stand-in texture is built in memory, so these do not depend on any PNG being present in the checkout.

- [ ] **Step 5: Commit**

```bash
git add scenes/chapter_view/ChapterView.gd tests/unit/test_chapter_view_background.gd
git commit -m "feat: size the place inset to integer scales via FolioMetrics"
```

---

### Task 6: Colophon shows the chapter's place name

The one behavioural change to the status line. Today it shows coin, debt, and reputations; the folio design puts the place name at the head.

**Files:**
- Modify: `scenes/chapter_view/ChapterView.gd` (`_update_colophon`)
- Modify: `content/chapters/manifest.json`
- Test: `tests/unit/test_chapter_view.gd`

**Interfaces:**
- Consumes: the manifest entry loaded in `load_chapter_by_id()`.
- Produces: `ChapterView.place_name: String`, defaulting to `""`.

- [ ] **Step 1: Write the failing test**

Append to `tests/unit/test_chapter_view.gd`:

```gdscript
func test_colophon_leads_with_the_chapter_place_name():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter_by_id("chapter_06_pushang")
	var colophon: Label = chapter_view.get_node("Folio/FolioMargin/Page/TextColumn/Colophon")
	assert_true(colophon.text.begins_with("Pushang"),
		"expected the place name at the head of the colophon, got: %s" % colophon.text)

func test_colophon_omits_the_place_name_when_the_manifest_gives_none():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.place_name = ""
	chapter_view.dialogue_engine.load_tree([{"id": "n01", "text": "", "choices": []}], "n01")
	chapter_view._update_colophon()
	var colophon: Label = chapter_view.get_node("Folio/FolioMargin/Page/TextColumn/Colophon")
	assert_true(colophon.text.begins_with("Coin:"),
		"with no place name the line should start at the coin, got: %s" % colophon.text)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_chapter_view.gd -gexit`

Expected: FAIL — `place_name` is not a property, and the colophon still begins with `Coin:`.

- [ ] **Step 3: Add place names to the manifest**

Add a `"place_name"` key to each entry in `content/chapters/manifest.json`, using the city the chapter is set in: `chapter_00_prologue` → `"Ghazni"`, `chapter_01_teginabad` → `"Teginabad"`, `chapter_02_bost` → `"Bost"`, `chapter_03_farah` → `"Farah"`, `chapter_04a_herat` → `"Herat"`, `chapter_04b_herat_favor` → `"Herat"`, `chapter_05_plunder_ending` → `"Herat"`, `chapter_06_pushang` → `"Pushang"`, `chapter_07_sarakhs` → `"Sarakhs"`, `chapter_07b_merv` → `"Merv"`, `chapter_08_nishapur` → `"Nishapur"`.

These 11 ids were verified against `content/chapters/manifest.json` when this plan was written; every entry currently has exactly `dialogue_path`, `glossary_path`, `next_chapter_id`, and `farrukh_wear_stage`, with `chapter_05_plunder_ending` additionally carrying `post_ending_cutscene_path`. Add `place_name` alongside them without disturbing the existing keys.

- [ ] **Step 4: Read and use the key**

In `scenes/chapter_view/ChapterView.gd`, add the property beside `chapter_id`:

```gdscript
var place_name: String = ""
```

In `load_chapter_by_id()`, after the existing `farrukh_wear_stage` assignment:

```gdscript
	place_name = str(entry.get("place_name", ""))
```

In `_update_colophon()`, seed the parts array with the place name before the coin entry:

```gdscript
	var parts: Array[String] = []
	if place_name != "":
		parts.append(place_name)
	parts.append("Coin: %.1f dirham" % wealth)
```

- [ ] **Step 5: Run test to verify it passes**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_chapter_view.gd -gexit`

Expected: PASS, including the four pre-existing colophon-composition tests.

- [ ] **Step 6: Commit**

```bash
git add scenes/chapter_view/ChapterView.gd content/chapters/manifest.json tests/unit/test_chapter_view.gd
git commit -m "feat: lead the colophon with the chapter's place name"
```

---

### Task 7: Glosses in the margin; retire the popup

Glosses stop being a click-to-open popup and become notes that appear in the margin for whatever the current node references. 200 of 229 nodes have none, and the maximum anywhere is 2, so the margin never crowds.

Glossed terms must also stop rendering as links. `GlossedTextParser.parse_to_bbcode()`
wraps each term in `[url=...]`, which `RichTextLabel` draws as a clickable link. With
the popup gone a click would do nothing, leaving a dead affordance — worse than no
affordance at all. So the terms keep a visual mark but lose the link.

**Files:**
- Modify: `engine/margin/GlossedTextParser.gd` (add a marked, non-link rendering)
- Modify: `scenes/chapter_view/ChapterView.gd` (`_render_current_node`, `_on_narration_meta_clicked`)
- Delete: `scenes/margin_popup/MarginPopup.tscn`, `scenes/margin_popup/MarginPopup.gd`
- Test: `tests/unit/test_glossed_text_parser.gd`, `tests/unit/test_chapter_view.gd`

**Interfaces:**
- Consumes: `GlossedTextParser.extract_term_ids()`, `MarginGlossary.get_entry()`.
- Produces: `GlossedTextParser.parse_to_marked_bbcode(raw_text: String, mark_color: Color) -> String`, `ChapterView._update_gloss_notes()`.

- [ ] **Step 1: Write the failing test**

In `tests/unit/test_chapter_view.gd`, delete `test_margin_popup_renders_headword_and_definition_for_each_entry` and the `MarginPopupScene` preload, then append:

```gdscript
func test_gloss_notes_render_one_note_per_glossed_term_in_the_node():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.margin_glossary.load_entries({
		"dallal": {"headword": "Dallal", "definition": "A broker who matches buyers to sellers for a cut."},
		"amana": {"headword": "Amana", "definition": "Property held in trust, owed back intact."},
	})
	chapter_view.dialogue_engine.load_tree([{
		"id": "n01",
		"text": "The {{dallal|dallal}} held it as {{amana|amana}}.",
		"choices": [],
	}], "n01")
	chapter_view._render_current_node()

	var gloss_notes: VBoxContainer = chapter_view.get_node("Folio/FolioMargin/Page/MarginColumn/GlossNotes")
	assert_eq(gloss_notes.get_child_count(), 2)
	var rendered := ""
	for note in gloss_notes.get_children():
		rendered += note.text
	assert_true(rendered.contains("Dallal"))
	assert_true(rendered.contains("A broker who matches buyers to sellers for a cut."))
	assert_true(rendered.contains("Amana"))

func test_gloss_notes_are_empty_for_a_node_with_no_glossed_terms():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.dialogue_engine.load_tree([{"id": "n01", "text": "Plain prose.", "choices": []}], "n01")
	chapter_view._render_current_node()
	var gloss_notes: VBoxContainer = chapter_view.get_node("Folio/FolioMargin/Page/MarginColumn/GlossNotes")
	assert_eq(gloss_notes.get_child_count(), 0)

func test_gloss_notes_clear_when_moving_to_a_node_with_fewer_terms():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.margin_glossary.load_entries({
		"dallal": {"headword": "Dallal", "definition": "A broker."},
	})
	chapter_view.dialogue_engine.load_tree([{"id": "n01", "text": "A {{dallal|dallal}}.", "choices": []}], "n01")
	chapter_view._render_current_node()
	var gloss_notes: VBoxContainer = chapter_view.get_node("Folio/FolioMargin/Page/MarginColumn/GlossNotes")
	assert_eq(gloss_notes.get_child_count(), 1, "sanity check: must be populated first")

	chapter_view.dialogue_engine.load_tree([{"id": "n02", "text": "Plain prose.", "choices": []}], "n02")
	chapter_view._render_current_node()
	assert_eq(gloss_notes.get_child_count(), 0)

func test_glossed_terms_are_still_unlocked_so_the_save_format_is_unchanged():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.margin_glossary.load_entries({
		"dallal": {"headword": "Dallal", "definition": "A broker."},
	})
	chapter_view.dialogue_engine.load_tree([{"id": "n01", "text": "A {{dallal|dallal}}.", "choices": []}], "n01")
	chapter_view._render_current_node()
	assert_true(chapter_view.margin_glossary.is_unlocked("dallal"))

func test_narration_marks_glossed_terms_without_making_them_dead_links():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.dialogue_engine.load_tree([{"id": "n01", "text": "A {{dallal|dallal}}.", "choices": []}], "n01")
	chapter_view._render_current_node()
	var narration_label: RichTextLabel = chapter_view.get_node("Folio/FolioMargin/Page/TextColumn/HeadBlock/NarrationLabel")
	assert_false(narration_label.text.contains("[url"),
		"the popup is gone, so a link affordance would do nothing when clicked")
	assert_true(narration_label.text.contains("dallal"), "the term itself must still be shown")
```

Also append to `tests/unit/test_glossed_text_parser.gd`:

```gdscript
func test_parse_to_marked_bbcode_colours_the_term_instead_of_linking_it():
	var marked := GlossedTextParser.parse_to_marked_bbcode(
		"He paid the {{dallal|dallal}} his cut.", Color("#7a1f14")
	)
	assert_false(marked.contains("[url"), "must not produce a link")
	assert_true(marked.contains("[color=#7a1f14]dallal[/color]"))
	assert_true(marked.begins_with("He paid the "))

func test_parse_to_marked_bbcode_handles_multi_term_tokens():
	var marked := GlossedTextParser.parse_to_marked_bbcode(
		"held as {{dallal,amana|a broker's trust}}", Color("#7a1f14")
	)
	assert_true(marked.contains("[color=#7a1f14]a broker's trust[/color]"))

func test_parse_to_marked_bbcode_leaves_unglossed_prose_untouched():
	assert_eq(GlossedTextParser.parse_to_marked_bbcode("Plain prose.", Color("#7a1f14")), "Plain prose.")

func test_parse_to_bbcode_still_produces_links_for_any_other_caller():
	# The original function is unchanged; only ChapterView switches away from it.
	assert_true(GlossedTextParser.parse_to_bbcode("a {{dallal|dallal}}").contains("[url=dallal]"))
```

If `tests/unit/test_glossed_text_parser.gd` does not exist, create it with
`extends GutTest` at the top.

- [ ] **Step 2: Run test to verify it fails**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_chapter_view.gd -gexit`

Expected: FAIL — `_update_gloss_notes()` does not exist, so `GlossNotes` has no children.

- [ ] **Step 3: Add the marked, non-link rendering**

In `engine/margin/GlossedTextParser.gd`, add alongside the existing functions. It
reuses the same `_token_regex()`, so the token format stays defined in one place:

```gdscript
# Same tokens as parse_to_bbcode(), but marked with colour rather than wrapped in
# [url]. ChapterView shows glosses permanently in the folio margin, so a link
# would be an affordance with nothing behind it.
static func parse_to_marked_bbcode(raw_text: String, mark_color: Color) -> String:
	var regex := _token_regex()
	var result := raw_text
	var mark_hex := "#" + mark_color.to_html(false)
	for match_result in regex.search_all(raw_text):
		var display_text: String = match_result.get_string(2)
		var token: String = match_result.get_string(0)
		result = result.replace(token, "[color=%s]%s[/color]" % [mark_hex, display_text])
	return result
```

- [ ] **Step 4: Render notes into the margin**

In `scenes/chapter_view/ChapterView.gd`, switch the narration assignment in
`_render_current_node()` over to the marked rendering and call the new helper
after it:

```gdscript
	narration_label.text = GlossedTextParser.parse_to_marked_bbcode(
		node.get("text", ""), BorrowedFortuneTheme.RUBRIC_RED
	)
	_update_gloss_notes()
```

Delete the `narration_label.meta_clicked.connect(_on_narration_meta_clicked)` line
from `_ready()` and delete `_on_narration_meta_clicked()` entirely — no `[url]` is
emitted any more, so the signal can never fire and an empty handler would only
mislead the next reader. `_ready()` may end up with no body at all; if so, remove
the function.

Then add the helper:

```gdscript
func _update_gloss_notes() -> void:
	for child in gloss_notes.get_children():
		child.queue_free()
	var raw_text: String = dialogue_engine.current_node().get("text", "")
	for term_id in GlossedTextParser.extract_term_ids(raw_text):
		if not margin_glossary.has_entry(term_id):
			continue
		# Unlocking is kept for save-format compatibility: unlocked_term_ids() is
		# still written into GameState by _save_and_finish().
		margin_glossary.unlock(term_id)
		var entry: Dictionary = margin_glossary.get_entry(term_id)
		var note := Label.new()
		note.theme_type_variation = &"GlossNote"
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.text = "%s — %s" % [entry.get("headword", term_id), entry.get("definition", "")]
		gloss_notes.add_child(note)
```

- [ ] **Step 5: Run both test files to verify they pass**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_chapter_view.gd,res://tests/unit/test_glossed_text_parser.gd -gexit`

Expected: PASS — five new ChapterView tests and four parser tests.

- [ ] **Step 6: Delete the popup**

```bash
git rm scenes/margin_popup/MarginPopup.tscn scenes/margin_popup/MarginPopup.gd
```

Then grep for stragglers and remove any remaining reference:

```bash
grep -rn "MarginPopup\|margin_popup" --include='*.gd' --include='*.tscn' . | grep -v '/addons/'
```

Expected after cleanup: no matches.

- [ ] **Step 7: Run the full suite**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`

Expected: green apart from the 12 known-stale content assertions.

- [ ] **Step 8: Commit**

```bash
git add -A scenes/ engine/margin/GlossedTextParser.gd tests/unit/test_chapter_view.gd tests/unit/test_glossed_text_parser.gd
git commit -m "feat: move glosses into the folio margin and retire MarginPopup"
```

---

### Task 8: Remove the superseded theme variations

`PortraitCard` and `DialogueParchment` are referenced by ChapterView and nothing else. With ChapterView rebuilt they are dead.

**Files:**
- Modify: `engine/theme/BorrowedFortuneTheme.gd` (`_apply_panel_style`)
- Modify: `theme/borrowed_fortune_theme.tres` (regenerated)
- Test: `tests/unit/test_borrowed_fortune_theme.gd`

**Interfaces:**
- Consumes: nothing.
- Produces: `Folio` and `Roundel` are the only panel variations.

- [ ] **Step 1: Confirm they really are unused**

```bash
grep -rn "PortraitCard\|DialogueParchment" --include='*.gd' --include='*.tscn' . | grep -v '/addons/'
```

Expected: matches only in `engine/theme/BorrowedFortuneTheme.gd` and `tests/unit/test_borrowed_fortune_theme.gd`. If any scene still references either name, stop and fix that scene first.

- [ ] **Step 2: Write the failing test**

In `tests/unit/test_borrowed_fortune_theme.gd`, replace the existing `PortraitCard` assertion (the test containing `theme.get_stylebox("panel", "PortraitCard")`) with:

```gdscript
func test_superseded_chapter_view_variations_are_gone():
	var theme := BorrowedFortuneTheme.build()
	assert_false(theme.has_stylebox("panel", "PortraitCard"),
		"PortraitCard was replaced by Roundel")
	assert_false(theme.has_stylebox("panel", "DialogueParchment"),
		"DialogueParchment was replaced by Folio")
```

- [ ] **Step 3: Run test to verify it fails**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_borrowed_fortune_theme.gd -gexit`

Expected: FAIL — both styleboxes are still registered.

- [ ] **Step 4: Remove the variations**

In `engine/theme/BorrowedFortuneTheme.gd`, reduce `_apply_panel_style()` to just the base panel, and delete the now-unused `_dialogue_parchment_stylebox()` helper:

```gdscript
static func _apply_panel_style(theme: Theme) -> void:
	theme.set_stylebox("panel", "Panel", _framed_panel_stylebox(4))
```

- [ ] **Step 5: Regenerate and test**

Run: `godot --headless --path . -s tools/build_theme.gd`

Then: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_borrowed_fortune_theme.gd -gexit`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add engine/theme/BorrowedFortuneTheme.gd theme/borrowed_fortune_theme.tres tests/unit/test_borrowed_fortune_theme.gd
git commit -m "refactor: drop the PortraitCard and DialogueParchment variations"
```

---

### Task 9: Verify the other five scenes under the new content scale

Task 1's settings are project-wide. `MainMenu`, `JourneyMapScreen`, `PrologueCutscene`, `EndingCutscene`, and `Main` all re-render under them. They are not redesigned here — only checked, and regressions fixed minimally.

**Files:**
- Create: `tests/integration/test_folio_layout.gd`
- Modify: `scenes/chapter_view/ChapterView.tscn` and `.gd` if the width-cap test fails (expected)
- Modify: only if a regression is found — `scenes/main_menu/MainMenu.tscn`, `scenes/journey_map/JourneyMapScreen.tscn`, `scenes/prologue_cutscene/PrologueCutscene.tscn`, `scenes/ending_cutscene/EndingCutscene.tscn`
- Test: `tests/unit/test_main_menu.gd`, `tests/unit/test_journey_map_screen.gd`

**Interfaces:**
- Consumes: the display settings from Task 1.
- Produces: nothing.

- [ ] **Step 1: Run the full suite**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`

Expected: green apart from the 12 known-stale content assertions. Record the exact failure count before continuing so the comparison later is honest.

- [ ] **Step 2: Write a layout test that runs at several window sizes**

The acceptance cases cannot be checked by driving the GUI — this may be running
headless with no one at the screen. Container layout, however, is computed on the
CPU, so resizing the root viewport and awaiting frames gives real rectangles.
GUT supports `await` in tests.

Create `tests/integration/test_folio_layout.gd`:

```gdscript
extends GutTest

const ChapterViewScene := preload("res://scenes/chapter_view/ChapterView.tscn")
const SIZES := [Vector2i(800, 600), Vector2i(1280, 720), Vector2i(2560, 1080)]

var _original_size: Vector2i

func before_all():
	_original_size = get_tree().root.size

func after_all():
	get_tree().root.size = _original_size

func _laid_out_view(text: String, choice_count: int, size: Vector2i):
	get_tree().root.size = size
	var choices := []
	for i in range(choice_count):
		choices.append({"text": "Choice number %d." % i, "next_id": "n01", "effects": {}})
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.dialogue_engine.load_tree([{"id": "n01", "text": text, "choices": choices}], "n01")
	chapter_view._render_current_node()
	# Two frames: one for the size change, one for containers to re-sort children.
	await get_tree().process_frame
	await get_tree().process_frame
	return chapter_view

func _node(view, path: String) -> Control:
	return view.get_node("Folio/FolioMargin/Page/%s" % path)

func test_four_choices_stay_inside_the_text_column_at_every_size():
	for size in SIZES:
		var view = await _laid_out_view("An officer at the gate named a sum.", 4, size)
		var choices := _node(view, "TextColumn/ChoicesContainer")
		var column := _node(view, "TextColumn")
		assert_eq(choices.get_child_count(), 4, "at %s" % size)
		assert_lte(choices.global_position.y + choices.size.y,
			column.global_position.y + column.size.y + 1.0,
			"choices overflow the text column at %s" % size)

func test_the_longest_node_is_not_clipped_at_every_size():
	var long_text := "x ".repeat(568)  # ~1135 characters, the prologue n12_departure length
	for size in SIZES:
		var view = await _laid_out_view(long_text, 1, size)
		var narration := _node(view, "TextColumn/HeadBlock/NarrationLabel")
		assert_gt(narration.size.y, 0.0, "narration has no height at %s" % size)
		# fit_content grows the label to its content; if the container had clamped it
		# the content height would exceed the drawn height.
		assert_lte(narration.get_content_height(), narration.size.y + 1.0,
			"narration is clipped at %s" % size)

func test_prose_column_never_exceeds_the_readability_cap():
	for size in SIZES:
		var view = await _laid_out_view("Short prose.", 2, size)
		var narration := _node(view, "TextColumn/HeadBlock/NarrationLabel")
		assert_lte(narration.size.x, float(FolioMetrics.NARRATION_MAX_WIDTH) + 1.0,
			"prose ran to %d px at %s, past the %d px cap" % [
				int(narration.size.x), size, FolioMetrics.NARRATION_MAX_WIDTH])

func test_margin_column_never_overlaps_the_text_column():
	for size in SIZES:
		var view = await _laid_out_view("Short prose.", 2, size)
		var column := _node(view, "TextColumn")
		var margin := _node(view, "MarginColumn")
		assert_lte(column.global_position.x + column.size.x, margin.global_position.x + 1.0,
			"text column runs into the margin at %s" % size)

func test_place_inset_stays_on_integer_scales_at_every_size():
	for size in SIZES:
		var view = await _laid_out_view("Short prose.", 2, size)
		var inset := _node(view, "TextColumn/HeadBlock/PlaceInset")
		if inset.texture == null:
			continue  # no place art in this checkout; nothing to scale
		assert_eq(int(inset.custom_minimum_size.x) % FolioMetrics.PLACE_BASE_WIDTH, 0,
			"inset off integer scale at %s" % size)
```

- [ ] **Step 3: Run it**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/integration/test_folio_layout.gd -gexit`

Expected: PASS. **`test_prose_column_never_exceeds_the_readability_cap` is the one
most likely to fail**, because nothing yet forces `NarrationLabel` to honour
`NARRATION_MAX_WIDTH` — that is the gap recorded in this plan's self-review. If it
fails, fix it now: add a trailing spacer to `HeadBlock` and cap the label.

In `ChapterView.tscn`, append to `HeadBlock`:

```
[node name="HeadSpacer" type="Control" parent="Folio/FolioMargin/Page/TextColumn/HeadBlock"]
layout_mode = 2
size_flags_horizontal = 3
```

And in `_resize_place_inset()`, after setting the inset size:

```gdscript
	narration_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	narration_label.custom_minimum_size.x = FolioMetrics.narration_width(
		available_width - place_inset.custom_minimum_size.x - _HEAD_BLOCK_GUTTER
	)
```

Then re-run until green.

- [ ] **Step 4: Fix any regression in the other scenes minimally**

If a scene breaks, prefer swapping the offending absolute offsets for a container over adjusting numbers — the same fix this plan applied to ChapterView. Do not redesign; these scenes have their own pass ahead of them. `MainMenu.tscn` has 12 offsets and `JourneyMapScreen.tscn` 16, so any fix should be small and local.

- [ ] **Step 5: Record what could not be verified without a display**

Two acceptance criteria from the spec are genuinely visual and no headless test
covers them:

1. **Pixel art reads crisp rather than smoothed.** Task 1's test proves the
   setting is `0` (Nearest); it cannot prove the pixels look right.
2. **The composition is pleasing** at each window size — the tests prove nothing
   overlaps or clips, not that it looks good.

If a display is available, run `godot --path .` and check both by eye. If not, say
plainly in the final report that these two remain unverified rather than implying
they passed.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "fix: keep the remaining scenes correct under the new content scale"
```

---

## Self-Review

**Spec coverage.** Each spec section maps to a task: display and rendering config → Task 1; inset scale selection → Tasks 2 and 5; theme → Tasks 3 and 8; layout regions and the node tree → Task 4; colophon → Task 6; gloss margin and popup retirement → Task 7; the five verified-not-redesigned scenes → Task 9. The spec's testing section is distributed across the tasks that create each behavior. The spec's out-of-scope items (controls, the per-render asset reload, README staleness) intentionally have no task.

**The runtime width cap.** `FolioMetrics.narration_width()` defines the cap and is unit-tested in Task 2, but the scene tree built in Task 4 does not enforce it — a `RichTextLabel` with `size_flags_horizontal = 3` expands to whatever its container gives. Rather than leave this to be noticed later, Task 9 Step 3 tests for it directly at 2560px wide and carries the fix inline (a trailing spacer in `HeadBlock` plus a `custom_minimum_size.x` assignment). Expect that test to fail on first run; that is the plan working, not a surprise.

**Verification honesty.** Two spec acceptance criteria — that the pixel art reads crisp, and that the composition looks good at each size — cannot be proven headlessly. Task 9 Step 5 requires reporting them as unverified rather than implying they passed.

**Type consistency.** `FolioMetrics.choose_place_scale()` and `narration_width()` keep identical signatures in Tasks 2 and 5. `_update_place_inset()`, `_update_colophon()`, and `_update_gloss_notes()` are named consistently from Task 4 onward. The `_PAGE` constant introduced in Task 4 is reused in Task 5. Node paths in the tests match the tree defined in Task 4 exactly.
