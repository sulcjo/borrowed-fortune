# Pixellab Art Pipeline Design

**Status:** approved, pending implementation plan.

## Goal

Give Borrowed Fortune its first visual art: one background image per real-world
location the story visits, generated offline via the [pixellab.ai](https://www.pixellab.ai)
API, committed to the repo, and shown behind each chapter's dialogue in
`ChapterView`. Everything else about the game (mechanics, content pipeline,
test discipline) stays exactly as it is.

## Why this split

Two genuinely separate concerns:

1. **Generating the art** - a one-off, re-runnable offline tool. Never runs
   inside the shipped game, never needs a player's machine to have an API key.
2. **Showing the art** - a small, permanent change to `ChapterView` so whatever
   PNGs exist under `assets/backgrounds/` actually appear on screen, with a
   silent no-op fallback for any chapter that doesn't have one yet.

Keeping them separate means the game never depends on pixellab being reachable,
and the generation tool never needs to know anything about Godot.

## Reconciling pixellab's native style with "Persian miniature"

Pixellab's `generate_image_pixflux` endpoint is built for game-sprite pixel
art - it defaults toward volumetric shading and busy per-pixel detail, which
reads as "video game asset," not "manuscript illustration." Rather than fight
the tool or invent a new visual language, this pass pushes pixflux's own style
knobs toward the miniature register and leans on a shared prompt template to
do the rest:

- `outline = "single color black outline"` - miniatures use firm dark
  linework for architecture and figures, not soft edges.
- `shading = "flat shading"` - flat color fields instead of gradient/volumetric
  shading.
- `detail = "low detail"` - avoids the busy pixel-noise that reads as "sprite"
  rather than "painting."
- `view = "side"` - manuscript miniatures are architectural side-elevations,
  not top-down game-map views.
- `no_background = false` - these are full painted scenes, not
  transparent-background sprites.
- A shared style clause and a shared negative-description are prepended /
  attached to every per-location prompt (see "Prompt template" below), so the
  miniature framing is consistent across all ten images rather than
  re-invented per location.

This is a deliberate, real constraint, not a cosmetic detail: it is the
concrete answer to the tension between "AI pixel-art generator" and "this
project's stated Persian-miniature art direction."

## Locations, not chapters

11 chapters visit 10 distinct real-world locations - Chapter 4A (Herat) and
4B (Herat, favor branch) are the same city. The generator is keyed by
location; the manifest of what to generate lists which chapter ids share a
given location, and the script writes the identical PNG to every listed
chapter id's output path. This means:

- No wasted API credits generating the same city twice.
- No location-to-chapter mapping logic needed anywhere in Godot - the game
  code only ever does a direct `chapter_id -> filename` lookup.

| Location file | Chapter ids | Grounded in (existing prose) |
|---|---|---|
| `ghazni.png` | `chapter_00_prologue` | Graveside/bazaar city where the debt is inherited (README premise; opening chapter is set in Ghazni before the road begins) |
| `teginabad.png` | `chapter_01_teginabad` | "a wall, a gate... a fortress squatting on patterned brick where the Ghazni road narrowed toward the desert crossing" |
| `bost.png` | `chapter_02_bost` | "canal-fed green, low domes and a long red-brick palace face... the sultan's winter residence, Lashkari Bazar, more garrison-town than palace" |
| `farah.png` | `chapter_03_farah` | "no wall worth the name, no palace skyline, only a scatter of mud-brick and tamarisk windbreak... a thin, stubborn irrigation" |
| `herat.png` | `chapter_04a_herat`, `chapter_04b_herat_favor` | "a green so sudden... the Hari Rud ran wide and steady... orchards and fields... the city itself sat in the middle of all that green" |
| `road_west.png` | `chapter_05_plunder_ending` | "The road west ran on regardless" - deliberately no city, an open, indifferent road (per this ending's own design: no new city) |
| `pushang.png` | `chapter_06_pushang` | "a lesser cousin... half of Herat's walls... the same brick, the same canal-fed green fighting the same patient desert" |
| `sarakhs.png` | `chapter_07_sarakhs` | "the Gate of Khorasan... the fortress sat squarely across the road on the Tejen's near bank, walls thick enough" |
| `merv.png` | `chapter_07b_merv` | "a market town grown into a provincial capital, threaded by canals... the best oasis on this whole stretch of road" |
| `nishapur.png` | `chapter_08_nishapur` | "The turquoise..." (city of turquoise-domed architecture; final chapter) |

## Files

```
tools/pixellab/
  locations.json           # the 10-entry manifest described above
  generate_backgrounds.py  # the generator script
  README.md                # setup + how to run

assets/backgrounds/
  chapter_00_prologue.png
  chapter_01_teginabad.png
  chapter_02_bost.png
  chapter_03_farah.png
  chapter_04a_herat.png
  chapter_04b_herat_favor.png   # byte-identical to chapter_04a_herat.png
  chapter_05_plunder_ending.png
  chapter_06_pushang.png
  chapter_07_sarakhs.png
  chapter_07b_merv.png
  chapter_08_nishapur.png

.env.example                # committed template, PIXELLAB_SECRET=
.env                        # gitignored, holds the real secret
```

`tools/` is a new top-level directory, alongside `engine/`, `content/`,
`scenes/`, `tests/`, `docs/` - it holds dev-only tooling that is not part of
the shipped game and is not GDScript.

## `locations.json` shape

```json
[
  {
    "output": "teginabad.png",
    "chapter_ids": ["chapter_01_teginabad"],
    "description": "a fortress gate of patterned brick squatting on a narrow desert road, thick walls, a single watchtower, dusty ochre stone against pale sky"
  },
  {
    "output": "herat.png",
    "chapter_ids": ["chapter_04a_herat", "chapter_04b_herat_favor"],
    "description": "a green river valley city among orchards, a wide steady river, domed rooftops rising from dense garden green"
  }
]
```

Each `description` is the location-specific clause only - the shared style
clause and shared negative description (below) are prepended/attached by the
script, not repeated per entry.

## Prompt template

Shared constants in `generate_backgrounds.py`:

```python
STYLE_CLAUSE = (
    "Persian miniature painting, flat gouache color fields, ochre and lapis "
    "palette, 11th-century Khorasan architecture, illuminated manuscript "
    "background"
)
NEGATIVE_DESCRIPTION = (
    "photorealistic, 3d render, modern clothing, modern buildings, gradient "
    "shading, blur, text, watermark, signature"
)
IMAGE_SIZE = {"width": 320, "height": 180}
GENERATION_PARAMS = dict(
    outline="single color black outline",
    shading="flat shading",
    detail="low detail",
    view="side",
    no_background=False,
    text_guidance_scale=8,
)
```

Full description sent per location: `f"{STYLE_CLAUSE}, {entry['description']}"`.
`seed` is derived deterministically from the location's `output` filename (e.g.
a stable hash truncated to the SDK's accepted range), so re-running the script
for a single location reproduces the same image rather than drawing a new
random one.

## Script behavior (`generate_backgrounds.py`)

- Loads the pixellab client via `pixellab.Client.from_env_file(".env")`
  (repo-root-relative path, resolved from the script's own location so it
  works regardless of the caller's cwd).
- Reads `locations.json`.
- For each entry, for each `output` path under `assets/backgrounds/`: if the
  file already exists and `--force` was not passed, skip it (idempotent -
  re-running the script after a partial batch, or after adding one new
  location, does not re-spend credits on images that already exist).
- On generation: calls `generate_image_pixflux`, saves via
  `response.image.pil_image().save(path)`, then copies that same file to
  every other `chapter_ids` entry sharing the location (Herat's two ids).
- Wraps each location's generation in its own try/except: a single failure
  (bad credentials, network error, content-policy rejection) is printed with
  the location name and the batch continues to the next entry rather than
  aborting. Failures are collected and summarized at the end.
- Prints per-image `usage.usd` cost as it goes, and calls `get_balance()` once
  at the end to report remaining credits.
- CLI: no arguments generates everything not yet present; `--force` 
  regenerates everything; `--force LOCATION_OUTPUT_NAME` regenerates just one
  (e.g. `--force herat.png`).

## Secrets

- `PIXELLAB_SECRET` is the exact environment variable name the SDK's
  `Client.from_env()` / `from_env_file()` read (verified directly against the
  SDK source: `pydantic_settings` with `env_prefix="PIXELLAB_"` and a
  `secret` field).
- `.env` at the repo root holds the real value, is added to `.gitignore`
  alongside the existing `export.cfg` / `export_presets.cfg` entries.
- `.env.example` is committed, containing just `PIXELLAB_SECRET=` as a
  template with a one-line comment pointing at pixellab's dashboard for
  obtaining a token.

## Godot-side change: showing the background

`scenes/chapter_view/ChapterView.tscn`: one new `TextureRect` node,
anchored full-rect, positioned behind the existing `NarrationLabel` /
`ChoicesContainer` / `MarginPopup` / `StatusReadout` in the tree (drawn
first, so everything else layers on top). `expand_mode` set to cover the
rect without distortion (`EXPAND_IGNORE_SIZE` + `STRETCH_KEEP_ASPECT_COVERED`).

`scenes/chapter_view/ChapterView.gd`:
- New `@onready var background: TextureRect = $Background`.
- New method `_update_background() -> void`, called from
  `_render_current_node()` alongside the existing `_update_status_readout()`
  call.
- Logic: build `"res://assets/backgrounds/%s.png" % chapter_id`; if
  `ResourceLoader.exists(path)`, load and assign it as `background.texture`;
  otherwise set `background.texture = null`. This means a chapter with no
  art yet (every chapter, until the script has actually been run once, and
  any future chapter added later without a matching background) renders
  exactly as it does today - no crash, no missing-texture placeholder, no
  new failure mode.

No other engine or content file changes. `DialogueEngine`, `Ledger`,
`ReputationTracker`, and every chapter's JSON are untouched.

## Testing

- `tests/unit/test_chapter_view.gd` gets new tests for `_update_background()`:
  one confirming a chapter id with a real background file on disk sets a
  non-null texture, one confirming an unknown/missing chapter id leaves
  `background.texture` null without erroring. This follows the project's
  existing GUT discipline for everything under `scenes/`.
- **Deliberate carve-out:** `generate_backgrounds.py` gets no automated
  test. It is a dev-only tool that wraps a paid third-party SDK and talks to
  a live network API - there is no Python test harness anywhere in this
  project, and a test that actually called pixellab would spend real money
  on every CI run. This mirrors the project's existing standing exception
  for full code review: a deliberate, explicitly-stated gap rather than a
  silent one. Its correctness is checked by running it once by hand against
  the real API and inspecting the resulting PNGs and `assets/backgrounds/`
  contents.

## What this pass does not do

- No live in-game API calls, ever - confirmed direction, not a placeholder.
- No portraits, icons, or any art beyond the ten location backgrounds.
- No animation, no parallax, no per-node (only per-chapter) art variation.
- No change to any chapter's JSON content, mechanics, or test files beyond
  `test_chapter_view.gd`.
- No retry/backoff logic in the generator - it's a small, manually-run batch;
  a failed location gets rerun by hand with `--force`.
