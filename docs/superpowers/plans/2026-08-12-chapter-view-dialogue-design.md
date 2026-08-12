# Chapter View Dialogue Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rework `ChapterView`'s dialogue presentation — a bottom-anchored cream parchment panel with black EB Garamond text, much larger framed portraits, and a matching restyle of the glossary popup — per `docs/superpowers/specs/2026-08-12-chapter-view-dialogue-design.md`.

**Architecture:** Five new entries added to the existing `BorrowedFortuneTheme.gd` builder (a default `Panel` style, two `Panel` type variations, a `RichTextLabel` color/size default, a `VScrollBar` style) cover `MarginPopup` and the new dialogue panel with zero or minimal scene edits. `ChapterView.tscn` gets a new `DialogueParchment` panel (absorbing the re-parented `NarrationLabel`/`ChoicesContainer`) and two new portrait-card wrapper panels. Portraits regenerate at a higher source resolution via the existing pixellab pipeline.

**Tech Stack:** Godot 4.3 / GDScript, GUT (headless), Python 3 + pixellab SDK (offline dev tool, not shipped).

## Global Constraints

- Godot 4.3.
- Test baseline confirmed on `master` just before this plan was written: **280 tests, 279 passing + 1 pre-existing harmless "risky" zero-assertion test** (`test_every_glossed_term_id_exists_in_the_merv_glossary`, unrelated — do not attempt to fix it), 1097 asserts.
- `master`'s `.godot/global_script_class_cache.cfg` is already primed from earlier work this session. This plan adds no new `class_name` file, so a fresh worktree branched from `master` should not need re-priming for that reason — but a fresh worktree's `.godot/` is gitignored and per-checkout, so if the very first GUT run in the worktree fails with class-resolution errors, prime once (`godot --headless --path . --editor --quit`, expect a harmless SIGSEGV) and re-run; don't prime pre-emptively or twice.
- **Real, verified gotcha — do not use `theme.set_font_size("font_size", "RichTextLabel", ...)`.** `RichTextLabel`'s real, engine-recognized font-size property is `normal_font_size`, not `font_size` (confirmed by querying `ThemeDB.get_default_theme().get_font_size_list("RichTextLabel")` directly against this Godot 4.3 build: `["normal_font_size", "bold_font_size", "italics_font_size", "bold_italics_font_size", "mono_font_size"]` — no bare `"font_size"` entry exists for this type). Setting the wrong key doesn't error, it's just silently inert. Confirmed-correct property names for this plan's other new Theme entries, same method: `RichTextLabel` color `"default_color"`; `VScrollBar` styleboxes `"scroll"`, `"scroll_focus"`, `"grabber"`, `"grabber_highlight"`, `"grabber_pressed"`.
- No shaders anywhere in this codebase. `StyleBoxFlat` has no gradient support — every new fill in this plan is a flat color, not a gradient (matching the already-shipped boxed buttons, which simplified the same way from their own early mockups).
- Any pixellab-generated PNG loads at runtime via raw `FileAccess.file_exists()` + `Image.load_from_file()` + `ImageTexture.create_from_image()` — never Godot's `load()`/resource-import pipeline. `ChapterView.gd`'s `_load_portrait_texture()` already does this correctly and needs no change for this plan.
- Font `.ttf` files load via `FontFile.new()` + `load_dynamic_font(path)`, never `load()`/`preload()` — not touched by this plan (no new font), but this remains the rule if any future task needs one.
- Standing project override in effect: **no reviewer subagent dispatch at any stage** — this overrides subagent-driven-development's default per-task reviewer step. The controller self-verifies every diff (`git diff`) and every test run directly instead.
- Commit per task.
- Isolation: `git worktree add -b chapter-view-dialogue master .worktrees/chapter-view-dialogue` from the repo root — not the generic `EnterWorktree` tool, per this project's established convention.
- Portrait regeneration (Task 2) is a real, funded pixellab API call (16 generations) — run it as an explicit, visible step, not silently.

---

## File Structure

| File | Task | Purpose |
|---|---|---|
| `engine/theme/BorrowedFortuneTheme.gd` | 1 | Modify — 5 new Theme entries |
| `theme/borrowed_fortune_theme.tres` | 1 | Regenerate via `tools/build_theme.gd` |
| `tests/unit/test_borrowed_fortune_theme.gd` | 1 | Modify — new assertions for the 5 entries |
| `tools/pixellab/generate_portraits.py` | 2 | Modify — `PORTRAIT_SIZE` 96→200 |
| `assets/portraits/*.png` (16 files) | 2 | Regenerate at 200x200 |
| `scenes/chapter_view/ChapterView.tscn` | 3 | Modify — `DialogueParchment` + portrait cards |
| `scenes/chapter_view/ChapterView.gd` | 3 | Modify — 4 `@onready` path updates |
| `tests/unit/test_chapter_view.gd` | 3 | Modify — 1 path update |

---

### Task 1: Theme additions for the parchment panel, portrait cards, and scrollbar

**Files:**
- Modify: `engine/theme/BorrowedFortuneTheme.gd`
- Modify (regenerate): `theme/borrowed_fortune_theme.tres`
- Modify: `tests/unit/test_borrowed_fortune_theme.gd`

**Interfaces:**
- Consumes: the existing `BorrowedFortuneTheme.build() -> Theme` method and its existing `_boxed_stylebox()`/`_focus_stylebox()` helpers — this task adds new static methods alongside `_apply_global_button_style()` etc., does not replace anything.
- Produces: three new type-variation/default-style names Task 3 will reference by string in `ChapterView.tscn`: the default `Panel` style (no variation name needed — it's the bare type default), `"DialogueParchment"` (a `Panel` variation), `"PortraitCard"` (a `Panel` variation). Also a global `RichTextLabel` color/size default and a global `VScrollBar` style, neither of which Task 3 needs to reference by name (they apply automatically to any `RichTextLabel`/`VScrollBar` in the scene tree).

- [ ] **Step 1: Add the new color constants**

In `engine/theme/BorrowedFortuneTheme.gd`, add these constants alongside the existing ones (after `BANNER_TEXT_DISABLED`):

```gdscript
const GOLD := Color("#c9a24b")
const PARCHMENT_FILL := Color("#e3d5aa")
const INK_TEXT := Color("#241a10")
const SCROLLBAR_TRACK := Color(0.353, 0.255, 0.118, 0.15)
const SCROLLBAR_GRABBER_HIGHLIGHT := Color("#d9b25e")
const SCROLLBAR_GRABBER_PRESSED := Color("#a8823a")
```

- [ ] **Step 2: Add the Panel styles**

Add these two new static methods anywhere after `_apply_banner_title_variation()`:

```gdscript
static func _apply_panel_style(theme: Theme) -> void:
	theme.set_stylebox("panel", "Panel", _framed_panel_stylebox(4))

	theme.set_type_variation("DialogueParchment", "Panel")
	theme.set_stylebox("panel", "DialogueParchment", _dialogue_parchment_stylebox())

	theme.set_type_variation("PortraitCard", "Panel")
	theme.set_stylebox("panel", "PortraitCard", _boxed_stylebox(BUTTON_FILL_NORMAL, GOLD))

static func _framed_panel_stylebox(corner_radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = PARCHMENT_FILL
	box.border_color = GOLD
	box.set_border_width_all(3)
	box.set_corner_radius_all(corner_radius)
	return box

static func _dialogue_parchment_stylebox() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = PARCHMENT_FILL
	box.border_color = GOLD
	box.border_width_top = 3
	return box
```

Note `_boxed_stylebox(BUTTON_FILL_NORMAL, GOLD)` for `"PortraitCard"` reuses the existing helper and the existing `BUTTON_FILL_NORMAL` constant directly — the portrait cards are the exact same brown-and-gold boxed material as the buttons, confirmed via the approved mockup, not a new color.

- [ ] **Step 3: Add the RichTextLabel and VScrollBar styles**

```gdscript
static func _apply_richtextlabel_defaults(theme: Theme) -> void:
	theme.set_color("default_color", "RichTextLabel", INK_TEXT)
	theme.set_font_size("normal_font_size", "RichTextLabel", 22)

static func _apply_scrollbar_style(theme: Theme) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = SCROLLBAR_TRACK
	track.set_corner_radius_all(2)

	var grabber := StyleBoxFlat.new()
	grabber.bg_color = GOLD
	grabber.set_corner_radius_all(2)

	var grabber_highlight := StyleBoxFlat.new()
	grabber_highlight.bg_color = SCROLLBAR_GRABBER_HIGHLIGHT
	grabber_highlight.set_corner_radius_all(2)

	var grabber_pressed := StyleBoxFlat.new()
	grabber_pressed.bg_color = SCROLLBAR_GRABBER_PRESSED
	grabber_pressed.set_corner_radius_all(2)

	theme.set_stylebox("scroll", "VScrollBar", track)
	theme.set_stylebox("scroll_focus", "VScrollBar", track)
	theme.set_stylebox("grabber", "VScrollBar", grabber)
	theme.set_stylebox("grabber_highlight", "VScrollBar", grabber_highlight)
	theme.set_stylebox("grabber_pressed", "VScrollBar", grabber_pressed)
```

- [ ] **Step 4: Call the new methods from `build()`**

Update `build()` to call all four new methods:

```gdscript
static func build() -> Theme:
	var theme := Theme.new()
	theme.default_font = _load_font(REGULAR_FONT_PATH)

	_apply_global_button_style(theme)
	_apply_banner_button_variation(theme)
	_apply_banner_title_variation(theme)
	_apply_panel_style(theme)
	_apply_richtextlabel_defaults(theme)
	_apply_scrollbar_style(theme)

	return theme
```

- [ ] **Step 5: Add new test assertions**

Add these functions to `tests/unit/test_borrowed_fortune_theme.gd` (same file, same pattern as the existing 6 tests — asserting exact builder output, not rendering):

```gdscript
func test_default_panel_style_is_parchment_with_gold_border():
	var theme := BorrowedFortuneTheme.build()
	var panel_style: StyleBoxFlat = theme.get_stylebox("panel", "Panel")
	assert_eq(panel_style.bg_color, Color("#e3d5aa"))
	assert_eq(panel_style.border_color, Color("#c9a24b"))

func test_dialogue_parchment_variation_has_a_top_only_border():
	var theme := BorrowedFortuneTheme.build()
	var panel_style: StyleBoxFlat = theme.get_stylebox("panel", "DialogueParchment")
	assert_eq(panel_style.border_width_top, 3)
	assert_eq(panel_style.border_width_bottom, 0)
	assert_eq(panel_style.border_width_left, 0)
	assert_eq(panel_style.border_width_right, 0)

func test_portrait_card_variation_is_brown_not_cream():
	var theme := BorrowedFortuneTheme.build()
	var panel_style: StyleBoxFlat = theme.get_stylebox("panel", "PortraitCard")
	assert_eq(panel_style.bg_color, Color("#3d2a15"))

func test_richtextlabel_default_color_is_ink_black():
	var theme := BorrowedFortuneTheme.build()
	assert_eq(theme.get_color("default_color", "RichTextLabel"), Color("#241a10"))

func test_richtextlabel_font_size_uses_the_correct_property_name():
	var theme := BorrowedFortuneTheme.build()
	assert_eq(theme.get_font_size("normal_font_size", "RichTextLabel"), 22)

func test_scrollbar_grabber_is_gold():
	var theme := BorrowedFortuneTheme.build()
	var grabber_style: StyleBoxFlat = theme.get_stylebox("grabber", "VScrollBar")
	assert_eq(grabber_style.bg_color, Color("#c9a24b"))
```

- [ ] **Step 6: Regenerate the committed `.tres` and run tests**

```bash
godot --headless --path . -s tools/build_theme.gd
```

Expected: `Theme saved to res://theme/borrowed_fortune_theme.tres`, exit code 0.

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=tests/unit/test_borrowed_fortune_theme.gd -gexit
```

Expected: `12/12 passed` (the existing 6 plus the 6 new ones above).

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: 286 tests total (280 baseline + 6 new), 285 passing + the same 1 pre-existing risky test, no new failures.

- [ ] **Step 7: Commit**

```bash
git add engine/theme/BorrowedFortuneTheme.gd theme/borrowed_fortune_theme.tres tests/unit/test_borrowed_fortune_theme.gd
git commit -m "feat: add parchment panel, portrait card, and scrollbar Theme styles"
```

---

### Task 2: Regenerate portraits at 200x200

**Files:**
- Modify: `tools/pixellab/generate_portraits.py`
- Modify (regenerate): `assets/portraits/*.png` (16 files)

**Interfaces:**
- Consumes: nothing from Task 1 — fully independent.
- Produces: nothing consumed by Task 3 — `ChapterView.gd`'s `_load_portrait_texture()` already loads whatever PNG exists at `res://assets/portraits/<id>.png` via `Image.load_from_file()`, which doesn't care about the source resolution. Task 3's larger on-screen portrait size works correctly regardless of whether this task has run yet (older 96x96 files just look softer when scaled up until this task lands) — do not block Task 3 on this task's completion.

- [ ] **Step 1: Bump `PORTRAIT_SIZE`**

In `tools/pixellab/generate_portraits.py`, change line 25:

```python
PORTRAIT_SIZE = {"width": 200, "height": 200}
```

(from the current `{"width": 96, "height": 96}` — 200 is comfortably under pixflux's confirmed 400px cap and divisible by 4.)

- [ ] **Step 2: Run the regeneration**

This is a real, funded pixellab API call — 16 generations (13 NPCs + 3 Farrukh wear-stages).

```bash
/run/media/sulcjo/sulcjo-data/fun/borrowed-fortune/.venv-pixellab/bin/python3 tools/pixellab/generate_portraits.py --force
```

Expected: 16 `generated <id> -> ...` lines, no `FAILED` lines, a final `remaining balance:` line (note: this account's balance endpoint always prints `usd=0.0` regardless of real funding — that is not a failure signal, see project memory; a real failure shows as an explicit `FAILED <id>: ...` line or a `failed:` summary line).

- [ ] **Step 3: Verify all 16 files actually changed**

```bash
git status --short assets/portraits/
```

Expected: all 16 existing portrait PNG paths show as modified (`M`). If any file is missing from this list, that specific generation silently didn't happen — investigate before committing, don't assume success from the script's own printed output alone.

- [ ] **Step 4: Commit**

```bash
git add tools/pixellab/generate_portraits.py assets/portraits/
git commit -m "feat: regenerate portraits at 200x200 for the enlarged dialogue-box display size"
```

---

### Task 3: `ChapterView` restructure — parchment panel, portrait cards, bottom anchoring

**Files:**
- Modify: `scenes/chapter_view/ChapterView.tscn`
- Modify: `scenes/chapter_view/ChapterView.gd`
- Modify: `tests/unit/test_chapter_view.gd`

**Interfaces:**
- Consumes: `"DialogueParchment"` and `"PortraitCard"` `Panel` type variations (Task 1). Does not depend on Task 2's portrait regeneration having run (see Task 2's Interfaces note).
- Produces: nothing consumed by a later task — this is the last task in the plan.

- [ ] **Step 1: Restructure `ChapterView.tscn`**

Replace the full file with:

```
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scenes/chapter_view/ChapterView.gd" id="1"]
[ext_resource type="PackedScene" path="res://scenes/margin_popup/MarginPopup.tscn" id="2"]

[node name="ChapterView" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1")

[node name="Background" type="TextureRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
expand_mode = 1
stretch_mode = 6

[node name="StatusReadout" type="Label" parent="."]
layout_mode = 1
anchors_preset = 10
anchor_right = 1.0
offset_left = 16.0
offset_top = 16.0
offset_right = -16.0
offset_bottom = 40.0
theme_override_font_sizes/font_size = 14
theme_override_colors/font_color = Color(0.55, 0.55, 0.55, 1)
horizontal_alignment = 2

[node name="NpcPortraitCard" type="Panel" parent="."]
layout_mode = 1
anchors_preset = 2
anchor_top = 1.0
anchor_bottom = 1.0
offset_left = 16.0
offset_top = -488.0
offset_right = 236.0
offset_bottom = -268.0
theme_type_variation = &"PortraitCard"

[node name="NpcPortrait" type="TextureRect" parent="NpcPortraitCard"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 6.0
offset_top = 6.0
offset_right = -6.0
offset_bottom = -6.0
mouse_filter = 2
expand_mode = 1
stretch_mode = 5

[node name="FarrukhPortraitCard" type="Panel" parent="."]
layout_mode = 1
anchors_preset = 3
anchor_left = 1.0
anchor_top = 1.0
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = -236.0
offset_top = -488.0
offset_right = -16.0
offset_bottom = -268.0
theme_type_variation = &"PortraitCard"

[node name="FarrukhPortrait" type="TextureRect" parent="FarrukhPortraitCard"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 6.0
offset_top = 6.0
offset_right = -6.0
offset_bottom = -6.0
mouse_filter = 2
expand_mode = 1
stretch_mode = 5

[node name="DialogueParchment" type="Panel" parent="."]
layout_mode = 1
anchors_preset = 12
anchor_top = 1.0
anchor_right = 1.0
anchor_bottom = 1.0
offset_top = -260.0
theme_type_variation = &"DialogueParchment"

[node name="NarrationLabel" type="RichTextLabel" parent="DialogueParchment"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 24.0
offset_top = 16.0
offset_right = -24.0
offset_bottom = -108.0
bbcode_enabled = true
scroll_active = true

[node name="ChoicesContainer" type="VBoxContainer" parent="DialogueParchment"]
layout_mode = 1
anchors_preset = 12
anchor_top = 1.0
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 24.0
offset_top = -92.0
offset_right = -24.0
offset_bottom = -16.0

[node name="MarginPopup" parent="." instance=ExtResource("2")]
visible = false
layout_mode = 1
anchors_preset = 3
anchor_left = 1.0
anchor_top = 1.0
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = -336.0
offset_top = -216.0
offset_right = -8.0
offset_bottom = -8.0
```

Notes on the geometry: `DialogueParchment` is a fixed 260px-tall band spanning the bottom of the screen — `NarrationLabel` fills the top ~136px of it (scrolls internally if text overflows, via `scroll_active = true`, Godot's default for `RichTextLabel` — set explicitly here for clarity) and `ChoicesContainer` occupies a fixed ~76px band below it for up to a few choice buttons. Both portrait cards are 220x220, positioned directly above `DialogueParchment`'s top edge (`offset_bottom = -268.0` for both cards lines up with `DialogueParchment`'s own top edge at `offset_top = -260.0`, minus this scene's screen-edge margins). `NpcPortrait`/`FarrukhPortrait` each sit inset 6px inside their card (so the card's gold border shows all the way around the portrait image) and use `stretch_mode = 5` (`STRETCH_KEEP_ASPECT_CENTERED`) so a portrait doesn't distort to fill a non-matching aspect ratio. `MarginPopup` and `StatusReadout` are unchanged from the current file.

- [ ] **Step 2: Update `ChapterView.gd`'s `@onready` paths**

Change exactly these 4 lines (the other 3 — `margin_popup`, `status_readout`, `background` — are untouched):

```gdscript
@onready var narration_label: RichTextLabel = $DialogueParchment/NarrationLabel
@onready var choices_container: VBoxContainer = $DialogueParchment/ChoicesContainer
@onready var npc_portrait: TextureRect = $NpcPortraitCard/NpcPortrait
@onready var farrukh_portrait: TextureRect = $FarrukhPortraitCard/FarrukhPortrait
```

No other line in `ChapterView.gd` changes — every method (`_render_current_node()`, `_update_portraits()`, `_load_portrait_texture()`, etc.) already references these by variable name, not by path.

- [ ] **Step 3: Update `test_chapter_view.gd`**

Change line 25 from:

```gdscript
	var narration_label: RichTextLabel = chapter_view.get_node("NarrationLabel")
```

to:

```gdscript
	var narration_label: RichTextLabel = chapter_view.get_node("DialogueParchment/NarrationLabel")
```

No other line in this file changes — confirmed by direct grep that no other test references `NarrationLabel`, `ChoicesContainer`, `NpcPortrait`, or `FarrukhPortrait` by path; choices are driven via `chapter_view._on_choice_pressed(index)` and `chapter_view.dialogue_engine.available_choices()` throughout the rest of the file.

- [ ] **Step 4: Run the chapter-view tests**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=tests/unit/test_chapter_view.gd -gexit
```

Expected: all tests in this file pass, 0 failures.

- [ ] **Step 5: Run the full suite (final regression gate for this plan)**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: 286 tests total (same count as after Task 1 — this task doesn't add or remove tests, only fixes one existing one), 285 passing + the 1 pre-existing risky test, 0 new failures.

- [ ] **Step 6: Commit**

```bash
git add scenes/chapter_view/ChapterView.tscn scenes/chapter_view/ChapterView.gd tests/unit/test_chapter_view.gd
git commit -m "feat: restructure ChapterView with a bottom parchment dialogue panel and framed portraits"
```

---

## Self-Review

**Spec coverage:**
- "Panel: flat cream fill, gold rule on top edge only, anchored bottom, fixed height, internal scroll, styled scrollbar" → Task 1 Steps 2-3 (styles) + Task 3 Step 1 (`scroll_active = true`, fixed 260px band). ✓
- "Text: ink-black, EB Garamond, size increase" → Task 1 Step 3 (`default_color`/`normal_font_size` on `RichTextLabel` — font family already comes from the existing `theme.default_font` fallback, untouched). ✓
- "Portraits: ~220px framed brown-and-gold card, no speaker-name label" → Task 3 Step 1 (`NpcPortraitCard`/`FarrukhPortraitCard`, 220x220, `"PortraitCard"` variation; no name `Label` added anywhere). ✓
- "Choices inside the same parchment surface" → Task 3 Step 1 (`ChoicesContainer` re-parented under `DialogueParchment`). ✓
- "Portrait source art regenerated at 200x200" → Task 2. ✓
- "Default Panel style reaches MarginPopup automatically" → Task 1 Step 2 (bare `"panel"`/`"Panel"` default, not a variation) — no `MarginPopup.tscn` edit anywhere in this plan, confirmed deliberate. ✓
- "PortraitCard variation is brown, not the cream default" → Task 1 Step 2 explicitly separates these two, Task 1 Step 5 has a dedicated regression test for exactly this (`test_portrait_card_variation_is_brown_not_cream`) given this was a real contradiction caught during the spec's own self-review. ✓
- "VScrollBar styled" → Task 1 Step 3. ✓
- Testing section's required `test_chapter_view.gd` line fix → Task 3 Step 3. ✓
- "What this pass does not do" (no speaker label, no glossed-term color change, `StatusReadout`/`MarginPopup` structure untouched) → nothing in any task adds a speaker label, touches `GlossedTextParser`, moves `StatusReadout`, or edits `MarginPopup.tscn`. ✓

**Placeholder scan:** no "TBD"/"TODO"; every code block is complete, runnable code. The one prose-only geometry explanation (Task 3 Step 1's "Notes on the geometry" paragraph) accompanies a fully-specified `.tscn` file with every offset already given as a real number — it explains the numbers, it doesn't stand in for them.

**Type/signature consistency:** `"DialogueParchment"` and `"PortraitCard"` are spelled identically everywhere they appear (Theme methods, `.tscn` `theme_type_variation` values, test assertions). The 4 `@onready` variable names (`narration_label`, `choices_container`, `npc_portrait`, `farrukh_portrait`) are unchanged from the existing file — only their right-hand-side paths change — so every other method in `ChapterView.gd` that already references these variables by name needs no edit, confirmed by re-reading the full current file before writing this plan.

**Task granularity check:** Task 1 (Theme) must precede Task 3 (scene restructure), since Task 3's `.tscn` references `"DialogueParchment"`/`"PortraitCard"` by string name. Task 2 (portrait regeneration) is genuinely independent of both — sequenced second here only because it's a real paid API call worth running early enough that a funding or API hiccup surfaces before the bigger scene-restructuring task, not because Task 3 needs it to succeed first.
