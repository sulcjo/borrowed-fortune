# Pixellab art generator

Generates the game's location background PNGs via [pixellab.ai](https://www.pixellab.ai)'s
`pixflux` API. Offline dev tool — the shipped game never calls this API; it only
ever reads whatever PNGs already exist under `assets/backgrounds/`.

## Setup

1. Get an API token from your pixellab.ai account dashboard.
2. `pip install pixellab`
3. Copy `.env.example` (repo root) to `.env` and fill in your token:
   ```
   PIXELLAB_SECRET=your-token-here
   ```
   `.env` is gitignored — never commit your real token.

## Usage

From the repo root:

```bash
python3 tools/pixellab/generate_backgrounds.py
```

Generates every location listed in `locations.json` that doesn't already have
a PNG under `assets/backgrounds/`. Safe to re-run — already-generated
locations are skipped, so it costs nothing to run again after adding one new
location.

To force a regeneration:

```bash
python3 tools/pixellab/generate_backgrounds.py --force              # regenerate everything
python3 tools/pixellab/generate_backgrounds.py --force herat.png    # regenerate just one location
```

Each location is generated once and its PNG is copied to every chapter id
listed in its `chapter_ids` array (e.g. Herat's Chapter 4A and 4B share one
generated image, so this only spends one generation, not two).

## Adding a new location

Add an entry to `locations.json`:

```json
{
  "output": "some_place.png",
  "chapter_ids": ["chapter_09_some_place"],
  "description": "one line, grounded in that chapter's actual opening prose"
}
```

Then re-run the script — it will only generate the new entry.
