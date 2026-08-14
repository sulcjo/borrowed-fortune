extends Control

const WORDS_PER_MINUTE := 180.0
const MINIMUM_PANEL_SECONDS := 4.0
const MAXIMUM_PANEL_SECONDS := 12.0
const FADE_DURATION_SECONDS := 0.6

@export var content_path: String = ""
@export var next_scene_path: String = ""

@onready var panel_image: TextureRect = $PanelImage
@onready var caption_label: RichTextLabel = $CaptionBar/CaptionLabel
@onready var skip_button: Button = $SkipButton

var panels: Array = []
var current_index := 0
var _advance_timer: Timer

func _ready() -> void:
	panels = _load_panels()
	skip_button.pressed.connect(_on_skip_pressed)
	_advance_timer = Timer.new()
	_advance_timer.one_shot = true
	_advance_timer.timeout.connect(_advance)
	add_child(_advance_timer)
	if panels.is_empty():
		return
	_show_panel(0)

func _load_panels() -> Array:
	if not FileAccess.file_exists(content_path):
		return []
	var file := FileAccess.open(content_path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	return data

static func compute_panel_duration_seconds(caption: String) -> float:
	var word_count := caption.split(" ", false).size()
	var estimated := (word_count / WORDS_PER_MINUTE) * 60.0
	return clamp(estimated, MINIMUM_PANEL_SECONDS, MAXIMUM_PANEL_SECONDS)

func _show_panel(index: int) -> void:
	current_index = index
	_display_panel_data(panels[index])

func _display_panel_data(panel: Dictionary) -> void:
	var image := Image.load_from_file(panel["image_path"])
	if image == null:
		panel_image.texture = null
	else:
		panel_image.texture = ImageTexture.create_from_image(image)
	caption_label.text = "[center]%s[/center]" % panel["caption"]
	_advance_timer.start(compute_panel_duration_seconds(panel["caption"]))

func _advance() -> void:
	if current_index + 1 >= panels.size():
		_finish()
		return
	_fade_to_panel(current_index + 1)

func _fade_to_panel(index: int) -> void:
	var tween := create_tween()
	tween.tween_property(panel_image, "modulate:a", 0.0, FADE_DURATION_SECONDS)
	tween.tween_callback(_show_panel.bind(index))
	tween.tween_property(panel_image, "modulate:a", 1.0, FADE_DURATION_SECONDS)

func _on_skip_pressed() -> void:
	_finish()

func _finish() -> void:
	get_tree().change_scene_to_file(next_scene_path)
