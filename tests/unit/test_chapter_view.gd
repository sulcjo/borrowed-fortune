extends GutTest

const ChapterViewScene := preload("res://scenes/chapter_view/ChapterView.tscn")

func test_chapter_view_renders_the_first_node_text_on_load():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter(
		"res://content/chapters/chapter_00_prologue/prologue.json",
		"res://content/glossary/prologue_terms.json"
	)
	var narration_label: RichTextLabel = chapter_view.get_node("Folio/FolioMargin/Page/TextColumn/HeadBlock/NarrationLabel")
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

func test_gloss_notes_render_one_note_per_glossed_term_in_the_node():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.margin_glossary.load_entries({
		"dallal": {"headword": "Dallal", "definition": "A broker who matches buyers to sellers for a cut."},
		"amana": {"headword": "Amana", "definition": "Property held in trust, owed back intact."},
	})
	chapter_view.dialogue_engine.load_tree([{
		"id": "n01",
		"text": "The {{dallal|dallal}} held it as {{amana|amana}}.",
		"choices": [],
	}], "n01")
	chapter_view._render_current_node()

	var gloss_notes: VBoxContainer = chapter_view.get_node("Folio/FolioMargin/Page/MarginColumn/GlossNotes")
	assert_eq(gloss_notes.get_child_count(), 2)
	var rendered := ""
	for note in gloss_notes.get_children():
		rendered += note.text
	assert_true(rendered.contains("Dallal"))
	assert_true(rendered.contains("A broker who matches buyers to sellers for a cut."))
	assert_true(rendered.contains("Amana"))

func test_gloss_notes_are_empty_for_a_node_with_no_glossed_terms():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.dialogue_engine.load_tree([{"id": "n01", "text": "Plain prose.", "choices": []}], "n01")
	chapter_view._render_current_node()
	var gloss_notes: VBoxContainer = chapter_view.get_node("Folio/FolioMargin/Page/MarginColumn/GlossNotes")
	assert_eq(gloss_notes.get_child_count(), 0)

func test_gloss_notes_clear_when_moving_to_a_node_with_fewer_terms():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.margin_glossary.load_entries({
		"dallal": {"headword": "Dallal", "definition": "A broker."},
	})
	chapter_view.dialogue_engine.load_tree([{"id": "n01", "text": "A {{dallal|dallal}}.", "choices": []}], "n01")
	chapter_view._render_current_node()
	var gloss_notes: VBoxContainer = chapter_view.get_node("Folio/FolioMargin/Page/MarginColumn/GlossNotes")
	assert_eq(gloss_notes.get_child_count(), 1, "sanity check: must be populated first")

	chapter_view.dialogue_engine.load_tree([{"id": "n02", "text": "Plain prose.", "choices": []}], "n02")
	chapter_view._render_current_node()
	assert_eq(gloss_notes.get_child_count(), 0)

func test_glossed_terms_are_still_unlocked_so_the_save_format_is_unchanged():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.margin_glossary.load_entries({
		"dallal": {"headword": "Dallal", "definition": "A broker."},
	})
	chapter_view.dialogue_engine.load_tree([{"id": "n01", "text": "A {{dallal|dallal}}.", "choices": []}], "n01")
	chapter_view._render_current_node()
	assert_true(chapter_view.margin_glossary.is_unlocked("dallal"))

func test_narration_marks_glossed_terms_without_making_them_dead_links():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.dialogue_engine.load_tree([{"id": "n01", "text": "A {{dallal|dallal}}.", "choices": []}], "n01")
	chapter_view._render_current_node()
	var narration_label: RichTextLabel = chapter_view.get_node("Folio/FolioMargin/Page/TextColumn/HeadBlock/NarrationLabel")
	assert_false(narration_label.text.contains("[url"),
		"the popup is gone, so a link affordance would do nothing when clicked")
	assert_true(narration_label.text.contains("dallal"), "the term itself must still be shown")

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
	for i in range(13):
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
	# Finish the Prologue (4 more presses) - this sets read_unsigned_letter and, at the end, auto-transitions.
	for i in range(4):
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
	var pushang_save_path := "user://borrowed_fortune_chapter_06_pushang.json"
	var sarakhs_save_path := "user://borrowed_fortune_chapter_07_sarakhs.json"
	var nishapur_save_path := "user://borrowed_fortune_chapter_08_nishapur.json"
	for path in [teginabad_save_path, bost_save_path, farah_save_path, herat_save_path, pushang_save_path, sarakhs_save_path, nishapur_save_path]:
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

	assert_eq(chapter_view.chapter_id, "chapter_08_nishapur")
	assert_eq(chapter_view.dialogue_engine.current_node()["id"], "n10a_ending_the_self_that_endures", "carries_the_commanders_token is already true from Sarakhs's own 'always press 0' path, so at n04_the_choice_before_the_khaneqah both choices are visible and index 0 is the gated one ('Seek out the family...'); at n09_the_final_choice index 0 is 'Hold to the self that carried you this far.'")
	assert_eq(chapter_view.next_chapter_id, null, "Chapter 8 is the long route's actual finale - no Chapter 9 exists")
	assert_true(chapter_view.dialogue_engine.flags.get("vowed_kafala", false), "the Prologue's kafala vow flag must survive all the way into Nishapur")
	assert_true(chapter_view.dialogue_engine.flags.get("knows_the_second_marks_name", false))
	assert_true(chapter_view.dialogue_engine.flags.get("partial_network_reveal", false))
	assert_false(chapter_view.dialogue_engine.flags.get("full_network_reveal", false))
	assert_true(chapter_view.dialogue_engine.flags.get("carries_the_commanders_token", false))
	assert_true(chapter_view.dialogue_engine.flags.get("chose_the_self_that_endures", false), "index 0 at n09_the_final_choice is 'Hold to the self that carried you this far.'")
	assert_false(chapter_view.dialogue_engine.flags.get("chose_the_self_dissolved", false))
	assert_almost_eq(chapter_view.ledger.total_wealth_dirham_equivalent(), -103.0, 0.0001, "Chapter 8's word-to-Nasuh scene (index 0, 'Send what you can spare') adds a 20.0 debt_repaid spend on this path")
	assert_almost_eq(chapter_view.ledger.total_debt_owed(), 590.0, 0.0001, "Nasuh's 60.0 debt drops to 40.0 after the 20.0 repayment; the other two debts (340.0 + 210.0) are untouched")
	assert_true(FileAccess.file_exists(teginabad_save_path), "passing through Teginabad on the way to Nishapur must still write Teginabad's save file")
	assert_true(FileAccess.file_exists(bost_save_path), "passing through Bost on the way to Nishapur must still write Bost's save file")
	assert_true(FileAccess.file_exists(farah_save_path), "passing through Farah on the way to Nishapur must still write Farah's save file")
	assert_true(FileAccess.file_exists(herat_save_path), "passing through Chapter 4A on the way to Nishapur must still write its own save file")
	assert_true(FileAccess.file_exists(pushang_save_path), "passing through Chapter 6 on the way to Nishapur must still write its own save file")
	assert_true(FileAccess.file_exists(sarakhs_save_path), "Chapter 7 is no longer the final chapter, but passing through it must still write its own save file")
	assert_true(FileAccess.file_exists(nishapur_save_path), "reaching Chapter 8's ending must write its own save file")

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

func test_apply_effects_with_debt_repaid_pays_down_the_matching_debt_and_spends_from_the_ledger():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.ledger.guarantee_debt_via_kafala("Nasuh's own back wages, unpaid four months", 60.0)
	chapter_view._apply_effects({"debt_repaid": {"creditor_name": "Nasuh's own back wages, unpaid four months", "amount_dirham_equivalent": 20.0}})
	assert_almost_eq(chapter_view.ledger.total_debt_owed(), 40.0, 0.0001)
	assert_almost_eq(chapter_view.ledger.total_wealth_dirham_equivalent(), -20.0, 0.0001)

func test_apply_effects_with_mudaraba_settlement_applies_a_positive_profit_share():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view._apply_effects({
		"mudaraba_settlement": {
			"financier_name": "Test Financier",
			"agent_name": "Farrukh",
			"capital_dirham_equivalent": 40.0,
			"agent_profit_share": 0.5,
			"outcome_value_dirham_equivalent": 60.0,
			"agent_was_negligent": false
		}
	})
	# profit = 60.0 - 40.0 = 20.0; agent_share = 20.0 * 0.5 = 10.0
	assert_almost_eq(chapter_view.ledger.total_wealth_dirham_equivalent(), 10.0, 0.0001)

func test_apply_effects_with_mudaraba_settlement_applies_zero_result_on_an_honest_loss():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view._apply_effects({
		"mudaraba_settlement": {
			"financier_name": "Mihran's contact",
			"agent_name": "Farrukh",
			"capital_dirham_equivalent": 40.0,
			"agent_profit_share": 0.5,
			"outcome_value_dirham_equivalent": 28.0,
			"agent_was_negligent": false
		}
	})
	# profit = 28.0 - 40.0 = -12.0 (loss), not negligent -> agent owes nothing
	assert_almost_eq(chapter_view.ledger.total_wealth_dirham_equivalent(), 0.0, 0.0001)

func test_apply_effects_with_mudaraba_settlement_applies_a_negative_result_on_a_negligent_loss():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view._apply_effects({
		"mudaraba_settlement": {
			"financier_name": "Test Financier",
			"agent_name": "Farrukh",
			"capital_dirham_equivalent": 40.0,
			"agent_profit_share": 0.5,
			"outcome_value_dirham_equivalent": 28.0,
			"agent_was_negligent": true
		}
	})
	# profit = 28.0 - 40.0 = -12.0; negligent -> agent bears the full loss
	assert_almost_eq(chapter_view.ledger.total_wealth_dirham_equivalent(), -12.0, 0.0001)

func test_status_readout_shows_coin_with_no_debt_or_reputation_before_any_choice():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter(
		"res://content/chapters/chapter_00_prologue/prologue.json",
		"res://content/glossary/prologue_terms.json"
	)
	var status_readout: Label = chapter_view.get_node("Folio/FolioMargin/Page/TextColumn/Colophon")
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
	var status_readout: Label = chapter_view.get_node("Folio/FolioMargin/Page/TextColumn/Colophon")
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
	var status_readout: Label = chapter_view.get_node("Folio/FolioMargin/Page/TextColumn/Colophon")
	assert_false(status_readout.text.contains("Hidden Network"), "hidden_network is only introduced in Chapter 4B - showing it here would spoil that thread's existence")
	assert_false(status_readout.text.contains("Ghaznavid"), "ghaznavid_officials is never touched during the Prologue")

func test_status_readout_reflects_spent_coin_as_a_negative_value():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter(
		"res://content/chapters/chapter_00_prologue/prologue.json",
		"res://content/glossary/prologue_terms.json"
	)
	chapter_view._apply_effects({"coin_spent_dirham_equivalent": 6.0})
	chapter_view._update_colophon()
	var status_readout: Label = chapter_view.get_node("Folio/FolioMargin/Page/TextColumn/Colophon")
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
	# always wins, silently, with no error. Chapter 5's own terminal nodes
	# (e.g. n06a_departure_bound_believed) are exactly this shape today; Chapter 4B's
	# two terminal nodes used to be too, before Task 2 wired them to Chapter 5.
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

func test_post_ending_cutscene_path_is_read_from_the_manifest():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter_by_id("fixture_chapter_with_post_ending_cutscene", "res://tests/fixtures/manifest_fixture.json")
	assert_eq(chapter_view.post_ending_cutscene_path, "res://tests/fixtures/does_not_need_to_exist.tscn")

func test_a_full_playthrough_via_the_plunder_branch_reaches_its_own_terminal_node():
	# Clear any save left by an earlier run first, or the file_exists() assertion below
	# would pass on a stale file instead of one this playthrough actually wrote.
	var herat_favor_save_path := "user://borrowed_fortune_chapter_04b_herat_favor.json"
	if FileAccess.file_exists(herat_favor_save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(herat_favor_save_path))
	assert_false(FileAccess.file_exists(herat_favor_save_path), "the previous save should be cleared before the playthrough starts")

	var plunder_ending_save_path := "user://borrowed_fortune_chapter_05_plunder_ending.json"
	if FileAccess.file_exists(plunder_ending_save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(plunder_ending_save_path))
	assert_false(FileAccess.file_exists(plunder_ending_save_path), "the previous save should be cleared before the playthrough starts")

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

	assert_eq(chapter_view.chapter_id, "chapter_05_plunder_ending")
	assert_eq(chapter_view.dialogue_engine.current_node()["id"], "n06a_departure_bound_believed", "always pressing choice 0 takes 'Agree to keep working with him' at Ch4B's own fork, then 'Tell yourself it was only ever going to be one more errand' at Ch5's own fork")
	assert_eq(chapter_view.next_chapter_id, null, "Chapter 5 is the true end of the plunder branch")
	assert_true(chapter_view.dialogue_engine.flags.get("owes_tahir_a_favor", false), "Farah's flag must survive all the way into Chapter 5")
	assert_true(chapter_view.dialogue_engine.flags.get("knows_the_second_marks_name", false))
	assert_true(chapter_view.dialogue_engine.flags.get("chose_to_stay_entangled", false))
	assert_false(chapter_view.dialogue_engine.flags.get("chose_to_pivot_away", false))
	assert_true(chapter_view.dialogue_engine.flags.get("chose_to_believe_the_lie", false))
	assert_false(chapter_view.dialogue_engine.flags.get("chose_to_see_clearly", false))
	assert_eq(chapter_view.reputation_tracker.get_reputation("hidden_network"), 3, "n09a_paid_as_agreed (+1) + n12b_rostams_own_road's understand option (+1) + n14_the_choice's stay-entangled option (+1) = 3")
	assert_almost_eq(chapter_view.ledger.total_wealth_dirham_equivalent(), -16.0, 0.0001, "unchanged since Chapter 4B - Chapter 5 has no coin effects at all")
	assert_true(FileAccess.file_exists("user://borrowed_fortune_chapter_03_farah.json"), "passing through Farah on the way to Herat must still write Farah's save file")
	assert_true(FileAccess.file_exists("user://borrowed_fortune_chapter_04b_herat_favor.json"), "Chapter 4B is no longer the final chapter, but passing through it must still write its own save file")
	assert_true(FileAccess.file_exists(plunder_ending_save_path), "reaching Chapter 5's ending must write its own save file")

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

	assert_eq(chapter_view.chapter_id, "chapter_05_plunder_ending", "Chapter 4B's n17b_departure_free now auto-transitions into Chapter 5, same as n17a_departure_bound does for the stay-entangled path")
	assert_eq(chapter_view.dialogue_engine.current_node()["id"], "n06b_departure_free_believed", "always pressing choice 0 takes 'Tell him this ends here' at Ch4B's own fork, then 'Let yourself believe the danger has passed' at Ch5's own fork")
	assert_true(chapter_view.dialogue_engine.flags.get("chose_to_pivot_away", false))
	assert_false(chapter_view.dialogue_engine.flags.get("chose_to_stay_entangled", false))
	assert_eq(chapter_view.reputation_tracker.get_reputation("hidden_network"), 1, "n09a_paid_as_agreed (+1) + n12b_rostams_own_road's understand option (+1) + n14_the_choice's pivot-away option (-1) = 1")
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
	# 9, not the 5 originally estimated: the always-press-0 walk from the Prologue through
	# Teginabad to Bost's fork already nets +3 trading_families before the fork itself is even
	# chosen (Prologue's n04_grave_question +1, n06_vow +2, Teginabad's n06_the_choice -1,
	# Teginabad's n10_the_provisioner "Pay what she asks" +1), and Farah's mystery branch
	# carries a third reputation bump beyond the bed and the fork - n17a_the_name_given_cleanly's
	# own "Continue" choice is worth +1 trading_families as well. Traced and confirmed via
	# checkpoint prints: 5 after Bost's fork, 8 after reaching Herat's first haggle, 8 after
	# accepting it (+0), 9 after paying Herat's second haggle in full (+1).
	# 3 (Prologue+Teginabad baseline) + 2 (Bost's patient path) + 1 (Farah's bed paid in full)
	# + 1 (Farah's fork into Umm-Kavus's channel) + 1 (Farah's n17a name-given bump)
	# + 0 (Herat's first haggle, accepted the rate) + 1 (Herat's second haggle, paid in full) = 9
	assert_eq(chapter_view.reputation_tracker.get_reputation("trading_families"), 9, "see trace above this assertion for the full breakdown")
	assert_eq(chapter_view.dialogue_engine.available_choices().size(), 2, "9 >= 4, the gated choice should be visible")
	chapter_view._on_choice_pressed(1) # the reputation-gated "Remind him what you've shown him..."
	assert_eq(chapter_view.dialogue_engine.current_node()["id"], "n19b_the_full_truth")
	assert_true(chapter_view.dialogue_engine.flags.get("full_network_reveal", false))

func test_choice_list_is_tall_enough_for_every_choice_it_holds():
	# Four choices is the real maximum across all 229 nodes - Pushang's
	# n09_the_officers_demand. The old layout pinned this container to 76px, which
	# four buttons at font_size 18 plus stylebox margins cannot fit. Built directly
	# rather than loaded from the chapter so the test does not break if that node's
	# prose or choice set is edited later.
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.dialogue_engine.load_tree([{
		"id": "n09",
		"text": "An officer at the gate named a sum.",
		"choices": [
			{"text": "Pay what he asks.", "next_id": "n09", "effects": {}},
			{"text": "Argue him down to something smaller.", "next_id": "n09", "effects": {}},
			{"text": "Refuse outright.", "next_id": "n09", "effects": {}},
			{"text": "Offer him something quieter, off the list.", "next_id": "n09", "effects": {}},
		],
	}], "n09")
	chapter_view._render_current_node()

	var choices_container: VBoxContainer = chapter_view.get_node("Folio/FolioMargin/Page/TextColumn/ChoicesContainer")
	assert_eq(choices_container.get_child_count(), 4, "all four choices must be present")

	var children_height := 0.0
	for child in choices_container.get_children():
		children_height += child.get_combined_minimum_size().y
	assert_gte(choices_container.get_combined_minimum_size().y, children_height,
		"the container must be at least as tall as the choices it holds")

func test_colophon_leads_with_the_chapter_place_name():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter_by_id("chapter_06_pushang")
	var colophon: Label = chapter_view.get_node("Folio/FolioMargin/Page/TextColumn/Colophon")
	assert_true(colophon.text.begins_with("Pushang"),
		"expected the place name at the head of the colophon, got: %s" % colophon.text)

func test_colophon_omits_the_place_name_when_the_manifest_gives_none():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.place_name = ""
	chapter_view.dialogue_engine.load_tree([{"id": "n01", "text": "", "choices": []}], "n01")
	chapter_view._update_colophon()
	var colophon: Label = chapter_view.get_node("Folio/FolioMargin/Page/TextColumn/Colophon")
	assert_true(colophon.text.begins_with("Coin:"),
		"with no place name the line should start at the coin, got: %s" % colophon.text)

func test_narration_renders_the_active_text_variant():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.dialogue_engine.load_tree([{
		"id": "n01",
		"text": "He named a sum.",
		"text_variants": [{"requires_flag": "bribed_before", "text": "He named a sum; he knew you paid."}],
		"choices": [],
	}], "n01")
	chapter_view.dialogue_engine.flags["bribed_before"] = true
	chapter_view._render_current_node()
	var narration: RichTextLabel = chapter_view.get_node("Folio/FolioMargin/Page/TextColumn/HeadBlock/NarrationLabel")
	assert_true(narration.text.contains("he knew you paid"))
	assert_false(narration.text.contains("He named a sum."),
		"the base reading must be replaced, not appended")

func test_a_term_glossed_only_inside_a_variant_still_gets_a_margin_note():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.margin_glossary.load_entries({
		"dallal": {"headword": "Dallal", "definition": "A broker."},
	})
	chapter_view.dialogue_engine.load_tree([{
		"id": "n01",
		"text": "He named a sum.",
		"text_variants": [{"requires_flag": "met_the_broker", "text": "The {{dallal|dallal}} named it for him."}],
		"choices": [],
	}], "n01")
	chapter_view.dialogue_engine.flags["met_the_broker"] = true
	chapter_view._render_current_node()
	var gloss_notes: VBoxContainer = chapter_view.get_node("Folio/FolioMargin/Page/MarginColumn/GlossNotes")
	assert_eq(gloss_notes.get_child_count(), 1, "the variant's glossed term needs a margin note")

func test_no_margin_note_for_a_term_in_an_inactive_variant():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.margin_glossary.load_entries({
		"dallal": {"headword": "Dallal", "definition": "A broker."},
	})
	chapter_view.dialogue_engine.load_tree([{
		"id": "n01",
		"text": "He named a sum.",
		"text_variants": [{"requires_flag": "met_the_broker", "text": "The {{dallal|dallal}} named it."}],
		"choices": [],
	}], "n01")
	chapter_view._render_current_node()
	var gloss_notes: VBoxContainer = chapter_view.get_node("Folio/FolioMargin/Page/MarginColumn/GlossNotes")
	assert_eq(gloss_notes.get_child_count(), 0)

func test_the_colophon_names_the_current_slot():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.place_name = "Nishapur"
	chapter_view.dialogue_engine.slots = ["the first evening", "the next morning"]
	chapter_view.dialogue_engine.load_tree([{"id": "n01", "text": "", "choices": []}], "n01")
	chapter_view._update_colophon()
	var colophon: Label = chapter_view.get_node("Folio/FolioMargin/Page/TextColumn/Colophon")
	assert_true(colophon.text.begins_with("Nishapur, the first evening"), "got: %s" % colophon.text)

func test_the_colophon_omits_the_slot_when_no_stay_is_declared():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.place_name = "Nishapur"
	chapter_view.dialogue_engine.load_tree([{"id": "n01", "text": "", "choices": []}], "n01")
	chapter_view._update_colophon()
	var colophon: Label = chapter_view.get_node("Folio/FolioMargin/Page/TextColumn/Colophon")
	assert_true(colophon.text.begins_with("Nishapur · "), "got: %s" % colophon.text)

func test_the_colophon_drops_the_slot_once_the_stay_is_spent():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.place_name = "Nishapur"
	chapter_view.dialogue_engine.slots = ["the only evening"]
	chapter_view.dialogue_engine.slot_index = 1
	chapter_view.dialogue_engine.load_tree([{"id": "n01", "text": "", "choices": []}], "n01")
	chapter_view._update_colophon()
	var colophon: Label = chapter_view.get_node("Folio/FolioMargin/Page/TextColumn/Colophon")
	assert_true(colophon.text.begins_with("Nishapur · "), "got: %s" % colophon.text)

func test_slots_are_taken_from_the_manifest_entry():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter_by_id("fixture_chapter_stay", "res://tests/fixtures/manifest_fixture.json")
	assert_eq(chapter_view.dialogue_engine.slots.size(), 2)
	assert_eq(str(chapter_view.dialogue_engine.slots[0]), "the first evening")

func test_a_stay_can_be_spent_and_records_what_was_declined():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter_by_id("fixture_chapter_stay", "res://tests/fixtures/manifest_fixture.json")
	var colophon: Label = chapter_view.get_node("Folio/FolioMargin/Page/TextColumn/Colophon")
	assert_true(colophon.text.begins_with("Fixture City, the first evening"), "got: %s" % colophon.text)

	# First slot: three opportunities and no exit.
	assert_eq(chapter_view.dialogue_engine.available_choices().size(), 3)
	chapter_view._on_choice_pressed(0)   # visit the widow
	chapter_view._on_choice_pressed(0)   # back to the hub
	assert_true(colophon.text.begins_with("Fixture City, the next morning"), "got: %s" % colophon.text)

	# Second slot: the visited opportunity is gone, still no exit.
	assert_eq(chapter_view.dialogue_engine.available_choices().size(), 2)
	chapter_view._on_choice_pressed(0)   # ask after the caravan master, spending the last slot
	chapter_view._on_choice_pressed(0)   # back to the hub

	# Spent: only the exit remains.
	var choices: Array = chapter_view.dialogue_engine.available_choices()
	assert_eq(choices.size(), 1)
	assert_eq(choices[0]["next_id"], "out")

	# And the one there was never time for is recorded as declined, while the two that
	# were taken are not.
	var flags: Dictionary = chapter_view.dialogue_engine.flags
	assert_true(flags.get("never_sat_with_scribe", false), "the scribe was never visited")
	assert_false(flags.get("never_visited_widow", false), "the widow was visited")
	assert_false(flags.get("never_asked_caravan", false), "the caravan master was asked")

func test_the_declined_opportunity_survives_a_save_and_reload():
	# The point of recording a declined opportunity is that a later chapter can read
	# it, which means it has to outlive the stay it happened in.
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter_by_id("fixture_chapter_stay", "res://tests/fixtures/manifest_fixture.json")
	chapter_view._on_choice_pressed(0)   # widow
	chapter_view._on_choice_pressed(0)   # back
	chapter_view._on_choice_pressed(0)   # caravan, exhausting the stay
	chapter_view._on_choice_pressed(0)   # back

	var state := GameState.new()
	state.dialogue_flags = chapter_view.dialogue_engine.flags
	state.slot_index = chapter_view.dialogue_engine.slot_index
	var restored := GameState.from_dict(state.to_dict())
	assert_true(restored.dialogue_flags.get("never_sat_with_scribe", false))
	assert_eq(restored.slot_index, 2)

# The returning-player path: MainMenu's Continue -> Main._ready() -> resume().
# Nothing covered it end to end, which is how the slot_index leak below survived.

func test_the_chapter_pointer_does_not_carry_the_finished_chapters_spent_slots():
	# The pointer says "start here next". It is written at the end of a chapter with
	# that chapter's state, and chapter_id overridden to the next one - so anything
	# in-chapter it carries is wrong by construction. slot_index is in-chapter: left
	# alone, a stay would begin with its time already spent as soon as two chapters
	# in a row declare one.
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	var state := GameState.new()
	state.slot_index = 2
	chapter_view._write_current_chapter_pointer("chapter_08_nishapur", state)

	var pointer_path := "user://borrowed_fortune_current_chapter.json"
	assert_true(FileAccess.file_exists(pointer_path), "the pointer should have been written")
	var file := FileAccess.open(pointer_path, FileAccess.READ)
	var pointer = JSON.parse_string(file.get_as_text())
	file.close()

	assert_eq(str(pointer["chapter_id"]), "chapter_08_nishapur", "sanity: it points at the next chapter")
	assert_eq(int(pointer.get("slot_index", 0)), 0,
		"the next chapter must begin with its stay unspent, not with this one's index")

func test_resume_restores_coin_debt_reputation_and_flags_from_a_real_save():
	# Drives the whole returning-player path: a GameState written by SaveManager,
	# read back, and handed to resume() the way Main._ready() hands it over.
	var written := GameState.new()
	written.chapter_id = "chapter_07b_merv"
	written.dialogue_flags = {"carries_the_commanders_token": true, "spoke_now": true}
	written.reputation_data = {"trading_families": 3, "ghaznavid_officials": -1}
	written.ledger_data = {"spent_dirham_equivalent": 40.0}
	written.slot_index = 1

	var save_path := "user://borrowed_fortune_test_resume_roundtrip.json"
	var manager := SaveManager.new()
	assert_eq(manager.save(written, save_path), OK)
	var restored := manager.load(save_path)
	assert_not_null(restored, "the save must read back")

	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.resume(restored.chapter_id, restored.to_dict())

	assert_eq(chapter_view.chapter_id, "chapter_07b_merv", "resumed into the saved chapter")
	assert_true(chapter_view.dialogue_engine.flags.get("carries_the_commanders_token", false),
		"flags must survive, or Merv's token-gated errand silently disappears")
	assert_eq(chapter_view.reputation_tracker.get_reputation("trading_families"), 3)
	assert_eq(chapter_view.reputation_tracker.get_reputation("ghaznavid_officials"), -1)
	assert_almost_eq(chapter_view.ledger.total_wealth_dirham_equivalent(), -40.0, 0.0001)

	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))

func test_resume_starts_the_chapter_at_its_first_node():
	# Chapter-granular saving is the design - the pointer is written at a chapter
	# boundary - so resuming lands at the start of the named chapter, not mid-scene.
	# Pinned because GameState still carries a dialogue_node_id that nothing reads.
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.resume("chapter_07b_merv", {"dialogue_node_id": "n06d_the_last_stretch"})
	assert_eq(chapter_view.dialogue_engine.current_node()["id"], "n01_merv_arrival",
		"resume is chapter-granular; the saved node id is not honoured")

func test_resume_into_a_chapter_with_a_stay_begins_with_its_time_unspent():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.resume("chapter_07b_merv", {"slot_index": 2})
	assert_eq(chapter_view.dialogue_engine.slots.size(), 2, "Merv declares two slots")
	assert_false(chapter_view.dialogue_engine.slots_spent(),
		"arriving in a city must not find its days already gone")
