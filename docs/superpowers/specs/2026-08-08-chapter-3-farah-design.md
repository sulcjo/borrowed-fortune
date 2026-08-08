# Chapter 3: Farah — Design Doc

**Status:** Approved for planning. **Date:** 2026-08-08
**Builds on:** `2026-08-07-borrowed-fortune-design.md` (setting/systems), the chapter-manifest pattern (Ch1), shipped Chapters 0-2 (`v0.1-prologue`, `v0.2-teginabad`, `v0.3-bost`).

---

## 1. High Concept

Chapter 3 is Farah — the route's thinnest-sourced stop, which the original spec flagged as "invent lightly" and suggested as a smaller breather chapter. This design deliberately goes the other way: Farah is where the campaign's structure itself forks for the first time.

Farrukh arrives still carrying two possible outcomes from Bost (a name pressed out of Mihran, or only the "follow the channels" metaphor) and needs to turn whichever he has into an actual lead. Farah gives him two ways to do that, through two new characters — **Umm-Kavus**, a widow who runs the caravanserai and doubles as an honest broker/courier for merchants who trust her, and **Tahir**, a demobilized soldier from Mahmud's India campaigns who deals in resold plunder goods and knows the name through channels a good deal less clean. Choosing between them is this chapter's real fork: it costs coin and reputation one way, or a standing favor owed and reputation the other — and it decides which of two branches Chapter 4 will need to be.

Three smaller, reconverging choices give the chapter texture before that fork: a frontier-collapse checkpoint scene, and — new to the game — a real, if deliberately small, trade interaction at Umm-Kavus's caravanserai, paying down the standing commitment to eventually give the trade system real gameplay.

**Disclosed scope decision:** this chapter is bigger than Chapters 1-2 (17 nodes vs. 11) and, unlike them, ends in two genuinely different places rather than one. That is intentional, confirmed with the user, and has a real downstream cost: whoever plans Chapter 4 will need to design **two** variants (a mystery-thread continuation and a plunder-thread continuation), not one.

---

## 2. Cast

**Umm-Kavus** — keeper of Farah's caravanserai, called by the road only her kunya (son Kavus, dead three years of a fever that also took her husband). Runs the inn alone, competently, having stopped expecting help. Doubles as Farah's local **dallāl** — broker, message-carrier, informal banker — for merchants who trust her network the way they once trusted her husband's. Her path is the clean, costly one: coin and time for an honest answer.

**Tahir** — a former soldier from Mahmud's India campaigns, younger than his tiredness suggests, dealing quietly in resold **ghanima** (war spoils) out of Farah precisely because nobody official comes looking here. Knows the second mark's name because plunder-money and the hidden network's money move through some of the same unofficial channels. Wants no coin — only a favor: carrying an unmarked bundle and a message to an unnamed man in Herat. His path is fast and cheap in dirhams, expensive in the currency the whole game actually runs on: obligation.

---

## 3. Chapter Structure — 17 nodes, three reconverging forks and one true fork

1. `n01_farah_arrival` — arrival, a relay with no wall worth the name
2. `n02_the_checkpoint` — **reconverging fork A**: a Ghaznavid patrol has stopped a family of Nasa refugees
   - **A. "Tell him they're traveling with you."** → `n03a_vouched`. Effects: flags `["vouched_for_the_family_at_farah"]`, reputation `{"townsfolk": 2, "ghaznavid_officials": -1}`
   - **B. "Say nothing. It isn't your caravan to risk."** → `n03b_uninvolved`. Effects: flags `["stayed_uninvolved_at_farah"]`, reputation `{"ghaznavid_officials": 1}`
3. `n03a_vouched` / `n03b_uninvolved` — short aftermath, both → `n04`
4. `n04_golnars_caravanserai` — Umm-Kavus introduced, her role as **dallāl** established
5. `n05_the_price_of_a_bed` — **reconverging fork B (the light trade beat)**
   - **A. "Pay what she asks."** → `n06a_paid_full`. Effects: `{"coin_spent_dirham_equivalent": 15.0, "reputation": {"trading_families": 1}}`
   - **B. "Haggle her down."** → `n06b_haggled`. Effects: `{"coin_spent_dirham_equivalent": 6.0}`
6. `n06a_paid_full` / `n06b_haggled` — both → `n07_two_doors`
7. `n07_two_doors` — Umm-Kavus lays out both possible sources for the second mark's name
   - **"Ask her plainly about it."** → `n08_the_choice` (always available)
   - **requires_flag: `pressed_mihran_for_the_name`** — "Mention you already have a name from Bost." → `n07x_the_name_already_known`
8. `n07x_the_name_already_known` — flag-gated bonus beat (mirrors Ch1's letter-callback pattern) → `n08_the_choice`. Effects: flags `["confirmed_the_name_at_farah"]`
9. `n08_the_choice` — **THE TRUE FORK**
   - **A. "Go to Umm-Kavus's channel."** → `n09a_golnars_channel`. Effects: flags `["chose_golnars_channel"]`, reputation `{"trading_families": 1}`
   - **B. "Seek out Tahir."** → `n09b_tahirs_price`. Effects: flags `["chose_tahirs_price"]`, reputation `{"trading_families": -1}`
10. **Mystery-clean tail:** `n09a_golnars_channel` → `n10a_the_name_given_cleanly` (effects: flags `["knows_the_second_marks_name"]`, reputation `{"trading_families": 1}`) → `n11a_departure_farah_mystery` — **terminal node**, `choices: []`, own `next_chapter_id: null`
11. **Plunder-entangled tail:** `n09b_tahirs_price` → `n10b_the_favor_owed` (effects: flags `["knows_the_second_marks_name", "owes_tahir_a_favor"]`, reputation `{"townsfolk": -1}`) → `n11b_departure_farah_plunder` — **terminal node**, `choices: []`, own `next_chapter_id: null`

Both tails deliver the same core clue (`knows_the_second_marks_name`) — neither choice is a trap or a dead end — but diverge in cost, reputation, persistent obligation, and which terminal node (and eventually which Chapter 4) follows.

---

## 4. Full Node Text

> **n01_farah_arrival**
> Farah did not announce itself the way Teginabad or Bost had - no wall worth the name, no palace skyline, only a scatter of mud-brick and tamarisk windbreak at a crossing of tracks in country that seemed to have given up deciding whether it was desert or something less committed. If the frontier the riders had spoken of at Ghazni was truly failing, Farah was less a place it would fail *at* than a place it would simply pass through unremarked - one more relay a courier used and forgot. Farrukh's caravan master called it a good place to sleep and a bad place to be remembered, in the same breath, and did not explain further.

> **n02_the_checkpoint**
> A half-dozen mounted men in state colors had a family off the road before Farrukh's caravan even reached the crossing - a father, two children, a grandmother too proud to sit in the dust though she'd clearly been made to. Nasa people, by the accent, though nobody had asked their names before assuming the worst of them. The patrol's leader was working up to deciding they were worth arresting for something, the way men do when they have quotas and no particular targets. He glanced at Farrukh's caravan and its manifest with open invitation: say these are yours, and this becomes simple.

> **n03a_vouched**
> Farrukh said it before he'd fully decided to - the same reflex, he would think later, that had put him at his father's grave promising a debt nobody made him promise. The patrol leader weighed the lie for exactly as long as it took to decide it wasn't worth the paperwork of disbelieving, and let the family fall in with the caravan's rear, the grandmother's eyes on Farrukh the entire time with an expression that was not quite gratitude - more like a woman recalculating how much she now owed a stranger, which was a feeling Farrukh understood better than he wanted to.

> **n03b_uninvolved**
> Farrukh said nothing, and the caravan master, without being asked, steered their party wide around the checkpoint's business as if it were weather. Whatever happened to the family happened behind him; he did not look back to find out, and told himself, not quite believing it, that a man carrying one dead man's debt already had no coin left over to spend on anyone else's trouble.

> **n04_golnars_caravanserai**
> The caravanserai Farah offered travelers was kept by a woman the road called Umm-Kavus - Kavus being, Farrukh gathered before he'd even set down his load, a son three years dead of a fever that had also taken the husband who'd built the place. She ran it now alone, with the particular competence of someone who had stopped expecting help and adjusted accordingly, weighing new arrivals for trouble the way Mihran in Bost had weighed silver - and serving, Farrukh would learn before the night was through, as Farah's {{dallal|dallāl}} besides: broker, message-carrier, and informal banker to whichever merchants trusted her enough to use her.

> **n05_the_price_of_a_bed**
> She named a price for a room, feed for the animals, and a meal that did not pretend to be more than it was - lentils, bread, a name pronounced like a formality rather than an introduction. It was, Farrukh judged, a fair price for a woman running the last real roof before empty country. It was also, by the custom of every bazaar he'd ever stood in, a price that expected to be argued with.

> **n06a_paid_full**
> Farrukh counted out her full price without a word of argument, and something in her posture eased by a fraction she didn't announce - not gratitude exactly, more the relief of a woman who'd braced for one more traveler treating her arithmetic as an opening bid. "Not everyone does that," she said, in the tone of someone filing the fact away rather than thanking him for it.

> **n06b_haggled**
> Farrukh talked her down the way his father had taught him without ever calling it teaching - patiently, without insult, treating her number as a starting position rather than an offense. She gave ground exactly as far as a woman running the only inn for a day's ride needed to and not a hand's width further, and seemed, if anything, to respect the attempt more than she would have respected silent payment. Coin was coin either way; what a man did with the asking was its own kind of introduction.

> **n07_two_doors**
> Over the meal, in the unhurried way innkeepers dispense information they've decided is safe, Umm-Kavus mentioned - not quite offering it, not quite withholding it - that a name like the one on the paper Farrukh was chasing could be found two ways in a place like Farah. She herself moved money for merchants who trusted her network of couriers and correspondents, the same quiet channels that had once carried her late husband's trade; if the second mark's name ran through anyone's books, it likely ran through someone she could ask. Or - and here her voice flattened slightly - there was a man on the caravanserai's far edge, a former soldier named Tahir, who dealt in goods that had come west with the army rather than with any merchant's manifest, and who made a habit of knowing things that moved through channels less concerned with anyone's good opinion.

> **n07x_the_name_already_known**
> Farrukh told her the name Mihran had given him under duress in Bost. Umm-Kavus went still in the same particular way Mihran himself had - a woman recognizing a debt she hadn't been told she owed. "Then you don't need me to find it," she said slowly, "only to be sure of what you've already got. That, at least, I can still help with, cheaply."

> **n08_the_choice**
> She laid the choice out for him as plainly as Mihran never quite had: her own channels would find the name cleanly, honestly, the way her husband had always done business, but it would cost coin and take the better part of two days he didn't have to spare. Tahir would have it faster, possibly by nightfall, and would not want coin at all - men like Tahir dealt in favors, not dirhams, and a favor owed to a man who traded in war's leftovers was not the kind of debt Farrukh's father's kafāla had prepared him to carry.

> **n09a_golnars_channel**
> Umm-Kavus sent word through whoever she sent word through - Farrukh never saw a courier leave, only understood, two days later, that one must have come and gone - and did not ask him for anything beyond the fee she'd already quoted, paid in advance, no argument on either side this time.

> **n10a_the_name_given_cleanly**
> The answer came back written in a hand Farrukh didn't recognize, on paper that had clearly traveled further than Farah: a name, a city - Rayy again, unsurprisingly, the same house whose seal Mihran had first recognized - and nothing else, no explanation, no warning, exactly the transaction it had been sold as. Farrukh had what he'd paid for and nothing he hadn't. It felt, oddly, like the cleanest thing to happen to him since his father's death, which was its own kind of unsettling.

> **n11a_departure_farah_mystery**
> He left Farah two days later than planned and, by his own accounting, no poorer in anything that mattered - a debt to Umm-Kavus fully paid, a name in his satchel that owed him nothing further, and a growing, uncomfortable awareness that every clean answer on this road seemed to cost exactly what it claimed to and not one dirham less. The track west went on toward Herat and whatever waited there; he did not yet know that the name in his satchel was about to matter more than the road itself.

> **n09b_tahirs_price**
> Tahir kept his goods the way a man keeps things he's not entirely proud of owning - out of sight, wrapped, catalogued only in his own head. He was younger than Farrukh expected for a veteran of a campaign three years gone, and tired in a way that had nothing to do with the road. He named the second mark's owner before Farrukh had finished asking, the way a man recites something he's said before and will say again.

> **n10b_the_favor_owed**
> "No coin," Tahir said, when Farrukh reached for his purse out of habit. "I don't need coin. I need someone who isn't me to carry a message to a house in Herat, when you're passing through it, to a man who won't take it from my hand." He did not say why the man wouldn't take it from his hand, and Farrukh, looking at the wrapped goods stacked against the wall - things that had come west as {{ghanima|ghanima}}, the spoils of a war three years cold, never logged, never taxed, or taxed only once, the {{khums|khums}} skimmed off the top for a sultan who would never see this particular bundle again - decided he did not especially want to ask. He had his name. He also, he understood with a clarity that felt almost physical, now owed something to a man who traded in the leftovers of Mahmud's wars, and had no idea yet what that something would turn out to cost.

> **n11b_departure_farah_plunder**
> He left Farah on schedule, a day ahead of where Umm-Kavus's channel would have put him, a name in his satchel that had cost him nothing he could count and something he suspected he'd be counting for a long while yet. The wrapped bundle Tahir had pressed him to carry rode in his own pack now, unexamined, addressed to a house in Herat he had never heard of until an hour ago. Somewhere behind him, he understood, Mahmud's campaigns had left a residue that didn't stay in Bost's painted walls - it moved, the way everything on this road moved, through hands willing to carry it for the right kind of debt.

---

## 5. New Glossary Terms (`content/glossary/farah_terms.json`)

| Term | Headword | Definition |
|---|---|---|
| `dallal` | Dallāl | A broker or intermediary - in trade, someone who connected buyers and sellers, verified goods, or carried messages and money between merchants who trusted his (or her) network more than any single stranger. |
| `ghanima` | Ghanima | The spoils of war under Islamic law - movable property seized in a successful campaign, subject to specific rules for its division among the ruler, the army, and other stakeholders. |
| `khums` | Khums | Literally "one-fifth." The Quranically mandated share of ghanima (war spoils) reserved for the ruler and state - historically a major, and controversial, source of treasury income from campaigns like Mahmud's raids into India. |

(`kafāla` and `dirham` are referenced in plain prose, deliberately not re-glossed - both already taught in the Prologue and persist in The Margin via the existing merge fix.)

---

## 6. Engine Changes Required

Three small, real changes:

**6.1 `Ledger` gains a spend capability.** New field `spent_dirham_equivalent: float = 0.0` and method `spend_dirham_equivalent(amount: float) -> void` that accumulates it. `total_wealth_dirham_equivalent()` subtracts the accumulated amount from the existing purse total. `to_dict()`/`load_from_dict()` gain the new field so it round-trips through saves. This deliberately mirrors the existing abstraction level of `Debt` (a float obligation, not a simulated physical object) rather than modeling coin selection/change-making against the `purse` array — that stays out of scope for this "light" pass, and is a reasonable problem to solve when a real bazaar chapter builds full buy/sell.

**6.2 `ChapterView._apply_effects()` gains one new effects key.** When an effects dict has `"coin_spent_dirham_equivalent"`, call `ledger.spend_dirham_equivalent()` with that value. No wealth-gating on choices — a player can go into negative abstract wealth, which nothing currently surfaces to the UI (wealth is not displayed anywhere yet) and is thematically consistent with a debt-laden protagonist. Real gating is future bazaar-chapter work, not this chapter's job.

**6.3 `ChapterView._save_and_finish()` resolves next-chapter per terminal node, not only per chapter.** Currently `next_chapter_id` comes solely from the chapter's manifest entry. Change: resolve `dialogue_engine.current_node().get("next_chapter_id", next_chapter_id)` and use that resolved value everywhere `next_chapter_id` is currently used in this function (the null-check, the recursion-guard dictionary, and the `load_chapter_by_id` call). Existing terminal nodes (Chapters 0-2) have no `next_chapter_id` key, so they fall through to the manifest default unchanged - this is purely additive.

**6.4 Manifest wiring.** `content/chapters/manifest.json`: change `chapter_02_bost`'s `next_chapter_id` from `null` to `"chapter_03_farah"`. Add a `chapter_03_farah` entry pointing at this chapter's dialogue/glossary files, with its own `next_chapter_id: null` at the chapter level (unreachable in practice, since both of this chapter's terminal nodes always set their own `next_chapter_id`, currently both `null` until Chapter 4's two variants exist).

---

## 7. Scope & Next Steps

Larger than Chapters 1-2 (17 nodes vs. 11, three engine touch points instead of zero or two), for a real structural reason: this is the chapter that makes the campaign's branching genuine rather than cosmetic. **Whoever plans Chapter 4 next inherits a real fork**: `n11a_departure_farah_mystery` and `n11b_departure_farah_plunder` both need a `next_chapter_id` pointing at two different chapters, each of which needs its own content reflecting a different persistent state (`knows_the_second_marks_name` alone vs. that flag plus `owes_tahir_a_favor` and a reputation hit). This should be planned as two chapter variants, not deferred or collapsed back into one — collapsing them would waste this chapter's entire point.

Next step: `writing-plans` to turn this into a task-by-task implementation plan, following the same TDD/subagent-driven-development pattern as the prior three chapters.
