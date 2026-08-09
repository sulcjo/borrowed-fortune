# Chapter 4B: Herat (The Favor Owed) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship Chapter 4B (Herat, the favor-owed continuation of Farah's plunder branch) — 22 nodes, one optional sideroad, a payment negotiation (first real use of `coin_gained_dirham_equivalent`), and a true fork (stay entangled vs. pivot away) — wired into the manifest so Prologue → Teginabad → Bost → Farah(plunder) → Herat(favor) auto-chains.

**Architecture:** Pure content authoring. No new engine capability is needed — this chapter is the second consumer of `v0.5-trading-engine` and the first consumer of `coin_gained_dirham_equivalent` and the `hidden_network` reputation faction, both of which already exist. Unlike Farah or Chapter 4A, this chapter's fork does not need a per-node `next_chapter_id` override: both of its tails lead to the *same* future next chapter, so ordinary manifest-level wiring is enough once that chapter exists — for now both terminal nodes simply carry an explicit `null`, same as every chapter's leading edge before its sequel exists.

**Design doc:** `docs/superpowers/specs/2026-08-09-chapter-4b-herat-design.md` — read for narrative rationale. This plan's briefs are self-sufficient.

## Global Constraints

- Godot 4.3 floor. Priming command for a fresh checkout: `godot --headless --path . --editor --quit`.
- Headless test run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`.
- Naming idiom: GDScript's own idiom — `snake_case` functions/variables, `PascalCase` types.
- **Hard rule: `JSON.parse_string` always deserializes numbers as `float`, never `int`.** Cast with `int(...)` before comparing against an int literal.
- **Choice ordering convention:** the always-available choice is listed before any gated one in a node's `choices` array. This chapter has no `requires_flag`/`requires_reputation` gates at all, so this rule doesn't bind any specific node here — noted for consistency with every other chapter's plan.
- This chapter reuses `hidden_network` as its reputation faction — the first chapter to touch it. No new faction id beyond that.
- **Deliberate node-id reuse across chapter files:** this chapter's true-fork node is named `n14_the_choice`, the exact same id as Farah's own true-fork node in a *different* file (`content/chapters/chapter_03_farah/farah.json`). This is safe and intentional — node ids are scoped per dialogue file, never compared across chapters by any engine code or test, and the reuse is a deliberate structural echo (this chapter's fork occupies the same narrative position in its own arc that Farah's fork occupied in its). Do not rename either one to "fix" an apparent collision; there isn't one. When writing tests that walk by node id across a multi-chapter playthrough, be aware the same id will be reached twice (once in Farah, once in this chapter) at very different press counts — see Task 3's tests for the pattern.
- Commit after each task.

---

### Task 1: Herat-favor glossary content

**Files:**
- Create: `content/glossary/herat_favor_terms.json`
- Test: `tests/unit/test_herat_favor_glossary_content.gd`

**Interfaces:**
- Produces: `content/glossary/herat_favor_terms.json` with exactly 2 term ids: `sikka`, `muhtasib`. Consumed by Task 2's dialogue content.

- [ ] **Step 1: Write the failing test**

Create `tests/unit/test_herat_favor_glossary_content.gd`:

```gdscript
extends GutTest

func test_herat_favor_glossary_has_the_two_expected_terms_with_headword_and_definition():
	var file := FileAccess.open("res://content/glossary/herat_favor_terms.json", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()

	var expected_ids := ["sikka", "muhtasib"]
	assert_eq(data.keys().size(), expected_ids.size())
	for term_id in expected_ids:
		assert_true(data.has(term_id), "missing glossary term '%s'" % term_id)
		assert_true(data[term_id].has("headword"))
		assert_true(data[term_id].has("definition"))
		assert_false(data[term_id]["headword"].is_empty())
		assert_false(data[term_id]["definition"].is_empty())
```

- [ ] **Step 2: Run test to verify it fails**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_herat_favor_glossary_content.gd -gexit`
Expected: FAIL — file does not exist.

- [ ] **Step 3: Create the glossary file**

Create `content/glossary/herat_favor_terms.json`:

```json
{
	"sikka": {
		"headword": "Sikka",
		"definition": "The exclusive right to stamp a ruler's name on minted coin - one of the two classical markers of sovereignty in Islamic political theory (alongside the khutba, having one's name invoked in the Friday sermon). Usurping it was a real act of political rebellion, not a formality."
	},
	"muhtasib": {
		"headword": "Muhtasib",
		"definition": "A market inspector, responsible for weights, measures, and honest dealing in the bazaar under Islamic law - the legitimate oversight that quarters like the one Rostam operates in exist specifically to stay outside of."
	}
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_herat_favor_glossary_content.gd -gexit`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add content/glossary/herat_favor_terms.json tests/unit/test_herat_favor_glossary_content.gd
git commit -m "feat: add Herat-favor glossary terms"
```

---

### Task 2: Herat-favor dialogue content — 22 nodes, one optional sideroad, one payment negotiation, one true fork

**Files:**
- Create: `content/chapters/chapter_04b_herat_favor/herat_favor.json`
- Test: `tests/unit/test_herat_favor_dialogue_content.gd`

**Interfaces:**
- Consumes: gloss tokens `sikka` and `muhtasib` must match Task 1's `herat_favor_terms.json` exactly.
- Produces: `content/chapters/chapter_04b_herat_favor/herat_favor.json`, 22 nodes, start node `n01_herat_arrival_the_favor`, exactly two terminal nodes (`choices: []`): `n17a_departure_bound` and `n17b_departure_free`, each with its own explicit `"next_chapter_id": null`.

This task tests the tree via `DialogueEngine` directly, in isolation — not through `ChapterView` or the manifest (Task 3 does that integration).

- [ ] **Step 1: Write the failing tests**

Create `tests/unit/test_herat_favor_dialogue_content.gd`:

```gdscript
extends GutTest

func _load_nodes() -> Array:
	var file := FileAccess.open("res://content/chapters/chapter_04b_herat_favor/herat_favor.json", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	return data

func test_every_next_id_points_at_a_node_that_exists():
	var nodes := _load_nodes()
	var known_ids: Dictionary = {}
	for node in nodes:
		known_ids[node["id"]] = true
	for node in nodes:
		for choice in node.get("choices", []):
			assert_true(known_ids.has(choice["next_id"]), "%s -> next_id '%s' does not exist" % [node["id"], choice["next_id"]])

func test_exactly_two_nodes_have_no_choices_and_they_are_the_two_terminal_nodes():
	var nodes := _load_nodes()
	var end_node_ids: Array = []
	for node in nodes:
		if node.get("choices", []).is_empty():
			end_node_ids.append(node["id"])
	end_node_ids.sort()
	assert_eq(end_node_ids, ["n17a_departure_bound", "n17b_departure_free"])

func test_both_terminal_nodes_carry_their_own_null_next_chapter_id():
	var nodes := _load_nodes()
	var by_id: Dictionary = {}
	for node in nodes:
		by_id[node["id"]] = node
	assert_true(by_id["n17a_departure_bound"].has("next_chapter_id"))
	assert_eq(by_id["n17a_departure_bound"]["next_chapter_id"], null)
	assert_true(by_id["n17b_departure_free"].has("next_chapter_id"))
	assert_eq(by_id["n17b_departure_free"]["next_chapter_id"], null)

func test_every_glossed_term_id_exists_in_the_herat_favor_glossary():
	var nodes := _load_nodes()
	var glossary_file := FileAccess.open("res://content/glossary/herat_favor_terms.json", FileAccess.READ)
	var glossary_data = JSON.parse_string(glossary_file.get_as_text())
	glossary_file.close()
	for node in nodes:
		for term_id in GlossedTextParser.extract_term_ids(node["text"]):
			assert_true(glossary_data.has(term_id), "node %s glosses unknown term '%s'" % [node["id"], term_id])

func test_choosing_rostam_directly_skips_the_sideroad():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival_the_favor")
	engine.choose(0) # n01 -> n02
	engine.choose(1) # "Find Rostam without delay." -> n05 directly
	assert_eq(engine.current_node()["id"], "n05_the_far_edge_of_herat")

func test_choosing_the_mint_visits_the_sideroad_then_converges():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival_the_favor")
	engine.choose(0) # n01 -> n02
	engine.choose(0) # "The mint draws your eye first." -> n03a
	assert_eq(engine.current_node()["id"], "n03a_the_mint_at_work")
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n04a_the_debasement")
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n05_the_far_edge_of_herat", "the sideroad must converge on the same node the direct choice reaches")

func test_the_payment_negotiations_insist_path():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival_the_favor")
	for i in range(7):
		engine.choose(0) # n01 -> n02 -> n03a -> n04a -> n05 -> n06 -> n07 -> n08
	assert_eq(engine.current_node()["id"], "n08_the_price_of_a_favor")
	var effects := engine.choose(0) # "Insist on the price you agreed."
	assert_almost_eq(float(effects["coin_gained_dirham_equivalent"]), 15.0, 0.0001)
	assert_eq(int(effects["reputation"]["hidden_network"]), 1)
	assert_eq(engine.current_node()["id"], "n09a_paid_as_agreed")

func test_the_payment_negotiations_push_too_far_path():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival_the_favor")
	for i in range(7):
		engine.choose(0)
	engine.choose(1) # "Push for more - he owes you for the risk." -> n09b
	assert_eq(engine.current_node()["id"], "n09b_pushing_for_more")
	var effects := engine.choose(1) # "Keep pushing." -> n10
	assert_almost_eq(float(effects["coin_gained_dirham_equivalent"]), 20.0, 0.0001)
	assert_eq(int(effects["reputation"]["hidden_network"]), -1)
	assert_eq(engine.current_node()["id"], "n10_extracted_more")

func test_the_payment_negotiations_backing_off_reaches_the_same_node_as_insisting():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival_the_favor")
	for i in range(7):
		engine.choose(0)
	engine.choose(1) # push -> n09b
	engine.choose(0) # "Back off. His agreed price is fine." -> n09a
	assert_eq(engine.current_node()["id"], "n09a_paid_as_agreed")

func test_the_payment_negotiations_passive_path_has_no_reputation_effect():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival_the_favor")
	for i in range(7):
		engine.choose(0)
	var effects := engine.choose(2) # "Take whatever he offers. Just be done with it."
	assert_almost_eq(float(effects["coin_gained_dirham_equivalent"]), 5.0, 0.0001)
	assert_eq(effects.get("reputation", {}), {})
	assert_eq(engine.current_node()["id"], "n09c_took_the_scraps")

func test_the_stay_entangled_path_is_walkable_and_sets_its_flags_and_reputation():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival_the_favor")
	for i in range(12):
		engine.choose(0) # reach n14_the_choice via the sideroad + insist-on-price defaults
	assert_eq(engine.current_node()["id"], "n14_the_choice")
	var fork_effects := engine.choose(0) # "Agree to keep working with him."
	assert_eq(fork_effects["flags"], ["chose_to_stay_entangled"])
	assert_eq(int(fork_effects["reputation"]["hidden_network"]), 1)
	engine.choose(0) # n15a -> n16a
	engine.choose(0) # n16a -> n17a
	assert_eq(engine.current_node()["id"], "n17a_departure_bound")
	assert_true(engine.is_chapter_end())
	assert_true(engine.flags.get("chose_to_stay_entangled", false))

func test_the_pivot_away_path_is_walkable_and_sets_its_flags_and_reputation():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival_the_favor")
	for i in range(12):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n14_the_choice")
	var fork_effects := engine.choose(1) # "Tell him this ends here."
	assert_eq(fork_effects["flags"], ["chose_to_pivot_away"])
	assert_eq(int(fork_effects["reputation"]["hidden_network"]), -1)
	engine.choose(0) # n15b -> n16b
	engine.choose(0) # n16b -> n17b
	assert_eq(engine.current_node()["id"], "n17b_departure_free")
	assert_true(engine.is_chapter_end())
	assert_true(engine.flags.get("chose_to_pivot_away", false))

func test_the_full_tree_is_walkable_from_start_to_end_via_first_choices():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival_the_favor")
	var visited := 0
	while not engine.is_chapter_end() and visited < 100:
		engine.choose(0)
		visited += 1
	assert_true(engine.is_chapter_end())
	assert_eq(engine.current_node()["id"], "n17a_departure_bound")
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_herat_favor_dialogue_content.gd -gexit`
Expected: FAIL — `content/chapters/chapter_04b_herat_favor/herat_favor.json` does not exist.

- [ ] **Step 3: Create the dialogue content**

Create `content/chapters/chapter_04b_herat_favor/herat_favor.json` as a JSON array of exactly these 22 node objects, in this order, with these exact `text`, `choices[].text`, `choices[].next_id`, and `choices[].effects` values. Every node other than the two terminal nodes needs `"choices"` populated; effects objects omit any key the node genuinely has nothing to say about.

1. `id: "n01_herat_arrival_the_favor"`, one choice `"Continue."` → `n02_the_bundle_and_the_favor`, no effects.
   text: `"Herat announced itself the same way it had for anyone arriving from the east - the green sudden after empty road, the mint-city's particular confidence - but Farrukh took less of it in than the moment probably deserved. He had a wrapped bundle riding in his own pack that wasn't his, a message he hadn't read addressed to a man he'd never heard of, and the specific unease of owing something to a person who had never once raised his voice to collect on it. Tahir hadn't needed to."`

2. `id: "n02_the_bundle_and_the_favor"`, two choices:
   - `"The mint draws your eye first."` → `n03a_the_mint_at_work`, no effects.
   - `"Find Rostam without delay."` → `n05_the_far_edge_of_herat`, no effects.
   text: `"He could have asked around for the man's name the honest way, the way he'd asked about everything else on this road - but honest questions in a city this size, about a man like the one Tahir had named, had a way of reaching the wrong ears before they reached the right ones. Farrukh decided the safer education, if he wanted one before he found the man himself, was the kind that didn't involve saying anyone's name aloud."`

3. `id: "n03a_the_mint_at_work"`, one choice `"Continue."` → `n04a_the_debasement`, no effects.
   text: `"The mint's exterior gave away almost nothing - a plain gate, a line of men with sacks of raw silver waiting with the patience of people used to waiting - but the guard at the entrance was happy enough to talk about the one thing every Heratigan seemed proud of regardless of their trade: that the coin in every purse in this bazaar had been struck here, under the Sultan's own {{sikka|sikka}}, the exclusive mark of a ruler's sovereignty that no one beneath him was legally permitted to stamp."`

4. `id: "n04a_the_debasement"`, one choice `"Continue."` → `n05_the_far_edge_of_herat`, no effects.
   text: `"What the guard didn't say, and what Farrukh had already half-guessed from two weeks of watching Ardashir-adjacent men weigh coin with more suspicion than the mint's reputation should have required, was the quieter fact underneath the proud one: a state paying for a war on a frontier that kept sending back bad news had exactly two ways to find more silver, and only one of them involved actually having more silver. Nobody at the mint gate said the word debasement. Nobody needed to; Farrukh had learned enough about coin on this road to recognize the shape of the problem even without the vocabulary for it."`

5. `id: "n05_the_far_edge_of_herat"`, one choice `"Continue."` → `n06_rostam_introduced`, no effects.
   text: `"The quarter Tahir's directions led him to was close enough to the respectable bazaar to share its name and far enough from it to share none of its manners - narrower streets, fewer questions asked aloud, goods stacked in back rooms that had never touched a customs ledger or seen the {{muhtasib|muhtasib}}'s inspection in longer than anyone here would admit to. Farrukh understood, walking it, why Ardashir's whole world ran on correspondence and reputation rather than ever setting foot somewhere like this himself."`

6. `id: "n06_rostam_introduced"`, one choice `"Continue."` → `n07_the_delivery`, no effects.
   text: `"The man Tahir had named was younger than Farrukh expected, and better dressed than the quarter around him - a man named Rostam, who took the bundle's description from Farrukh's mouth before Farrukh had finished giving it, the particular impatience of someone who had done this exact transaction with a dozen different couriers and had long since stopped finding any of them interesting."`

7. `id: "n07_the_delivery"`, one choice `"Continue."` → `n08_the_price_of_a_favor`, no effects.
   text: `"Farrukh handed over the bundle and the unread message together, and watched Rostam check the wrapping's seal with the practiced eye of a man who had been shorted before and intended never to be shorted again. He seemed satisfied. He did not, notably, explain what was in it, and Farrukh had long since stopped expecting anyone on this road to."`

8. `id: "n08_the_price_of_a_favor"`, three choices:
   - `"Insist on the price you agreed."` → `n09a_paid_as_agreed`, effects `{"coin_gained_dirham_equivalent": 15.0, "reputation": {"hidden_network": 1}}`
   - `"Push for more - he owes you for the risk."` → `n09b_pushing_for_more`, no effects.
   - `"Take whatever he offers. Just be done with it."` → `n09c_took_the_scraps`, effects `{"coin_gained_dirham_equivalent": 5.0}`
   text: `"\"Tahir's arrangement covers the delivery,\" Rostam said, counting out coin with the same unhurried precision every sarraf on this road seemed to share regardless of which side of the law they worked. \"Whether it covers what you actually risked carrying it is a separate question, and one I notice Tahir left you to answer yourself.\""`

9. `id: "n09a_paid_as_agreed"`, one choice `"Continue."` → `n11_after_the_payment`, no effects.
   text: `"Farrukh took the agreed sum without pushing the matter, and Rostam's approval was almost imperceptible - a man filing away, the same way Ardashir had, that this particular courier didn't need managing."`

10. `id: "n09b_pushing_for_more"`, two choices:
    - `"Back off. His agreed price is fine."` → `n09a_paid_as_agreed` (same node/effects as item 9)
    - `"Keep pushing."` → `n10_extracted_more`, effects `{"coin_gained_dirham_equivalent": 20.0, "reputation": {"hidden_network": -1}}`
    text: `"Farrukh said, as levelly as he could manage, that carrying an unmarked bundle for a stranger across half of Khorasan was worth more than the bare delivery fee. Rostam considered him for a moment with something that wasn't quite respect. \"It might be,\" he allowed. \"How much more are we discussing?\""`

11. `id: "n10_extracted_more"`, one choice `"Continue."` → `n11_after_the_payment`, no effects.
    text: `"Farrukh pushed, and got more coin for it than the delivery alone had been worth - and watched something behind Rostam's eyes recalculate him from an asset into a cost, a man who negotiated a little too well for someone who was supposed to be grateful for the work at all."`

12. `id: "n09c_took_the_scraps"`, one choice `"Continue."` → `n11_after_the_payment`, no effects.
    text: `"Farrukh took what was offered without argument, mostly because he wanted to be out of the room faster than the negotiation would have taken, and told himself the coin difference wasn't worth whatever it would have cost him to fight for it here specifically."`

13. `id: "n11_after_the_payment"`, one choice `"Continue."` → `n12_rostams_boast`, no effects.
    text: `"Business concluded, Rostam didn't immediately dismiss him - poured something from a jug Farrukh didn't recognize, the unhurried gesture of a man who'd decided, for reasons of his own, that the conversation wasn't quite finished yet."`

14. `id: "n12_rostams_boast"`, one choice `"Continue."` → `n13_the_weight_of_knowing`, no effects.
    text: `"\"You did better than the last one,\" Rostam said, apropos of nothing Farrukh had asked. \"Had a courier eight, nine months back, decided halfway through his second run that the money wasn't worth what he was starting to understand he was carrying. Asked too many questions. Then he asked them somewhere he shouldn't have.\" He didn't finish the thought, and the not-finishing was its own kind of answer - not a threat exactly, more the flat, unbothered tone of a man reporting weather. \"You strike me as smarter than he was. I mean that as a compliment.\""`

15. `id: "n13_the_weight_of_knowing"`, one choice `"Continue."` → `n14_the_choice`, no effects.
    text: `"Farrukh walked out of the quarter with his coin and without whatever the last courier had lost, turning over the particular arithmetic of a man who'd just been complimented for his own self-preservation. The network Mihran had first named in Bost, the one crucified for in Rayy nine years ago for believing in something dangerous enough to die for - that network, whatever remained of it, had apparently produced men like Rostam somewhere along the way: not believers, not survivors exactly, just men who'd found a profitable use for other people's old convictions and other people's continuing silence."`

16. `id: "n14_the_choice"`, two choices:
    - `"Agree to keep working with him."` → `n15a_entangled_deeper`, effects `{"flags": ["chose_to_stay_entangled"], "reputation": {"hidden_network": 1}}`
    - `"Tell him this ends here."` → `n15b_pivot_away`, effects `{"flags": ["chose_to_pivot_away"], "reputation": {"hidden_network": -1}}`
    text: `"Rostam named a second errand before Farrukh had reached the door, offered with the same flat unbotheredness as everything else he said - not quite a demand, not quite a request, structured carefully enough that refusing it would require Farrukh to say so out loud, to a man who had just finished explaining, in his own unhurried way, what happened to couriers who said things like that."`

17. `id: "n15a_entangled_deeper"`, one choice `"Continue."` → `n16a_the_first_task`, no effects.
    text: `"Farrukh said yes. It was, he told himself, only ever going to be one more errand - the same lie, he suspected, that the last courier had probably told himself right up until it stopped being true."`

18. `id: "n16a_the_first_task"`, one choice `"Continue."` → `n17a_departure_bound`, no effects.
    text: `"Rostam gave him the particulars without ceremony - a name, a place, nothing that sounded any more dangerous than the delivery he'd just completed - and Farrukh understood, accepting it, that he had just become a slightly different kind of person than the one who'd walked into this quarter an hour ago, in a way no single moment of the conversation had quite let him refuse."`

19. `id: "n17a_departure_bound"`, `choices: []`, `"next_chapter_id": null`.
    text: `"He left Herat carrying two things he hadn't arrived with: a name and a city from Ardashir's side of this journey that he'd never get to hear, and an understanding with a dangerous man that had no clean end date attached to it. The road west went on regardless of what a man carried into it."`

20. `id: "n15b_pivot_away"`, one choice `"Continue."` → `n16b_the_veiled_threat`, no effects.
    text: `"Farrukh said no. He said it as plainly and as unremarkably as he could manage, the way a man declines a second cup of tea rather than the way a man refuses an enemy, on the theory - unproven, and he was aware it was unproven - that Rostam might let a small refusal pass if it didn't sound like a threat to him."`

21. `id: "n16b_the_veiled_threat"`, one choice `"Continue."` → `n17b_departure_free`, no effects.
    text: `"Rostam didn't argue, which was somehow worse than arguing would have been. \"Your choice,\" he said, in the same flat voice he'd used to describe the last courier's mistake, and let the silence afterward do whatever work he'd decided it needed to do. He didn't say Farrukh had chosen wrong. He didn't need to; the not-saying was, Farrukh understood by now, exactly how this particular man delivered his more serious sentences."`

22. `id: "n17b_departure_free"`, `choices: []`, `"next_chapter_id": null`.
    text: `"He left Herat unbound to anything further, which felt less like relief than he'd expected it to - more like a man who has stepped back from a ledge and is still, several streets later, waiting to find out whether the ground was ever actually going to give way. He did not know if he'd see Rostam's name again. He suspected, without being able to say exactly why, that not knowing was itself the point."`

- [ ] **Step 4: Run tests to verify they pass**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_herat_favor_dialogue_content.gd -gexit`
Expected: PASS, all tests.

- [ ] **Step 5: Commit**

```bash
git add content/chapters/chapter_04b_herat_favor/herat_favor.json tests/unit/test_herat_favor_dialogue_content.gd
git commit -m "feat: add Chapter 4B (Herat, the favor owed) dialogue content"
```

---

### Task 3: Manifest wiring and cross-chapter integration tests

**Files:**
- Modify: `content/chapters/manifest.json`
- Modify: `content/chapters/chapter_03_farah/farah.json` (one field on one node)
- Modify: `tests/unit/test_chapter_view.gd`

**Interfaces:**
- Consumes: Task 1's glossary, Task 2's dialogue content.
- Produces: a working Prologue → Teginabad → Bost → Farah(plunder) → Herat(favor) auto-chain, verified end to end via both of this chapter's tails, without disturbing the mystery-branch chain (Farah → Chapter 4A) already wired.

- [ ] **Step 1: Wire the manifest**

Add a new entry to `content/chapters/manifest.json`:

```json
	"chapter_04b_herat_favor": {
		"dialogue_path": "res://content/chapters/chapter_04b_herat_favor/herat_favor.json",
		"glossary_path": "res://content/glossary/herat_favor_terms.json",
		"next_chapter_id": null
	}
```

Do **not** change `chapter_03_farah`'s own manifest-level `next_chapter_id` (it's already `null`, and stays `null`). Do **not** touch the existing `chapter_04a_herat` entry.

- [ ] **Step 2: Wire Farah's plunder terminal node**

In `content/chapters/chapter_03_farah/farah.json`, find the node with `"id": "n19b_departure_farah_plunder"` and change its `"next_chapter_id": null` to `"next_chapter_id": "chapter_04b_herat_favor"`. Do **not** touch `n18a_departure_farah_mystery`'s `next_chapter_id` — it's already wired to `"chapter_04a_herat"` and must stay that way.

- [ ] **Step 3: Extend the plunder-branch full-playthrough test**

In `tests/unit/test_chapter_view.gd`, `test_a_full_playthrough_via_the_plunder_branch_reaches_its_own_terminal_node` currently asserts the playthrough ends at Farah. Since Farah's plunder terminal now auto-transitions into Chapter 4B, the "always press index 0" loop continues further: index 0 at `n02_the_bundle_and_the_favor` is the mint sideroad, index 0 at `n08_the_price_of_a_favor` is "insist on the price you agreed," and index 0 at `n14_the_choice` (Chapter 4B's own, not Farah's — see the Global Constraints note on deliberate node-id reuse) is "agree to keep working with him," so the playthrough lands on the stay-entangled terminal.

Change the function's final assertions from:

```gdscript
	assert_eq(chapter_view.chapter_id, "chapter_03_farah")
	assert_eq(chapter_view.dialogue_engine.current_node()["id"], "n19b_departure_farah_plunder")
	assert_eq(chapter_view.next_chapter_id, null, "Farah's plunder branch has no Chapter 4 yet")
	assert_true(chapter_view.dialogue_engine.flags.get("owes_tahir_a_favor", false))
	assert_true(chapter_view.dialogue_engine.flags.get("knows_the_second_marks_name", false))
	assert_almost_eq(chapter_view.ledger.total_wealth_dirham_equivalent(), -15.0, 0.0001)
	assert_true(FileAccess.file_exists("user://borrowed_fortune_chapter_03_farah.json"))
```

to:

```gdscript
	assert_eq(chapter_view.chapter_id, "chapter_04b_herat_favor")
	assert_eq(chapter_view.dialogue_engine.current_node()["id"], "n17a_departure_bound")
	assert_eq(chapter_view.next_chapter_id, null, "Chapter 4B has no Chapter 5 yet")
	assert_true(chapter_view.dialogue_engine.flags.get("owes_tahir_a_favor", false), "Farah's flag must survive into Herat")
	assert_true(chapter_view.dialogue_engine.flags.get("knows_the_second_marks_name", false))
	assert_true(chapter_view.dialogue_engine.flags.get("chose_to_stay_entangled", false), "index 0 at Chapter 4B's own n14_the_choice is 'Agree to keep working with him'")
	assert_false(chapter_view.dialogue_engine.flags.get("chose_to_pivot_away", false))
	assert_eq(chapter_view.reputation_tracker.get_reputation("hidden_network"), 2, "n09a_paid_as_agreed (+1) + n14_the_choice's stay-entangled option (+1); hidden_network is untouched by every earlier chapter, so this chapter's own effects are the whole total")
	assert_almost_eq(chapter_view.ledger.total_wealth_dirham_equivalent(), 0.0, 0.0001, "Farah's -15.0 plus this chapter's insist-on-the-price payment: +15.0")
	assert_true(FileAccess.file_exists("user://borrowed_fortune_chapter_03_farah.json"), "passing through Farah on the way to Herat must still write Farah's save file")
	assert_true(FileAccess.file_exists("user://borrowed_fortune_chapter_04b_herat_favor.json"), "reaching this chapter's stay-entangled ending must write its own save file")
```

**If the `reputation_tracker.get_reputation("hidden_network")` assertion does not equal 2,** do not just change the expected number — print `chapter_view.reputation_tracker.get_reputation("hidden_network")` right before the assertion and compare against this chapter's own effects (Task 2, node `n09a_paid_as_agreed` and the stay-entangled branch of `n14_the_choice`) to find the actual discrepancy. Unlike the `trading_families` faction (which every earlier chapter touches), `hidden_network` is this chapter's alone, so the arithmetic should be simple — if it's wrong, the most likely cause is a mismatched effects value in the shipped `herat_favor.json`, not a missed cross-chapter contribution.

- [ ] **Step 4: Add a dedicated test proving the pivot-away tail is reachable**

Append to `tests/unit/test_chapter_view.gd`:

```gdscript
func test_a_full_playthrough_via_the_pivot_away_path_reaches_its_own_terminal_node():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter_by_id("chapter_00_prologue")
	# Walk with "always press 0" until Farah's own true fork, then take the plunder
	# branch (index 1) there.
	var presses := 0
	while chapter_view.dialogue_engine.current_node().get("id", "") != "n14_the_choice" and presses < 200:
		chapter_view._on_choice_pressed(0)
		presses += 1
	assert_eq(chapter_view.dialogue_engine.current_node()["id"], "n14_the_choice", "this is Farah's own n14_the_choice - Chapter 4B is not loaded yet")
	chapter_view._on_choice_pressed(1) # "Seek out Tahir." (Farah's fork)

	# Continue with "always press 0" through the rest of Farah and into Chapter 4B, until
	# reaching THAT chapter's own n14_the_choice (same node id, different file - see the
	# Global Constraints note on deliberate node-id reuse). This second stop cannot be
	# confused with the first: many presses and an entire chapter transition separate them.
	presses = 0
	while chapter_view.dialogue_engine.current_node().get("id", "") != "n14_the_choice" and presses < 200:
		chapter_view._on_choice_pressed(0)
		presses += 1
	assert_eq(chapter_view.chapter_id, "chapter_04b_herat_favor", "should have auto-transitioned into Chapter 4B via Farah's plunder terminal")
	assert_eq(chapter_view.dialogue_engine.current_node()["id"], "n14_the_choice", "this is Chapter 4B's own n14_the_choice")
	chapter_view._on_choice_pressed(1) # "Tell him this ends here." (Chapter 4B's fork)

	presses = 0
	while chapter_view.dialogue_engine.available_choices().size() > 0 and presses < 200:
		chapter_view._on_choice_pressed(0)
		presses += 1
	assert_lt(presses, 200, "the pivot-away path should end on its own, not hit the safety cap")

	assert_eq(chapter_view.chapter_id, "chapter_04b_herat_favor")
	assert_eq(chapter_view.dialogue_engine.current_node()["id"], "n17b_departure_free")
	assert_true(chapter_view.dialogue_engine.flags.get("chose_to_pivot_away", false))
	assert_false(chapter_view.dialogue_engine.flags.get("chose_to_stay_entangled", false))
	assert_eq(chapter_view.reputation_tracker.get_reputation("hidden_network"), 0, "n09a_paid_as_agreed (+1) + n14_the_choice's pivot-away option (-1) = 0")
	assert_true(FileAccess.file_exists("user://borrowed_fortune_chapter_04b_herat_favor.json"))
```

- [ ] **Step 5: Run the ChapterView tests**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_chapter_view.gd -gexit`
Expected: PASS, including `test_glossary_terms_and_flag_names_are_unique_across_all_manifest_chapters`, which needs no changes to pick up `chapter_04b_herat_favor` — if it fails, a flag name or glossary term id collided with an earlier chapter's; re-check Task 1/2 against the earlier chapters before changing this test.

- [ ] **Step 6: Commit**

```bash
git add content/chapters/manifest.json content/chapters/chapter_03_farah/farah.json tests/unit/test_chapter_view.gd
git commit -m "feat: wire Chapter 4B into the manifest via Farah's plunder terminal node"
```

---

### Task 4: Full-suite verification

**Files:** none (verification only).

**Interfaces:** none.

- [ ] **Step 1: Run the entire suite headless**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`

- [ ] **Step 2: Confirm a clean pass**

Confirm: every test passes, no float/int comparison warnings, and the total test/assert counts increased from the pre-Chapter-4B baseline (151 tests / 556 asserts) by roughly the number of new tests this plan added (1 in Task 1, 15 in Task 2, 1 net-new in Task 3 — the extension of the existing plunder-branch test doesn't add a test, only the new pivot-away test does).

If the GUT GUI-asset import noise from a fresh worktree shows up again (unrelated `addons/gut/` font/image resource errors) — this was already investigated and confirmed non-blocking during the trading-engine and Chapter 4A plans; don't re-litigate it, just confirm the actual test pass/fail counts are clean.

- [ ] **Step 3: Report**

No commit for this task (verification only). Report the final pass/fail counts in the task report.

---

## Post-Plan Note

Both of this chapter's terminal nodes (`n17a_departure_bound`, `n17b_departure_free`) currently carry `next_chapter_id: null`, same as every chapter's leading edge before its sequel exists. When Chapter 5 (the shared ending chapter for the whole Farah-plunder branch) is built, wiring it is simpler than this chapter's own wiring was: a single manifest-level `next_chapter_id` on `chapter_04b_herat_favor` would work for both tails *if* the two terminal nodes are changed to omit their own override entirely — but since the established convention in this codebase is for every terminal node to explicitly declare its own value (never relying on omission), the more consistent approach is to set both nodes' `next_chapter_id` to the same Chapter 5 id explicitly. Either way, Chapter 5's design must account for `chose_to_stay_entangled` vs. `chose_to_pivot_away` (and the `hidden_network` reputation each leaves behind) mattering to its own content, not just carrying through as inert flags — this chapter's whole point was to make that fork mean something.
