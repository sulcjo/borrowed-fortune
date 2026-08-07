extends RefCounted
class_name GameState

var chapter_id: String = ""
var dialogue_node_id: String = ""
var dialogue_flags: Dictionary = {}
var reputation_data: Dictionary = {}
var unlocked_glossary_terms: Array = []
var ledger_data: Dictionary = {}

func to_dict() -> Dictionary:
	return {
		"chapter_id": chapter_id,
		"dialogue_node_id": dialogue_node_id,
		"dialogue_flags": dialogue_flags,
		"reputation_data": reputation_data,
		"unlocked_glossary_terms": unlocked_glossary_terms,
		"ledger_data": ledger_data,
	}

static func from_dict(data: Dictionary) -> GameState:
	var state := GameState.new()
	state.chapter_id = data.get("chapter_id", "")
	state.dialogue_node_id = data.get("dialogue_node_id", "")
	state.dialogue_flags = data.get("dialogue_flags", {})
	state.reputation_data = data.get("reputation_data", {})
	state.unlocked_glossary_terms = data.get("unlocked_glossary_terms", [])
	state.ledger_data = data.get("ledger_data", {})
	return state
