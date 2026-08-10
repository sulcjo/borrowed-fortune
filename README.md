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

The game has no save/resume-on-boot yet — closing and reopening always restarts at the Prologue. In-progress chapter state is saved to disk as you go, but nothing reads it back in on launch.

## Running the tests

[GUT](https://github.com/bitwes/Gut) is vendored at `addons/gut/`. A fresh checkout needs one priming run before the headless test command will find its class names:

```bash
godot --headless --path . --editor --quit   # once, per fresh checkout
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

226 tests, 944 asserts, all green.

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
