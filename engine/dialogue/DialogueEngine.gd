extends RefCounted
class_name DialogueEngine

var current_node_id: String = ""
var flags: Dictionary = {}
var reputation: Dictionary = {}
var _nodes_by_id: Dictionary = {}

func load_tree(nodes: Array, start_id: String) -> void:
	var errors := validate_tree(nodes)
	assert(errors.is_empty(), "DialogueEngine: invalid node graph — " + ", ".join(errors))
	_nodes_by_id.clear()
	for node in nodes:
		_nodes_by_id[node["id"]] = node
	current_node_id = start_id

func validate_tree(nodes: Array) -> Array:
	var errors: Array = []
	var seen_ids: Dictionary = {}
	var known_ids: Dictionary = {}
	for node in nodes:
		known_ids[node["id"]] = true
	for node in nodes:
		var node_id: String = node["id"]
		if seen_ids.has(node_id):
			errors.append("duplicate node id '%s'" % node_id)
		seen_ids[node_id] = true
		var residual_bbcode := GlossedTextParser.parse_to_bbcode(node.get("text", ""))
		if residual_bbcode.contains("{{"):
			errors.append("node '%s' has an unparsed gloss token (check for a space after a comma in a multi-id token, or a malformed {{...}})" % node_id)
		for choice in node.get("choices", []):
			var next_id = choice.get("next_id")
			if next_id != null and not known_ids.has(next_id):
				errors.append("node '%s' has a choice with dangling next_id '%s'" % [node_id, next_id])
	return errors

func current_node() -> Dictionary:
	return _nodes_by_id.get(current_node_id, {})

func available_choices() -> Array:
	var result: Array = []
	for choice in current_node().get("choices", []):
		if _choice_is_available(choice):
			result.append(choice)
	return result

func choose(choice_index: int) -> Dictionary:
	var choices := available_choices()
	if choice_index < 0 or choice_index >= choices.size():
		return {}
	var choice: Dictionary = choices[choice_index]
	var effects: Dictionary = choice.get("effects", {})
	for flag_name in effects.get("flags", []):
		flags[flag_name] = true
	current_node_id = choice["next_id"]
	return effects

func is_chapter_end() -> bool:
	return available_choices().is_empty()

func _choice_is_available(choice: Dictionary) -> bool:
	var requires_flag = choice.get("requires_flag", null)
	if requires_flag != null and not flags.get(requires_flag, false):
		return false
	var requires_reputation = choice.get("requires_reputation", null)
	if requires_reputation != null:
		var faction_id: String = requires_reputation["faction_id"]
		var min_score: int = int(requires_reputation["min_score"])
		if reputation.get(faction_id, 0) < min_score:
			return false
	return true
