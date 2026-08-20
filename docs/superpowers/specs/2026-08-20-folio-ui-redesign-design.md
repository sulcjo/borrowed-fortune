# Folio UI redesign — ChapterView, theme foundation, display config

Date: 2026-08-20
Status: design approved, ready for implementation planning

## Why

`ChapterView` is built from 33 absolute pixel offsets against a project that
declares no `[display]` section at all. Nothing scales, and two of the faults are
live in shipped content rather than hypothetical:

- **Choice overflow.** `ChoicesContainer` is pinned to 76px (`offset_top = -92`,
  `offset_bottom = -16`). Pushang's `n09_the_officers_demand` has four choices —
  the real maximum across all 229 nodes. Four buttons at `font_size = 18` plus
  stylebox margins cannot fit 76px.
- **Prose squeezed.** `NarrationLabel` reserves a fixed 108px for choices that
  actually begin 92px up, leaving roughly 136px of text box. The prologue's
  `n12_departure` is 1135 characters and scrolls inside it while most of the
  screen shows background art.

Two further defects found during design:

- **Pixel art is blurred.** Backgrounds are 320×180 and portraits 200×200 —
  deliberate pixel assets from the pixellab pipeline. There is no `[rendering]`
  section, so the default canvas texture filter is linear and the art is
  interpolated 4–6× on the way to the screen.
- **Portrait collision.** The portrait cards use `offset_top = -488` against a
  bottom anchor while `DialogueParchment` claims the bottom 260px. Below roughly
  500px of window height they overlap `StatusReadout`.

This spec replaces ChapterView's layout with a manuscript-folio composition built
entirely from containers, establishes the display and rendering foundation the
whole project sits on, and retires the glossary popup.

## Scope

**In scope**

- `scenes/chapter_view/ChapterView.tscn` and `.gd` — full layout replacement.
- `project.godot` — new `[display]` and `[rendering]` sections.
- `engine/theme/BorrowedFortuneTheme.gd` — new theme variations for folio
  regions, with `theme/borrowed_fortune_theme.tres` regenerated from it.
- A new pure-logic engine class for inset scale selection.
- `scenes/margin_popup/` — retired.
- Updating the 18 test assertions that depend on the old node paths.

**Verified, not redesigned**

Adding `display/window/stretch/mode` changes how every scene renders. `MainMenu`,
`JourneyMapScreen`, `PrologueCutscene`, `EndingCutscene`, and `Main` must be
checked under the new content scale and any regression fixed, but their visual
redesign is deferred. They keep their current composition.

**Out of scope**

- **Controls and input.** Focus management, keyboard reach for glossary terms,
  choice shortcuts, and gamepad are a separate spec, deliberately sequenced
  after this one so they build on the finished theme and layout.
- **The per-render asset reload.** `_update_background()` and
  `_update_portraits()` call `Image.load_from_file()` and
  `ImageTexture.create_from_image()` on every node render, re-decoding PNGs from
  disk on every click. Real, but a performance concern rather than a layout one.
  Flagged, not fixed here.
- **README staleness.** The README says the game has no save/resume on boot, but
  `MainMenu.gd` has a working `ContinueButton` gated on the pointer file. Noted
  for a separate correction.

## Design decisions and their provenance

Each was chosen from rendered alternatives during brainstorming:

1. **Single folio, miniature inset into the text block** — over a two-page spread
   and over an illuminated cartouche on full-bleed art. The content model already
   assumes marginalia: the code calls it `MarginGlossary` and `MarginPopup`, and
   the README describes glossing "the way a manuscript's margin might."
2. **Folio fills the window, prose column capped** — over a fixed letterboxed
   reference page and over a true portrait folio. A larger monitor should buy
   more visible prose, not larger pixels.
3. **Place as inset, people as margin roundels** — over compositing figures into
   the place, and over two separate plates. Compositing needs art redrawn to
   composite; separate plates cost the most vertical space. Roundels are a real
   manuscript device and give Farrukh's three wear stages somewhere continuously
   visible to live.
4. **Glosses appear in the margin unbidden; the popup retires.** Density makes
   gating pointless: 200 of 229 nodes carry no gloss at all, the average is 0.15
   per node and the maximum is 2. The unlock mechanic that a click would drive is
   already dead — `is_unlocked()` is read only by tests, and
   `ChapterView.resume()` never restores `unlocked_glossary_terms`, so the state
   is written to the save and never read back.

## Layout

Five regions, all container-driven. No absolute offsets.

```
ChapterView (Control)
└── FolioMargin (MarginContainer)          page margins
    └── Folio (HBoxContainer)
        ├── TextColumn (VBoxContainer)      expands; max width capped
        │   ├── HeadBlock (HBoxContainer)
        │   │   ├── PlaceInset (AspectRatioContainer → TextureRect)
        │   │   └── NarrationLabel (RichTextLabel, fit_content = true)
        │   ├── ChoicesRule (HSeparator)
        │   ├── ChoicesContainer (VBoxContainer)   sized by its children
        │   ├── ColophonRule (HSeparator)
        │   └── Colophon (Label)
        └── MarginColumn (VBoxContainer)     fixed custom_minimum_size.x
            ├── NpcRoundel (Panel → TextureRect + caption)
            ├── FarrukhRoundel (Panel → TextureRect + caption)
            └── GlossNotes (VBoxContainer)
```

**Prose beside the inset, not under it.** Godot's `RichTextLabel` supports no
float or wrap-around, so text cannot flow beneath the inset. `HeadBlock` places
the inset and the full narration side by side; the prose column is as tall as its
content requires.

**Choice list.** `ChoicesContainer` takes its height from its children. The
four-choice overflow becomes structurally impossible rather than repaired — there
is no fixed height left to exceed.

**Margin column.** Fixed width, always present. It carries Farrukh's roundel on
every node and the NPC's roundel whenever the node names one, so it is never
empty and never needs a hidden state. Gloss notes append beneath the roundels.

**Colophon.** One line along the foot of the text column, replacing
`StatusReadout` in the top-right. It keeps today's composition — coin, debt when
non-zero, then each faction's reputation, joined with the existing `·` separator,
including the negative-zero normalisation — and **adds the chapter's place name at
the head of the line**, which the current readout does not show. That addition is
the one behavioural change to the status line and affects the four existing
`StatusReadout` assertions.

**Width cap.** `NarrationLabel` is capped at 720px at the 1280×720 reference,
roughly 85–90 characters per line, so prose never runs to a punishing measure on
a wide display. Surplus width past the cap goes to the folio's outer margins
rather than to the inset or the prose — wide margins are what a real manuscript
page does with spare vellum, and it keeps the inset on its integer scales.

## Inset scale selection

The inset is pixel art and must land on integer multiples of 320×180. Because the
folio expands to the window, the scale has to be chosen rather than fixed. The
arithmetic at the 1280×720 reference:

| Inset scale | Inset size | Prose width | 1135-char node | Fits ~600px? |
|---|---|---|---|---|
| 2× | 640×360 | ~440px | ~23 lines ≈ 621px | no |
| 1× | 320×180 | ~760px | ~14 lines ≈ 378px | yes |

So: **choose the largest integer scale whose remaining prose width lets the
node's text fit the available height, with a floor of 1×.** Short nodes get a
large inset; the long prologue node gets a small one. This is the honest cost of
having picked prose over art — long nodes show small art.

This rule is pure arithmetic over (text length, available width, available
height, font metrics). It belongs in `engine/`, consistent with the project's
existing separation — `engine/` is pure `RefCounted` logic with no scene tree,
fully unit-tested, and `scenes/` renders it. New class:
`engine/theme/FolioMetrics.gd`, exposing the scale choice as a static function so
it can be tested without instantiating a scene.

## Theme

`engine/theme/BorrowedFortuneTheme.gd` is the source of truth;
`theme/borrowed_fortune_theme.tres` is a generated artifact, produced by
`tools/build_theme.gd` calling `BorrowedFortuneTheme.build()` and saving through
`ResourceSaver`. Theme work therefore means editing the `.gd`, re-running the
generator, and committing the regenerated `.tres`:

```bash
godot --headless --path . -s tools/build_theme.gd
```

The existing variations are `BannerButton`, `BannerTitle`, `DialogueParchment`,
and `PortraitCard`. Changes:

- Add a `Folio` variation for the parchment ground of the whole page.
- Add a `Roundel` variation for the circular figure medallions.
- Add a `Colophon` variation for the status line, and a `GlossNote` variation for
  margin notes, both drawing on the existing `#6b5a44` muted ink.
- **Remove `PortraitCard` and `DialogueParchment`.** Both are referenced by
  ChapterView and nothing else, so `Roundel` and `Folio` do not sit alongside
  them — they replace them outright. `test_borrowed_fortune_theme.gd` asserts the
  `PortraitCard` panel stylebox and must be updated with them.
- Choices become rubricated text lines rather than filled buttons: a `Rubric`
  variation using the existing rubric red with a gold left rule, replacing the
  `#3d2a15` filled `Button` styling in this scene only. The global `Button`
  styling is untouched, so menus keep their present look.

The existing `focus` styleboxes and `FOCUS_RING` colour stay exactly as they are.
They are already defined and correct; the controls spec will start using them.

## project.godot

```ini
[display]
window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"

[rendering]
textures/canvas_textures/default_texture_filter=0   ; Nearest
```

`canvas_items` with `expand` is what makes the folio fill the window while UI
scales. `default_texture_filter=0` stops the pixel art being linearly
interpolated. Both are project-wide, which is why the other five scenes need
verification.

## ChapterView.gd changes

The dialogue, ledger, reputation, save, and manifest logic is unchanged. Only
rendering changes:

- `_render_current_node()` keeps its sequence but writes into the new nodes.
- `_update_portraits()` targets the two roundels instead of the two offset cards.
- `_update_background()` becomes `_update_place_inset()` — the chapter image
  becomes the inset texture rather than a full-bleed background, and its scale
  comes from `FolioMetrics`.
- `_update_status_readout()` becomes `_update_colophon()`, same string
  composition, including the existing negative-zero normalisation.
- `_on_narration_meta_clicked()` no longer opens a popup. Glossed terms for the
  current node are rendered into `GlossNotes` during `_render_current_node()`.
  `margin_glossary.unlock()` is still called so `unlocked_term_ids()` keeps
  populating the save, preserving the existing save format.

`scenes/margin_popup/MarginPopup.tscn` and `.gd` are deleted.

## Testing

Engine code and scene orchestration are both `.gd`, so the standing project rule
exempting *content* changes from GUT maintenance does not apply here. This work
carries tests.

**Assertions that break** — 18 hard-coded node paths across three files. Most are
repointed at the new nodes; the two popup paths are deleted outright along with
the scene they cover.

| File | Paths |
|---|---|
| `tests/unit/test_chapter_view.gd` | `DialogueParchment/NarrationLabel`, `StatusReadout` ×4, `MarginPopup`, `MarginRichTextLabel` |
| `tests/unit/test_chapter_view_portraits.gd` | `NpcPortraitCard/NpcPortrait` ×4, `FarrukhPortraitCard/FarrukhPortrait` ×2, `NpcPortraitCard` ×2, `FarrukhPortraitCard` |
| `tests/unit/test_chapter_view_background.gd` | `Background` ×2 |

The popup-rendering test in `test_chapter_view.gd` is removed with the scene it
covers; its replacement asserts gloss notes render into `GlossNotes`.

**New tests**

- `FolioMetrics` scale selection: a short node picks a large scale, the 1135-char
  prologue node picks 1×, the floor is never breached, and the result is always
  an integer multiple.
- `ChoicesContainer` holds one child per available choice for the 4-choice
  Pushang node, and the container's minimum height is at least the sum of its
  children — the assertion that would have caught the original overflow.
- Gloss notes: a node with two glossed terms renders two notes; a node with none
  renders an empty margin without error.
- Colophon composition, ported from the four existing `StatusReadout` tests.
- `BorrowedFortuneTheme.build()` returns the new `Folio`, `Roundel`, `Colophon`,
  and `Rubric` variations, and no longer returns `PortraitCard` or
  `DialogueParchment` — extending `test_borrowed_fortune_theme.gd` and replacing
  its `PortraitCard` assertion.

**Known-stale assertions.** Twelve fixed-count content assertions are already
failing across four dialogue-content test files, documented in their commit
messages and unrelated to this work. They stay as they are; this spec neither
fixes nor is blocked by them.

## Risks and tradeoffs

- **Art gets smaller.** The place image moves from full-bleed background to a
  bounded inset, and on long nodes it drops to 1× — 320×180 within a 1280-wide
  page. This is the direct consequence of choosing prose room over art presence.
  It is the decision most worth revisiting after seeing it running.
- **Composition varies by window.** `expand` means the approved proportions are
  one instance of a range rather than a fixed picture, so more layouts need
  eyeballing than a letterboxed design would need.
- **Project-wide settings.** The display and rendering changes touch all seven
  scenes at once. The five outside this redesign are verified, not reworked, so
  they may look merely acceptable rather than good until their own pass.
- **Font metrics in pure logic.** `FolioMetrics` needs line-height and average
  character width to choose a scale. Taking real metrics from a `Font` would drag
  scene-tree types into `engine/`; the class instead accepts metrics as
  parameters, and `ChapterView` supplies them from the live theme font. This
  keeps `engine/` pure at the cost of the caller passing correct numbers.

## Verification

1. `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`
   — new and updated tests green, no new failures beyond the 12 known-stale.
2. Run the game and walk to Pushang `n09_the_officers_demand`: four choices all
   visible and clickable, nothing clipped.
3. Load prologue `n12_departure`: all 1135 characters visible without scrolling.
4. Resize from small to ultrawide: no overlap, no clipping, prose column capped,
   inset on integer scales.
5. Confirm pixel art renders crisp rather than smoothed.
6. Open each of the other five scenes and confirm nothing regressed under the new
   content scale.
