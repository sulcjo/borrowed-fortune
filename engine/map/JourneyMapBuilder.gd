extends RefCounted
class_name JourneyMapBuilder

func build_waypoints(route_data: Dictionary, visited_chapter_ids: Dictionary, current_chapter_id: String) -> Array:
	var display_names: Dictionary = route_data.get("display_names", {})
	var waypoints: Array = []

	for chapter_id in route_data.get("shared_prefix", []):
		waypoints.append(_make_waypoint(chapter_id, display_names, visited_chapter_ids, current_chapter_id, false))

	var fork: Dictionary = route_data.get("fork", {})
	var main_id: String = fork.get("main", "")
	var favor_id: String = fork.get("favor", "")

	if _is_reached(main_id, visited_chapter_ids, current_chapter_id):
		waypoints.append(_make_waypoint(main_id, display_names, visited_chapter_ids, current_chapter_id, false))
		_append_suffix(waypoints, route_data.get("main_suffix", []), display_names, visited_chapter_ids, current_chapter_id)
	elif _is_reached(favor_id, visited_chapter_ids, current_chapter_id):
		waypoints.append(_make_waypoint(favor_id, display_names, visited_chapter_ids, current_chapter_id, false))
		_append_suffix(waypoints, route_data.get("favor_suffix", []), display_names, visited_chapter_ids, current_chapter_id)

	return waypoints

func all_chapter_ids(route_data: Dictionary) -> Array:
	var ids: Array = []
	for chapter_id in route_data.get("shared_prefix", []):
		ids.append(chapter_id)
	var fork: Dictionary = route_data.get("fork", {})
	if fork.has("main"):
		ids.append(fork["main"])
	if fork.has("favor"):
		ids.append(fork["favor"])
	for entry in route_data.get("main_suffix", []):
		ids.append(_entry_chapter_id(entry))
	for entry in route_data.get("favor_suffix", []):
		ids.append(_entry_chapter_id(entry))
	return ids

func _entry_chapter_id(entry) -> String:
	if entry is Dictionary:
		return entry["chapter_id"]
	return entry

func _append_suffix(waypoints: Array, suffix: Array, display_names: Dictionary, visited_chapter_ids: Dictionary, current_chapter_id: String) -> void:
	var last_index := suffix.size() - 1
	for i in range(suffix.size()):
		var entry = suffix[i]
		var chapter_id := _entry_chapter_id(entry)
		var is_optional: bool = entry is Dictionary and entry.get("optional", false)
		var is_ending := i == last_index
		if is_optional and not _is_reached(chapter_id, visited_chapter_ids, current_chapter_id):
			continue
		waypoints.append(_make_waypoint(chapter_id, display_names, visited_chapter_ids, current_chapter_id, is_ending))

func _is_reached(chapter_id: String, visited_chapter_ids: Dictionary, current_chapter_id: String) -> bool:
	if chapter_id == "":
		return false
	return chapter_id == current_chapter_id or visited_chapter_ids.has(chapter_id)

func _make_waypoint(chapter_id: String, display_names: Dictionary, visited_chapter_ids: Dictionary, current_chapter_id: String, is_ending: bool) -> Dictionary:
	var status: String
	if chapter_id == current_chapter_id:
		status = "current"
	elif visited_chapter_ids.has(chapter_id):
		status = "visited"
	else:
		status = "unvisited"
	return {
		"chapter_id": chapter_id,
		"display_name": display_names.get(chapter_id, chapter_id),
		"status": status,
		"is_ending": is_ending,
	}
