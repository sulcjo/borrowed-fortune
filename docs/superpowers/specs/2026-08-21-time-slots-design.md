# Named time slots — a stay you can spend

Date: 2026-08-21
Status: design approved, ready for implementation planning

## Why

The delayed-consequences work made the game more *responsive*: a decision taken in
one city now changes how a later city reads. It deliberately did not make the game
more *decidable*, and the measurement says so. Across all 229 nodes:

| Measure | Value |
|---|---|
| Nodes offering **no decision** (0 or 1 choice) | **175 / 229 (76%)** |
| Nodes with 2 choices | 45 (20%) |
| Nodes with 3 or more choices | 9 (4%) |

That 76% is the distance between this game and the quality it is reaching for. A
node that reads differently because you bribed an official four chapters back is a
reaction. A morning in which three things are happening and there is room for one is
a decision. Conditional text cannot produce the second by construction; this can.

## The prototype already in the repository

Nishapur is described as a two-day stay, and structurally it is:

- **Day one, a spine:** `n01_nishapur_arrival` → `n02` → `n03` → `n03b_word_to_nasuh`
  → `n03c` → `n03d_the_ledgers_last_entry` → `n03e_the_first_night`
- **Day two:** `n04_the_choice_before_the_khaneqah`, which offers three options — the
  unspent favour, Bahram's family (gated on `carries_the_commanders_token`), and the
  mandatory Mansur beat — and then converges on the khānaqāh.

So "several things, room for one" already exists. It is implemented as a plain
three-way branch, which means:

- nothing conveys what was given up; the unchosen options simply never recur
- there is no concept of time, only of position in a graph
- it cannot be reused by another city without being rewritten
- it cannot express "two of four", only "one of three"

This spec generalises that shape rather than inventing a system.

## Decisions and their provenance

1. **Named time slots**, over an abstract action budget, over opportunity-sets with
   no counter, over days with expiring events. Named slots are diegetic: the player
   reads "the next morning", not "1 action remaining", which suits a game whose
   entire surface is a manuscript. An action budget would want a counter on screen
   and pull the folio toward a HUD. Expiring events are the strongest version of the
   idea and much the largest build; they also risk the player never learning that
   content existed.
2. **Untaken opportunities set flags.** Ending a stay records what was declined as
   precisely as what was done, so the `text_variants` machinery can pay it off
   later. This is the unread-letter thread generalised: an absence that nothing
   registers is invisible, and invisible absence is indistinguishable from absent
   content.
3. **Mandatory beats stay on the spine, outside the hub.** A hub holds only optional
   opportunities. This avoids a "mandatory opportunity" concept entirely — the
   engine never has to decide whether a stay may end — and it matches Nishapur's
   real shape, where the Mansur beat is required and belongs before or after the
   stay rather than inside it.

## The model

A chapter's manifest entry declares its stay:

```json
"chapter_08_nishapur": {
  "dialogue_path": "res://content/chapters/chapter_08_nishapur/nishapur.json",
  "glossary_path": "res://content/glossary/nishapur_terms.json",
  "next_chapter_id": null,
  "farrukh_wear_stage": 3,
  "place_name": "Nishapur",
  "stay": { "slots": ["the first evening", "the next morning", "that afternoon"] }
}
```

A **hub** is an ordinary node whose choices are the opportunities. Taking one runs
its branch; the branch returns to the hub. Three new optional keys on a choice:

```json
{
  "text": "Go to Bahram's family with the token.",
  "next_id": "n05a_bahrams_family",
  "spends_slot": true,
  "forbids_flag": "visited_bahrams_family",
  "forgone_flag": "never_visited_bahrams_family",
  "requires_flag": "carries_the_commanders_token",
  "effects": { "flags": ["visited_bahrams_family"] }
}
```

- `spends_slot` — taking this choice advances the stay by one slot. Omitted or false
  means the choice is free, so a hub can hold questions that cost no time.
- `forbids_flag` — hides the choice once the named flag is set, which is how a taken
  opportunity stops being offered.
- `forgone_flag` — written when the stay ends with this opportunity never taken.

A fourth key gates the way out. The hub's onward choice — the one that leaves the
city — carries `requires_slots_spent: true`, so it is hidden while time remains and
appears once the stay is exhausted:

```json
{ "text": "Leave for the khanaqah.", "next_id": "n06_the_khaneqah_at_dusk",
  "requires_slots_spent": true, "effects": {} }
```

Without this the player could walk out of a stay without spending it, and the
forgone flags would never be written.

A chapter without a `stay` key behaves exactly as it does today. Every existing
chapter is therefore untouched until deliberately converted.

## Engine additions

Five, each small. One is nearly free because of the delayed-consequences refactor.

```gdscript
var slots: Array = []          # slot names for this chapter's stay; empty if none
var slot_index: int = 0        # which slot the stay is in

func current_slot_name() -> String   # "" when the chapter declares no stay
func slots_spent() -> bool           # slot_index >= slots.size(), false with no stay
```

**Who supplies `slots`.** `DialogueEngine` never reads the manifest — `ChapterView`
does, in `load_chapter_by_id()`, which is already where `place_name` and
`farrukh_wear_stage` are lifted out of the entry. It assigns
`dialogue_engine.slots` there, the same way it assigns `dialogue_engine.reputation`
before each render. The engine stays free of file access, which is the existing
division and worth keeping.

- **`forbids_flag` and `requires_slots_spent` in `_conditions_met()`.** Because that
  predicate is already shared by choices *and* `text_variants`, adding them there
  makes them work for prose and options at once, with no second implementation — a
  hub's text can vary on whether time is gone, for free. This is the
  delayed-consequences refactor paying a dividend it was not written for.
- **`spends_slot` handled in `choose()`**, advancing `slot_index`.
- **Stay exhaustion.** When `slot_index` reaches `slots.size()`, every hub choice
  carrying a `forgone_flag` that was never taken has that flag set, and the hub's
  onward choice becomes available.
- **Corrected during implementation.** This spec claimed slot-spending
  opportunities "hide themselves once the slots are gone, via the same condition
  mechanism". They do not — `forbids_flag` hides only an opportunity that was
  *taken*, so an untaken one stayed on offer after the stay was exhausted, and
  taking it pushed the slot index past the end of the stay. The end-to-end test
  caught it; the unit tests could not, because none of them returned to a hub after
  exhaustion. `_choice_is_available()` now refuses any `spends_slot` choice once
  `slots_spent()` is true. That belongs there rather than in `_conditions_met()`:
  it is a rule about spending time, not a condition an author writes.
- **Validation.** `validate_tree()` rejects `spends_slot` on a choice in a chapter
  with no declared stay, and a `forgone_flag` that collides with a flag some choice
  sets directly.

## Save format

`GameState` gains one key, `slot_index`. `from_dict()` reads every field through
`.get()` with a default, so an old save simply starts the stay at zero. That makes
the change backward-compatible at no cost — but it is the first change to the save
format in this project, and worth stating plainly rather than burying.

`slots` itself is not saved: it is content, reloaded from the manifest, so editing
the slot names of a chapter does not invalidate saves.

## The visible surface

The colophon currently reads `Nishapur · Coin: 0.0 dirham`. With a stay in progress
it reads `Nishapur, the next morning · Coin: 0.0 dirham`. The slot is prose in the
same muted ink as the rest of the line — no counter, no new UI, no HUD.

The hub's own text uses `text_variants` gated on the slot, so returning to it reads
differently each time. That, rather than any mechanism, is what makes a slot feel
like a time of day instead of a resource.

## Retrofitting Nishapur is a separate task

Nishapur's day-two fork currently *converges*: each of its three branches flows
onward to the khānaqāh. A hub needs them to *return*. That is real restructuring of
shipped, tested content, and five of the 22 known-stale test failures already live in
`test_nishapur_dialogue_content.gd`.

Build the machinery against a new or simpler city first, prove it there, and retrofit
Nishapur as its own task afterwards. Doing both at once would make a machinery bug
and a content-restructuring bug indistinguishable.

## Testing

- `current_slot_name()` for: no stay declared, first slot, last slot, exhausted.
- `spends_slot` advances the index; a choice without it does not.
- `forbids_flag` hides a choice once its flag is set, and combines with
  `requires_flag` and `requires_reputation` (all three on one choice).
- Stay exhaustion sets every untaken `forgone_flag` and none of the taken ones.
- A hub returned to in a later slot renders different prose, via `text_variants`.
- `GameState` round-trips `slot_index`, and a save written before this change loads
  with the stay at zero.
- Validation rejects `spends_slot` without a declared stay.
- The colophon shows the slot name when a stay is active and omits it otherwise.
- The metrics ratchet in `test_consequence_metrics.gd` must be retightened: every
  `forgone_flag` is a new flag that is *set*, so authoring a hub without paying any
  of them off would push the dead-flag count back up. That is the ratchet doing its
  job, and the fix is to consume some, not to loosen it.

## Risks

- **Forgone flags are dead state until used.** Each one raises the dead-flag count
  the delayed-consequences work just lowered. This is acceptable only if hubs are
  authored alongside at least some payoffs; otherwise the ratchet will block, which
  is the intended pressure.
- **The 76% figure only moves if hubs offer real alternatives.** A hub with one
  opportunity and a "leave" option is a single-choice node wearing a costume. The
  metric to watch is nodes with 3 or more choices, currently 9.
- **Slot names are per-chapter prose**, so they can drift in register between
  cities — "the first evening" beside "day two". A short authoring note in the spec
  is the only guard.
- **First save-format change.** Backward-compatible by construction, but it
  establishes a precedent, and the next such change may not be as cheap.

## Verification

1. Full suite green apart from the pre-existing 22 failures and 1 risky.
2. `godot --path . -s tools/verify_folio_layout.gd` exits 0 — the colophon grows by
   a slot name and must not overflow the folio.
3. Walk a hub city: take one opportunity, confirm the others remain offered until
   the slots run out, then confirm the untaken ones set their flags.
4. Load a save written before this change and confirm the stay begins at zero.
5. Re-measure the consequence metrics and retighten the ratchet.
