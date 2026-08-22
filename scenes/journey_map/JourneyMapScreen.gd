extends Control

const TextureLoaderScript := preload("res://engine/assets/TextureLoader.gd")

const ROUTE_PATH := "res://content/map/route.json"
const POINTER_PATH := "user://borrowed_fortune_current_chapter.json"

@onready var background: TextureRect = $Background
@onready var banner_texture: TextureRect = $TitleBannerPanel/BannerTexture
@onready var waypoints_container: HBoxContainer = $WaypointsContainer
@onready var back_button: Button = $BackButton

func _ready() -> void:
	_update_background()
	_update_banner()
	back_button.pressed.connect(_on_back_pressed)
	_render_waypoints()

func _update_background() -> void:
	background.texture = TextureLoaderScript.load_texture("res://assets/backgrounds/journey_map.png")

func _update_banner() -> void:
	banner_texture.texture = TextureLoaderScript.load_texture("res://assets/ui/menu_banner_short.png")

func _render_waypoints() -> void:
	var route_data := _load_route_data()
	var builder := JourneyMapBuilder.new()
	var visited_chapter_ids := _scan_visited_chapter_ids(route_data, builder)
	var current_chapter_id := _read_current_chapter_id()
	var waypoints := builder.build_waypoints(route_data, visited_chapter_ids, current_chapter_id)

	for child in waypoints_container.get_children():
		child.queue_free()
	for waypoint in waypoints:
		waypoints_container.add_child(_build_waypoint_node(waypoint))

func _load_route_data() -> Dictionary:
	var file := FileAccess.open(ROUTE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed == null or not (parsed is Dictionary):
		return {}
	return parsed

func _scan_visited_chapter_ids(route_data: Dictionary, builder: JourneyMapBuilder) -> Dictionary:
	var visited: Dictionary = {}
	for chapter_id in builder.all_chapter_ids(route_data):
		if FileAccess.file_exists("user://borrowed_fortune_%s.json" % chapter_id):
			visited[chapter_id] = true
	return visited

func _read_current_chapter_id() -> String:
	if not FileAccess.file_exists(POINTER_PATH):
		return ""
	var file := FileAccess.open(POINTER_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed == null or not (parsed is Dictionary) or not parsed.has("chapter_id"):
		return ""
	return parsed["chapter_id"]

func _build_waypoint_node(waypoint: Dictionary) -> Control:
	var container := VBoxContainer.new()
	container.name = waypoint["chapter_id"]

	var texture_rect := TextureRect.new()
	texture_rect.name = "Thumbnail"
	texture_rect.custom_minimum_size = Vector2(112, 63)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_rect.texture = _load_thumbnail(waypoint["chapter_id"])
	if waypoint["status"] == "unvisited":
		texture_rect.modulate = Color(0.5, 0.5, 0.5, 0.55)
	container.add_child(texture_rect)

	var label := Label.new()
	label.name = "Label"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if waypoint["is_ending"] and waypoint["status"] != "unvisited":
		label.text = "Journey's End"
	elif waypoint["status"] == "current":
		label.text = "▶ %s" % waypoint["display_name"]
	else:
		label.text = waypoint["display_name"]
	container.add_child(label)

	return container

func _load_thumbnail(chapter_id: String) -> Texture2D:
	return TextureLoaderScript.load_texture("res://assets/backgrounds/%s.png" % chapter_id)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")
