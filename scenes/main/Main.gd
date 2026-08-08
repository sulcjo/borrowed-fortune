extends Control

@onready var chapter_view = $ChapterView

func _ready() -> void:
	chapter_view.load_chapter(
		"res://content/chapters/chapter_00_prologue/prologue.json",
		"res://content/glossary/prologue_terms.json"
	)
