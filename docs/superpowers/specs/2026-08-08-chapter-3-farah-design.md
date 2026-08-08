# Chapter 3: Farah — Design Doc

**Status:** Approved for planning. **Date:** 2026-08-08
**Builds on:** `2026-08-07-borrowed-fortune-design.md` (setting/systems), the chapter-manifest pattern (Ch1), shipped Chapters 0-2 (`v0.1-prologue`, `v0.2-teginabad`, `v0.3-bost`).

**Revision note:** this doc was expanded at the user's request for "much more written content and story depth" than Chapters 1-2. The structural concept (true fork, light trade, reconverging texture) is unchanged from the first draft; node count nearly doubled (17 → 27) and every surviving scene grew — new interiority beats, deeper characterization for both new NPCs, more historical grounding, and reactive texture that reads earlier choices back to the player without adding new structural branches.

---

## 1. High Concept

Chapter 3 is Farah — the route's thinnest-sourced stop, which the original spec flagged as "invent lightly" and suggested as a smaller breather chapter. This design deliberately goes the other way: Farah is where the campaign's structure itself forks for the first time, and where the game slows down to spend real time on two new characters instead of rushing past them.

Farrukh arrives still carrying two possible outcomes from Bost (a name pressed out of Mihran, or only the "follow the channels" metaphor) and needs to turn whichever he has into an actual lead. Farah gives him two ways to do that, through **Umm-Kavus**, a widow who runs the caravanserai and doubles as an honest broker/courier for merchants who trust her, and **Tahir**, a demobilized soldier from Mahmud's India campaigns who deals in resold plunder goods and knows the name through channels a good deal less clean. Choosing between them is this chapter's real fork: it costs coin and reputation one way, or a standing favor owed and reputation the other — and it decides which of two branches Chapter 4 will need to be.

Before that fork, the chapter takes its time: a frontier-collapse checkpoint scene grown into a real political exchange with a Ghaznavid officer, a dedicated interiority beat testing the Floating Man idea against a specific choice rather than leaving it abstract, a full character introduction and backstory conversation with Umm-Kavus that mirrors Farrukh's own grief back at him, a real (if deliberately small) trade interaction paying down the standing trading-system commitment, and a common-room scene that reads earlier choices back to the player without spawning new branches. Both post-fork tails get their own multi-beat arc rather than a single paragraph each — Tahir in particular gets a real characterization scene, including a moment that uses the spec's own flagged Somnath-legend material honestly.

**Disclosed scope decision:** this chapter is substantially bigger than Chapters 1-2 (27 nodes vs. 11) and, unlike them, ends in two genuinely different places rather than one. That is intentional, confirmed with the user twice now — once for the branching structure, once for the expanded depth — and has a real downstream cost: whoever plans Chapter 4 will need to design **two** variants (a mystery-thread continuation and a plunder-thread continuation), not one.

---

## 2. Cast

**Umm-Kavus** — keeper of Farah's caravanserai, called by the road only her kunya (son Kavus, dead three years of a fever that also took her husband). Runs the inn alone, competently, having stopped expecting help. Doubles as Farah's local **dallāl** — broker, message-carrier, informal banker — for merchants who trust her network the way they once trusted her husband's, built on **amāna**: trust deposited on reputation, not paperwork. Gets a dedicated backstory beat: what the inn cost her, why she kept it instead of selling, and why she recognizes something of herself in a nineteen-year-old carrying his father's debt. Her path is the clean, costly one: coin and time for an honest answer.

**Tahir** — a former soldier from Mahmud's India campaigns, younger than his tiredness suggests, dealing quietly in resold **ghanima** (war spoils) out of Farah precisely because nobody official comes looking here. Knows the second mark's name because plunder-money and the hidden network's money move through some of the same unofficial channels. Gets his own characterization beat before the transaction — a specific, ordinary-soldier's account of the campaign that punctures the Somnath legend's exaggerations without pretending the reality was better, only different. Wants no coin — only a favor: carrying an unmarked bundle and a message to an unnamed man in Herat. His path is fast and cheap in dirhams, expensive in the currency the whole game actually runs on: obligation.

**The checkpoint patrol** — led by a **ghulām**, one of the Turkic slave-soldiers who formed the professional core of the Ghaznavid army — not a customs officer like Sa'id in Teginabad, but a frontier soldier with a different relationship to state power. His exchange with Farrukh is this chapter's second real politics beat, connecting the abstract "plunder economy" theme to the military institution that actually produces and is funded by it, before Tahir ever makes it personal.

---

## 3. Chapter Structure — 27 nodes, three reconverging forks, two reactive-but-non-branching beats, and one true fork

**Act I — Arrival and the checkpoint**
1. `n01_farah_arrival` — arrival; qanat-fed green, frontier attrition, geography grounding
2. `n02_the_checkpoint` — the patrol has a refugee family off the road
3. `n03_the_officers_arithmetic` — the **ghulām** officer talks frontier politics with Farrukh while deciding what to do with the family
4. `n04_the_choice_at_the_checkpoint` — **reconverging fork A**
   - **A. "Tell him they're traveling with you."** → `n05a_vouched`. Effects: flags `["vouched_for_the_family_at_farah"]`, reputation `{"townsfolk": 2, "ghaznavid_officials": -1}`
   - **B. "Say nothing. It isn't your caravan to risk."** → `n05b_uninvolved`. Effects: flags `["stayed_uninvolved_at_farah"]`, reputation `{"ghaznavid_officials": 1}`
5. `n05a_vouched` / `n05b_uninvolved` — aftermath, both → `n06`
6. `n06_after_the_checkpoint` — **dedicated interiority beat**: grief, the Floating Man, contingent existence, tested against this specific choice

**Act II — Umm-Kavus and the caravanserai**
7. `n07_arrival_at_the_caravanserai` — first sight of the inn, other travelers, trade-corridor texture
8. `n08_umm_kavus_introduced` — her introduction, her role as **dallāl**
9. `n09_umm_kavus_backstory` — Farrukh asks; she tells him about the son and the husband
10. `n10_the_price_of_a_bed` — **reconverging fork B (the light trade beat)**
    - **A. "Pay what she asks."** → `n11a_paid_full`. Effects: `{"coin_spent_dirham_equivalent": 15.0, "reputation": {"trading_families": 1}}`
    - **B. "Haggle her down."** → `n11b_haggled`. Effects: `{"coin_spent_dirham_equivalent": 6.0}`
11. `n11a_paid_full` / `n11b_haggled` — both → `n12`
12. `n12_the_common_room` — evening scene, frontier news, world texture
    - always available: continue → `n13_two_doors`
    - **requires_flag: `vouched_for_the_family_at_farah`** — "See how the family is settling in." → `n12x_the_family_again` (reactive callback, not a new branch)
13. `n12x_the_family_again` — the grandmother speaks; effects: reputation `{"townsfolk": 1}` → `n13_two_doors`

**Act III — The setup**
14. `n13_two_doors` — Umm-Kavus lays out both possible sources for the second mark's name
    - **"Ask her plainly about it."** → `n14_the_choice` (always available)
    - **requires_flag: `pressed_mihran_for_the_name`** — "Mention you already have a name from Bost." → `n13x_the_name_already_known`
15. `n13x_the_name_already_known` — flag-gated bonus beat (Ch1-style callback) → `n14_the_choice`. Effects: flags `["confirmed_the_name_at_farah"]`
16. `n14_the_choice` — **THE TRUE FORK**
    - **A. "Go to Umm-Kavus's channel."** → `n15a_umm_kavus_channel`. Effects: flags `["chose_umm_kavus_channel"]`, reputation `{"trading_families": 1}`
    - **B. "Seek out Tahir."** → `n15b_finding_tahir`. Effects: flags `["chose_tahirs_price"]`, reputation `{"trading_families": -1}`

**Act IV-A — Mystery-clean tail**
17. `n15a_umm_kavus_channel` — word sent
18. `n16a_the_wait` — two days, texture, a second small interiority beat
19. `n17a_the_name_given_cleanly` — the answer arrives. Effects: flags `["knows_the_second_marks_name"]`, reputation `{"trading_families": 1}`
20. `n18a_departure_farah_mystery` — **terminal node**, `choices: []`, own `next_chapter_id: null`

**Act IV-B — Plunder-entangled tail**
21. `n15b_finding_tahir` — searching the caravanserai's edge, atmosphere
22. `n16b_tahirs_price` — he names the second mark's owner
23. `n17b_the_war_he_carries` — Tahir's own account of the campaign; the Somnath legend, honestly handled
24. `n18b_the_favor_owed` — the ask. Effects: flags `["knows_the_second_marks_name", "owes_tahir_a_favor"]`, reputation `{"townsfolk": -1}`
25. `n19b_departure_farah_plunder` — **terminal node**, `choices: []`, own `next_chapter_id: null`

Both tails deliver the same core clue (`knows_the_second_marks_name`) — neither choice is a trap or a dead end — but diverge in cost, reputation, persistent obligation, characterization, and which terminal node (and eventually which Chapter 4) follows.

---

## 4. Full Node Text

> **n01_farah_arrival**
> Farah did not announce itself the way Teginabad or Bost had - no wall worth the name, no palace skyline, only a scatter of mud-brick and tamarisk windbreak at a crossing of tracks in country that seemed to have given up deciding whether it was desert or something less committed. What green there was ran along channels dug by hands generations dead - a thin, stubborn irrigation the road's guide called older than any dynasty currently claiming this ground, older probably than the idea of Ghazni itself. If the frontier the riders had spoken of at Ghazni was truly failing, Farah was less a place it would fail at than a place it would simply pass through unremarked - one more relay a courier used and forgot. Farrukh's caravan master called it a good place to sleep and a bad place to be remembered, in the same breath, and did not explain further.

> **n02_the_checkpoint**
> A half-dozen mounted men in state colors had a family off the road before Farrukh's caravan even reached the crossing - a father, two children, a grandmother too proud to sit in the dust though she'd clearly been made to. Nasa people, by the accent, though nobody had asked their names before assuming the worst of them. Their leader sat his horse with the particular stillness of a man who did not need to raise his voice to be obeyed, a stillness Farrukh had learned, since Ghazni, to associate less with rank than with the specific kind of training that produced it.

> **n03_the_officers_arithmetic**
> He was a {{ghulam|ghulām}} - one of the Turkic soldiers bought young, raised in the palace's own household, and made into the empire's actual sword arm, more reliably loyal to the Sultan than any tribal levy or hereditary noble ever managed to be, or so the arrangement's defenders always said. He looked Farrukh's caravan over the way a man appraises livestock, not unkindly, and said, when Farrukh asked - more from nerves than courage - what the family had done: "Done. Nothing, probably. Fled something, which is worse for my purposes, because it means somebody above me will ask what fled toward us, and I have no answer that doesn't sound like a confession of a border I can't actually hold." He said it without bitterness, a professional stating a professional's problem, and Farrukh understood, not for the first time this journey, that the men enforcing the frontier's edge often believed in its failure more thoroughly than anyone they were failing to protect.

> **n04_the_choice_at_the_checkpoint**
> The ghulām's patience, such as it was, had a shape Farrukh could see closing. He glanced at Farrukh's manifest with the same open invitation Sa'id's men had offered back in Teginabad, though this offer had nothing to do with silk or seals: say these are yours, and this becomes simple for both of us. Refuse, and simple stops being available to anyone.

> **n05a_vouched**
> Farrukh said it before he'd fully decided to - the same reflex, he would think later, that had put him at his father's grave promising a debt nobody made him promise. The ghulām weighed the lie for exactly as long as it took to decide it wasn't worth the paperwork of disbelieving, and let the family fall in with the caravan's rear, the grandmother's eyes on Farrukh the entire time with an expression that was not quite gratitude - more like a woman recalculating how much she now owed a stranger, which was a feeling Farrukh understood better than he wanted to.

> **n05b_uninvolved**
> Farrukh said nothing, and the caravan master, without being asked, steered their party wide around the checkpoint's business as if it were weather. Whatever happened to the family happened behind him; he did not look back to find out, and told himself, not quite believing it, that a man carrying one dead man's debt already had no coin left over to spend on anyone else's trouble.

> **n06_after_the_checkpoint**
> He found himself, walking the last stretch into Farah proper, doing the counting exercise again - the one the old letter-writer in Ghazni had given him without quite meaning to teach it. Whether he'd claimed the family or let them pass him by, the choice itself had not been his to avoid; only its shape had been his to choose, the way a man floating in Avicenna's old thought-experiment, suspended in darkness with every limb cut off from sensation, still could not stop being a self that reasoned and chose, even stripped of every borrowed thing that usually told him who he was. His father's debt was borrowed obligation, freely re-chosen. This one - a stranger's family, a soldier's arithmetic he'd either fed or starved with one sentence - had not even offered him the dignity of a grave to swear it at. He had simply had to decide, in a moment, what kind of man made that decision, and live afterward with whichever one had answered.

> **n07_arrival_at_the_caravanserai**
> The caravanserai occupied the better half of what passed for Farah's center - low, mud-brick, built around a courtyard where animals and men shared space with the practiced indifference of people who had done this every night of their working lives. A Balkh horse-trader argued prices with a man Farrukh didn't recognize; a Sistan indigo-seller's mules stood tethered near enough that the dye-stained sacks perfumed half the yard. Trade did not stop for a failing frontier, Farrukh was beginning to understand. It simply grew more careful about which roads it trusted.

> **n08_umm_kavus_introduced**
> The caravanserai was kept by a woman the road called Umm-Kavus - Kavus being, Farrukh gathered before he'd even set down his load, a son three years dead of a fever that had also taken the husband who'd built the place. She ran it now alone, with the particular competence of someone who had stopped expecting help and adjusted accordingly, weighing new arrivals for trouble the way Mihran in Bost had weighed silver - and serving, Farrukh would learn before the night was through, as Farah's {{dallal|dallāl}} besides: broker, message-carrier, and informal banker to whichever merchants trusted her enough to use her, on nothing sturdier than {{amana|amāna}} - a trust deposited on reputation, not on any paper a qadi would recognize.

> **n09_umm_kavus_backstory**
> Farrukh asked her, once the introductions were done, why she'd kept the caravanserai instead of selling it and going to family somewhere easier. She looked at him for a moment the way Mihran had looked at him in Bost - recognizing something before being told it. "Because it was his," she said, "and because keeping a thing running is a way of arguing with the fact that the man who built it isn't. You'll understand that better than most travelers I get through here, I think, carrying what you're carrying." She did not ask what, specifically, he was carrying. She didn't need to; men his age traveling alone on this road were carrying some version of the same thing, and she had learned, she said, not to make them say it aloud before she'd fed them.

> **n10_the_price_of_a_bed**
> She named a price for a room, feed for the animals, and a meal that did not pretend to be more than it was - lentils, bread, a name pronounced like a formality rather than an introduction. It was, Farrukh judged, a fair price for a woman running the last real roof before empty country. It was also, by the custom of every bazaar he'd ever stood in, a price that expected to be argued with.

> **n11a_paid_full**
> Farrukh counted out her full price without a word of argument, and something in her posture eased by a fraction she didn't announce - not gratitude exactly, more the relief of a woman who'd braced for one more traveler treating her arithmetic as an opening bid. "Not everyone does that," she said, in the tone of someone filing the fact away rather than thanking him for it.

> **n11b_haggled**
> Farrukh talked her down the way his father had taught him without ever calling it teaching - patiently, without insult, treating her number as a starting position rather than an offense. She gave ground exactly as far as a woman running the only inn for a day's ride needed to and not a hand's width further, and seemed, if anything, to respect the attempt more than she would have respected silent payment. Coin was coin either way; what a man did with the asking was its own kind of introduction.

> **n12_the_common_room**
> Supper ran long, the way it does at the last real stop before empty country - travelers trading news the way they'd trade goods, weighing each rumor's worth before passing it on. Someone had heard Sarakhs's garrison had been reinforced; someone else swore the opposite, that it had been quietly thinned to reinforce somewhere closer to Ghazni. Nobody at the table had anything reliable to say about Nasa beyond what Farrukh had already carried out of the capital himself, which told him, more than any single rumor did, how far that particular piece of bad news had already traveled ahead of accurate detail.

> **n12x_the_family_again**
> The grandmother found him before he found her - upright now, dust brushed off with what dignity the road allowed, the children asleep somewhere behind her. She didn't thank him, exactly; she told him, instead, the name of the village they'd left and the name of the one they hoped still existed for them to reach, as if trusting a near-stranger with two names was its own kind of payment. "You didn't have to know either of those," she said. "Most men who help you don't want to know what they've helped with." It was, Farrukh thought, a fair description of most of what he'd done since his father's grave.

> **n13_two_doors**
> Over the meal, in the unhurried way innkeepers dispense information they've decided is safe, Umm-Kavus mentioned - not quite offering it, not quite withholding it - that a name like the one on the paper Farrukh was chasing could be found two ways in a place like Farah. She herself moved money for merchants who trusted her network of couriers and correspondents, the same quiet channels that had once carried her late husband's trade; if the second mark's name ran through anyone's books, it likely ran through someone she could ask. Or - and here her voice flattened slightly - there was a man on the caravanserai's far edge, a former soldier named Tahir, who dealt in goods that had come west with the army rather than with any merchant's manifest, and who made a habit of knowing things that moved through channels less concerned with anyone's good opinion.

> **n13x_the_name_already_known**
> Farrukh told her the name Mihran had given him under duress in Bost. Umm-Kavus went still in the same particular way Mihran himself had - a woman recognizing a debt she hadn't been told she owed. "Then you don't need me to find it," she said slowly, "only to be sure of what you've already got. That, at least, I can still help with, cheaply."

> **n14_the_choice**
> She laid the choice out for him as plainly as Mihran never quite had: her own channels would find the name cleanly, honestly, the way her husband had always done business, but it would cost coin and take the better part of two days he didn't have to spare. Tahir would have it faster, possibly by nightfall, and would not want coin at all - men like Tahir dealt in favors, not dirhams, and a favor owed to a man who traded in war's leftovers was not the kind of debt Farrukh's father's kafāla had prepared him to carry.

> **n15a_umm_kavus_channel**
> Umm-Kavus sent word through whoever she sent word through - Farrukh never saw a courier leave, only understood, two days later, that one must have come and gone - and did not ask him for anything beyond the fee she'd already quoted, paid in advance, no argument on either side this time.

> **n16a_the_wait**
> The two days passed slower than any two days had a right to. Farrukh made himself useful around the caravanserai rather than sit with his own thoughts uninterrupted - mending a strap, watering animals that weren't his, anything with an end he could see. Umm-Kavus caught him at it on the second afternoon and told him, not unkindly, that he didn't have to earn his keep twice. "I know," he said, and kept mending the strap anyway, because the alternative was counting, again, everything that was and wasn't his to carry, and he had done enough of that arithmetic for one week.

> **n17a_the_name_given_cleanly**
> The answer came back written in a hand Farrukh didn't recognize, on paper that had clearly traveled further than Farah: a name, a city - Rayy again, unsurprisingly, the same house whose seal Mihran had first recognized - and nothing else, no explanation, no warning, exactly the transaction it had been sold as. Farrukh had what he'd paid for and nothing he hadn't. It felt, oddly, like the cleanest thing to happen to him since his father's death, which was its own kind of unsettling.

> **n18a_departure_farah_mystery**
> He left Farah two days later than planned and, by his own accounting, no poorer in anything that mattered - a debt to Umm-Kavus fully paid, a name in his satchel that owed him nothing further, and a growing, uncomfortable awareness that every clean answer on this road seemed to cost exactly what it claimed to and not one dirham less. She saw him off at the gate herself, which she said she didn't do for every traveler, and told him to come back through with better news than he'd brought this time, if the road ever let him. The track west went on toward Herat and whatever waited there; he did not yet know that the name in his satchel was about to matter more than the road itself.

> **n15b_finding_tahir**
> The caravanserai's far edge was where Umm-Kavus's orderly economy gave way to something looser - a lean-to, a cookfire not quite public, goods stacked with the specific carelessness of a man who didn't expect anyone with authority to ask him to account for them. Tahir kept his own hours and his own company, and the other travelers gave his corner the wide berth people give a dog they aren't sure is friendly.

> **n16b_tahirs_price**
> He was younger than Farrukh expected for a veteran of a campaign three years gone, and tired in a way that had nothing to do with the road. He named the second mark's owner before Farrukh had finished asking, the way a man recites something he's said before and will say again - a name, a house, delivered flat, already priced in his head before Farrukh had offered anything.

> **n17b_the_war_he_carries**
> Farrukh, against his better judgment, asked him what it had actually been like - the campaign, the wealth, the stories that made it back to Ghazni's bazaars taller than anything a soldier could have carried home himself. Tahir laughed, once, without much humor in it. "Twenty million dinars, a temple's doors made of sandalwood, gates men still swear were dragged all the way back to Ghazni," he said. "Ask ten men who were actually there and you'll get ten different numbers, all of them smaller than the one you've heard, and none of us in a position to correct the ones telling it bigger, because the bigger version pays better in a bazaar story than the truth does. What I carried back fit in two saddlebags and a debt to a quartermaster who overcharged every soldier under him for the privilege of a horse. That's the campaign nobody sings about." He didn't say it like a man asking for pity, only like a man setting a ledger straight for its own sake, the way Farrukh's father might have, if his father had ever seen anything worth calling war.

> **n18b_the_favor_owed**
> "No coin," Tahir said, when Farrukh reached for his purse out of habit. "I don't need coin. I need someone who isn't me to carry a message to a house in Herat, when you're passing through it, to a man who won't take it from my hand." He did not say why the man wouldn't take it from his hand, and Farrukh, looking at the wrapped goods stacked against the wall - things that had come west as {{ghanima|ghanima}}, the spoils of a war three years cold, never logged, never taxed, or taxed only once, the {{khums|khums}} skimmed off the top for a sultan who would never see this particular bundle again - decided he did not especially want to ask. He had his name. He also, he understood with a clarity that felt almost physical, now owed something to a man who traded in the leftovers of Mahmud's wars, and had no idea yet what that something would turn out to cost.

> **n19b_departure_farah_plunder**
> He left Farah on schedule, a day ahead of where Umm-Kavus's channel would have put him, a name in his satchel that had cost him nothing he could count and something he suspected he'd be counting for a long while yet. The wrapped bundle Tahir had pressed him to carry rode in his own pack now, unexamined, addressed to a house in Herat he had never heard of until an hour ago. Somewhere behind him, he understood, Mahmud's campaigns had left a residue that didn't stay in Bost's painted walls, and didn't stay in a soldier's two saddlebags either - it moved, the way everything on this road moved, through hands willing to carry it for the right kind of debt, and his hands, he was fairly sure, had just joined them.

---

## 5. New Glossary Terms (`content/glossary/farah_terms.json`)

| Term | Headword | Definition |
|---|---|---|
| `ghulam` | Ghulām | A Turkic soldier, typically purchased and raised from youth within the royal household, forming the professional backbone of the Ghaznavid army - more directly loyal to the sultan than levies drawn from tribes or hereditary nobility. |
| `dallal` | Dallāl | A broker or intermediary - in trade, someone who connected buyers and sellers, verified goods, or carried messages and money between merchants who trusted his (or her) network more than any single stranger. |
| `amana` | Amāna | A trust or deposit held in safekeeping - the basic concept underlying informal courier and broker networks, where reputation, not paperwork, secured someone else's money or message. |
| `ghanima` | Ghanima | The spoils of war under Islamic law - movable property seized in a successful campaign, subject to specific rules for its division among the ruler, the army, and other stakeholders. |
| `khums` | Khums | Literally "one-fifth." The Quranically mandated share of ghanima (war spoils) reserved for the ruler and state - historically a major, and controversial, source of treasury income from campaigns like Mahmud's raids into India. |

(`kafāla`, `dirham`, and `kunya` are referenced in plain prose, deliberately not re-glossed - all three already taught in the Prologue and persist in The Margin via the existing merge fix.)

---

## 6. Engine Changes Required

Three small, real changes:

**6.1 `Ledger` gains a spend capability.** New field `spent_dirham_equivalent: float = 0.0` and method `spend_dirham_equivalent(amount: float) -> void` that accumulates it. `total_wealth_dirham_equivalent()` subtracts the accumulated amount from the existing purse total. `to_dict()`/`load_from_dict()` gain the new field so it round-trips through saves. This deliberately mirrors the existing abstraction level of `Debt` (a float obligation, not a simulated physical object) rather than modeling coin selection/change-making against the `purse` array — that stays out of scope for this "light" pass, and is a reasonable problem to solve when a real bazaar chapter builds full buy/sell.

**6.2 `ChapterView._apply_effects()` gains one new effects key.** When an effects dict has `"coin_spent_dirham_equivalent"`, call `ledger.spend_dirham_equivalent()` with that value. No wealth-gating on choices — a player can go into negative abstract wealth, which nothing currently surfaces to the UI (wealth is not displayed anywhere yet) and is thematically consistent with a debt-laden protagonist. Real gating is future bazaar-chapter work, not this chapter's job.

**6.3 `ChapterView._save_and_finish()` resolves next-chapter per terminal node, not only per chapter.** Currently `next_chapter_id` comes solely from the chapter's manifest entry. Change: resolve `dialogue_engine.current_node().get("next_chapter_id", next_chapter_id)` and use that resolved value everywhere `next_chapter_id` is currently used in this function (the null-check, the recursion-guard dictionary, and the `load_chapter_by_id` call). Existing terminal nodes (Chapters 0-2) have no `next_chapter_id` key, so they fall through to the manifest default unchanged - this is purely additive.

**6.4 Manifest wiring.** `content/chapters/manifest.json`: change `chapter_02_bost`'s `next_chapter_id` from `null` to `"chapter_03_farah"`. Add a `chapter_03_farah` entry pointing at this chapter's dialogue/glossary files, with its own `next_chapter_id: null` at the chapter level (unreachable in practice, since both of this chapter's terminal nodes always set their own `next_chapter_id`, currently both `null` until Chapter 4's two variants exist).

---

## 7. Scope & Next Steps

Substantially larger than Chapters 1-2 (27 nodes vs. 11, three engine touch points instead of zero or two), for two compounding reasons: this is the chapter that makes the campaign's branching genuine rather than cosmetic, and the user explicitly asked for more written depth than any prior chapter delivered. Expect the implementation plan's content-authoring tasks to take longer per task than Chapters 1-2's did, simply on volume — this is not a signal anything is wrong, it is the intended scope.

**Whoever plans Chapter 4 next inherits a real fork**: `n18a_departure_farah_mystery` and `n19b_departure_farah_plunder` both need a `next_chapter_id` pointing at two different chapters, each of which needs its own content reflecting a different persistent state (`knows_the_second_marks_name` alone vs. that flag plus `owes_tahir_a_favor` and a reputation hit). This should be planned as two chapter variants, not deferred or collapsed back into one — collapsing them would waste this chapter's entire point.

Next step: `writing-plans` to turn this into a task-by-task implementation plan, following the same TDD/subagent-driven-development pattern as the prior three chapters.
