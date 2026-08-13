# Sarakhs — A Wife Also Chosen (Garrison-Town Social Structure)

**Status:** approved, pending implementation plan.

## Goal

Seventh installment of the content-expansion initiative — the last remaining topic deferred from Bost's own clarifying question: garrison-town social structure, as distinct from the military hierarchy (ghulam/ghazi pay split) and administrative decline already covered elsewhere. Sarakhs was confirmed as the better fit over Pushang: it's a literal fortress-garrison, already has an established, unnamed recurring figure (the old soldier at `n03a_the_ghulams_road`) to extend, and Bahram's own aside about "my wife's people, west of here" (`n08_the_commanders_charge`) already hints at family life beyond the ranks.

**Real correction made during research, not assumed:** the original idea (ghulams marrying local women, integrating into the civilian population) is factually backwards. Verified via live web search: ghilman were typically married to Turkic slave-women *chosen for them* by their owners — a deliberately maintained caste separateness, not community integration. Sebuk-Tegin — already name-dropped in this exact chapter's `n03a` as the ghulam who "ended up governing an entire province" — is the documented exception: he married *up*, into his own master's daughter, which the search results explicitly note is why that story gets told and retold. This is a better, more specific, more grounded scene than the original idea, and it builds directly on content already in this chapter rather than a generic "soldiers have families too" beat.

## The content

Retarget `n04a_the_treasurys_long_reach`'s single existing choice (`"Continue."`) from `next_id: "n05_bahram_the_gatekeeper"` to `next_id: "n04b_a_wife_also_chosen"`. Its own `text` and `effects` (`{}`) stay unchanged. This sideroad is optional — reached only via `n02_the_choice_at_the_yard`'s "Linger in the garrison's outer yard" choice; the "Go straight to whoever commands this gate" choice skips it entirely and lands on `n05` directly, unaffected by anything in this pass.

Two new nodes inserted between `n04a` and `n05`:

**`n04b_a_wife_also_chosen`**: the old soldier from `n03a` points out his own wife crossing the yard — Turkic-born too, bought young the same as he was, given to him "the same way his sword and his post had been given to him." He retells the Sebuk-Tegin story from `n03a` from a different angle this time: "That's why men still tell it. The rest of us don't marry up. We marry whoever the ledger already owns." Two choices:
- `"Ask if it's always arranged that way."` (index 0) → `n04c_what_the_arrangement_makes`, effects `{"flags": ["learned_of_arranged_ghulam_marriages"]}` — flavor-only tracking flag, no currently-planned payoff, same shape as this initiative's prior flavor flags (Teginabad's `haggled_at_teginabad`, Bost's `learned_of_two_mints_dispute`, Pushang's `asked_about_the_khutba`).
- `"Say nothing. It's not yours to ask about."` (index 1) → straight to `n05_bahram_the_gatekeeper`, effects `{}`.

**`n04c_what_the_arrangement_makes`** (only reached via "Ask"): a flat, unsentimental answer — "Always, far as I've ever seen... Didn't stop anything growing there after, mind - I've two sons and no complaints to make of either her or them. Only that whatever grew, grew from a start neither of us picked." Deliberately avoids both romanticizing the arrangement and treating it as pure grievance — matches the old soldier's established voice ("a fact of the arithmetic, not a wound," echoing `n04a`'s own "fragile arithmetic" line). One choice, `"Continue."` → `n05_bahram_the_gatekeeper`, effects `{}`.

Both paths converge on the existing `n05_bahram_the_gatekeeper`, unchanged. Neither new node uses an `npc_portrait` key — the old soldier, like Pushang's passerby, stays unnamed and unportrayed, consistent with how this chapter already treats him in `n03a`/`n04a`.

**No new glossary term.** "Ghulam" is used repeatedly as plain prose throughout this chapter already (`n03a`, `n04a`, `n05`) and is confirmed, via direct check of `content/glossary/sarakhs_terms.json`'s actual keys, to never have been a glossed term at all (only `ghazi` is) — so no collision risk and no new entry needed; the new nodes simply continue this chapter's own existing convention.

**Zero coin/reputation effects on either new choice** — deliberately flavor-only, same low-blast-radius design as this initiative's last two passes (Bost's currency scene, Pushang's khutba scene), for the same reason: the value here is the worldbuilding beat, not another economic lever.

## Testing

Verified directly against the real current test files, not assumed:

- Exactly **one** existing test needs updating: `tests/unit/test_sarakhs_dialogue_content.gd`'s `test_choosing_the_yard_visits_the_sideroad_then_converges()`. It currently walks `n01 -> n02 -> n03a -> n04a -> n05` via 4 explicit `engine.choose(0)` calls, asserting the node id at each step. After this change, the 4th `choose(0)` (at `n04a`) lands on `n04b`, not `n05` — the test needs 2 more `choose(0)` calls added (through `n04b`'s "Ask" choice, index 0, to `n04c`, then `n04c`'s only choice to `n05`) with matching intermediate assertions, before its final assertion (still `n05_bahram_the_gatekeeper`) holds again.
- **Every other test in this file is confirmed unaffected**, verified by direct reading, not assumed: `test_choosing_straight_to_the_commander_skips_the_sideroad()` and all of `test_the_accept_freely_choice...`, `test_the_accept_for_coin_choice...`, `test_the_decline_choice...`, `test_the_road_fork_straight_to_nishapur...`, `test_the_road_fork_via_merv...` all take `n02`'s "Go straight to whoever commands this gate" choice (index 1), which skips the sideroad entirely and reaches `n05` in one step regardless of anything added between `n04a` and `n05`. None of their hop-counts change.
- `tests/unit/test_npc_portrait_content.gd`'s check of `n05_bahram_the_gatekeeper`'s portrait is unaffected — `n05` itself doesn't change.
- Two new test functions needed for the new nodes: one walking "Ask" through to `n04c_what_the_arrangement_makes` and confirming the flag + eventual convergence on `n05`, one walking "Say nothing" straight to `n05` with empty effects.
- `test_every_next_id_points_at_a_node_that_exists` and `test_exactly_two_nodes_have_no_choices_and_they_are_the_two_terminal_nodes` automatically cover the new nodes' wiring, no manual change needed. `test_every_glossed_term_id_exists_in_the_sarakhs_glossary` needs no change — the new nodes introduce no glossed term at all.
- `test_glossary_terms_and_flag_names_are_unique_across_all_manifest_chapters` (in `test_chapter_view.gd`) automatically covers the new `learned_of_arranged_ghulam_marriages` flag — confirmed via direct grep that this flag name does not already exist anywhere in the project.
- **This sideroad IS on the "always press 0" path** (`n02`'s index-0 choice is "Linger in the garrison's outer yard"), so `test_chapter_view.gd`'s full-playthrough tests will walk through both new nodes. Confirmed **unaffected** regardless: their `while ... presses < 200` loops absorb the extra hops with no assertion changes needed, and since neither new choice carries any coin or reputation effect, no cumulative wealth/reputation total shifts.
- The full existing suite (300 tests as of the last merge to `master`) must grow by exactly 2 (the two new dialogue-content tests) to 302, with no failures.

## What this pass does not do

- Does not add any new NPC, name, or portrait — the old soldier stays unnamed, matching `n03a`/`n04a`'s own established treatment of him.
- Does not touch `n04a`'s or `n05`'s own text, or any other already-shipped Sarakhs content.
- Does not add a glossary entry for `ghulam` (out of scope for this pass — the chapter's existing convention of leaving it unglossed is left as-is, not revisited).
- Does not add any coin or reputation effect anywhere in this pass.
- Does not assert anything about what became of the old soldier's two sons — deliberately left open, avoiding an unverified claim about hereditary status in this system.
