extends RefCounted
class_name DialogueEngine

var current_node_id: String = ""
var flags: Dictionary = {}
var _nodes_by_id: Dictionary = {}

func load_tree(nodes: Array, start_id: String) -> void:
	_nodes_by_id.clear()
	for node in nodes:
		_nodes_by_id[node["id"]] = node
	current_node_id = start_id

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
	if requires_flag == null:
		return true
	return flags.get(requires_flag, false)
