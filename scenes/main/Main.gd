extends Control

@onready var chapter_view = $ChapterView
const POINTER_PATH := "user://borrowed_fortune_current_chapter.json"

func _ready() -> void:
	chapter_view.resume(_resolve_starting_chapter_id(), _read_pointer_file())

func _resolve_starting_chapter_id() -> String:
	var pointer := _read_pointer_file()
	if not pointer.has("chapter_id"):
		return "chapter_00_prologue"
	return pointer["chapter_id"]

func _read_pointer_file() -> Dictionary:
	if not FileAccess.file_exists(POINTER_PATH):
		return {}
	var file := FileAccess.open(POINTER_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed == null or not (parsed is Dictionary):
		return {}
	return parsed
