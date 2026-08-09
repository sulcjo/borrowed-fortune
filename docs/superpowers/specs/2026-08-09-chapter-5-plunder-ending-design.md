# Chapter 5 (Plunder Ending) Design

**Chapter id:** `chapter_05_plunder_ending` — deliberately distinct from whatever id the long main route's eventual Chapter 5 (Pushang/Sarakhs/Nishapur) gets, per the naming-collision risk flagged when Chapter 4A shipped.

## Purpose

Closes the plunder-branch substory that began at Farah's fork (`n19b_departure_farah_plunder`) and continued through Chapter 4B. This is a full ending of the game for this route — not a stepping stone to a further chapter. It does **not** resolve the father's debt or the suftaja mystery; that payoff stays exclusive to Chapter 4A's gated full-truth reveal. This ending is about the character's state at journey's end — bound to Rostam, or free of him — not about tying off plot threads. (Confirmed with the user: "deliberately open / no closure.")

## Structure

Entered from both of Chapter 4B's terminal nodes (`n17a_departure_bound`, `n17b_departure_free`), which currently set `next_chapter_id: null` and must be updated to point here. A shared two-node opening leads into a flag-gated fork (mirrors the existing pattern already tested in Teginabad's letter-callback content: two choices, each `requires_flag`-gated on one of two mutually exclusive flags, so exactly one is ever visible — not a real choice, just automatic routing based on which 4B ending the player reached).

Each branch (bound / free) is fully distinct — its own three-node arc culminating in a final choice that is purely flavor (a flag only, no coin or reputation effect, since there is nothing left in the game to spend it on) — a last piece of self-narration the player gives Farrukh. That choice determines which of two terminal variants closes the branch, so the closing image itself reflects what was chosen, rather than a single generic wrap-up that would have to stay vague about both options — following the same "outcome-agnostic vs. outcome-specific" lesson the story review's fix pass just re-learned the hard way in Chapter 4A's aftermath nodes.

Both branches close on a final callback to Avicenna's floating-man thought experiment — introduced by the Ghazni letter-writer in the Prologue, reused in Farah (`n06_after_the_checkpoint`) and in Chapter 4A's aftermath (`n20_aftermath`) — giving the whole campaign's recurring philosophical throughline its last word, reframed each time around what Farrukh has just chosen to become.

No new location, NPC, or glossary term. The chapter is deliberately set on an unnamed stretch of road — no new city — both to fit the "short/compromised route" framing (contrast with the long route's eventual grand arrival at Nishapur) and to avoid any naming overlap with that other, unbuilt Chapter 5.

## Node-by-node content

### Shared opening

```
n01_the_road_west:
"He left Herat the way he'd left every stop before it - before first light, before the muster drums had found whatever rhythm they were going to keep without him - and did not look back at a city he had arrived in one kind of man and was leaving as some other kind, not yet named. The road west ran on regardless, the way it always had, indifferent to which man was walking it."
-> "Continue." -> n02_which_road_he_walks

n02_which_road_he_walks:
"What he carried out of that quarter with Rostam - the understanding, or the absence of one - was going to matter more on this stretch of road than anything he'd carried out of Farah."
-> "Continue." [requires_flag: chose_to_stay_entangled] -> n03a_the_shape_of_the_understanding
-> "Continue." [requires_flag: chose_to_pivot_away] -> n03b_the_shape_of_the_refusal
```

### Bound branch (`chose_to_stay_entangled`)

```
n03a_the_shape_of_the_understanding:
"There was no letter to answer, no date circled on any calendar he owned, nothing a qadi could have pointed to and called a contract - and that, he was beginning to understand, was precisely the design of it. An understanding without an end date didn't need enforcing. It only needed remembering, and Farrukh found he was already doing that without being asked, the way a man checks a debt is still there before he's even asked to pay it."
-> "Continue." -> n04a_the_watchfulness_learned

n04a_the_watchfulness_learned:
"He caught himself doing it on the third day out - the specific, unhurried way of looking at a stranger's hands before their face, the same appraisal he'd watched Rostam make of every courier who walked into that quarter. He did not remember deciding to learn it. It had simply arrived, the way a language arrives in a house where everyone around you speaks it long enough."
-> "Continue." -> n05a_the_lie_he_might_tell

n05a_the_lie_he_might_tell:
"Somewhere past the last outlying field, walking a road with no name he'd bothered to ask, Farrukh understood that whatever he told himself now about why he'd said yes would very likely be the version he carried the rest of the way west."
-> "Tell yourself it was only ever going to be one more errand." [flags: chose_to_believe_the_lie] -> n06a_departure_bound_believed
-> "Admit, at least to yourself, what you've actually become." [flags: chose_to_see_clearly] -> n06a_departure_bound_clear_eyed

n06a_departure_bound_believed (terminal, next_chapter_id: null):
"He told himself it was only ever going to be one more errand, and felt the lie settle into him with the particular ease of a story a man has decided, deliberately, to believe. Avicenna's floating man, stripped of every borrowed sense, was still supposed to know, without instruction, that he existed. Farrukh walked on knowing rather less than that about the man currently doing the walking - only that he was moving, that the road accepted him regardless of which version of himself he'd chosen to carry into it, and that some accountings, unlike his father's, might never come due at all, which was its own kind of debt."

n06a_departure_bound_clear_eyed (terminal, next_chapter_id: null):
"He did not tell himself it was only one more errand. He let himself know, plainly, walking a road he hadn't bothered to name, exactly what kind of understanding he'd agreed to and exactly what kind of man agreed to that kind of thing without a date attached to it. Avicenna's floating man, stripped of every borrowed sense, was still supposed to know, without instruction, that he existed. Farrukh knew that much too, at least - knew it clearly, for once, without the comfort of not looking - and understood that clarity, on this particular road, was not the same thing as being free."
```

### Free branch (`chose_to_pivot_away`)

```
n03b_the_shape_of_the_refusal:
"He had said no as plainly as a man could say it, and Rostam had let the silence do whatever work he'd decided it needed to do rather than argue - which meant Farrukh had left that quarter without ever actually learning whether a small, quietly delivered refusal was the kind of thing a man like that let go of, or only the kind of thing he set aside to collect later, at his own convenience."
-> "Continue." -> n04b_watching_the_road_behind

n04b_watching_the_road_behind:
"He caught himself doing it on the third day out - glancing back at a stretch of empty road more often than the road itself gave him reason to, the specific attention of a man who has decided a threat unconfirmed is not the same thing as a threat that has passed. Nothing followed that he could see. He was no longer entirely sure that was the same as nothing following."
-> "Continue." -> n05b_the_bet_he_could_not_confirm

n05b_the_bet_he_could_not_confirm:
"Somewhere past the last outlying field, walking a road with no name he'd bothered to ask, Farrukh understood that whatever he told himself now about whether he was actually safe would very likely be the version he carried the rest of the way west."
-> "Let yourself believe the danger has passed." [flags: chose_to_believe_the_danger_passed] -> n06b_departure_free_believed
-> "Accept that you may never know if it has." [flags: chose_to_accept_uncertainty] -> n06b_departure_free_uncertain

n06b_departure_free_believed (terminal, next_chapter_id: null):
"He let himself believe it was over, and felt the belief settle into him with the particular relief of a story a man has decided, deliberately, to trust. Avicenna's floating man, stripped of every borrowed sense, was still supposed to know, without instruction, that he existed. Farrukh walked on believing rather more than that about the road behind him - that it was empty, that it would stay empty, that a debt refused was the same as a debt discharged - and did not let himself wonder, more than once or twice a day, whether he'd simply chosen the more comfortable arithmetic."

n06b_departure_free_uncertain (terminal, next_chapter_id: null):
"He did not let himself believe it was over. He accepted, instead, walking a road he hadn't bothered to name, that some threats don't announce their ending any more clearly than they announced their beginning, and that a man could spend the rest of a long road checking behind him for something that had already stopped watching, or hadn't yet started. Avicenna's floating man, stripped of every borrowed sense, was still supposed to know, without instruction, that he existed. Farrukh knew that much, walking on - only that, and the uncomfortable, clarifying fact that uncertainty, carried far enough, was its own kind of company."
```

Twelve nodes total, four distinct terminal endings — short relative to the 22-26 node main chapters, matching this chapter's role as the plunder branch's compact close.

## Wiring

- New manifest entry: `chapter_05_plunder_ending` → `{dialogue_path, glossary_path, next_chapter_id: null}`.
- New glossary file `content/glossary/chapter_05_plunder_ending_terms.json`: empty object `{}` — no new terminology, consistent with how the Avicenna callback has never needed its own glossary entry in any prior chapter.
- Change `chapter_04b_herat_favor/herat_favor.json`'s two terminal nodes' `next_chapter_id` from `null` to `"chapter_05_plunder_ending"` (the node-level value, not just the manifest — the established footgun from every prior chapter wiring).
- `tests/unit/test_herat_favor_dialogue_content.gd`'s `test_both_terminal_nodes_carry_their_own_null_next_chapter_id` currently asserts both are `null` — must be strengthened to assert the new value, per the established "grep for tests asserting the OLD value, never delete, strengthen" lesson from every prior chapter's wiring task.
- `tests/unit/test_chapter_view.gd`'s two full-playthrough tests (mystery branch reaches `chapter_04a_herat`; plunder branch reaches `chapter_04b_herat_favor`) — the plunder-branch one currently asserts `chapter_view.chapter_id == "chapter_04b_herat_favor"` and `next_chapter_id == null` as final state. It must be extended one step further to walk into `chapter_05_plunder_ending` and assert its actual final node/flags, following the exact same pattern the mystery-branch test already uses for reaching `chapter_04a_herat`.

## Global constraints (unchanged from every prior chapter)

Godot 4.3 floor. `JSON.parse_string` deserializes numbers as float — n/a here, this chapter has no numeric effects at all (no coin, no reputation deltas — first chapter in the game with neither). No combat. No religious/ritual framing of the hidden network (n/a here — the network itself is never mentioned again in this chapter; it already got its full disambiguation in Chapter 4B and this ending is about Farrukh's own state, not the network). Commit per task.
