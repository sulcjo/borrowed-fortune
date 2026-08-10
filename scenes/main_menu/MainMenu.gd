extends Control

const POINTER_PATH := "user://borrowed_fortune_current_chapter.json"

@onready var background: TextureRect = $Background
@onready var continue_button: Button = $ButtonsContainer/ContinueButton
@onready var new_game_button: Button = $ButtonsContainer/NewGameButton
@onready var quit_button: Button = $ButtonsContainer/QuitButton

func _ready() -> void:
	_update_background()
	continue_button.disabled = not FileAccess.file_exists(POINTER_PATH)
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _update_background() -> void:
	var path := "res://assets/backgrounds/main_menu.png"
	if not FileAccess.file_exists(path):
		background.texture = null
		return
	var image := Image.load_from_file(path)
	if image == null:
		background.texture = null
		return
	background.texture = ImageTexture.create_from_image(image)

func _on_new_game_pressed() -> void:
	if FileAccess.file_exists(POINTER_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(POINTER_PATH))
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")

func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
