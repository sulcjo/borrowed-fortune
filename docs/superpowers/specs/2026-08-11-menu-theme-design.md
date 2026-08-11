# Menu Theme Design

**Status:** approved, pending implementation plan.

## Goal

Fix a real readability problem, caught by looking at a live screenshot of the shipped main menu: New Game/Continue/Map/Quit float directly on top of the busiest part of the background art with no separation, and Godot's default disabled-button styling makes `Continue`/`Map` genuinely hard to read. This grew into a full visual pass, worked out interactively with the visual companion across many rounds - the result is a bordeaux cloth banner (an *alam*-style pennant, gold fold-trim) for the two menu screens' titles/buttons, and a project-wide `Theme` resource (first one in this project) that also fixes every button's contrast everywhere, including `ChapterView`'s in-chapter choices.

This explicitly reverses a call made in the earlier main-menu spec ("No custom button skinning or a full Theme resource - confirmed, background art only, default Buttons") - that's fine, the user revisited it with a live screenshot in hand, which is exactly the kind of thing that should prompt reopening an earlier decision.

## Scope: project-wide theme, menu-only banner

Two distinct layers, confirmed with the user:

1. **A project-wide `Theme` resource** (font + a boxed button style with real disabled-state contrast) applies everywhere via `project.godot`'s `[gui] theme/custom` - every `Button` and every `Label`/`RichTextLabel` in the game, including `ChapterView`'s choice buttons, `NarrationLabel`, `StatusReadout`, and `MarginPopup`, picks up the new font and (for buttons) the new boxed style automatically. **This is a real, foreseeable side effect worth stating plainly: every piece of text in the game changes font family**, not just the two menu screens - `NarrationLabel`'s wrapping/positioning logic itself is untouched, only its typeface changes.
2. **A banner-shaped decorative panel**, built from real generated art plus native Godot nodes, is menu-screen-only: `MainMenu`'s title + 4 buttons, and `JourneyMapScreen`'s title only (its waypoint row and Back button are a different shape/purpose and keep the plain global button style, not the flat banner-button style).

## Palette and typography

Colors, confirmed through several rounds of live mockups against the real background art:

- Bordeaux cloth: `#5a1f2e` → `#451624` → `#341220` (vertical gradient, top to bottom) - muted from an earlier brighter red per direct feedback ("mute red, more like bordeaux").
- Gold trim/border/rule accents: `#c9a24b` (a single flat gold, not the repeating fold-pattern gradient shown in the mockup - see "Banner art" below for why).
- Cream text (on bordeaux or dark-brown surfaces): `#f2e2c0`.
- Dark ink-brown (fallback, not used on the final approved direction but consistent with earlier palette rounds): not used - the shipped direction is bordeaux+gold+cream throughout, not the parchment/manuscript alternative explored earlier in the same session.
- Disabled text: cream at 32% opacity (`Color(0.949, 0.886, 0.753, 0.32)` in Godot's 0-1 float notation) - this exact number is the fix for the problem that started this whole pass; Godot's own default disabled-button dimming was the original complaint.
- Focus ring: `#6b7f8a` (a muted slate-blue, callback to lapis lazuli - the real historical pigment of this era/region - explored in an earlier mockup round before the banner direction was chosen; kept as the one surviving thread from that round since it reads well as a focus-state color regardless of the surrounding panel style).

Typography: **EB Garamond** (Regular + Bold), an open-license (OFL) humanist old-style serif - chosen over the initially-described "Palatino" because Palatino is a licensed commercial font Godot cannot legally bundle; EB Garamond is the closest freely-redistributable match to the calligraphic warmth the user picked in the font-comparison mockup. Fetched from Google Fonts' CSS API (confirmed reachable from this environment):

```bash
curl -s "https://fonts.googleapis.com/css2?family=EB+Garamond:wght@400;700&display=swap" -A "Mozilla/5.0"
```

This returns the real `.ttf` URLs on `fonts.gstatic.com` for both weights - the implementation plan downloads both files directly from those URLs into `assets/fonts/`, with a short `assets/fonts/LICENSE-EBGaramond.txt` (OFL text) committed alongside, matching how `.env.example`/README files elsewhere in this project document a dependency's terms.

## Global default `Button` style (used everywhere `Theme` applies, including `ChapterView`)

A boxed, warm-brown-and-gold button - one coherent style shown during the ten-directions comparison ("10. No panel, styled buttons only" - the smallest-change-from-shipped option), carried forward as the actual global default since it pairs cleanly with the bordeaux/gold banner palette without literally reusing the banner's own flat/text-only look (which is reserved for buttons that sit directly on the banner texture):

- Font size 18px (bumped up from Godot's default ~16px - a small, concrete part of the "readability of text" fix the user originally asked for, applied to every button in the game, not just the menu).
- Normal: fill `#3d2a15`, border `#7a5a32` (1px), corner radius 2px, text `#f0e6cc`.
- Hover: fill lightens to `#4a3520`, border unchanged.
- Pressed: fill darkens to `#2e2013`.
- Disabled: fill `rgba(60,48,32,0.5)`, border `rgba(122,90,50,0.25)`, text `rgba(240,230,204,0.35)` - this is the actual fix for `ContinueButton`/`MapButton`'s original readability problem, and it also improves every in-chapter choice button's disabled state (though none currently ship disabled - `DialogueEngine.available_choices()` already filters gated choices out entirely rather than rendering them disabled, so this state may never actually appear in `ChapterView` today; it's still correct for the Theme to define it, since Godot requires every `Button` state to resolve to *something*, and a future feature could change that filtering behavior).
- Focus: adds a 2px outline in `#6b7f8a`.

## Menu-only banner treatment

Two `Theme` Type Variations, layered on top of the global default above, assigned only where the banner art actually sits behind the control:

- **`"BannerButton"`** (a `Button` variation): flat, no visible box at any state, font size 20px, `#f2e2c0` text (cream, matching the banner's own palette). Exactly one button is bold at a time, matching whichever action is the actual current default: `MainMenu.gd`'s existing `continue_button.disabled` check already knows this - `continue_button.bold = not continue_button.disabled` (bold when Continue is usable) and `new_game_button.bold = continue_button.disabled` (bold when it's the only sensible first move). Godot doesn't have a per-`Button` `bold` property directly - this is implemented by setting `theme_override_font_styles/bold_font` per button, toggled in the same place the existing `disabled` assignment already happens in `_ready()`, not a new design decision layered on top of it.
- **`"BannerTitle"`** (a `Label` variation): EB Garamond Bold, font size 36px (the exact size `MainMenu.tscn`'s `TitleLabel` already ships with today - this variation formalizes an existing value into the theme rather than introducing a new one), `#f2e2c0`, with a soft drop shadow (`shadow_color = Color(0,0,0,0.4)`, offset `Vector2(2,2)`) for legibility against the busiest background art.

`MainMenu.tscn`'s `TitleLabel` and all four buttons in `ButtonsContainer` get these variations. `JourneyMapScreen.tscn`'s `TitleLabel` gets `"BannerTitle"`; its `WaypointsContainer` and `BackButton` are left on the plain global default (no variation set) - they're a different shape/purpose (a wide horizontal row of location thumbnails, and a plain navigation button) and don't sit on the banner texture at all.

## Banner art: generated cloth shape, native gold trim

Godot's `StyleBox` system can't draw an arbitrary tapered-pennant silhouette without a shader (this project has none, by established convention). Rather than fight that, the banner's *cloth shape* is generated as real art through a small new pipeline, and the *gold trim* stays a native Godot element - splitting the work along the line each approach is actually good at:

- **New `tools/pixellab/ui_assets.json` + `tools/pixellab/generate_ui_assets.py`**, mirroring `generate_backgrounds.py`'s structure closely (same `pixflux_client.build_description()`/`compute_seed()`/`generate_pixflux()` imports, same skip-if-exists/`--force` CLI shape) but two concrete differences: `no_background=True` is passed explicitly (the existing `generate_backgrounds.py` never passes this parameter at all, always producing opaque full-bleed scenes - confirmed by reading the file directly, not assumed), and output goes to a new `assets/ui/` directory instead of `assets/backgrounds/`, since this is UI chrome, not a location scene.
- Two entries, two sizes rather than one asset stretched via Godot's 9-patch scaling - a tapered point sitting in a 9-patch's stretched edge region is a real scaling risk not worth taking when a second free generation avoids it entirely:
  - `menu_banner_tall.png` (for `MainMenu`'s title + 4 buttons) - description: *"a hanging bordeaux wine-red cloth pennant banner, tapered pointed bottom edge, subtle fabric folds and creases, no text, no border trim, transparent background"*.
  - `menu_banner_short.png` (for `JourneyMapScreen`'s title only) - same description, shorter/wider aspect ratio.
- The gold fold-trim seen in the mockup (a repeating light/dark vertical pattern) is **not** baked into the generated art - a precise repeating pattern is a bad fit for a generative image model's actual strengths, and it's trivial to build natively instead: two plain `ColorRect` nodes, solid `#c9a24b`, positioned along the banner's left/right edges in each `.tscn`. This is a deliberate simplification from the mockup's fold-pattern texture to a flat gold bar - recorded here as a conscious choice, not an oversight.
- Loaded via the same raw `FileAccess.file_exists()` + `Image.load_from_file()` + `ImageTexture.create_from_image()` pattern already established for every other pixellab-generated asset in this project (a `TextureRect` in each `.tscn`, a `_update_banner()` method in each script) - **not** `load()`/the resource-import pipeline, for the same reason as every prior asset: a PNG dropped in by an external script, in a checkout that's never had its editor opened, needs an import pass `load()` can't rely on.

## Scene structure changes

`MainMenu.tscn`: a new `BannerPanel` `Control` node becomes the parent of a `BannerTexture` (`TextureRect`, loads `menu_banner_tall.png`), two `GoldTrimLeft`/`GoldTrimRight` (`ColorRect`), and the *existing* `TitleLabel` and `ButtonsContainer` re-parented underneath it (currently both are direct children of the scene root, independently anchored) - `BannerPanel` becomes the one thing centered on screen, and `TitleLabel`/`ButtonsContainer` position relative to it instead of the whole viewport. The existing `Background` `TextureRect` (the caravan-departure scene) is untouched, still the full-rect layer behind everything.

`JourneyMapScreen.tscn`: the same pattern, scaled down - a `TitleBannerPanel` wrapping `BannerTexture` (`menu_banner_short.png`) + trim + the existing `TitleLabel`, positioned at the top of the screen. `WaypointsContainer` and `BackButton` are unchanged.

`ChapterView.tscn`: no scene changes at all - it inherits the new global `Button`/`Label` defaults automatically via `project.godot`'s theme setting, with zero edits to the scene file itself.

## Testing

- No new GUT test can meaningfully assert on visual/theme properties like colors or fonts - this project's existing tests never assert pixel-level appearance, and that precedent holds here. What *can* and should be tested: `test_main_menu.gd`'s existing lookups (`menu.get_node("ButtonsContainer/ContinueButton")`, etc.) currently work because `ButtonsContainer` is a direct child of the scene root. Once `ButtonsContainer` is re-parented under the new `BannerPanel`, that exact path string breaks - `get_node("ButtonsContainer/ContinueButton")` would no longer resolve, since the node is no longer a direct child. Every such lookup in `test_main_menu.gd` must be updated to the new full path (`get_node("BannerPanel/ButtonsContainer/ContinueButton")`) as part of this same task - a required accompanying test change, not something that happens to keep working on its own.
- `test_journey_map_screen.gd`'s existing lookups (`screen.waypoints_container`, label text under specific `get_child()` indices) are unaffected - `WaypointsContainer` isn't being re-parented, only `TitleLabel` is.
- The full existing suite (274 tests before this pass) must stay green - this is a real regression risk given how much scene-tree restructuring is involved, not a pass-through change.

## What this pass does not do

- Does not touch `NarrationLabel`'s positioning, `StatusReadout`'s layout, or `MarginPopup`'s structure - only their inherited font family changes, nothing else about them.
- Does not add the banner-shaped panel to `ChapterView` or wrap in-chapter choices in any decorative panel - confirmed explicitly with the user, plain global-themed buttons only there.
- Does not attempt a literal, historically faithful *unvan*/interlace reproduction - the earlier illuminated-manuscript mockup rounds explored that direction in more period-accurate detail and were superseded by the user's own preference for the simpler cloth-banner direction; this spec documents the banner as the shipped direction, not a compromise.
- Does not change any game logic, dialogue content, or save/state behavior - purely visual.
