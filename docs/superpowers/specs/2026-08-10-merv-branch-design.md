# Merv Branch Design

**Chapter id:** `chapter_07b_merv` — a branch off Chapter 7 (Sarakhs), not a continuation past it. The `b` suffix signals this explicitly, distinguishing it from the numbered main-line sequence (`chapter_07_sarakhs` → `chapter_08_nishapur`).

## Purpose

The last unbuilt piece of content from the master design spec's original 8-stop scope: "Optional branch: Merv - off the direct line, a real detour, but fell in 1037 - the clearest 'this already happened here' stop in the game." This is the **first content added after the main campaign's completion**, and the first chapter in the whole project that isn't a strict linear continuation of the immediately-prior chapter's terminal node.

**Two structural questions, resolved with the user before any content design:**

1. **Access mechanism:** the detour is offered by modifying Chapter 7's already-shipped ending — the only way to offer a real "detour to Merv, then continue to Nishapur" vs. "go straight to Nishapur" choice, since the engine has no native branch-and-return mechanism. This is a bigger touch than any prior chapter's wiring task, which only ever changed an existing terminal's `next_chapter_id` from `null` to a value — this modifies already-tested content directly. Scoped to minimize risk (see "Modifying Chapter 7" below): the existing terminal node `n11_departure_sarakhs` is left completely untouched, both its id and its text, so every existing test that references it by name or via the "always press 0" playthrough pattern keeps passing unchanged.
2. **Time treatment:** Merv uses the **same dramatic-irony treatment as every other location** — visited in the story's actual present, 1035, its real 1037 fall never witnessed or even suspected by any character. No time-skip — this game's one ironclad cross-chapter convention stays intact. The irony is for the *player* alone, who knows the history; nothing in the prose winks at it.

## Historical grounding (verified via dedicated research, not assumed)

- **Scale, calibrated down from the obvious assumption.** Merv's famous "one of the world's great cities" / population-in-the-hundreds-of-thousands reputation is specifically **12th-century**, tied to Sultan Sanjar's later Seljuk-era city — a full century after this chapter's 1035 present. For 1035, the accurate framing is "a major provincial capital and Silk Road node," not superlative hype. No population figure exists for 1035 in the sources found.
- **Real physical grounding:** the Murghab-fed oasis and its canal system (the Majan and Razik canals, specifically attested) with a real administrative detail — a *mir-ab* (water-bailiff) office overseeing the irrigation workforce. A genuinely useful, non-ominous texture point: 10th-century geographer al-Muqaddasi already described a third of the old city/citadel as visibly emptying as commerce shifted to a newer walled quarter — an ordinary urban shift, not decline or crisis, and exactly the kind of grounded, non-foreshadowing detail this chapter needs.
- **The Nestorian Christian community holds up, with a real anchor:** metropolitan ʿAbdishoʿ was still active and corresponding with Baghdad as late as 1018/19 — seventeen years before this chapter's present, and functioning, not declining. A genuinely attested 1007 episode has the Merv metropolitan relaying intelligence from a Christian merchant network reaching as far as Mongolia — used here only as texture for "Merv sits in a real long-distance communication web," not dramatized as its own scene (no church architecture or specific quarter is invented, since none is attested for this date).
- **The mercantile hook is real infrastructure, not invention:** suftaja (bills of exchange) and hawala (trust-based debt transfer), operated by sarrafs, were the real backbone of long-distance Islamic trade by this era, and Merv's bazaar is specifically attested to have had money-changer shops. A merchant using a well-connected Merv correspondent to send routine word ahead is grounded in real institutions — the specific correspondent and her shop are an invented (but plausible) individual, not a claim about a documented historical bank.
- **Deliberately excluded, to avoid overstating the irony:** Merv's real 1037 transition to the Seljuks was, per the sources, largely negotiated/ceded rather than a violent conquest — the Ghaznavids ceded Sarakhs, Abivard, and Merv, and Sultan Mas'ud was reportedly unpopular locally. This is not dramatized in-fiction (no character has any way to know it), but it shapes the chapter's tone: nothing here should imply a coming catastrophe, because the real history wasn't one. The irony is quieter and more accurate than "doom nobody sees coming" — it's simply an unremarkable city about to change hands, exactly as unremarkably as it's depicted here.
- **This chapter deliberately does not advance the Rayy mystery or the father's debt.** It's optional bonus content; nothing in it can be load-bearing for players who never take the detour. The mercantile hook (sending word ahead) is self-contained and mundane on purpose.

## Modifying Chapter 7 (Sarakhs)

Exact current shipped structure (verified by reading the file directly before writing this spec): `n10_after_the_gate`'s single choice currently points straight to `n11_departure_sarakhs` (the terminal node, `next_chapter_id: "chapter_08_nishapur"`).

**Change:** insert one new fork node between them. `n10_after_the_gate`'s choice's `next_id` changes from `"n11_departure_sarakhs"` to `"n10b_the_road_forks"` (a new node). That new node offers two choices — one reaching the **existing, completely unmodified** `n11_departure_sarakhs` (same id, same text, same `next_chapter_id`), the other reaching a **new** terminal node `n11b_departure_via_merv` (`next_chapter_id: "chapter_07b_merv"`).

This is deliberately the smallest possible change: `n11_departure_sarakhs` itself — the node every existing test either names directly or reaches via the "always press choice 0" playthrough pattern — is untouched. Putting "go straight to Nishapur" at choice index 0 of the new fork node means every existing test that walks this chapter with `choose(0)` keeps reaching exactly the same nodes, in exactly the same number of *meaningful* steps (one extra "Continue"-shaped press, which loop-based tests don't count and press-count-based tests in this chapter don't currently rely on reaching this far). Only one existing test needs updating: `test_exactly_one_node_has_no_choices_and_it_is_the_last_node` must become a two-terminal-node assertion, since there are now two.

```
n10b_the_road_forks:
"Sarakhs behind him now in more than one sense, Farrukh found the road forked in a way his guide hadn't mentioned until they were standing at it - the straight route west toward Nishapur, or a longer swing through Merv first, a city his guide swore was worth the extra days to anyone who'd never seen it."
-> "Take the road straight to Nishapur." -> n11_departure_sarakhs (existing, byte-for-byte unchanged)
-> "Take the longer road through Merv first." -> n11b_departure_via_merv

n11b_departure_via_merv (terminal, next_chapter_id: "chapter_07b_merv"):
"He left Sarakhs by the longer road, telling himself an extra handful of days was a small enough price for seeing a city this size before whatever came next made seeing it harder to reach. Whatever Bahram's token was worth, wherever it ended up, it would simply have to wait a little longer than the straight road would have made him wait."
```

## Structure (the Merv chapter itself)

Nine nodes, entry node `n01_merv_arrival`, terminal node `n07_departure_merv`. Atmospheric/collective (confirmed with the user) — no central NPC, matching Pushang's departure rather than Sarakhs's/every-other-chapter's one-confidant pattern; fits the "nothing looks wrong" thesis better than a sustained relationship would.

1. **Arrival** (`n01_merv_arrival`) — calibrated scale ("a market town grown into a provincial capital," not superlative hype).
2. **The old quarter** (`n02_the_citadel_that_was`) — the real, non-ominous urban-shift detail (commerce moving to newer walls), framed as ordinary rather than decline.
3. **The bazaar** (`n03_the_bazaar_at_the_crossing`) — real commercial texture, purely descriptive, no foreshadowing gesture.
4. **The correspondent network** (`n04_a_network_reaching_far`) — the real 1007 Mongolia-reaching-network detail as camp/bazaar legend, setting up the mercantile hook.
5. **The haggle** (`n05_the_sarrafs_price`) — three choices, matching every prior chapter's haggle pattern, real but modest, distinct trade-offs: pay in full (+coin cost, +1 `trading_families`), haggle down (smaller coin cost, no reputation), or decide it can wait (no cost at all — declining a personal/optional errand is never punished, same rule Chapter 7 established for Bahram's charge).
6. **Departure** (`n07_departure_merv`) — terminal, `next_chapter_id: "chapter_08_nishapur"`. Same destination whether or not the detour was taken.

## Node-by-node content

```
n01_merv_arrival:
"Merv announced itself the way a name announces a reputation older than the man carrying it - a market town grown into a provincial capital, threaded by canals that had been running the same patient water since long before any Ghaznavid, or whoever came before them, had bothered to tax it. Farrukh's guide called it the best oasis on this whole stretch of road, and for once didn't seem to be exaggerating for the sake of a story."
-> "Continue." -> n02_the_citadel_that_was

n02_the_citadel_that_was:
"A third of the old city, his guide told him, had emptied out entirely in his own father's lifetime - not abandoned exactly, just outgrown, its business and its people drifting toward the newer walls a short walk east, the way a river finds a straighter channel and simply stops bothering with the old one. Farrukh understood the shape of it without needing the explanation: a city didn't have to be dying to have parts of itself the present had quietly moved past."
-> "Continue." -> n03_the_bazaar_at_the_crossing

n03_the_bazaar_at_the_crossing:
"The bazaar here ran to a scale Teginabad and Bost's markets hadn't prepared him for - a domed crossing where four main streets converged, money-changers and goldsmiths and weavers and coppersmiths each keeping to their own stretch of it, the whole arrangement running with the unhurried, settled competence of a trade pattern old enough that nobody currently working it had ever had to invent it."
-> "Continue." -> n04_a_network_reaching_far

n04_a_network_reaching_far:
"A money-changer working the bazaar's money-changing row mentioned, when Farrukh asked after sending word ahead of himself, that a correspondent three doors down had once relayed word all the way to the Mongolian steppe inside a single season - a story told with the specific pride of a city that measured its own importance by how far its letters could travel rather than by anything closer to home."
-> "Continue." -> n05_the_sarrafs_price

n05_the_sarrafs_price:
"The correspondent in question named a fee for carrying word ahead to Nishapur - nothing urgent in the message itself, only that a traveler was coming, the kind of ordinary courtesy that kept a household from being caught flat-footed by an arrival at its door."
-> "Pay what she asks." [coin_spent_dirham_equivalent: 8.0, reputation: trading_families +1] -> n06a_word_sent
-> "Try to talk her down." [coin_spent_dirham_equivalent: 5.0] -> n06b_word_sent_cheaper
-> "Decide the word can wait. Keep the coin." [no effects] -> n06c_word_unsent

n06a_word_sent:
"She took the fee without argument and wrote quickly, in a hand Farrukh couldn't read upside down, whatever a professional correspondent actually wrote in these situations. It was, he suspected, the smallest and least complicated transaction he'd make on this entire road."
-> "Continue." -> n07_departure_merv

n06b_word_sent_cheaper:
"She gave a little ground on the price, the way every sarraf on this road eventually did when pressed without heat, and wrote the same message regardless of what it had cost to commission it."
-> "Continue." -> n07_departure_merv

n06c_word_unsent:
"Farrukh decided a household that had gone this long without word from him could manage a few more days of it, and kept walking instead of paying anyone to say otherwise."
-> "Continue." -> n07_departure_merv

n07_departure_merv (terminal, next_chapter_id: "chapter_08_nishapur"):
"He left Merv the way he'd left every stop on this road, carrying a little more of it than he'd arrived with and a little less coin than he'd have liked - west now, properly, toward Nishapur and whatever waited for him there, the longer road behind him exactly as unremarkable, up close, as any of the shorter ones had been."
```

## Glossary (`content/glossary/merv_terms.json`)

Empty (`{}`) — no new terminology. Same precedent as Chapter 5 (plunder ending): not every chapter needs new glossed vocabulary, and this one's real grounding (suftaja/hawala/sarraf) is already-established terminology from earlier chapters, reused as plain prose.

## Wiring

- New manifest entry: `chapter_07b_merv` → `{dialogue_path: "res://content/chapters/chapter_07b_merv/merv.json", glossary_path: "res://content/glossary/merv_terms.json", next_chapter_id: null}`.
- Modify `content/chapters/chapter_07_sarakhs/sarakhs.json` per "Modifying Chapter 7" above: change `n10_after_the_gate`'s choice `next_id` from `"n11_departure_sarakhs"` to `"n10b_the_road_forks"`; add the two new nodes.
- Update `tests/unit/test_sarakhs_dialogue_content.gd`'s `test_exactly_one_node_has_no_choices_and_it_is_the_last_node` to expect two terminal node ids, sorted.
- Add new Sarakhs-side tests: the fork's two choices reach the right destinations (`n11_departure_sarakhs` unchanged; `n11b_departure_via_merv` with the correct `next_chapter_id`).
- **Grep `tests/` for the literal string `n11_departure_sarakhs` before touching anything**, per this project's now-consistent practice — but note the expected outcome here is different from every prior wiring task: since `n11_departure_sarakhs` itself is NOT changing, no existing assertion about it should need updating. If the grep turns up an assertion that *would* break, that's a sign the "leave `n11_departure_sarakhs` untouched" plan wasn't followed correctly — treat it as a real problem, not routine wiring.
- No existing `test_chapter_view.gd` full-playthrough assertions should need value changes — the "always press 0" path still reaches the exact same final chapter/node/flags/wealth it did before this branch existed, just via one additional "Continue"-shaped fork. Confirm this by running the full suite; do not pre-emptively edit that test's assertions without first confirming they actually fail.

## Global constraints (unchanged from every prior chapter)

Godot 4.3 floor. `JSON.parse_string` deserializes numbers as float — cast to `int` before comparing/assigning `int`-typed reputation values. No combat. No religious/ritual framing of the hidden network — n/a, this chapter never mentions it. No time-skip — Merv is visited in the story's actual 1035 present, exactly like every other location. Commit per task.
