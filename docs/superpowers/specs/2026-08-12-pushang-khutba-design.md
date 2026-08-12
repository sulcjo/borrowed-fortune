# Pushang — The Khutba (Legitimacy at a Distance)

**Status:** approved, pending implementation plan.

## Goal

Sixth installment of the content-expansion initiative. Adds the one angle of "frontier political/military decline" this game hasn't yet dramatized directly: court-level political legitimacy, as distinct from the administrative decay (Pushang's shuttered stalls, thinned watch, requisition tax) and military-pay fragility (Sarakhs's ghulam/ghazi split, treasury's long reach) already shipped. Extends `n08_the_sultans_three_tongues` directly — a natural neighbor, since that node already gestures at how governing this empire depends on being understood/obeyed by everyone whose obedience is actually needed.

## The content

Retarget `n08_the_sultans_three_tongues`'s single existing choice (`"Continue."`) from `next_id: "n09_the_officers_demand"` to `next_id: "n08b_the_khutba"`. Its own `text` and `effects` (`{}`) stay unchanged.

Two new nodes inserted between it and the existing, unchanged `n09_the_officers_demand`:

**`n08b_the_khutba`**: Farrukh overhears the Friday khutba carrying into the street. The khatib names both the Abbasid Caliph al-Qa'im (Baghdad — real, reigned 1031-1075, contemporary to this game's 1035-1038 setting, confirmed via live research before writing) and Sultan Mas'ud (Ghazni — real, reigned 1030-1040/41, also confirmed) in the same practiced breath, "as if the two men named in it governed a single, unbroken thing rather than whatever this fraying stretch of road actually was" — the ritual claim of unbroken authority landing right next to the visible fraying Farrukh just walked through in this same chapter. Deliberately does **not** reference Mas'ud's actual 1040 army rebellion/succession crisis — that is after this game's present and would be a spoiler/anachronism, same discipline as the Merv branch's no-time-skip rule. Two choices:
- `"Ask a passerby if the khutba's always this exact."` (index 0) → `n08c_the_passerbys_answer`, effects `{"flags": ["asked_about_the_khutba"]}` — flavor-only tracking flag, no currently-planned payoff, same shape as Teginabad's `haggled_at_teginabad` and Bost's `learned_of_two_mints_dispute`.
- `"Notice how practiced the words sound, and say nothing."` (index 1) → straight to `n09_the_officers_demand`, effects `{}`.

**`n08c_the_passerbys_answer`** (only reached via "Ask"): an unnamed local, waiting in the same patch of shade, answers flatly — "Every week. Word for word, far as I've ever caught it... Suppose that's the one thing round here that hasn't had to change." No NPC name or portrait, consistent with Pushang's deliberate no-central-NPC, atmospheric/collective structure. One choice, `"Continue."` → `n09_the_officers_demand`, effects `{}`.

Both paths converge on the existing `n09_the_officers_demand`, unchanged. Neither new node uses an `npc_portrait` key, matching this chapter's own established style for its atmospheric beats (`n01`, `n02`, `n07`, `n08` all omit it too).

**New glossed term, `khutba`**, added to `content/glossary/pushang_terms.json`: the Friday sermon in which the ruling authority is formally named and blessed — one of Islamic political theory's two classical legitimacy markers alongside the sikka (coin), which this game already glosses in `herat_favor_terms.json` (Chapter 4B). **Confirmed no collision, unlike sikka/suftaja before it:** grepped every glossary file directly — "khutba" appears only inside `sikka`'s existing definition prose in `herat_favor_terms.json`, never as its own headword/key anywhere in the project. Free to introduce fresh here.

**Zero coin/reputation effects on either new choice** — deliberately flavor-only, same low-blast-radius design as Bost's currency-mechanics pass, and for the same reason: this scene's value is the worldbuilding beat, not another economic lever, and it means no full-playthrough cumulative total in `test_chapter_view.gd` needs touching.

## Testing

Verified directly against the real current test files, not assumed:

- `tests/unit/test_pushang_dialogue_content.gd` has 4 tests (`test_the_comply_choice_reaches_its_outcome_and_effects`, `test_the_haggle_choice_reaches_its_outcome_and_effects`, `test_the_refuse_choice_reaches_its_outcome_and_effects`, `test_the_bribe_choice_reaches_its_outcome_and_effects`) that each use `for i in range(8): engine.choose(0)` to reach `n09_the_officers_demand`, with the first test's own comment spelling out the exact chain: `n01 -> n02 -> n03 -> n04 -> n05 -> n06 -> n07 -> n08 -> n09`. Inserting 2 sequential nodes where a single direct link (`n08 -> n09`, 1 press) previously existed makes that same "always press 0" leg `n08 -> n08b -> n08c -> n09` (3 presses) — a net **+2**, same arithmetic shape as Bost's own currency-mechanics insertion. All 4 `range(8)` calls become `range(10)`; the first test's chain comment should be updated to include `n08b`/`n08c`.
- Two new test functions needed: one walking the "Ask" choice through to `n08c_the_passerbys_answer` and confirming the flag + eventual convergence on `n09_the_officers_demand`, one walking "Notice... say nothing" straight to `n09` with empty effects.
- `test_every_next_id_points_at_a_node_that_exists`, `test_exactly_one_node_has_no_choices_and_it_is_the_last_node`, and `test_every_glossed_term_id_exists_in_the_pushang_glossary` all automatically cover the new nodes' wiring and the new glossed term — no manual change needed to those tests themselves, only to the glossary file the last one reads.
- `test_glossary_terms_and_flag_names_are_unique_across_all_manifest_chapters` (in `test_chapter_view.gd`) automatically covers the new `khutba` term and `asked_about_the_khutba` flag — confirmed via direct grep that neither already exists anywhere else in the project.
- `test_chapter_view.gd`'s full-playthrough wealth/reputation totals are confirmed **unaffected** — the new choices carry zero coin or reputation effects. Their internal `while ... presses < 200` / node-id-stop loops absorb the extra hops with no assertion changes needed, exactly as confirmed for Bost's own currency-mechanics pass.
- The full existing suite (298 tests as of the last merge to `master`) must grow by exactly 2 (the two new dialogue-content tests) to 300, with no failures.

## What this pass does not do

- Does not add any new NPC or portrait.
- Does not touch `n08`'s or `n09`'s own text, or any other already-shipped Pushang content.
- Does not reference Mas'ud's real 1040 army rebellion or any other event after this game's 1035-1038 present.
- Does not reuse or redefine the `sikka` term.
- Does not add any coin or reputation effect anywhere in this pass.
