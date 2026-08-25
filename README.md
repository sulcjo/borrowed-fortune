# Borrowed Fortune

A narrative game about inheriting a dead man's debts on a frontier that's about to fail.

## Premise

Ghazni, 1035 CE. Your father has just died, leaving a debt-choked, half-finished trading venture. At his graveside, you swear to stand surety for it yourself — a real, binding Islamic legal act (*kafāla*), not required of you by law, chosen anyway. Buried in the ledger is a payment instrument and a shipment manifest that don't match anything the shop ever carried — tied to money that smells of the Sultan's India campaigns, and to a name spoken with real fear.

The game is the road from Ghazni toward Nishapur. The frontier is failing as you travel it — real history: the Battle of Nasa (1035) is already unsettling news when you set out, and Sarakhs, Herat, and Nishapur all fall to the Seljuks within three years of your journey's start. You are walking toward a city that is, historically, about to stop being Ghaznavid at all. The empire's contingency and your father's contingency are the same shape.

No combat. Every stop is a node-chain of dialogue and choice, grounded in real 11th-century Ghaznavid Khorasan — Islamic-law mechanics (*kafāla*, *zakāt*, *ushr*), real historical figures and events (with anything invented or legendary flagged as such), and a Persian-miniature art direction framed diegetically as a later manuscript's retelling of the story.

## Status

The full campaign, as originally scoped, is built: both branches, both endings, and the one optional detour.

- **Prologue → Teginabad → Bost → Farah** — a true fork at Farah decides everything downstream.
- **The clean lead** continues to **Herat → Pushang → Sarakhs → (optional: Merv) → Nishapur**, ending in a choice about what kind of self survives a road like this one.
- **The favor owed** is shorter, forks again on its own terms, and converges on a single, quieter ending back in Herat's shadow.

11 chapters, two full playthroughs' worth of story, no dead ends.

## Running it

Requires the [Godot 4.3](https://godotengine.org/) engine.

```bash
godot --path /path/to/borrowed-fortune
```

or open the project in the Godot editor and run `scenes/main/Main.tscn` directly.

Progress survives closing the game. The main menu's **Continue** appears once there is
anything to continue, and resumes at the start of the chapter you had reached, with
coin, debt, reputation and story flags restored. Saving is chapter-granular by
design: state is written at each chapter boundary, so Continue puts you at the
opening of the next chapter rather than mid-scene.

## Running the tests

[GUT](https://github.com/bitwes/Gut) is vendored at `addons/gut/`. A fresh checkout needs one priming run before the headless test command will find its class names:

```bash
godot --headless --path . --editor --quit   # once, per fresh checkout
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

**Prefer `godot --headless --import`** — it builds both the import cache and the
script-class cache, exits 0, and needs no display:

```bash
godot --headless --import                    # twice, per fresh checkout
godot --headless --import
```

Twice is not superstition. On a checkout with no `.godot/` the first pass imports GUT's
own scripts but cannot yet resolve their class names, and ends with:

```
ERROR: Some GUT class_names have not been imported.  Please restart the Editor or run godot --headless --import
Missing class_names:  ["GutHookScript", "GutInputFactory", ... "GutTest", "GutUtils"]
```

It still exits 0, so a script that checks only the exit code will move on and every test
will then fail to parse `extends GutTest`. The second pass sees the cache the first one
wrote and is silent.

`--editor --quit` also works but ends in an abort (exit 134) after writing the
class cache, and on a checkout whose `.godot/imported/` is empty it fails earlier
still, on missing `.ctex` files for GUT's own icons and fonts. Use `--import`.

Re-run the priming step after adding any new `class_name`; the cache is gitignored,
so a checkout that predates a class cannot resolve it. Symptom:
`Parse Error: Identifier "..." not declared in the current scope`.

### Walking a chapter in a test

Do not write `for i in range(9): engine.choose(0)`. That 9 is not a fact about the
route, it is a count of how many nodes happened to sit in front of the target on the
day the test was written — add one beat of prose and the test lands short and fails,
having found nothing wrong. Twenty-two tests were red at once for exactly that, and
the cost was not the red: a route genuinely breaking looked identical, so the suite
had stopped being able to report one.

Use the helper instead:

```gdscript
const Nav := preload("res://tests/helpers/navigation.gd")

Nav.expect_reaches(self, engine, "n12_departure_provisioned")
```

It presses 0 until the target arrives or a 60-step budget runs out, and on failure
reports the route it actually walked. Adding prose no longer breaks it; a broken route
still fails. Take a specific option with `engine.choose(index)` as before, and use the
helper only for the prose in between. Keep an assertion exact where the exact landing
is the point — a choice's immediate destination, or an accumulated total.

### Assets

Every texture is loaded through `engine/assets/TextureLoader.gd`, which asks for the
**imported** resource rather than reading the PNG off disk. That distinction is not
cosmetic: `Image.load_from_file()` reads a raw file, an exported build serves
`res://` out of the `.pck` where only imported resources live, and Godot warns
"this will not work on export" for precisely that reason. Loading raw would have
shipped a build with no art in it.

`*.import` files are versioned, because they carry each texture's UID and import
settings and keep imports reproducible across machines. The imported binaries
themselves live in `.godot/`, which is not versioned — so a fresh clone still needs
one `godot --headless --import` pass to generate them.

The loader keeps a raw-file fallback for images written at runtime, which tests do;
those are never imported, so `load()` cannot see them. Shipped assets never take
that branch.

### Verifying an export without export templates

Templates are only needed to produce a runnable binary. `--export-pack` writes just
the `.pck`, needs no templates, and is enough to prove the game finds its art when
`res://` is served from a pack instead of the filesystem:

```bash
# 1. A minimal preset. export_presets.cfg is gitignored, so write it locally:
#      [preset.0]
#      name="Linux"
#      platform="Linux"
#      export_filter="all_resources"
#      include_filter="*.txt,*.json"
#      exclude_filter=""
godot --headless --path . --export-pack "Linux" /tmp/bf.pck

# 2. Run the verifier from OUTSIDE the project directory (see the first trap below)
cd /tmp && godot --headless --main-pack /tmp/bf.pck -s tools/verify_export_textures.gd
```

It exits 0 when every checked asset resolves, and prints what
`Image.load_from_file()` does with the same path for contrast — `null`, which is what
every scene would have received before textures were loaded as imported resources.

**Two traps, both of which produce a confident false pass:**

- **Run it from outside the project.** With a `project.godot` in the working
  directory, `res://` resolves to the project on disk rather than to the pack, so
  everything appears to work and nothing has actually been tested.
- **Do not set `exclude_filter="*.png"`.** It looks like the way to prove the raw
  files are unnecessary, but it also strips the `*.png.import` remaps that map
  `res://assets/foo.png` to its `.ctex` — after which `load()` fails too, for a
  reason that has nothing to do with the code.

### Checking the folio layout

The unit and integration tests run headless, where container layout resolves
differently than under a real renderer — a page can be badly broken on screen while
every headless assertion passes. After touching `ChapterView`'s tree, `FolioMetrics`,
or anything that changes how the page is measured, run the rendered check as well:

```bash
godot --path . -s tools/verify_folio_layout.gd
```

It drives the real `Main.tscn` path, prints every region's rectangle, and exits
non-zero if the page overflows its window, the prose column has collapsed, or the
place inset has come off an integer scale. Needs a display; it is not a headless
check.

### Checking the ending outro's captions

The endings' outro panels are mostly caption-only — text over black, with no picture to
caption — and the caption bar is authored to sit in the bottom strip of the frame, where
it belongs under an image and reads as a subtitle to a missing one without. The unit
tests assert the anchor values, which is geometry rather than appearance, so there is a
rendered check too:

```bash
godot --path . -s tools/verify_outro_captions.gd
```

It measures where the caption actually lands in a 1280x720 window for both kinds of
panel and exits non-zero if a caption-only panel is not near the middle of the frame, if
it still draws its scrim, or if an imaged panel failed to put the bar back. Needs a
display.

## How it's built

```
engine/     pure GDScript logic - RefCounted classes, no scene tree, fully unit-tested
content/    the story itself - JSON dialogue trees, JSON glossaries, no code
scenes/     Godot orchestration - the views and popups that render content/ through engine/
tests/      GUT unit tests, one file per engine class and per chapter's content
docs/       design specs and implementation plans for every chapter, in the order they shipped
```

Every chapter is a JSON node graph: an id, some prose, a list of choices, each choice pointing at the next node and carrying optional effects (coin, reputation, story flags). A chapter manifest (`content/chapters/manifest.json`) chains chapters together — a chapter's terminal node names the next chapter's id, and the game loads it automatically. No engine change has ever been needed to add story content; the dialogue format has been expressive enough for every chapter, fork, sideroad, and gated reveal this game has, including the reputation-gated reveal in Chapter 4A and the branch-and-return detour to Merv.

Reputation is tracked per faction (trading families, ordinary townsfolk, Ghaznavid officials, and — much later — a hidden network) rather than one global morality meter, and — along with running coin and any outstanding debt — is always visible on screen, not hidden from the player.

## Historical grounding

Real places, real events, real vocabulary, glossed in-game the way a manuscript's margin might gloss an unfamiliar term for a later reader. Where something is legend rather than record — a treasure figure inflated by bazaar retelling, a saying attributed to a Sufi teacher through 130 years of hagiography — the game says so, in-fiction, rather than presenting it as settled fact. Every chapter's design doc (`docs/superpowers/specs/`) records what was verified before being written and what was deliberately left out as anachronistic or unattested.
