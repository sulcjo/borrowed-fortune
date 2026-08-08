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
