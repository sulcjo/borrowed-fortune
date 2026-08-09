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
	for path in [teginabad_save_path, bost_save_path, farah_save_path]:
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

	assert_eq(chapter_view.chapter_id, "chapter_03_farah")
	assert_eq(chapter_view.dialogue_engine.current_node()["id"], "n18a_departure_farah_mystery")
	assert_eq(chapter_view.next_chapter_id, null, "Farah's mystery branch has no Chapter 4 yet")
	assert_true(chapter_view.dialogue_engine.flags.get("vowed_kafala", false), "the Prologue's kafala vow flag must survive into Farah")
	assert_true(chapter_view.dialogue_engine.flags.get("knows_the_second_marks_name", false))
	assert_almost_eq(chapter_view.ledger.total_wealth_dirham_equivalent(), -15.0, 0.0001)
	assert_true(FileAccess.file_exists(teginabad_save_path), "passing through Teginabad on the way to Farah must still write Teginabad's save file")
	assert_true(FileAccess.file_exists(bost_save_path), "passing through Bost on the way to Farah must still write Bost's save file")
	assert_true(FileAccess.file_exists(farah_save_path), "reaching Farah's mystery-branch ending must write its own save file")

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
	# always wins, silently, with no error. Farah's two terminal nodes are exactly
	# this shape today.
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

	assert_eq(chapter_view.chapter_id, "chapter_03_farah")
	assert_eq(chapter_view.dialogue_engine.current_node()["id"], "n19b_departure_farah_plunder")
	assert_eq(chapter_view.next_chapter_id, null, "Farah's plunder branch has no Chapter 4 yet")
	assert_true(chapter_view.dialogue_engine.flags.get("owes_tahir_a_favor", false))
	assert_true(chapter_view.dialogue_engine.flags.get("knows_the_second_marks_name", false))
	assert_almost_eq(chapter_view.ledger.total_wealth_dirham_equivalent(), -15.0, 0.0001)
	assert_true(FileAccess.file_exists("user://borrowed_fortune_chapter_03_farah.json"))

func test_reputation_changes_are_synced_into_the_dialogue_engine_before_rendering():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.reputation_tracker.adjust_reputation("trading_families", 3)
	chapter_view._render_current_node()
	assert_eq(chapter_view.dialogue_engine.reputation.get("trading_families", 0), 3)
