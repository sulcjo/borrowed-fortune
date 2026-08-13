extends Control

const POINTER_PATH := "user://borrowed_fortune_current_chapter.json"
const ROUTE_PATH := "res://content/map/route.json"
const BOLD_FONT_PATH := "res://assets/fonts/EBGaramond-Bold.ttf"

@onready var background: TextureRect = $Background
@onready var banner_texture: TextureRect = $BannerPanel/BannerTexture
@onready var continue_button: Button = $BannerPanel/ButtonsContainer/ContinueButton
@onready var new_game_button: Button = $BannerPanel/ButtonsContainer/NewGameButton
@onready var map_button: Button = $BannerPanel/ButtonsContainer/MapButton
@onready var quit_button: Button = $BannerPanel/ButtonsContainer/QuitButton

func _ready() -> void:
	_update_background()
	_update_banner()
	continue_button.disabled = not FileAccess.file_exists(POINTER_PATH)
	map_button.disabled = _map_button_should_be_disabled()
	_update_default_action_emphasis()
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	map_button.pressed.connect(_on_map_pressed)
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

func _update_banner() -> void:
	var path := "res://assets/ui/menu_banner_tall.png"
	if not FileAccess.file_exists(path):
		banner_texture.texture = null
		return
	var image := Image.load_from_file(path)
	if image == null:
		banner_texture.texture = null
		return
	banner_texture.texture = ImageTexture.create_from_image(image)

func _update_default_action_emphasis() -> void:
	if continue_button.disabled:
		new_game_button.add_theme_font_override("font", _bold_font())
		continue_button.remove_theme_font_override("font")
	else:
		continue_button.add_theme_font_override("font", _bold_font())
		new_game_button.remove_theme_font_override("font")

func _bold_font() -> FontFile:
	var font := FontFile.new()
	font.load_dynamic_font(BOLD_FONT_PATH)
	return font

func _map_button_should_be_disabled() -> bool:
	var route_data := _load_route_data()
	var builder := JourneyMapBuilder.new()
	for chapter_id in builder.all_chapter_ids(route_data):
		if FileAccess.file_exists("user://borrowed_fortune_%s.json" % chapter_id):
			return false
	return true

func _load_route_data() -> Dictionary:
	var file := FileAccess.open(ROUTE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed == null or not (parsed is Dictionary):
		return {}
	return parsed

func _on_new_game_pressed() -> void:
	if FileAccess.file_exists(POINTER_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(POINTER_PATH))
	get_tree().change_scene_to_file("res://scenes/prologue_cutscene/PrologueCutscene.tscn")

func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")

func _on_map_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/journey_map/JourneyMapScreen.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
