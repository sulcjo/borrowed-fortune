extends RefCounted
class_name SaveManager

func save(state: GameState, file_path: String) -> Error:
	var json_text := JSON.stringify(state.to_dict())
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(json_text)
	file.close()
	return OK

func load(file_path: String) -> GameState:
	if not FileAccess.file_exists(file_path):
		return null
	var file := FileAccess.open(file_path, FileAccess.READ)
	var json_text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(json_text)
	if parsed == null:
		return null
	return GameState.from_dict(parsed)
