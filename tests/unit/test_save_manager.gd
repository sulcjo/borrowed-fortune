extends GutTest

func _sample_state() -> GameState:
	var state := GameState.new()
	state.chapter_id = "chapter_00_prologue"
	state.dialogue_node_id = "n4"
	state.dialogue_flags = {"spoke_now": true}
	state.reputation_data = {"trading_families": 2}
	state.unlocked_glossary_terms = ["khwaja", "ghusl"]
	state.ledger_data = {"purse": [], "debts": [{"creditor_name": "Nasuh", "amount_dirham_equivalent": 60.0, "is_guaranteed_by_kafala": true}]}
	return state

func test_game_state_to_dict_and_from_dict_round_trip():
	var original := _sample_state()
	var restored := GameState.from_dict(original.to_dict())
	assert_eq(restored.chapter_id, original.chapter_id)
	assert_eq(restored.dialogue_node_id, original.dialogue_node_id)
	assert_eq(restored.dialogue_flags, original.dialogue_flags)
	assert_eq(restored.reputation_data, original.reputation_data)
	assert_eq(restored.unlocked_glossary_terms, original.unlocked_glossary_terms)
	assert_eq(restored.ledger_data, original.ledger_data)

func test_from_dict_on_empty_dict_uses_safe_defaults():
	var state := GameState.from_dict({})
	assert_eq(state.chapter_id, "")
	assert_eq(state.dialogue_flags, {})
	assert_eq(state.unlocked_glossary_terms, [])

func test_save_then_load_round_trips_through_a_real_file():
	var manager := SaveManager.new()
	var path := "user://test_save_round_trip.json"
	var original := _sample_state()

	var save_error := manager.save(original, path)
	assert_eq(save_error, OK)

	var restored := manager.load(path)
	assert_not_null(restored)
	assert_eq(restored.chapter_id, original.chapter_id)
	assert_eq(restored.dialogue_node_id, original.dialogue_node_id)

	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func test_load_returns_null_when_file_does_not_exist():
	var manager := SaveManager.new()
	var restored := manager.load("user://this_file_does_not_exist_12345.json")
	assert_null(restored)

func test_slot_index_round_trips():
	var state := GameState.new()
	state.slot_index = 2
	var restored := GameState.from_dict(state.to_dict())
	assert_eq(restored.slot_index, 2)

func test_a_save_written_before_slots_existed_loads_at_the_first_slot():
	# Every field in from_dict() is read with a default, which is what makes this
	# backward-compatible - and this is the first change to the save format.
	var restored := GameState.from_dict({"chapter_id": "chapter_00_prologue"})
	assert_eq(restored.slot_index, 0)
