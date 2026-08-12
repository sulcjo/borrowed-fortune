# Teginabad Tutorial Trade Design

**Status:** approved, pending implementation plan.

## Goal

Chapter 1 (Teginabad) currently has zero economic content — every choice's effects are flags/reputation only, no coin ever moves. This adds the player's first trade in the whole game: three new nodes at the end of the chapter, where Farrukh provisions for the desert crossing to Bost. This is the first installment of a broader "add more content to the chapters" initiative — subsequent chapters get their own design/spec/plan cycle later, one at a time, matching this project's established precedent (Chapters 5/6/7/8 each got their own cycle).

## Why here, and why it doesn't contradict what's already written

`n08_guide_transition` (already shipped) says Farrukh hires a caravan guide "haggling nothing, since there was nothing left in him to haggle with" — a deliberate grief-driven characterization beat, not an oversight, and not touched by this change. The new scene is a **different transaction, with a different person, immediately after** — the point is the contrast: he couldn't engage over the guide's fee, but something shifts one stall later. `n09_departure_teginabad` (the current final node) is also untouched — it stays exactly as shipped, and its `choices: []` becomes a single `"Continue."` into the new scene. This is deliberately a **small** turning point, not a reversal: the act of choosing to push back (if the player does) is the beat, not a dramatic transformation.

## Placement and mechanics

Three new nodes, using the existing trading-engine mechanics exactly as already used elsewhere (no engine changes — `coin_spent_dirham_equivalent` and `reputation` effects keys, `Ledger.spend_dirham_equivalent()`/`ReputationTracker.adjust_reputation()` already wired through `ChapterView._apply_effects()`): `n10_the_provisioner` (opening, 3 choices) → `n11_provisioner_pushback` (reached only by haggling, 2 choices) → `n12_departure_provisioned` (new terminal, replaces `n09` as the chapter's end, same text regardless of path). This is smaller than the full Chapters 4A/4B haggle template (opening/lowball/reaction/breakdown-or-discount) but richer than the game's minimal precedent (Farah's single-node, two-choice bed price) — it teaches that pushing back gets a real but modest concession, without the stakes of a breakdown branch, appropriate for the player's very first trade.

Choice phrasing reuses this project's own established exact wording for haggle scenes (confirmed via direct grep: "Pay what she asks." and "Try to talk her down." both already appear verbatim in Farah's and Merv's haggle nodes) rather than inventing new phrasing for the same action.

`n12_departure_provisioned` omits `next_chapter_id` entirely (same convention as the `n09` it replaces) — the manifest's existing `chapter_02_bost` default for `chapter_01_teginabad` applies unchanged. No manifest edit in this pass.

## Content (exact text and effects)

`n09_departure_teginabad`'s existing text is unchanged. Its `"choices": []` becomes:
```json
"choices": [{"text": "Continue.", "next_id": "n10_the_provisioner", "effects": {}}]
```

**`n10_the_provisioner`** (new node, `npc_portrait: "teginabadprovisioner"`):
> At the last stall before the gate closed off the desert road, a woman was calling out prices for waterskins, dried dates, and feed enough for two animals across empty country - the same unglamorous arithmetic Farrukh had waved past an hour before, when the caravan master's fee hadn't seemed worth arguing over. This time, for no reason he could have named, it did. She named eight dirhams for the lot, in the flat voice of someone who'd already decided what she'd settle for and wasn't going to say so first.

Choices:
- `"Pay what she asks."` → `n12_departure_provisioned`, effects `{"coin_spent_dirham_equivalent": 8.0, "reputation": {"trading_families": 1}}`
- `"Try to talk her down."` → `n11_provisioner_pushback`, effects `{}`
- `"Take the water, skip the rest, and go."` → `n12_departure_provisioned`, effects `{"coin_spent_dirham_equivalent": 3.0}`

**`n11_provisioner_pushback`** (new node, `npc_portrait: "teginabadprovisioner"`):
> She didn't look up from tying off a waterskin. "Eight is the price for a man who wants to reach Bost with feed left over," she said. "I can do seven, if you're the praying kind and don't mind your animals thinking hard thoughts about you around Bost." It wasn't much of a concession. It was, Farrukh noted with something almost like satisfaction, a concession.

Choices:
- `"Take the seven."` → `n12_departure_provisioned`, effects `{"coin_spent_dirham_equivalent": 7.0, "flags": ["haggled_at_teginabad"]}`
- `"Pay the eight after all."` → `n12_departure_provisioned`, effects `{"coin_spent_dirham_equivalent": 8.0, "reputation": {"trading_families": 1}}`

The "pay the eight after all" choice gets the same `trading_families` reputation as paying fair directly from `n10` - from the provisioner's side, both are the identical outcome (eight dirhams, deal closed at her asking price); reputation reflects what she experienced, not which route Farrukh took to get there. Caught during this spec's own self-review - an earlier draft gave this path no reputation at all, which was inconsistent with the direct-pay path for an identical result.

**`n12_departure_provisioned`** (new node, no `npc_portrait` — Farrukh is alone again by this point, matching the existing convention that departure/transition nodes drop the prior scene's portrait, e.g. Herat 4A's `n21_departure_herat`):
> The gate fell behind him with the animals fed and the waterskins full, whatever that had cost. It was a small thing - a woman's asking price, met or shaved down by one dirham, nothing that would have troubled his father's ledgers for a moment - but it was the first arithmetic since Ghazni that Farrukh had done because he wanted to, and not because grief or custom or a customs officer's patience had required it of him. The desert road to Bost opened out ahead, indifferent to the distinction, the way roads are.

Choices: `[]` (terminal).

No new reputation faction, no new flags beyond `haggled_at_teginabad` (which nothing downstream reads yet — recorded for a future chapter to potentially call back to, same pattern as `carries_the_commanders_token` from Sarakhs, though this spec makes no forward-reference commitment; it may simply stay unread, which is fine, several existing flags already do).

## New portrait

One new NPC, `teginabadprovisioner`, added to `tools/pixellab/npcs.json`:
```json
{
  "id": "teginabadprovisioner",
  "description": "a weathered provisioner woman at a roadside stall, waterskins and dried dates on display, practical desert-travel dress, waist-up portrait bust"
}
```
Generated via the existing `tools/pixellab/generate_portraits.py` at the project's current portrait resolution (200x200, per the ChapterView dialogue rework earlier this session) — a real, funded pixellab API call, one generation.

## Glossary

No new glossed terms. Confirmed via direct grep that "dirham" already appears as ordinary prose vocabulary in this game's existing chapters (e.g. Chapter 1's own `n07a_bribe`, and Chapter 4A's Herat bazaar description) and is never itself a glossary entry — it doesn't need defining, it's just the coin.

## Testing

- `tests/unit/test_teginabad_dialogue_content.gd` has two tests that assert the OLD terminal node and must be updated in the same task, not deferred — this is the exact "grep for tests asserting the old value" lesson this project has hit before, at both the flag-name and node-path level:
  - `test_exactly_one_node_has_no_choices_and_it_is_the_last_node()` currently asserts `end_node_ids == ["n09_departure_teginabad"]` → must become `["n12_departure_provisioned"]`.
  - `test_the_full_tree_is_walkable_from_start_to_end_via_first_choices()` currently asserts the final node reached by always choosing index 0 is `"n09_departure_teginabad"` → must become `"n12_departure_provisioned"` (choosing index 0 at `n10_the_provisioner` is "Pay what she asks.", which leads directly to `n12` — the always-first-choice walk never visits the haggle branch, which is correct and expected, matching how this same walk never visits the bribe-vs-honest fork's alternate branch either).
- New tests, following this file's own established pattern (a `_load_nodes()`-based `DialogueEngine` walk, asserting effects the same split way — `assert_eq` on flags/reputation/coin keys individually, never a whole-dict `assert_eq`, per this file's own documented reason: `JSON.parse_string()` always returns floats, and Godot's `Dictionary ==` requires exact type equality at every nested leaf):
  - The pay-fair path reaches `n12_departure_provisioned` with `coin_spent_dirham_equivalent == 8.0` and `reputation == {"trading_families": 1}`.
  - The haggle-then-accept path (`n10` → "Try to talk her down." → `n11` → "Take the seven.") reaches `n12` with `coin_spent_dirham_equivalent == 7.0` and sets the `haggled_at_teginabad` flag.
  - The haggle-then-back-off path (`n10` → "Try to talk her down." → `n11` → "Pay the eight after all.") reaches `n12` with `coin_spent_dirham_equivalent == 8.0` and `reputation == {"trading_families": 1}` (same outcome as paying fair directly), and does **not** set `haggled_at_teginabad`.
  - The minimal-water path reaches `n12` directly with `coin_spent_dirham_equivalent == 3.0`.
- `tests/unit/test_npc_portrait_content.gd` has no existing Chapter 1 coverage at all (confirmed by reading the file directly — it covers Prologue, Farah, Pushang, Herat 4A/4B, Sarakhs, Nishapur, but never Teginabad). Add one new test to this file, `test_teginabad_provisioner_portrait_is_set_on_both_haggle_nodes()`, following its own established `_portrait_for()` helper pattern, asserting `"teginabadprovisioner"` on both `n10_the_provisioner` and `n11_provisioner_pushback`, and `null` on `n12_departure_provisioned` (Farrukh alone again, no NPC on-page).
- `tests/unit/test_teginabad_glossary_content.gd` needs no change — no new glossed terms.
- The full existing suite (289 tests as of the last merge to `master`) must stay green, plus whatever this pass adds.

## What this pass does not do

- Does not touch any other chapter, or the broader "add more content" initiative beyond this one scene — that stays chapter-by-chapter, one design cycle at a time.
- Does not add any new engine code — the trading engine (`coin_gained_dirham_equivalent`/`coin_spent_dirham_equivalent`, `requires_reputation` gating) already exists and needs nothing new for this scene, which uses only the already-wired `coin_spent_dirham_equivalent` and `reputation` keys.
- Does not change `content/chapters/manifest.json` — Chapter 1's `next_chapter_id`/`farrukh_wear_stage` entry is untouched, and the new terminal node defers to it exactly as the old one did.
- Does not add a UI tutorial hint, narrator aside, or any other fourth-wall-breaking text calling attention to the mechanic — consistent with this game having zero meta/tutorial text anywhere else. The scene teaches the mechanic by being one, not by explaining itself.
