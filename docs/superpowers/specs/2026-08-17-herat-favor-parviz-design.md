# Herat Favor — Parviz, the Other Courier

**Status:** approved, pending implementation plan.

## Goal

This is the "expand the dark route" item from the north-star expansion list — the one item this session's per-city sweep flagged as too large for the light-touch pattern used everywhere else (Ghazni through Nishapur, both confirmed via direct read that Merv and the plunder route's existing content need no further additions). Scoped down through direct conversation with the user to something concretely buildable in one pass.

**Confirmed with the user:**
- The plunder ending (`chapter_05_plunder_ending`) stays exactly as spare and open as its own design doc already commits to ("deliberately open / no closure"). This pass adds atmosphere and characterization to the entangled path, not resolution.
- New content lives entirely inside the existing `chapter_04b_herat_favor.json` — no new chapter file, no manifest changes, no new location.
- The gap: `n14_the_choice` → `n15a_entangled_deeper` → `n16a_the_first_task` → `n17a_departure_bound` currently *tells* the player Farrukh takes on a second errand but never *shows* it. That's the thinnest stretch on either branch of this chapter.
- The task itself: another delivery, structurally like the one Farrukh just completed for Rostam — but this one makes the network's human cost visible, rather than adding physical danger or resolving the plot.
- Scale: a full mini-scene (roughly 6-7 nodes) with a named minor character, not a one-line aside.
- The character (**Parviz**, see below) reads as *comfortable* in this work, not miserable or cautionary — the user explicitly preferred this over a more obviously-warning-sign portrayal, since it's more unsettling and more consistent with this game's general avoidance of simple morality.
- Parviz gets a real generated portrait via the existing `tools/pixellab/generate_portraits.py` pipeline, not a portrait-less background mention — the user's explicit choice, made aware this requires a paid third-party API call and `.env` credentials this worktree does not currently have.

## The content

Retarget `n16a_the_first_task`'s single existing choice (`"Continue."`) from `next_id: "n17a_departure_bound"` to `next_id: "n16c_the_handoff"`. Its own `text` and `effects` (`{}`) stay unchanged.

Five new nodes inserted between it and the existing, unchanged `n17a_departure_bound`:

**`n16c_the_handoff`**: Farrukh arrives at the place Rostam named — a location beat, not a new city (matches this chapter's existing pattern of unnamed back-room/quarter settings, e.g. `n05_the_far_edge_of_herat`). Ends on noticing someone already there, waiting on the same errand — unnamed at this point. `npc_portrait`: none (nobody's been introduced yet). One choice, `"Continue."` → `n16d_parviz_introduced`, effects `{}`.

**`n16d_parviz_introduced`**: that someone is Parviz — a courier a year or so further into this work than Farrukh, doing the identical job, at ease with it in a way that reads as unplaceable at first (not obviously threatening, not obviously worn down either). `npc_portrait: "parviz"`. One choice, `"Continue."` → `n16e_parviz_at_ease`, effects `{}`.

**`n16e_parviz_at_ease`**: Parviz talks about the work the way a man talks about any job he's stopped resenting — no lecture, no warning, just visible comfort with something Farrukh is still only one errand into. This is the scene's real content: showing that entanglement can start to feel normal rather than obviously costly. `npc_portrait: "parviz"`. Two choices:
- `"Ask him if it gets easier."` (index 0) → `n16f_asked_if_it_gets_easier`, effects `{"reputation": {"hidden_network": 1}}` — Parviz answers as reassurance, not warning; a small gesture of the same recognition `n12c_a_moment_of_recognition` established with Rostam himself.
- `"Say as little as possible. This isn't a friendship."` (index 1) → straight to `n16h_carrying_it_back`, effects `{}` — no penalty, matching this game's established "declining a personal matter costs nothing" precedent (same shape as `n12b_rostams_own_road`'s own "say nothing" branch).

**`n16f_asked_if_it_gets_easier`** (only reached via "ask"): Parviz's answer — yes, and he means it kindly, which is the unsettling part. `npc_portrait: "parviz"`. One choice, `"Continue."` → `n16h_carrying_it_back`, effects `{}`.

**`n16h_carrying_it_back`**: task completed, converging point for both branches above. A short reflection beat — Farrukh carries the image of Parviz's ease forward, not a resolved feeling, just an unresolved one he's now walking around with. `npc_portrait`: none (Parviz is off-page again; matches the established convention of NPCs not persisting into solo reflection beats, e.g. `n20_aftermath` in `herat.json`). One choice, `"Continue."` → `n17a_departure_bound`, effects `{}`.

Both branches converge on the existing `n17a_departure_bound`, unchanged — same text, same `flags: ["chose_to_stay_entangled"]` already set upstream at `n14_the_choice`, same `next_chapter_id: "chapter_05_plunder_ending"`.

No new flag is introduced anywhere in this scene. Neither ending reads it (`chapter_05_plunder_ending`'s design doc confirms no new content is planned there), so a new flag here would be exactly the orphaned-seed pattern already worked through and rejected at Pushang.

## Portrait asset

New entry needed in `tools/pixellab/npcs.json`:

```json
{"id": "parviz", "description": "a young courier in road-worn but decent clothes, relaxed unguarded posture, faint easy smile, waist-up portrait bust"}
```

Generating it requires `python tools/pixellab/generate_portraits.py` (or equivalent invocation per `tools/pixellab/README.md`) with valid pixellab API credentials in `.env` at the repo root — **this worktree currently has no `.env`**, so this step is blocked on the user supplying credentials, not on anything content-side. The dialogue content itself does not depend on the portrait existing: `npc_portrait: "parviz"` referencing a not-yet-generated file fails gracefully to no portrait shown (confirmed via the existing `test_npc_portrait_with_unknown_id_clears_without_erroring` test in `tests/unit/test_chapter_view_portraits.gd`), so content and portrait-generation can land in either order or even separately.

## Testing

Per the user's standing instruction partway through this session, the GUT suite is not being run or maintained for content changes in this project. Verification for this pass is:

- `python3 -c "import json; json.load(open('content/chapters/chapter_04b_herat_favor/herat_favor.json'))"` after the edit, to confirm valid JSON.
- Manual trace of both new-node next_id chains to confirm no dead ends and correct convergence on `n17a_departure_bound`.
- Manual confirmation that this insertion sits only on the `chose_to_stay_entangled` path (`n15a_entangled_deeper` onward) and never on `chose_to_pivot_away` (`n15b_pivot_away` → `n16b_the_veiled_threat` → `n17b_departure_free`), so the pivot-away ending and its flags are entirely unaffected.
- advisor() consultation before considering the pass complete, matching this session's established practice.

If the user later reverses the standing test-suite instruction, the following would need updating in `tests/unit/test_herat_favor_dialogue_content.gd`: any test using a hardcoded step count that crosses the `n16a` → `n17a` boundary, plus two new dedicated tests (one per branch) and a `hidden_network` reputation-total update in `tests/unit/test_chapter_view.gd`'s plunder-branch full-playthrough test (currently asserts `total == 3`; would become `4` on the "ask if it gets easier" default path, since that choice sits at index 0).

## What this pass does not do

- Does not resolve, hint at, or change anything about `chapter_05_plunder_ending`'s deliberately open endings, or any of its flags.
- Does not reveal, hint at, or overclaim anything about the Rayy/Buyid/da'i backstory — untouched, per this chapter's own existing established boundary.
- Does not show or reference the "last courier" Rostam alluded to in `n12_rostams_boast` — that stays deliberately unshown; Parviz is a distinct, currently-unharmed character.
- Does not add a coin effect anywhere — the stakes here are relational (`hidden_network` reputation) and atmospheric, not economic.
- Does not add a new glossary term.
- Does not touch the `chose_to_pivot_away` branch at all.
