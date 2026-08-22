extends RefCounted
class_name GameState

var chapter_id: String = ""
# Written on every save and deliberately not read back. Resuming is chapter-granular
# - Continue starts at the chapter's first node - so honouring this would drop the
# player mid-scene with a chapter's state only partly rebuilt. Kept rather than
# removed because it is correct data: a future mid-chapter resume needs exactly this,
# and deleting it now would mean two save-format changes instead of none.
var dialogue_node_id: String = ""
var dialogue_flags: Dictionary = {}
var reputation_data: Dictionary = {}
var unlocked_glossary_terms: Array = []
var ledger_data: Dictionary = {}
# Which slot of the current chapter's stay the player is in. Zero for a chapter that
# declares no stay, and for any save written before stays existed.
var slot_index: int = 0

func to_dict() -> Dictionary:
	return {
		"chapter_id": chapter_id,
		"dialogue_node_id": dialogue_node_id,
		"dialogue_flags": dialogue_flags,
		"reputation_data": reputation_data,
		"unlocked_glossary_terms": unlocked_glossary_terms,
		"ledger_data": ledger_data,
		"slot_index": slot_index,
	}

static func from_dict(data: Dictionary) -> GameState:
	var state := GameState.new()
	state.chapter_id = data.get("chapter_id", "")
	state.dialogue_node_id = data.get("dialogue_node_id", "")
	state.dialogue_flags = data.get("dialogue_flags", {})
	state.reputation_data = data.get("reputation_data", {})
	state.unlocked_glossary_terms = data.get("unlocked_glossary_terms", [])
	state.ledger_data = data.get("ledger_data", {})
	# int() for the same reason farrukh_wear_stage casts: JSON parses numbers as float.
	state.slot_index = int(data.get("slot_index", 0))
	return state
