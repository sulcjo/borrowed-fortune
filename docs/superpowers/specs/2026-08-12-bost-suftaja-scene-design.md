# Bost Suftaja Scene Design

**Status:** approved, pending implementation plan.

## Goal

Second installment of the ongoing content-expansion initiative (first was Chapter 1's tutorial trade). Bost is currently one of the shortest chapters (10 nodes, ~855 words) and purely mystery-plot focused. Real gap: Mihran is explicitly a sarraf (money-changer) by profession, but the existing scene never has him actually change money — Farrukh visits only for the suftaja mystery reveal. This adds two new nodes giving Mihran a real, ordinary transaction first, and uses it to explain — in his own voice, grounded in real medieval Islamic financial practice, not invented — what a suftaja actually is and why it matters, right before Farrukh reveals he's carrying one. User's own framing: make Bost "the hub of player gaining... context knowledge... to understand the situation of the character in that era," scoped specifically to the suftaja/banking system (confirmed via multi-select clarifying question — other candidate topics, currency/coinage, the frontier's political decline, social structure, were all deliberately not chosen for this pass).

## Research (verified via web search, not invented)

- **Suftaja**: an Arabic form of Persian *sufta* ("promissory note"), attested from 9th-century Arabic papyri — a bill of exchange between three parties (payor, payee, and a correspondent banker in another city). Unlike currency exchange, a suftaja was written for payment in the *same specie* in another region — the coin never moves, only the paper does. It worked because bankers maintained a web of mutual trust and accounts across the Islamic world. Purpose: avoid losing money to a shipwreck or road-robbers — directly matches this game's own setup (Farrukh carrying his father's suftaja through dangerous frontier country).
- **Sarraf**: a money-changer who assayed/weighed the era's bimetallic coinage (gold dinars, silver dirhams) against counterweights, for a small commission. Historically a profession often looked down on and frequently performed by non-Muslims (several hadiths warned against it) — this lines up with, and doesn't require inventing anything beyond, Mihran's *already-shipped* jizya-paying detail (added in an earlier content pass, `content/chapters/chapter_02_bost/bost.json`'s existing `n06_the_danger` node). Pre-weighed, sealed bags of coin were the era's real efficiency shortcut for avoiding a full reweigh every time.

## Placement and mechanics

Two new nodes, inserted between the existing `n02_seeking_the_sarraf` (Farrukh finds Mihran's shop) and `n03_mihran_examines` (the suftaja mystery begins) — neither existing node's own text changes, only `n02`'s `"choices"`/`next_id` is redirected. This is a minimal, additive insertion using node-id letter suffixes (`n02b`, `n02c`) rather than renumbering every subsequent node, matching this project's established "smallest safe diff" precedent (the Merv branch's insertion approach) — `n03` through `n10` are byte-for-byte unchanged.

No new engine code — reuses the existing `coin_spent_dirham_equivalent`/`reputation` effects keys exactly as already wired through `ChapterView._apply_effects()`.

## Content (exact text and effects)

`n02_seeking_the_sarraf`'s existing text is unchanged. Its choice becomes:
```json
"choices": [{"text": "Continue.", "next_id": "n02b_the_ordinary_business", "effects": {}}]
```

**`n02b_the_ordinary_business`** (new node, `npc_portrait: "mihran"`):
> Before Farrukh could say why he'd come, Mihran glanced at the pouch on his belt - the same unspoken question, Farrukh guessed, that any sarraf put to a travel-worn stranger before business of any other kind. "Thorough, or quick?" Mihran asked, already reaching for his scale. "Thorough, I check every coin against the stones myself. Costs a little more. Quick, I go by eye - and my eye is usually right, for what that's worth to you."

Choices:
- `"Thorough. Weigh every coin."` → `n02c_mihran_on_letters_of_credit`, effects `{"coin_spent_dirham_equivalent": 2.0}`
- `"Quick is fine. I trust you."` → `n02c_mihran_on_letters_of_credit`, effects `{"coin_spent_dirham_equivalent": 1.0, "reputation": {"trading_families": 1}}`

**`n02c_mihran_on_letters_of_credit`** (new node, `npc_portrait: "mihran"`):
> He worked as he talked, unbothered by silence but not opposed to filling it either. "Where are you bound?" Farrukh said Farah, and past it, though not why. Mihran nodded like he'd heard the shape of that answer before. "Then you're carrying your coin the wrong way," he said. "Every dirham on you past here is a dirham a bad road or a worse man can take from you. Men who move money seriously don't carry it at all - they carry paper. A letter naming a sum, and a name in some other city who already owes the man who wrote it that much, or trusts him enough to advance it without asking why. The coin never travels. Only the promise does, city to city, banker to banker, on nothing but each man's word that the last one was good for it." He said it the way a man recites something true and faintly boring - a fact of his trade, not a marvel. Farrukh set his father's {{suftaja|suftaja}} on the counter without a word. The same kind of paper Mihran had just finished describing. He suspected this one would not turn out to be boring at all.

Choices: `[{"text": "Continue.", "next_id": "n03_mihran_examines", "effects": {}}]`

This connects directly into the existing `n03_mihran_examines` text ("Mihran took the suftaja without much interest until he actually read it, and then went quiet...") — his initial disinterest now lands harder, since he'd just finished calling this exact category of document "faintly boring."

## New glossary entry

One new term in `content/glossary/bost_terms.json` (alongside the existing `sarraf`/`jizya` entries, which are unchanged):
```json
"suftaja": {
  "headword": "Suftaja",
  "definition": "A letter of credit used across the medieval Islamic world - a name and a sum written on paper, redeemable through a network of bankers who trusted each other's word, so a merchant's money never had to survive the road in coin."
}
```

## Testing

- `tests/unit/test_bost_dialogue_content.gd` has two tests that walk a hardcoded 6 `engine.choose(0)` calls from `n01_bost_arrival` to reach `n07_the_offer` — both must become 8, since the new insertion adds 2 hops (`n02` → `n02b` → `n02c` → `n03`, where today it's `n02` → `n03` directly): `test_the_pressed_path_is_walkable_and_sets_its_flag_and_reputation()` and `test_the_patient_path_is_walkable_and_converges_on_the_same_node()`.
- The same file's `test_the_full_tree_is_walkable_from_start_to_end_via_first_choices()` uses a `while` loop keyed on reaching `n10_departure_bost`, not a hardcoded hop count — needs no change. Its two portrait/text-content regression tests (`test_mihran_has_a_small_unstated_zoroastrian_cue`, `test_bost_arrival_names_saeed_by_name_not_just_teginabad_generically`) assert on `n01`/`n02`'s existing text, which is unchanged — need no change either. `test_exactly_one_node_has_no_choices_and_it_is_the_last_node()` still asserts `n10_departure_bost`, unaffected.
- `tests/unit/test_chapter_view.gd`'s full-playthrough tests hardcode cumulative totals across the whole game — checked directly, not assumed, learning from the exact same class of gap that bit the Teginabad pass twice already. The new node's index-0 choice ("Thorough," 2.0 spent, no reputation effect) sits on the "always press choice 0" path every one of these tests walks, so:
  - `test_a_full_playthrough_via_the_mystery_branch_carries_prologue_flags_through_farah()`'s wealth assertion moves from `-65.0` to `-67.0`.
  - `test_a_full_playthrough_via_the_plunder_branch_reaches_its_own_terminal_node()`'s wealth assertion moves from `-8.0` to `-10.0`.
  - `test_the_full_truth_is_reachable_with_strong_accumulated_reputation()`'s reputation assertion (`trading_families == 9`) does **not** change - the reputation-bearing choice ("Quick is fine, I trust you") is at index 1, never taken by an always-first-choice walk. This was a deliberate design choice (see "Placement and mechanics"), specifically to avoid a second cascading reputation-total fix on top of the wealth one.
- No new test needed for the new `mihran` portrait usage on `n02b`/`n02c` - `mihran` is an existing, already-generated portrait id, not a new NPC.
- The full existing suite (294 tests as of the last merge to `master`) must stay green, plus whatever this pass adds.

## What this pass does not do

- Does not cover the other candidate "context knowledge" topics from the clarifying question (currency/coinage mechanics, the frontier's political decline, social structure/garrison-town life) - the user specifically scoped this pass to the suftaja/banking system only. Any of the others could be a future installment.
- Does not touch `n03` through `n10` - the suftaja-mystery reveal, the pressed-vs-patient fork, and the chapter's ending are unchanged, both in text and in node ids.
- Does not add a new NPC or portrait - Mihran already exists and is already generated.
- Does not change `content/chapters/manifest.json` - Chapter 2's `next_chapter_id`/`farrukh_wear_stage` entry is untouched.
- Does not add any UI tutorial hint or narrator aside - consistent with every other content pass this session, the scene teaches by being one.
