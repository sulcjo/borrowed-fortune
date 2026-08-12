# Chapter View Dialogue Design

**Status:** approved, pending implementation plan.

## Goal

Rework `ChapterView`'s dialogue presentation — the screen every chapter's narration and choices render through — to fix real readability and cohesion problems, and bring it in line with the bordeaux/gold/parchment visual language already shipped for the menus. Confirmed via a live screenshot of the current game (Prologue, first node): narration text is light-colored and sits directly on top of busy background art near the *top* of the screen, portraits are a tiny 72px icon in the bottom corner, and nothing about the screen ties visually to the menus' new theme.

## Scope

Everything in `ChapterView.tscn`: `NarrationLabel`, `ChoicesContainer`, `NpcPortrait`/`FarrukhPortrait`, `StatusReadout`, and `MarginPopup` (a separate scene, instanced into `ChapterView`, sharing this project's only other `Panel` node). `MainMenu` and `JourneyMapScreen` are untouched — that pass already shipped.

## Visual direction

Worked out interactively with the visual companion across several rounds, landing on a **parchment strip** anchored to the bottom of the screen — chosen over a bordeaux-cloth continuation of the menu banner specifically because the ask was for **black, readable text**, which needs a light backing, not a dark one. The parchment material itself is the actual point of connection to the menus: same gold (`#c9a24b`) accent color, same EB Garamond font, same "manuscript" register — just inverted light-surface/dark-text instead of the banner's dark-surface/light-text, because these are different jobs (a title banner vs. a body of readable prose).

- **Panel:** flat cream fill (`#e3d5aa`), a single gold rule along the top edge only, anchored full-width at the bottom of the screen. Fixed height — long narration scrolls *inside* the panel (Godot's `RichTextLabel` supports internal scrolling natively) rather than the panel growing with text or choice count, so a 1-choice scene and a 4-choice scene look the same size. The scrollbar itself is styled (gold grabber, translucent brown track) rather than left as Godot's default gray.
- **Text:** ink-black/dark-brown (`#241a10`), EB Garamond (already the project's default font via the Theme), a real size increase from Godot's ~16px default.
- **Portraits:** both `NpcPortrait` and `FarrukhPortrait` move from a 72px floating transparent icon to a much larger (~220px) framed card — flat brown fill (`#3d2a15`, the exact same `BUTTON_FILL_NORMAL` value already defined in `BorrowedFortuneTheme.gd` for the boxed buttons, not a new color), gold border — positioned flanking the parchment panel, left (NPC) and right (Farrukh), directly above its top edge. Flat, not a gradient: Godot's `StyleBoxFlat` has no gradient support, the same reason the boxed buttons already settled on a flat fill instead of the gradient shown in their own early mockups. No invented speaker-name label above the portraits: this game's dialogue nodes are third-person narration prose, not per-line character speech (confirmed by reading `ChapterView.gd`/`DialogueEngine` — there is no "speaker" field anywhere in the data), so a name tag would be inventing an attribution the content doesn't have. Portraits are scene-identity indicators, not speech-attribution.
- **Choices:** the existing boxed brown/gold `Button` style (already shipped project-wide) sits directly inside the same parchment panel, below the narration text — one continuous reading-and-deciding surface instead of two visually disconnected areas.
- **Portrait source art:** regenerated at 200x200 (up from the current 96x96) via the existing `tools/pixellab/generate_portraits.py` pipeline, so the much larger on-screen size is genuinely crisper rather than a soft upscale of low-resolution source art. Real cost: 16 generations, on the now-funded pixellab account.

## Theme additions (project-wide, in `BorrowedFortuneTheme.gd`)

Five new entries, alongside the existing global `Button` style:

- **Default `Panel` style:** cream fill (`#e3d5aa`), gold border (`#c9a24b`, 3px, all sides), 4px corner radius. This is a global default, not a type variation — it applies automatically to `MarginPopup` too (confirmed: it's the only other `Panel` node in the project), which is exactly the "harmonize" ask: the glossary popup gets the same parchment treatment with zero scene edits.
- **`"DialogueParchment"` `Panel` type variation:** same cream fill and gold color, but the border applies to the top edge only (0 elsewhere) and no corner radius — a flat-topped band that spans the screen's full width, assigned specifically to the new bottom dialogue panel (not the default, since `MarginPopup` needs a complete frame on all sides, being a floating box rather than a screen-edge band).
- **`"PortraitCard"` `Panel` type variation:** flat brown fill (`#3d2a15`, reusing the existing `BUTTON_FILL_NORMAL` constant), gold border (`#c9a24b`, 3px, all sides), 4px corner radius — confirmed via the approved mockup as brown, matching the buttons, **not** the cream used by the default `Panel` style/`MarginPopup`. Assigned to the two new portrait-card wrapper panels described below.
- **Default `RichTextLabel` color and size:** `default_color` set to the ink-black `#241a10`, `font_size` set to 22px (up from Godot's ~16px default). This is deliberately a **global** Theme default, not a per-node override — `MarginPopup`'s own `MarginRichTextLabel` is also a `RichTextLabel`, and once its panel is cream, black text there reads exactly as well as it does in the main dialogue panel. One change serves both.
- **`VScrollBar` style:** `grabber` gold (`#c9a24b`), `grabber_highlight` a lighter gold (`#d9b25e`), `grabber_pressed` a darker gold (`#a8823a`), `scroll` (the track) a translucent brown (`Color(0.353, 0.255, 0.118, 0.15)`) — the same accent language as everything else, instead of Godot's default gray/blue.

## Scene structure changes

`ChapterView.tscn`: a new `DialogueParchment` panel node (using the `"DialogueParchment"` type variation) anchored full-width at the bottom of the screen. `NarrationLabel` and `ChoicesContainer` move underneath it (currently both are direct children of the scene root, independently positioned). `NpcPortrait` and `FarrukhPortrait` each gain a wrapping card (a `Panel` using the `"PortraitCard"` type variation — brown, not the cream default, per the Theme additions above) containing the actual portrait `TextureRect`, larger than today and positioned flanking `DialogueParchment`'s top edge. `Background` and `StatusReadout` are untouched, in both position and node type — `StatusReadout` is a plain `Label`, not a `RichTextLabel`, so it is unaffected by the `RichTextLabel` color/size Theme addition above; its own hardcoded color (`Color(0.55, 0.55, 0.55, 1)`) is left as-is, since it was never part of the readability complaint and re-litigating it is outside what was asked. `MarginPopup.tscn` itself needs no structural changes — its `Panel` and its `MarginRichTextLabel` both inherit the new global defaults automatically.

## Testing

- Same discipline as the menu-theme pass: no GUT test can meaningfully assert on colors, fonts, or pixel layout, and none tries to.
- `test_chapter_view.gd` interacts with choices exclusively through `chapter_view._on_choice_pressed(index)` and `chapter_view.dialogue_engine.available_choices()` — never by walking `ChoicesContainer`'s node tree — and never references `NpcPortrait`/`FarrukhPortrait` by path at all. Confirmed by reading the file directly: re-parenting those three nodes under `DialogueParchment` has **zero** test impact.
- Exactly one existing test breaks and must be fixed in the same task: `test_chapter_view_renders_the_first_node_text_on_load` (`test_chapter_view.gd:25`) does `chapter_view.get_node("NarrationLabel")` — this must become `chapter_view.get_node("DialogueParchment/NarrationLabel")` once `NarrationLabel` is re-parented.
- The full existing suite (280 tests as of the last merge to `master`) must stay green.

## What this pass does not do

- Does not add a speaker-name label or any other per-line attribution UI — the underlying dialogue data has no speaker field, and inventing one is new content-model scope, not a visual fix.
- Does not add visual distinction (color, underline styling beyond Godot's default clickable-link behavior) to glossed terms inside narration text — that's an existing, separate gap (`GlossedTextParser` wraps them in a plain `[url=...]` tag with no color), never complained about, and not part of this ask.
- Does not touch `StatusReadout`'s position or its own hardcoded gray color, or `MarginPopup`'s node structure — only the shared `Panel`/`RichTextLabel` Theme defaults reach it.
- Does not change any game logic, dialogue content, or save/state behavior — purely visual, like the menu-theme pass before it.
