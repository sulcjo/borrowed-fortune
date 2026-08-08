extends RefCounted
class_name MarginGlossary

var _entries: Dictionary = {}
var _unlocked: Dictionary = {}

func load_entries(entries: Dictionary) -> void:
	for term_id in entries:
		_entries[term_id] = entries[term_id]

func has_entry(term_id: String) -> bool:
	return _entries.has(term_id)

func get_entry(term_id: String) -> Dictionary:
	return _entries.get(term_id, {})

func unlock(term_id: String) -> void:
	if has_entry(term_id):
		_unlocked[term_id] = true

func is_unlocked(term_id: String) -> bool:
	return _unlocked.get(term_id, false)

func unlocked_term_ids() -> Array:
	return _unlocked.keys()
