# Chapter 4A: Herat — The Clean Lead — Design Doc

**Status:** Approved for planning. **Date:** 2026-08-09
**Builds on:** `2026-08-07-borrowed-fortune-design.md` (setting/systems), `2026-08-09-trading-engine-design.md` (haggle template, `requires_reputation`, coin income — `v0.5-trading-engine`), shipped Chapters 0-3 (`v0.1` through `v0.4`). Follows the **mystery** branch of Farah's true fork (`n18a_departure_farah_mystery`, flags `chose_umm_kavus_channel` / `knows_the_second_marks_name`).

---

## 1. High Concept

Farrukh arrives in Herat carrying the cleanest lead he's had since Ghazni: a name, and a city — Rayy, again, the same house whose seal Mihran first recognized in Bost. Herat is real and well-documented for this window: a provincial capital on the Hari Rud, one of six Ghaznavid mints, and a city that historically falls in 1038 — the same year as the game's ending. The spec's own research note says the pressure of the empire's collapse "should be audible here." This chapter makes it audible through an optional sideroad (a veteran soldier at the garrison gate, a muster far thinner than the one Sultan Mas'ud himself called here in 1020) while the main thread does two things at once: it's the first chapter to make the new trading engine's haggling and reputation-gating actually matter to the plot, and it delivers the story's biggest single escalation yet — the first real, undeniable acknowledgment that the hidden network behind Farrukh's father's suftaja is exactly what the Ghazni rumors said it was, tied to a real, dated historical rupture: the 1029 fall of Rayy, when the last Buyid ruler (Majd al-Dawla) was deposed and the state crucified Ismailis in the same city, the same year.

The reveal is **reputation-gated**, using the trading engine's `requires_reputation` primitive for the first time in real content — and the gate reads Farrukh's *whole accumulated* `trading_families` standing, Prologue through Herat, not just this chapter's own dealings. That matches Ardashir's own line at the reveal: "It's whatever you've already shown me, added up." Herat's two haggles with **Ardashir** are a *penalty gate*, not a reward gate — the chapter's own best-case contribution is a modest +1, its worst is -3, so pushing him aggressively is what costs Farrukh the full picture, not something he can single-handedly earn here. Even so, Herat's own play is the deciding factor across most of the range of standing a player could plausibly arrive with (worked out precisely at implementation time: the chosen threshold decides the outcome in 11 of the 16 realistic pre-Herat standings, and is unreachable in only one deliberately hostile combination, which still resolves to the game's ordinary partial-reveal ending rather than a dead end). This is the chapter's central design idea: the haggle scenes are not flavor sitting beside the mystery, they gate it directly — just not in isolation from everything that came before.

**No further branching this chapter.** Unlike Farah, Chapter 4A does not fork — both reveal depths converge on the same closing beat and the same (not-yet-built) next chapter, continuing the game's long route toward Nishapur. Chapter 4A is explicitly **not** shared content with Chapter 4B (the Farah-plunder branch's chapter) — confirmed with the user as fully distinct.

---

## 2. Cast

**Ardashir** — a sarraf whose stall in Herat's bazaar is trusted by half the caravan trade passing through, tied by correspondence to trading houses that survived the 1029 collapse in Rayy. Older than Mihran, quieter than Umm-Kavus, exactingly fair in every transaction — which is exactly what makes him worth doing real business with before asking him anything dangerous. Knows precisely what the "second mark" and the Rayy connection actually are, and will only say so plainly to someone who has already shown him, through ordinary dealing, that he isn't a fool or a informant.

**The old soldier** — unnamed, stationed at Herat's garrison gate doing the particular kind of nothing that comes with being told to wait. Mustered here himself in 1020, when a young Mas'ud (Sultan today) first called men up in this same yard — a real muster, with a real destination. What's happening now is a **hashar**, an emergency levy of farmers and shopkeepers rather than soldiers bred to it, and he knows exactly what that difference means without needing to say the word "Seljuk" aloud.

---

## 3. Chapter Structure — 26 nodes, one optional sideroad, two haggle scenes, one reputation-gated reveal

**Act I — Arrival**
1. `n01_herat_arrival` — real scale, the Hari Rud oasis, biggest city since Ghazni
2. `n02_the_citys_pulse` — Herat as a mint city; the muster rumor introduced; **optional sideroad fork**
   - `"Let the garrison gate draw you first."` → `n03a_the_old_soldier`
   - `"Head straight for the bazaar."` → `n05_the_bazaar_of_herat` (skips the sideroad entirely)

**Act II — Optional sideroad: the frontier pressure made audible**
3. `n03a_the_old_soldier` — the veteran, the levy
4. `n04a_the_1020_muster` — the real 1020 muster vs. today's **hashar**, unsaid "Seljuk" → `n05_the_bazaar_of_herat`

**Act III — Ardashir and the first haggle**
5. `n05_the_bazaar_of_herat` — real bazaar texture
6. `n06_ardashir_introduced`
7. `n07_the_exchange_rate` — **haggle scene 1** (worn travel coin for clean Herat silver)
   - `"Accept his rate."` → `n08a_accepted_the_rate`. Effects: `{"coin_spent_dirham_equivalent": 10.0}`
   - `"Argue the discount."` → `n08b_argued_the_discount`
   - `"Walk away, keep the old coin."` → `n08c_kept_the_old_coin`. Effects: `{}`
8. `n08b_argued_the_discount` — round 2
   - `"Back off, accept his rate."` → `n08a_accepted_the_rate` (same node/effects as above)
   - `"Push further."` → `n09_grudging_exchange`. Effects: `{"coin_spent_dirham_equivalent": 5.0, "reputation": {"trading_families": -1}}`
9. `n08a_accepted_the_rate` / `n08c_kept_the_old_coin` / `n09_grudging_exchange` — all → `n10_after_first_exchange`

**Act IV — The second haggle: paying for correspondence**
10. `n10_after_first_exchange` — brief transition
11. `n11_the_correspondence` — **haggle scene 2** (Ardashir offers to send word through his network — this is what gives Farrukh a legitimate reason to raise Rayy at all)
    - `"Pay what he asks."` → `n12a_paid_in_full`. Effects: `{"coin_spent_dirham_equivalent": 20.0, "reputation": {"trading_families": 1}}`
    - `"Try to talk him down."` → `n12b_haggled_the_fee`
    - `"Decide you don't need the service."` → `n12c_declined_the_service`. Effects: `{}`
12. `n12b_haggled_the_fee` — round 2
    - `"Accept a small reduction."` → `n13_reduced_fee`. Effects: `{"coin_spent_dirham_equivalent": 14.0, "reputation": {"trading_families": 1}}`
    - `"Keep pushing."` → `n14_pushed_too_far`. Effects: `{"coin_spent_dirham_equivalent": 10.0, "reputation": {"trading_families": -2}}`
13. `n12a_paid_in_full` / `n12c_declined_the_service` / `n13_reduced_fee` / `n14_pushed_too_far` — all → `n15_after_second_exchange`

**Act V — The reveal**
14. `n15_after_second_exchange` → `n16_raising_the_rayy_connection`
15. `n16_raising_the_rayy_connection` — Farrukh finally asks
16. `n17_ardashirs_hesitation` — the calculation, mirroring Mihran's stillness in Bost
17. `n18_the_moment_of_truth` — **the reputation gate**
    - `"Ask him plainly, one merchant to another."` (always available) → `n19a_the_partial_truth`. Effects: `{"flags": ["partial_network_reveal"]}`
    - **requires_reputation: `{"faction_id": "trading_families", "min_score": 4}`** — `"Remind him what you've shown him, fairly, since you arrived."` → `n19b_the_full_truth`. Effects: `{"flags": ["full_network_reveal"], "reputation": {"trading_families": 1}}`
18. `n19a_the_partial_truth` / `n19b_the_full_truth` — both → `n20_aftermath`

**Act VI — Departure**
19. `n20_aftermath` — interiority beat
20. `n21_departure_herat` — **terminal node**, `choices: []`, `next_chapter_id: null` (no Chapter 5-main yet)

---

## 4. Full Node Text

> **n01_herat_arrival**
> Herat announced itself before the eye found any wall - a green so sudden after the Farah road's thin channels that Farrukh's caravan guide, a Heratigan by birth, laughed out loud at his own relief. The Hari Rud ran wide and steady here, feeding orchards and fields that had outlasted every dynasty that had ever claimed them, and the city itself sat in the middle of all that green like a fact nobody had gotten around to arguing with yet. Bost had been a palace pretending to be a market. Herat was simply a city - the biggest, Farrukh understood without being told, since Ghazni itself.

> **n02_the_citys_pulse**
> It did not take an afternoon to learn that Herat struck its own coin - one of six mints still answering to the Sultan, the guide said, with the particular pride of a man reciting a fact about his home he'd repeated to a thousand strangers before Farrukh. It took rather less time to notice the other thing everyone in the bazaar seemed to be discussing in lowered voices: a muster, called sooner and thinner than anyone remembered the last one being, men going to garrison duty who'd expected another season free of it.

> **n03a_the_old_soldier**
> An old soldier sat by the garrison gate doing the particular kind of nothing men do when they've been told to wait and given no further instruction - watching new levies shuffle through with the flat expression of someone who has seen this exact scene often enough that the details have stopped mattering to him individually. Farrukh asked, since the man seemed willing to be asked things, what all the hurry was for.

> **n04a_the_1020_muster**
> "Hurry." The old soldier said the word like it tasted wrong. "I mustered here myself, boy, near twenty years gone now - when the young prince who's Sultan today first called men up in this very yard, before he'd worn the title a season. That muster had banners, had a march worth remembering, had somewhere real to go and something real to be marching toward." He nodded at the {{hashar|hashar}} shuffling past - farmers and shopkeepers pressed into service rather than soldiers bred to it. "This is a man patching a roof with whatever's on hand because he can't wait for proper tile. Nobody's said the word Seljuk to me directly. Nobody needs to." He didn't say anything further, and didn't seem to expect Farrukh to either.

> **n05_the_bazaar_of_herat**
> Herat's bazaar ran long enough that a man could lose an entire day just walking its length without transacting a single dirham - dyers, ironworkers, a street that smelled entirely of saffron, and, threaded through all of it, the particular hush of stalls where actual silver changed hands rather than goods, run by men who weighed coin for a living the way Mihran had in Bost, except here with a mint's own authority standing behind whatever they said a coin was worth.

> **n06_ardashir_introduced**
> Farrukh found the one the road's own gossip had already half-pointed him toward before he'd finished asking - a sarraf named Ardashir, older than Mihran, quieter than Umm-Kavus, running a stall so plain and so trusted that half the caravan trade passing through Herat used no other scale. He took Farrukh's coin for a first, small exchange without comment, weighed it, and named a rate that was, Farrukh judged, exactly fair and not a hair more generous than that.

> **n07_the_exchange_rate**
> He offered to take Farrukh's travel-worn coin off his hands - foreign mintings, clipped edges, the ordinary wreckage of a long road - and give him clean Herat silver in exchange, at a rate that discounted for the wear rather more heavily than Farrukh's own eye judged fair.

> **n08a_accepted_the_rate**
> Farrukh took the rate without argument. Ardashir counted out the clean silver with the same unhurried precision he'd used to name the discount in the first place, and said nothing further about it - a man who had made his offer honestly and expected to be dealt with the same way in return.

> **n08b_argued_the_discount**
> Farrukh pointed out, as evenly as he could manage, that the discount ran heavier than the coins' actual wear justified. Ardashir looked at him for a moment with something that might have been mild interest. "It does," he agreed, entirely unbothered. "Most men don't notice, or don't say so if they do. What would you have it be instead?"

> **n09_grudging_exchange**
> Farrukh pushed harder than the moment strictly called for, and got a better rate for it - a smaller one than he'd hoped, and a longer silence from Ardashir afterward than the transaction itself required. Coin was coin. Whatever he'd spent to get it back was harder to weigh.

> **n08c_kept_the_old_coin**
> Farrukh decided the worn coin would spend well enough elsewhere and declined the exchange. Ardashir shrugged, entirely untroubled either way, and went back to whatever he'd been doing before Farrukh's shadow had fallen across his stall.

> **n10_after_first_exchange**
> Farrukh lingered a moment longer than the transaction required, the way a man does when he has a second, harder question waiting behind the first easy one.

> **n11_the_correspondence**
> "You're not here for silver," Ardashir said, before Farrukh had found a way to raise it himself. "Men who are, don't linger." He named a fee, plainly, for sending word through the correspondents he kept in cities a caravan guide wouldn't think to ask about - the kind of service, he made clear without quite saying so, that existed for exactly the sort of question Farrukh hadn't asked yet.

> **n12a_paid_in_full**
> Farrukh paid what he asked, without argument, the same way he'd learned to pay Umm-Kavus in Farah - and watched something in Ardashir's manner ease by the same small fraction it had eased in hers.

> **n12b_haggled_the_fee**
> Farrukh tried the fee the way he'd tried the exchange rate - reasonably, without heat. Ardashir's expression didn't change, but he named a slightly lower figure, the kind of movement that cost him nothing and told Farrukh nothing either, except that the door hadn't closed.

> **n12c_declined_the_service**
> Farrukh decided the fee wasn't worth what it bought and said so, and Ardashir took the refusal exactly as evenly as he'd taken everything else - a man who sold a service, not a man invested in anyone buying it. It left the door to Rayy no more open than Farrukh's own nerve would make it, a few minutes from now, without a paid pretext to lean on.

> **n13_reduced_fee**
> Farrukh accepted the reduction and paid it, and let the matter rest there. It was, he judged, exactly the right amount of pressing - enough to show he wasn't being careless with his father's remaining coin, not so much that it read as anything other than ordinary bazaar custom.

> **n14_pushed_too_far**
> Farrukh pressed a second time, the way he had at the exchange rate, and this time Ardashir's patience visibly thinned. He gave the reduction anyway - a sarraf's professional habit outlasting his personal irritation - but the ease that had been building between them closed over like a door shutting quietly rather than being slammed.

> **n15_after_second_exchange**
> Whatever Ardashir made of him after two rounds of ordinary bazaar business, Farrukh had run out of pretexts for lingering a third time without simply asking.

> **n16_raising_the_rayy_connection**
> Farrukh laid it out as plainly as he could manage - the suftaja, the second mark Mihran had recognized and refused to fully explain, the house in Rayy his father's accounts should never have mentioned at all. Ardashir listened without once looking up from the coins he was still, out of habit, sorting.

> **n17_ardashirs_hesitation**
> When he finally did look up, it was with the same particular stillness Farrukh had seen twice already on this road - a man doing the arithmetic of how much a stranger's trustworthiness was actually worth, weighed against what the honest answer might cost him if he'd guessed wrong.

> **n18_the_moment_of_truth**
> "I could tell you what I actually know," Ardashir said at last, "or I could tell you the version of it that's safe for both of us regardless of who you turn out to be. Which one you get isn't really my decision to make anymore. It's whatever you've already shown me, added up."

> **n19a_the_partial_truth**
> "The house had trouble," Ardashir said, choosing his words the way a man picks a path across a floor he doesn't trust. "Trouble tied to things that happened in Rayy a while back - things men in my trade learned not to discuss above a whisper, even now. Your father's paper is a piece of that trouble, passed down further than anyone probably meant it to travel. That's what I can safely give you." It was, Farrukh understood, exactly as much as a cautious stranger owed another cautious stranger, and not one word more.

> **n19b_the_full_truth**
> "Nine years ago," Ardashir said, "Rayy had a ruler of its own house - the last of the old Buyid line, a man named Majd al-Dawla - until your Sultan's father took the city and put him somewhere comfortable and permanent in Ghazni instead. That was the political half of it. The other half happened the same year: men were crucified in Rayy's streets for belonging to a network the state called dangerous enough to kill for - {{dai|da'i}}, missionaries for a cause based in Cairo, funded from Cairo, answerable to nobody the Sultan recognized as legitimate. What's left of both collapses - the old house's money, and whatever survived of that network - didn't vanish. It went quiet, and it went underground, and some of it apparently still moves, carefully, through paper like your father's. I don't know why he was carrying it. I don't think you'll like finding out, whenever you do."

> **n20_aftermath**
> Farrukh walked back through Herat's long bazaar without seeing much of it, turning the shape of what he now knew over in his hands like a coin he couldn't yet tell was genuine. His father had never so much as mentioned Rayy at the dinner table, had never once used a word like Buyid or missionary in Farrukh's hearing - and yet here it was, folded into a debt Farrukh had sworn at a graveside to carry without knowing what, exactly, he'd agreed to be responsible for. Avicenna's floating man, stripped of every borrowed sense, was still supposed to know he existed. Farrukh was beginning to suspect a man could know considerably less than that about the debts he'd sworn to.

> **n21_departure_herat**
> He left Herat before the muster drums had found their full rhythm, west toward Pushang and whatever came after it, carrying a name from Rayy that had stopped being merely mysterious and started being dangerous, in roughly the proportion Ardashir had warned him it would.

---

## 5. New Glossary Terms (`content/glossary/herat_terms.json`)

| Term | Headword | Definition |
|---|---|---|
| `hashar` | Hashar | An emergency levy of ordinary townsmen and farmers, called up for military service in a crisis - distinct from a standing army's professional soldiers (such as the ghulam), and a real sign of a state under strain. |
| `dai` | Da'i | Literally "one who summons" - a missionary or propagandist for the Ismaili Shia cause, historically directed and funded from Fatimid Cairo, operating underground in Sunni-ruled territory where the activity was treated as a capital offense. |

(`sarraf`, `ghulam`, `suftaja`, `kafala`, and `dirham` are referenced in plain prose, deliberately not re-glossed - all already taught in earlier chapters and persist in The Margin via the existing merge fix.)

---

## 6. Engine Notes — Consumes Existing Capability, One Real Prerequisite

This chapter needs **zero new engine capability** — it is the first real consumer of everything `v0.5-trading-engine` shipped: two multi-round haggle scenes using the documented template, and the first `requires_reputation` gate in shipped content.

**One real prerequisite, flagged by the trading engine's own final review and not yet built:** `DialogueEngine.validate_tree()` does not currently validate `requires_reputation`'s shape. Since this chapter is the first to actually use the key, its implementation plan must add that validation as its first task, before content authoring — malformed `requires_reputation` should fail loudly at `load_tree()` time (the same place duplicate ids and dangling `next_id`s are already caught), not silently at render time. **The fix must not use `.get(...)` with defaults** — the trading-engine review worked the arithmetic showing that `.get("faction_id", "")` / `.get("min_score", 0)` makes a malformed gate evaluate to `0 < 0 → false`, which makes the gated choice visible to *everyone* rather than failing closed. Validation belongs in `validate_tree()`, asserting the shape is well-formed before the chapter ever loads.

---

## 7. Scope & Next Steps

Comparable size to Farah (26 nodes vs. 27), no new engine work beyond the one validation prerequisite above, one optional sideroad, two real haggle scenes, one reputation-gated reveal. This is the first chapter whose central mystery payoff is mechanically gated by how the trade system was played, not just narratively flavored by it.

**Chapter 4A does not fork and is not shared content with Chapter 4B** (the Farah-plunder branch, confirmed separately as fully distinct). `n21_departure_herat`'s `next_chapter_id` stays `null` until a Chapter 5-main (or whatever the long route's next stop is named) exists — likely Pushang, per the original 8-stop route.

Next step: `writing-plans` to turn this into a task-by-task implementation plan, following the same TDD/subagent-driven-development pattern as every prior chapter, with the `validate_tree()` prerequisite as its own first task.
