# Chapter 4B: Herat — The Favor Owed — Design Doc

**Status:** Approved for planning. **Date:** 2026-08-09
**Builds on:** `2026-08-07-borrowed-fortune-design.md` (setting/systems), `2026-08-09-trading-engine-design.md` (haggle template, `requires_reputation`, `coin_gained_dirham_equivalent`), `2026-08-09-chapter-4a-herat-design.md` (the sibling chapter — confirmed fully distinct, no shared content), shipped Chapters 0-4A (`v0.1` through `v0.6`). Follows the **plunder** branch of Farah's true fork (`n19b_departure_farah_plunder`, flags `chose_tahirs_price` / `owes_tahir_a_favor` / `knows_the_second_marks_name`).

---

## 1. High Concept

Farrukh arrives in Herat carrying Tahir's wrapped bundle and an unread message, addressed to a man he's never heard of, in payment of a favor he already regrets owing. Where Chapter 4A's Farrukh came to Herat curious and in control, this Farrukh comes obligated and exposed — the delivery is not optional, and the man on the other end of it is not accountable to anyone Farrukh could appeal to.

That man is **Rostam** — a name that means something very different in the *Shahnameh* than it does in his own mouth. He deals in goods that came west with Mahmud's armies and never saw a customs manifest, and he uses what's left of the Rayy network (the same real history Chapter 4A's Ardashir explains: the 1029 fall of the Buyid house, the Ismaili crucifixions, the underground channels that survived both) purely as cover and leverage — not conviction. Getting the delivery done means dealing with him directly, including at least one real negotiation over what Farrukh is owed for the errand. What Farrukh learns along the way — not through anything supernatural or ritualistic, but through Rostam's own careless boasting about a previous courier who tried to walk away from him — is that the "favor" was never going to end cleanly with one delivery. That's the chapter's real fork: agree to keep working for him, or tell him this ends here, knowing he doesn't take that well.

**Disclosed handling of a sensitive real-history thread:** the hidden network's actual origin (per Chapter 4A) is real, dated Ismaili-Fatimid history — a persecuted minority position, not a caricature. This chapter is explicit that **Rostam is a corruption of that network, not a representative of it** — a profiteer riding its cover and its silence for his own gain. The darkness in this chapter (real menace, a real prior victim referenced but never shown) is criminal and personal, not religious or ritualistic — deliberately avoiding the lurid "secret murder cult" framing that later legend (Marco Polo's embellished "Assassins" tales) attached to Ismaili history without basis, the same way Chapter 3 flagged the Somnath legend as later invention rather than repeating it as fact.

**First real use of `coin_gained_dirham_equivalent`** (shipped in `v0.5`, never yet exercised by content): Rostam pays Farrukh for the delivery, and how hard Farrukh negotiates the payment is itself a real choice with real tradeoffs — pushing harder gets more coin at the cost of `hidden_network` standing, since a courier who negotiates too sharply reads as a liability, not an asset. **First real use of the `hidden_network` faction** (named in the original master spec's reputation design, never touched by any shipped chapter) — fitting, since this is the first chapter where Farrukh deals directly with someone actually inside that world rather than someone adjacent to or investigating it.

**One optional sideroad:** Herat's mint, seen from this chapter's shadier angle — the real historical concept of **sikka** (a ruler's exclusive right to stamp coin, one of Islamic political theory's two markers of sovereignty alongside the khutba) and the real pressure toward debasement in a state running out of money to fight a war it's losing, contrasted pointedly against the underground trade Farrukh is about to transact in.

**No branching to a different chapter.** Unlike Farah, this chapter's true fork does not lead to two different next chapters — both tails converge on the same (not-yet-built) Chapter 5, a short ending chapter shared by anyone who took the Farah-plunder branch at all, regardless of which way this chapter's fork goes. The fork changes what Farrukh carries into that ending, not which ending-chapter file loads.

---

## 2. Cast

**Rostam** — deals in resold **ghanima** out of a quarter of Herat the respectable bazaar trade doesn't use, on the far side of the same underground channels Ardashir's world (Chapter 4A) touches only by correspondence. Genuinely capable, genuinely dangerous, and entirely uninterested in whatever cause originally justified the network he exploits — to him it's cover and leverage, nothing more. Not performatively menacing; his danger surfaces mostly in what he says carelessly, assuming Farrukh is already too implicated to matter. Knows exactly how much a courier who "asks too many questions" or "decides the money isn't worth it" has cost him before, and isn't shy about saying so once payment is settled.

---

## 3. Chapter Structure — 22 nodes, one optional sideroad, one payment negotiation, one true fork converging on a shared next chapter

**Act I — Arrival, obligated rather than curious**
1. `n01_herat_arrival_the_favor` — arrival, framed through what Farrukh is carrying and owes, not what he's investigating
2. `n02_the_bundle_and_the_favor` — interiority; **optional sideroad fork**
   - `"The mint draws your eye first."` → `n03a_the_mint_at_work`
   - `"Find Rostam without delay."` → `n05_the_far_edge_of_herat` (skips the sideroad)

**Act II — Optional sideroad: the mint, seen from the wrong side of it**
3. `n03a_the_mint_at_work` — **sikka**, the mint as a real seat of state authority
4. `n04a_the_debasement` — the real pressure toward debasing coin in a state running out of money → `n05_the_far_edge_of_herat`

**Act III — Rostam and the delivery**
5. `n05_the_far_edge_of_herat` — the quarter the respectable bazaar trade doesn't use
6. `n06_rostam_introduced`
7. `n07_the_delivery` — the bundle and message change hands
8. `n08_the_price_of_a_favor` — **the payment negotiation** (a *reward* gate, not a spend gate — first real content use of `coin_gained_dirham_equivalent`)
   - `"Insist on the price you agreed."` → `n09a_paid_as_agreed`. Effects: `{"coin_gained_dirham_equivalent": 15.0, "reputation": {"hidden_network": 1}}`
   - `"Push for more - he owes you for the risk."` → `n09b_pushing_for_more`
   - `"Take whatever he offers. Just be done with it."` → `n09c_took_the_scraps`. Effects: `{"coin_gained_dirham_equivalent": 5.0}`
9. `n09b_pushing_for_more` — round 2
   - `"Back off. His agreed price is fine."` → `n09a_paid_as_agreed` (same node/effects as above)
   - `"Keep pushing."` → `n10_extracted_more`. Effects: `{"coin_gained_dirham_equivalent": 20.0, "reputation": {"hidden_network": -1}}`
10. `n09a_paid_as_agreed` / `n09c_took_the_scraps` / `n10_extracted_more` — all → `n11_after_the_payment`

**Act IV — The reveal**
11. `n11_after_the_payment` → `n12_rostams_boast`
12. `n12_rostams_boast` — the unsettling reveal: a previous courier, referenced not shown, who tried to walk away
13. `n13_the_weight_of_knowing` — interiority

**Act V — The true fork**
14. `n14_the_choice` — **THE TRUE FORK**
    - `"Agree to keep working with him."` → `n15a_entangled_deeper`. Effects: `{"flags": ["chose_to_stay_entangled"], "reputation": {"hidden_network": 1}}`
    - `"Tell him this ends here."` → `n15b_pivot_away`. Effects: `{"flags": ["chose_to_pivot_away"], "reputation": {"hidden_network": -1}}`
15. **Stay-entangled tail:** `n15a_entangled_deeper` → `n16a_the_first_task` → `n17a_departure_bound` — **terminal node**, `choices: []`, `next_chapter_id: null`
16. **Pivot-away tail:** `n15b_pivot_away` → `n16b_the_veiled_threat` → `n17b_departure_free` — **terminal node**, `choices: []`, `next_chapter_id: null`

Both terminal nodes carry `knows_the_second_marks_name` forward (already set, from Farah) plus the chapter's own flag, and both are meant to receive the *same* future `next_chapter_id` once Chapter 5 exists — this is a real narrative fork with real consequences, not a fork in which chapter loads next.

---

## 4. Full Node Text

> **n01_herat_arrival_the_favor**
> Herat announced itself the same way it had for anyone arriving from the east - the green sudden after empty road, the mint-city's particular confidence - but Farrukh took less of it in than the moment probably deserved. He had a wrapped bundle riding in his own pack that wasn't his, a message he hadn't read addressed to a man he'd never heard of, and the specific unease of owing something to a person who had never once raised his voice to collect on it. Tahir hadn't needed to.

> **n02_the_bundle_and_the_favor**
> He could have asked around for the man's name the honest way, the way he'd asked about everything else on this road - but honest questions in a city this size, about a man like the one Tahir had named, had a way of reaching the wrong ears before they reached the right ones. Farrukh decided the safer education, if he wanted one before he found the man himself, was the kind that didn't involve saying anyone's name aloud.

> **n03a_the_mint_at_work**
> The mint's exterior gave away almost nothing - a plain gate, a line of men with sacks of raw silver waiting with the patience of people used to waiting - but the guard at the entrance was happy enough to talk about the one thing every Heratigan seemed proud of regardless of their trade: that the coin in every purse in this bazaar had been struck here, under the Sultan's own {{sikka|sikka}}, the exclusive mark of a ruler's sovereignty that no one beneath him was legally permitted to stamp.

> **n04a_the_debasement**
> What the guard didn't say, and what Farrukh had already half-guessed from two weeks of watching Ardashir-adjacent men weigh coin with more suspicion than the mint's reputation should have required, was the quieter fact underneath the proud one: a state paying for a war on a frontier that kept sending back bad news had exactly two ways to find more silver, and only one of them involved actually having more silver. Nobody at the mint gate said the word debasement. Nobody needed to; Farrukh had learned enough about coin on this road to recognize the shape of the problem even without the vocabulary for it.

> **n05_the_far_edge_of_herat**
> The quarter Tahir's directions led him to was close enough to the respectable bazaar to share its name and far enough from it to share none of its manners - narrower streets, fewer questions asked aloud, goods stacked in back rooms that had never touched a customs ledger or seen the {{muhtasib|muhtasib}}'s inspection in longer than anyone here would admit to. Farrukh understood, walking it, why Ardashir's whole world ran on correspondence and reputation rather than ever setting foot somewhere like this himself.

> **n06_rostam_introduced**
> The man Tahir had named was younger than Farrukh expected, and better dressed than the quarter around him - a man named Rostam, who took the bundle's description from Farrukh's mouth before Farrukh had finished giving it, the particular impatience of someone who had done this exact transaction with a dozen different couriers and had long since stopped finding any of them interesting.

> **n07_the_delivery**
> Farrukh handed over the bundle and the unread message together, and watched Rostam check the wrapping's seal with the practiced eye of a man who had been shorted before and intended never to be shorted again. He seemed satisfied. He did not, notably, explain what was in it, and Farrukh had long since stopped expecting anyone on this road to.

> **n08_the_price_of_a_favor**
> "Tahir's arrangement covers the delivery," Rostam said, counting out coin with the same unhurried precision every sarraf on this road seemed to share regardless of which side of the law they worked. "Whether it covers what you actually risked carrying it is a separate question, and one I notice Tahir left you to answer yourself."

> **n09a_paid_as_agreed**
> Farrukh took the agreed sum without pushing the matter, and Rostam's approval was almost imperceptible - a man filing away, the same way Ardashir had, that this particular courier didn't need managing.

> **n09b_pushing_for_more**
> Farrukh said, as levelly as he could manage, that carrying an unmarked bundle for a stranger across half of Khorasan was worth more than the bare delivery fee. Rostam considered him for a moment with something that wasn't quite respect. "It might be," he allowed. "How much more are we discussing?"

> **n10_extracted_more**
> Farrukh pushed, and got more coin for it than the delivery alone had been worth - and watched something behind Rostam's eyes recalculate him from an asset into a cost, a man who negotiated a little too well for someone who was supposed to be grateful for the work at all.

> **n09c_took_the_scraps**
> Farrukh took what was offered without argument, mostly because he wanted to be out of the room faster than the negotiation would have taken, and told himself the coin difference wasn't worth whatever it would have cost him to fight for it here specifically.

> **n11_after_the_payment**
> Business concluded, Rostam didn't immediately dismiss him - poured something from a jug Farrukh didn't recognize, the unhurried gesture of a man who'd decided, for reasons of his own, that the conversation wasn't quite finished yet.

> **n12_rostams_boast**
> "You did better than the last one," Rostam said, apropos of nothing Farrukh had asked. "Had a courier eight, nine months back, decided halfway through his second run that the money wasn't worth what he was starting to understand he was carrying. Asked too many questions. Then he asked them somewhere he shouldn't have." He didn't finish the thought, and the not-finishing was its own kind of answer - not a threat exactly, more the flat, unbothered tone of a man reporting weather. "You strike me as smarter than he was. I mean that as a compliment."

> **n13_the_weight_of_knowing**
> Farrukh walked out of the quarter with his coin and without whatever the last courier had lost, turning over the particular arithmetic of a man who'd just been complimented for his own self-preservation. The network Mihran had first named in Bost, the one that got its people crucified in Rayy nine years ago for believing in something dangerous enough to die for - that network, whatever remained of it, had apparently produced men like Rostam somewhere along the way: not believers, not survivors exactly, just men who'd found a profitable use for other people's old convictions and other people's continuing silence.

> **n14_the_choice**
> Rostam named a second errand before Farrukh had reached the door, offered with the same flat unbotheredness as everything else he said - not quite a demand, not quite a request, structured carefully enough that refusing it would require Farrukh to say so out loud, to a man who had just finished explaining, in his own unhurried way, what happened to couriers who said things like that.

> **n15a_entangled_deeper**
> Farrukh said yes. It was, he told himself, only ever going to be one more errand - the same lie, he suspected, that the last courier had probably told himself right up until it stopped being true.

> **n16a_the_first_task**
> Rostam gave him the particulars without ceremony - a name, a place, nothing that sounded any more dangerous than the delivery he'd just completed - and Farrukh understood, accepting it, that he had just become a slightly different kind of person than the one who'd walked into this quarter an hour ago, in a way no single moment of the conversation had quite let him refuse.

> **n17a_departure_bound**
> He left Herat carrying two things he hadn't arrived with: a name and a city from Ardashir's side of this journey that he'd never get to hear, and an understanding with a dangerous man that had no clean end date attached to it. The road west went on regardless of what a man carried into it.

> **n15b_pivot_away**
> Farrukh said no. He said it as plainly and as unremarkably as he could manage, the way a man declines a second cup of tea rather than the way a man refuses an enemy, on the theory - unproven, and he was aware it was unproven - that Rostam might let a small refusal pass if it didn't sound like a threat to him.

> **n16b_the_veiled_threat**
> Rostam didn't argue, which was somehow worse than arguing would have been. "Your choice," he said, in the same flat voice he'd used to describe the last courier's mistake, and let the silence afterward do whatever work he'd decided it needed to do. He didn't say Farrukh had chosen wrong. He didn't need to; the not-saying was, Farrukh understood by now, exactly how this particular man delivered his more serious sentences.

> **n17b_departure_free**
> He left Herat unbound to anything further, which felt less like relief than he'd expected it to - more like a man who has stepped back from a ledge and is still, several streets later, waiting to find out whether the ground was ever actually going to give way. He did not know if he'd see Rostam's name again. He suspected, without being able to say exactly why, that not knowing was itself the point.

---

## 5. New Glossary Terms (`content/glossary/herat_favor_terms.json`)

| Term | Headword | Definition |
|---|---|---|
| `sikka` | Sikka | The exclusive right to stamp a ruler's name on minted coin - one of the two classical markers of sovereignty in Islamic political theory (alongside the khutba, having one's name invoked in the Friday sermon). Usurping it was a real act of political rebellion, not a formality. |
| `muhtasib` | Muhtasib | A market inspector, responsible for weights, measures, and honest dealing in the bazaar under Islamic law - the legitimate oversight that quarters like the one Rostam operates in exist specifically to stay outside of. |

(`ghanima`, `sarraf`, and `dai` are referenced in plain prose, deliberately not re-glossed - all already taught in earlier chapters and persist in The Margin via the existing merge fix.)

---

## 6. Engine Notes — Consumes Existing Capability, No New Engine Work

This chapter needs **zero new engine capability.** It is the second real consumer of `v0.5-trading-engine` (after Chapter 4A) and the first real consumer of `coin_gained_dirham_equivalent` specifically, and the first chapter to touch the `hidden_network` reputation faction (named in the original master spec, never used by any shipped chapter until now).

**Structurally simpler than Farah or Chapter 4A's forks:** both of this chapter's terminal nodes lead to the *same* future next chapter, not different ones, so — unlike Farah's per-node `next_chapter_id` override — this chapter does not need that mechanism at all. Both terminal nodes explicitly declare `"next_chapter_id": null` for now (matching the established convention for any chapter's leading edge before its sequel exists), and when Chapter 5 is built, wiring it is a single manifest-level change (`chapter_04b_herat_favor`'s own `next_chapter_id` set once) plus updating both terminal nodes' explicit values to match — simpler than Chapter 4A's wiring task, which had to reach into Farah's own content.

---

## 7. Scope & Next Steps

Slightly smaller than Chapter 4A (22 nodes vs. 26) and structurally simpler (no per-node chapter override needed), but every bit as much a real payoff chapter: first income mechanic in real content, first `hidden_network` reputation, and the chapter that finally makes Tahir's Farah-ending bundle mean something concrete. Confirmed fully distinct from Chapter 4A per the user's earlier decision — no shared authored content between them.

**Whoever plans Chapter 5 next** inherits a real design question the ledger should already be tracking: both of this chapter's tails (`chose_to_stay_entangled` vs. `chose_to_pivot_away`) need to matter to that chapter's content, not just its opening flags — Chapter 5 is described elsewhere as "a short ending chapter, concluding the game with one of its possible endings" for the whole Farah-plunder branch, and this chapter's fork is very likely meant to determine *which* ending within that, not just flavor text along the way.

Next step: `writing-plans` to turn this into a task-by-task implementation plan, following the same TDD/subagent-driven-development pattern as every prior chapter.
