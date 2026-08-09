extends GutTest

const MarginPopupScene := preload("res://scenes/margin_popup/MarginPopup.tscn")

func test_margin_popup_renders_headword_and_definition_for_each_entry():
	var popup = add_child_autofree(MarginPopupScene.instantiate())
	popup.show_entries([
		{"headword": "Khwaja", "definition": "A respectful address."},
		{"headword": "Kunya", "definition": "A father's honorific name."},
	])
	var rendered_text: String = popup.get_node("MarginRichTextLabel").text
	assert_true(rendered_text.contains("Khwaja"))
	assert_true(rendered_text.contains("A respectful address."))
	assert_true(rendered_text.contains("Kunya"))
	assert_true(rendered_text.contains("A father's honorific name."))

const ChapterViewScene := preload("res://scenes/chapter_view/ChapterView.tscn")

func test_chapter_view_renders_the_first_node_text_on_load():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter(
		"res://content/chapters/chapter_00_prologue/prologue.json",
		"res://content/glossary/prologue_terms.json"
	)
	var narration_label: RichTextLabel = chapter_view.get_node("NarrationLabel")
	assert_true(narration_label.text.contains("Farrukh ibn Hasan al-Nishapuri"))

func test_chapter_view_choosing_an_option_advances_the_node_and_applies_effects():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter(
		"res://content/chapters/chapter_00_prologue/prologue.json",
		"res://content/glossary/prologue_terms.json"
	)
	# Must go through _on_choice_pressed (not dialogue_engine.choose() directly) -
	# choose() only applies flags; _on_choice_pressed also routes reputation/debt
	# effects into _apply_effects(), which is what actually updates the ledger.
	# n01 -> n02 -> n03 -> n04 -> (pick "Step forward now...") -> n05a -> n06_vow
	for i in range(5):
		chapter_view._on_choice_pressed(0)
	# now sitting at n06_vow; one more press applies its kafala debts and flag
	chapter_view._on_choice_pressed(0)
	assert_almost_eq(chapter_view.ledger.total_debt_owed(), 610.0, 0.0001)
	assert_true(chapter_view.dialogue_engine.flags.get("vowed_kafala", false))

func test_chapter_view_clicking_a_glossed_term_unlocks_and_shows_it():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter(
		"res://content/chapters/chapter_00_prologue/prologue.json",
		"res://content/glossary/prologue_terms.json"
	)
	chapter_view._on_narration_meta_clicked("khwaja,kunya")
	assert_true(chapter_view.margin_glossary.is_unlocked("khwaja"))
	assert_true(chapter_view.margin_glossary.is_unlocked("kunya"))
	var popup = chapter_view.get_node("MarginPopup")
	assert_true(popup.visible)

func test_load_chapter_with_missing_dialogue_file_does_not_crash():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter(
		"res://content/chapters/does_not_exist.json",
		"res://content/glossary/prologue_terms.json"
	)
	assert_eq(chapter_view.dialogue_engine.current_node_id, "", "load_tree() should never have been called on a missing dialogue file")

func test_load_chapter_with_missing_glossary_file_does_not_crash():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter(
		"res://content/chapters/chapter_00_prologue/prologue.json",
		"res://content/glossary/does_not_exist.json"
	)
	assert_eq(chapter_view.dialogue_engine.current_node_id, "", "load_tree() should never have been called when the glossary file is missing")

func test_load_chapter_by_id_resolves_manifest_and_sets_chapter_id():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter_by_id("fixture_chapter_a", "res://tests/fixtures/manifest_fixture.json")
	assert_eq(chapter_view.chapter_id, "fixture_chapter_a")
	assert_eq(chapter_view.next_chapter_id, "fixture_chapter_b")
	assert_true(chapter_view.dialogue_engine.current_node()["text"].contains("Fixture A"))

func test_load_chapter_by_id_with_null_next_chapter_id():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter_by_id("fixture_chapter_b", "res://tests/fixtures/manifest_fixture.json")
	assert_eq(chapter_view.next_chapter_id, null)

func test_reaching_chapter_end_with_a_next_chapter_id_auto_transitions():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter_by_id("fixture_chapter_terminal", "res://tests/fixtures/manifest_fixture.json")
	assert_eq(chapter_view.chapter_id, "fixture_chapter_b")
	assert_true(chapter_view.dialogue_engine.current_node()["text"].contains("Fixture B"))

func test_reaching_chapter_end_with_no_next_chapter_id_does_not_transition():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter_by_id("fixture_chapter_b", "res://tests/fixtures/manifest_fixture.json")
	assert_eq(chapter_view.chapter_id, "fixture_chapter_b")
	assert_eq(chapter_view.next_chapter_id, null)

func test_completing_the_prologue_via_the_real_manifest_loads_teginabad():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter_by_id("chapter_00_prologue")
	for i in range(11):
		chapter_view._on_choice_pressed(0)
	assert_eq(chapter_view.chapter_id, "chapter_01_teginabad")
	assert_eq(chapter_view.dialogue_engine.current_node()["id"], "n01_teginabad_arrival")

func test_a_prologue_flag_survives_into_teginabad_and_gates_the_letter_callback():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter_by_id("chapter_00_prologue")
	# Walk to n09_suftaja_letter_choice (8 presses), then choose "read the letter in full" (index 0).
	for i in range(8):
		chapter_view._on_choice_pressed(0)
	chapter_view._on_choice_pressed(0)
	# Finish the Prologue (2 more presses) - this sets read_unsigned_letter and, at the end, auto-transitions.
	for i in range(2):
		chapter_view._on_choice_pressed(0)
	assert_eq(chapter_view.chapter_id, "chapter_01_teginabad")
	# Walk to Teginabad's fork (5 presses), then choose the honest path (index 1).
	for i in range(5):
		chapter_view._on_choice_pressed(0)
	chapter_view._on_choice_pressed(1)
	assert_eq(chapter_view.dialogue_engine.available_choices().size(), 2, "the letter-callback choice should be visible because read_unsigned_letter carried over from the Prologue")

func test_a_manifest_cycle_of_already_over_chapters_stops_instead_of_recursing():
	# Both cycle fixtures are over the instant they load, so each one auto-transitions from
	# inside its own load. Without the guard in _save_and_finish() this call never returns.
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter_by_id("fixture_chapter_cycle_a", "res://tests/fixtures/manifest_fixture.json")
	assert_eq(chapter_view.chapter_id, "fixture_chapter_cycle_a", "the chain must stop once it would re-enter a chapter it is already transitioning through")

func test_a_full_playthrough_via_the_mystery_branch_carries_prologue_flags_through_farah():
	# Clear any saves left by an earlier run first, or the file_exists() assertions below
	# would pass on stale files instead of on ones this playthrough actually wrote.
	var teginabad_save_path := "user://borrowed_fortune_chapter_01_teginabad.json"
	var bost_save_path := "user://borrowed_fortune_chapter_02_bost.json"
	var farah_save_path := "user://borrowed_fortune_chapter_03_farah.json"
	var herat_save_path := "user://borrowed_fortune_chapter_04a_herat.json"
	for path in [teginabad_save_path, bost_save_path, farah_save_path, herat_save_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		assert_false(FileAccess.file_exists(path), "the previous save should be cleared before the playthrough starts")

	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter_by_id("chapter_00_prologue")
	# Press "first choice" until the story is over. Every reconverging fork in this chain
	# (Prologue, Teginabad, Bost, and Farah's checkpoint/trade/two-doors forks) lists its
	# always-available choice at index 0, and Farah's true fork's index 0 is the mystery
	# branch (Umm-Kavus's channel) - so "always press 0" walks the whole chain and lands
	# on Farah's mystery-branch terminal node, not the plunder one.
	var presses := 0
	while chapter_view.dialogue_engine.available_choices().size() > 0 and presses < 200:
		chapter_view._on_choice_pressed(0)
		presses += 1
	assert_lt(presses, 200, "the playthrough should end on its own, not hit the safety cap")

	assert_eq(chapter_view.chapter_id, "chapter_04a_herat")
	assert_eq(chapter_view.dialogue_engine.current_node()["id"], "n21_departure_herat")
	assert_eq(chapter_view.next_chapter_id, null, "Chapter 4A has no Chapter 5 yet")
	assert_true(chapter_view.dialogue_engine.flags.get("vowed_kafala", false), "the Prologue's kafala vow flag must survive all the way into Herat")
	assert_true(chapter_view.dialogue_engine.flags.get("knows_the_second_marks_name", false))
	assert_true(chapter_view.dialogue_engine.flags.get("partial_network_reveal", false), "index 0 at n18_the_moment_of_truth is the always-available partial-truth choice, listed before the reputation-gated one, so a press-0-only playthrough takes it regardless of whether the gate has opened")
	assert_false(chapter_view.dialogue_engine.flags.get("full_network_reveal", false))
	assert_almost_eq(chapter_view.ledger.total_wealth_dirham_equivalent(), -45.0, 0.0001, "Farah's -15.0 plus Herat's two accepted-rate haggles: -10.0 and -20.0")
	assert_true(FileAccess.file_exists(teginabad_save_path), "passing through Teginabad on the way to Herat must still write Teginabad's save file")
	assert_true(FileAccess.file_exists(bost_save_path), "passing through Bost on the way to Herat must still write Bost's save file")
	assert_true(FileAccess.file_exists(farah_save_path), "passing through Farah on the way to Herat must still write Farah's save file")
	assert_true(FileAccess.file_exists("user://borrowed_fortune_chapter_04a_herat.json"), "reaching Herat's ending must write its own save file")

func test_glossary_terms_and_flag_names_are_unique_across_all_manifest_chapters():
	var manifest_file := FileAccess.open("res://content/chapters/manifest.json", FileAccess.READ)
	var manifest = JSON.parse_string(manifest_file.get_as_text())
	manifest_file.close()

	var seen_term_ids: Dictionary = {}
	var seen_flag_names: Dictionary = {}

	for chapter_id in manifest:
		var entry: Dictionary = manifest[chapter_id]

		var glossary_file := FileAccess.open(entry["glossary_path"], FileAccess.READ)
		var glossary_data = JSON.parse_string(glossary_file.get_as_text())
		glossary_file.close()
		for term_id in glossary_data:
			assert_false(seen_term_ids.has(term_id), "glossary term '%s' is defined in both %s and %s" % [term_id, seen_term_ids.get(term_id, ""), chapter_id])
			seen_term_ids[term_id] = chapter_id

		var dialogue_file := FileAccess.open(entry["dialogue_path"], FileAccess.READ)
		var dialogue_data = JSON.parse_string(dialogue_file.get_as_text())
		dialogue_file.close()
		for node in dialogue_data:
			for choice in node.get("choices", []):
				for flag_name in choice.get("effects", {}).get("flags", []):
					if seen_flag_names.has(flag_name):
						assert_eq(seen_flag_names[flag_name], chapter_id, "flag '%s' is set by both %s and %s - if this is intentional (the same flag legitimately set in two places), this assertion is safe to loosen; if not, it's a real collision" % [flag_name, seen_flag_names[flag_name], chapter_id])
					seen_flag_names[flag_name] = chapter_id

func test_apply_effects_with_coin_spent_dirham_equivalent_spends_from_the_ledger():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view._apply_effects({"coin_spent_dirham_equivalent": 6.0})
	assert_almost_eq(chapter_view.ledger.total_wealth_dirham_equivalent(), -6.0, 0.0001)

func test_apply_effects_with_coin_gained_dirham_equivalent_receives_into_the_ledger():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view._apply_effects({"coin_gained_dirham_equivalent": 20.0})
	assert_almost_eq(chapter_view.ledger.total_wealth_dirham_equivalent(), 20.0, 0.0001)

func test_status_readout_shows_coin_with_no_debt_or_reputation_before_any_choice():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter(
		"res://content/chapters/chapter_00_prologue/prologue.json",
		"res://content/glossary/prologue_terms.json"
	)
	var status_readout: Label = chapter_view.get_node("StatusReadout")
	assert_eq(status_readout.text, "Coin: 0.0 dirham")

func test_status_readout_shows_debt_and_reputation_after_the_kafala_vow():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter(
		"res://content/chapters/chapter_00_prologue/prologue.json",
		"res://content/glossary/prologue_terms.json"
	)
	# n01 -> n02 -> n03 -> n04 -> (pick "Step forward now...", +1 trading_families) ->
	# n05a -> n06_vow; one more press applies n06_vow's own effects (+2 trading_families,
	# +1 townsfolk, the three kafala debts) - same 6-press sequence as
	# test_chapter_view_choosing_an_option_advances_the_node_and_applies_effects above.
	for i in range(6):
		chapter_view._on_choice_pressed(0)
	var status_readout: Label = chapter_view.get_node("StatusReadout")
	assert_true(status_readout.text.contains("Debt owed: 610.0 dirham"), "the three debts guaranteed by n06_vow sum to 340+210+60=610")
	assert_true(status_readout.text.contains("Trading Families: +3"), "n04's spoke-now choice (+1) plus n06_vow's own (+2) = +3")
	assert_true(status_readout.text.contains("Townsfolk: +1"))

func test_status_readout_never_shows_a_faction_the_player_has_not_encountered_yet():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter(
		"res://content/chapters/chapter_00_prologue/prologue.json",
		"res://content/glossary/prologue_terms.json"
	)
	for i in range(6):
		chapter_view._on_choice_pressed(0)
	var status_readout: Label = chapter_view.get_node("StatusReadout")
	assert_false(status_readout.text.contains("Hidden Network"), "hidden_network is only introduced in Chapter 4B - showing it here would spoil that thread's existence")
	assert_false(status_readout.text.contains("Ghaznavid"), "ghaznavid_officials is never touched during the Prologue")

func test_status_readout_reflects_spent_coin_as_a_negative_value():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter(
		"res://content/chapters/chapter_00_prologue/prologue.json",
		"res://content/glossary/prologue_terms.json"
	)
	chapter_view._apply_effects({"coin_spent_dirham_equivalent": 6.0})
	chapter_view._update_status_readout()
	var status_readout: Label = chapter_view.get_node("StatusReadout")
	assert_true(status_readout.text.contains("Coin: -6.0 dirham"))

func test_a_terminal_nodes_own_next_chapter_id_overrides_the_manifest_default():
	# fixture_chapter_terminal_override is a new fixture chapter (add it to
	# tests/fixtures/manifest_fixture.json and its own dialogue fixture file)
	# whose manifest entry has next_chapter_id: null, but whose single node is
	# already a terminal node (choices: []) carrying its own
	# "next_chapter_id": "fixture_chapter_a" — proving the node-level value wins.
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter_by_id("fixture_chapter_terminal_override", "res://tests/fixtures/manifest_fixture.json")
	assert_eq(chapter_view.chapter_id, "fixture_chapter_a", "the terminal node's own next_chapter_id should have won over the manifest's null")

func test_a_terminal_nodes_explicit_null_next_chapter_id_blocks_the_manifests_non_null_default():
	# The trap this guards against: wiring a manifest's next_chapter_id to a real
	# chapter id does nothing if the terminal node the player actually lands on
	# already carries its own explicit "next_chapter_id": null - the node's value
	# always wins, silently, with no error. Chapter 4B's two terminal nodes
	# (n17a_departure_bound, n17b_departure_free) are exactly this shape today.
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter_by_id("fixture_chapter_terminal_null_override", "res://tests/fixtures/manifest_fixture.json")
	assert_eq(chapter_view.chapter_id, "fixture_chapter_terminal_null_override", "an explicit null on the node must block the manifest's non-null next_chapter_id")

func test_a_terminal_node_without_its_own_next_chapter_id_falls_back_to_the_manifest():
	# Regression guard: fixture_chapter_terminal (already used above) has no
	# per-node next_chapter_id, only the manifest's "fixture_chapter_b" ->
	# next_chapter_id "fixture_chapter_terminal" -> (terminal, no override) chain
	# already covered by test_reaching_chapter_end_with_a_next_chapter_id_auto_transitions.
	# This test covers the opposite direction: a terminal chapter whose manifest
	# entry's next_chapter_id is null and whose node also sets no override stays put.
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter_by_id("fixture_chapter_b", "res://tests/fixtures/manifest_fixture.json")
	assert_eq(chapter_view.chapter_id, "fixture_chapter_b")

func test_a_full_playthrough_via_the_plunder_branch_reaches_its_own_terminal_node():
	# Clear any save left by an earlier run first, or the file_exists() assertion below
	# would pass on a stale file instead of one this playthrough actually wrote.
	var herat_favor_save_path := "user://borrowed_fortune_chapter_04b_herat_favor.json"
	if FileAccess.file_exists(herat_favor_save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(herat_favor_save_path))
	assert_false(FileAccess.file_exists(herat_favor_save_path), "the previous save should be cleared before the playthrough starts")

	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter_by_id("chapter_00_prologue")
	# Walk with "always press 0" until Farah's true fork, exactly like the mystery-branch
	# playthrough above - but stop by node id rather than a hardcoded press count, since
	# that count would silently go stale if any earlier chapter's node count ever changes.
	var presses := 0
	while chapter_view.dialogue_engine.current_node().get("id", "") != "n14_the_choice" and presses < 200:
		chapter_view._on_choice_pressed(0)
		presses += 1
	assert_eq(chapter_view.dialogue_engine.current_node()["id"], "n14_the_choice", "should reach Farah's true fork by always taking the first choice through every earlier chapter and fork")
	chapter_view._on_choice_pressed(1) # "Seek out Tahir."
	presses = 0
	while chapter_view.dialogue_engine.available_choices().size() > 0 and presses < 200:
		chapter_view._on_choice_pressed(0)
		presses += 1
	assert_lt(presses, 200, "the plunder branch should end on its own, not hit the safety cap")

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
	assert_true(FileAccess.file_exists(herat_favor_save_path), "reaching this chapter's stay-entangled ending must write its own save file")

func test_a_full_playthrough_via_the_pivot_away_path_reaches_its_own_terminal_node():
	# Clear any save left by an earlier run first, or the file_exists() assertion below
	# would pass on a stale file instead of one this playthrough actually wrote.
	var herat_favor_save_path := "user://borrowed_fortune_chapter_04b_herat_favor.json"
	if FileAccess.file_exists(herat_favor_save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(herat_favor_save_path))
	assert_false(FileAccess.file_exists(herat_favor_save_path), "the previous save should be cleared before the playthrough starts")

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
	assert_true(FileAccess.file_exists(herat_favor_save_path), "reaching this chapter's pivot-away ending must write its own save file")

func test_reputation_changes_are_synced_into_the_dialogue_engine_before_rendering():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.reputation_tracker.adjust_reputation("trading_families", 3)
	chapter_view._render_current_node()
	assert_eq(chapter_view.dialogue_engine.reputation.get("trading_families", 0), 3)

func test_the_full_truth_is_reachable_with_strong_accumulated_reputation():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter_by_id("chapter_00_prologue")
	# Walk to Bost's fork by node id, then choose the patient path (index 1) for +2
	# trading_families - the highest-reputation option anywhere in the game so far.
	var presses := 0
	while chapter_view.dialogue_engine.current_node().get("id", "") != "n07_the_offer" and presses < 200:
		chapter_view._on_choice_pressed(0)
		presses += 1
	assert_eq(chapter_view.dialogue_engine.current_node()["id"], "n07_the_offer")
	chapter_view._on_choice_pressed(1) # "Don't make him say it." -> earned_mihrans_trust, trading_families +2

	# Continue with index 0 through the rest of Bost and all of Farah - index 0 at
	# Farah's n10_the_price_of_a_bed is "Pay what she asks" (+1), and index 0 at
	# n14_the_choice is Umm-Kavus's channel (+1, and the only way into Chapter 4A at all).
	presses = 0
	while chapter_view.dialogue_engine.current_node().get("id", "") != "n07_the_exchange_rate" and presses < 200:
		chapter_view._on_choice_pressed(0)
		presses += 1
	assert_eq(chapter_view.dialogue_engine.current_node()["id"], "n07_the_exchange_rate", "should have reached Herat's first haggle via Farah's mystery branch")

	# In Herat, take the non-aggressive path through both haggles: accept the exchange
	# rate (0 reputation cost), then pay the correspondence fee in full (+1).
	chapter_view._on_choice_pressed(0) # "Accept his rate." -> n08a
	presses = 0
	while chapter_view.dialogue_engine.current_node().get("id", "") != "n11_the_correspondence" and presses < 200:
		chapter_view._on_choice_pressed(0)
		presses += 1
	assert_eq(chapter_view.dialogue_engine.current_node()["id"], "n11_the_correspondence")
	chapter_view._on_choice_pressed(0) # "Pay what he asks." -> n12a, +1 trading_families

	presses = 0
	while chapter_view.dialogue_engine.current_node().get("id", "") != "n18_the_moment_of_truth" and presses < 200:
		chapter_view._on_choice_pressed(0)
		presses += 1
	assert_eq(chapter_view.dialogue_engine.current_node()["id"], "n18_the_moment_of_truth")
	# 8, not the 5 originally estimated: the always-press-0 walk from the Prologue through
	# Teginabad to Bost's fork already nets +2 trading_families before the fork itself is even
	# chosen (Prologue's n04_grave_question +1, n06_vow +2, Teginabad's n06_the_choice -1), and
	# Farah's mystery branch carries a third reputation bump beyond the bed and the fork - n17a_
	# the_name_given_cleanly's own "Continue" choice is worth +1 trading_families as well. Traced
	# and confirmed via checkpoint prints: 4 after Bost's fork, 7 after reaching Herat's first
	# haggle, 7 after accepting it (+0), 8 after paying Herat's second haggle in full (+1).
	# 2 (Prologue+Teginabad baseline) + 2 (Bost's patient path) + 1 (Farah's bed paid in full)
	# + 1 (Farah's fork into Umm-Kavus's channel) + 1 (Farah's n17a name-given bump)
	# + 0 (Herat's first haggle, accepted the rate) + 1 (Herat's second haggle, paid in full) = 8
	assert_eq(chapter_view.reputation_tracker.get_reputation("trading_families"), 8, "see trace above this assertion for the full breakdown")
	assert_eq(chapter_view.dialogue_engine.available_choices().size(), 2, "8 >= 4, the gated choice should be visible")
	chapter_view._on_choice_pressed(1) # the reputation-gated "Remind him what you've shown him..."
	assert_eq(chapter_view.dialogue_engine.current_node()["id"], "n19b_the_full_truth")
	assert_true(chapter_view.dialogue_engine.flags.get("full_network_reveal", false))
