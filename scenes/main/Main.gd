extends Control

@onready var chapter_view = $ChapterView

func _ready() -> void:
	chapter_view.load_chapter_by_id("chapter_00_prologue")
