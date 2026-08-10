# NPC Portraits Design

**Status:** approved, pending implementation plan.

## Goal

Second pixellab.ai art pass. Adds one small bust portrait per chapter's central
scene-presence (named or not) plus a three-stage progressive-wear portrait of
Farrukh himself, displayed in two corner slots above the choices — extending,
not replacing, the location-background pass that shipped first.

## Roster

Every chapter's central NPC(s), grounded directly in the shipped dialogue text
(not invented, not assumed from the design specs). Physical detail in the
prompt column is quoted or closely paraphrased from the actual chapter text;
where the text gives none, the prompt leans on the character's stated role and
historically-attested dress for that role instead of inventing appearance.

| npc_id | Chapter | Textual grounding | Prompt (appended to the shared style clause) |
|---|---|---|---|
| `nasuh` | Prologue | "a quiet, ink-stained man who had kept the shop's accounts for eleven years" | an ink-stained clerk in a plain robe, seated with an open ledger, quiet composed bearing |
| `ostad` | Prologue | "an old friend of his father's," a professional letter-writer | an elderly letter-writer in a simple dignified robe, pen and paper, gentle bearing |
| `saidibnyaqub` | Teginabad | "young for the amid he claimed, his robe good cloth gone thin at the cuffs" | a young customs officer in good cloth worn thin at the cuffs, stack of ledgers, fortress gate |
| `mihran` | Bost | sarraf, "weighed silver for a living" (no physical description) | a sarraf money-changer at his scale, weighing silver, market stall |
| `ummkavus` | Farah | widow running the caravanserai alone (no physical description) | a widow running a caravanserai alone, practical dress, keys at her belt, doorway |
| `tahir` | Farah | "younger than Farrukh expected for a veteran of a campaign ten years gone, and tired in a way that had nothing to do with the road" | a tired ex-soldier, younger than expected, worn campaign-era clothing, guarded posture |
| `ardashir` | Herat 4A | "older than Mihran, quieter than Umm-Kavus" | an older, quiet sarraf at a mint counting-table, precise composed bearing |
| `rostam` | Herat-Favor 4B | "younger than Farrukh expected, and better dressed than the quarter around him" | a young, sharp-eyed courier-network fixer, better dressed than his surroundings |
| `behdinshopkeeper` | Pushang | "a woman old enough to have buried a husband and young enough not to have expected to yet" | a Zoroastrian Behdin shopkeeper, a woman in early widowhood, plain dress, shop counter |
| `tarsamerchant` | Pushang | cloth merchant, laying out goods (no physical description) | a Christian Tarsa cloth merchant laying out bolts of dyed cloth, market stall |
| `pushanggateofficer` | Pushang | "young, tired, working from a list that clearly hadn't gotten shorter all week" | a young, tired Ghaznavid gate officer with a requisition list, garrison gate |
| `bahram` | Sarakhs | "older than most of the men drilling in his yard," a ghulam | an older ghulam gate-officer in service dress, watchful bearing, garrison yard |
| `teacher` | Nishapur | "old enough to have outlived most of his own scandals," deliberately self-effacing | an old, self-effacing teacher in plain worn robes, seated simply, khaneqah courtyard, no ornament |

13 NPC portraits. Herat 4A's "old soldier at the garrison gate" is excluded -
pure background-color mention, never a scene partner. Chapters 5 and Merv get
zero NPC portraits - confirmed by direct read, no hidden NPC in either.

## Farrukh's own portrait: progressive wear, not age

The story's own internal timeline (checked directly against the text before
this design was written) spans weeks, not years - Prologue departs within a
week of the burial, Herat-Favor's "two weeks," Chapter 5's "third day out."
Nothing supports literal aging. What the text does support is *wear*:
Chapter 5 itself says he "arrived one kind of man and was leaving as some
other kind." Three stages, same face, progressively more travel-worn:

| Stage | Chapters | Prompt |
|---|---|---|
| 1 - fresh | Prologue, Teginabad, Bost | a young merchant's son, nineteen, plain mourning-appropriate travel dress, composed but grieving expression, clean-kept |
| 2 - hardening | Farah, Herat 4A, Herat-Favor 4B, Pushang | the same young merchant, road-dust on his clothes, more guarded and hardened expression, sun-worn |
| 3 - worn | Sarakhs, Merv, Nishapur, and Chapter 5 (the short route's own ending) | the same young merchant, visibly travel-worn, weathered and resolute bearing, dust and wear on travel clothes |

Chapter 5 gets stage 3 despite being only three days past Herat: it's the
short route's own ending, and the chapter's own text explicitly marks a
completed change at that point - matching the equal narrative weight this
project has given both endings elsewhere. Farrukh's bust is **always**
present (unlike the NPC slot, which hides when absent) - every chapter,
including the two with no NPC, has a wear stage.

**Generation continuity:** three separate pixflux calls for the same person
would not reliably look like the same person. Stage 1 generates first, then
stage 2's call passes stage 1's output as `init_image` (with `color_image`
too, to hold the palette), and stage 3 chains off stage 2 the same way - so
each stage is a real edit of the previous one, not an independent roll. All
three additionally share Farrukh's own deterministic seed.

## Where a portrait shows: no new manifest file

Reuses the exact idiom `next_chapter_id` already uses on terminal nodes: an
optional key directly on a dialogue node. `ChapterView` already reads
arbitrary keys off `dialogue_engine.current_node()` (e.g.
`node.get("next_chapter_id", ...)`) - portraits follow the same pattern:

```json
{
  "id": "n01_sarakhs_arrival",
  "text": "...",
  "npc_portrait": "bahram",
  "choices": [...]
}
```

A node with no `npc_portrait` key means no NPC is present at that beat - the
slot hides. Farah's two-NPC chapter needs nothing special: Umm-Kavus's nodes
carry `"npc_portrait": "ummkavus"`, Tahir's carry `"npc_portrait": "tahir"`.
Pushang's three figures work the same way, one value per relevant node.

Farrukh's wear stage is chapter-level, not node-level (it's physical wear
from the road, not a per-scene thing) - one new field per chapter entry in
`content/chapters/manifest.json`:

```json
"chapter_07_sarakhs": {
  "dialogue_path": "res://content/chapters/chapter_07_sarakhs/sarakhs.json",
  "glossary_path": "res://content/glossary/sarakhs_terms.json",
  "next_chapter_id": null,
  "farrukh_wear_stage": 3
}
```

All 11 chapters get this field (including Chapter 5 and Merv, since
Farrukh's bust is never absent).

## Files on disk

```
assets/portraits/
  nasuh.png
  ostad.png
  saidibnyaqub.png
  mihran.png
  ummkavus.png
  tahir.png
  ardashir.png
  rostam.png
  behdinshopkeeper.png
  tarsamerchant.png
  pushanggateofficer.png
  bahram.png
  teacher.png
  farrukh_stage_1.png
  farrukh_stage_2.png
  farrukh_stage_3.png
```

Flat, single level - matches `assets/backgrounds/`'s existing structure; 16
files doesn't justify subdirectories.

## Godot-side change: the portrait dock

New `PortraitDock`-equivalent: two `TextureRect` bust frames added directly to
`ChapterView.tscn` (no separate sub-scene needed for two nodes) -
`NpcPortrait` anchored bottom-left, `FarrukhPortrait` anchored bottom-right,
both sized small (roughly 64x64), sitting above `ChoicesContainer`. Both are
inserted into the node tree after `Background` (so they draw on top of it)
but before `MarginPopup` (so a clicked glossary popup still draws on top of
*them* - unchanged from today's behavior).

`ChapterView.gd` gets `_update_portraits()`, called from `_render_current_node()`
alongside `_update_background()` and `_update_status_readout()`:

- NPC side: reads `dialogue_engine.current_node().get("npc_portrait", null)`.
  Null → `npc_portrait.visible = false`. A value → build
  `res://assets/portraits/<value>.png`, same raw `FileAccess.file_exists()` +
  `Image.load_from_file()` pattern the background loader already uses (no
  Godot resource-import dependency, no new priming step), show it.
- Farrukh side: reads the current chapter's `farrukh_wear_stage` from the
  manifest entry already loaded by `load_chapter_by_id()` (a new
  `farrukh_wear_stage: int` member, set alongside the existing
  `next_chapter_id` in that method) and builds
  `res://assets/portraits/farrukh_stage_<N>.png`. Always visible; if the file
  is missing (no art generated yet), same null-safe fallback as everywhere
  else - texture cleared, nothing crashes.

## Generation

`tools/pixellab/npcs.json` - flat array of `{id, output, description}`,
same shape discipline as `locations.json`. Farrukh's three stages are a
separate small list in the same file (or a second array in it - implementation
detail for the plan) since they chain via `init_image`/`color_image` rather
than being independent entries.

Shares `generate_backgrounds.py`'s style constants, its direct-`requests.post`
fix for this account's generations-typed usage responses, and its
idempotent skip/`--force` behavior - extended with one new parameter:
`no_background: true` for every portrait (busts need a transparent
background to composite into the in-game frame, unlike backgrounds, which
are full painted scenes). Same shared `STYLE_CLAUSE` and
`NEGATIVE_DESCRIPTION` as backgrounds, so the two passes read as one
consistent art direction.

## Testing

- `ChapterView` gets new GUT tests for `_update_portraits()`: a node with
  `npc_portrait` set shows the right bust; a node without one hides it; the
  Farrukh slot always shows using the loaded chapter's `farrukh_wear_stage`
  even on a chapter with zero NPCs (Chapter 5, Merv); a missing portrait file
  clears the texture without erroring - mirrors every fallback test already
  written for backgrounds.
- Same carve-out as the backgrounds pass: no automated test for the
  generator script itself, verified by a mock-based dry run during
  implementation, never a live call.

## What this pass does not do

- No portraits for any chapter beyond the 13 NPCs + Farrukh listed above -
  no attempt to illustrate every name mentioned in passing.
- No portrait animation, no expression variants, no per-choice portrait
  swaps within a single scene beyond the existing per-node granularity.
- Does not resolve the same exported-build limitation already recorded for
  backgrounds (raw `res://` PNG reads don't survive an export) - it's the
  same accepted, recorded gap, not a new one.
