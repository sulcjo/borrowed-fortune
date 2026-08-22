extends Control

const TextureLoaderScript := preload("res://engine/assets/TextureLoader.gd")
# By path rather than by class_name: the global class cache lives in the gitignored
# .godot directory, so a fresh checkout has no DialogueEngine registered yet and a
# bare reference here fails to parse before the editor has ever run.
const DialogueEngineScript := preload("res://engine/dialogue/DialogueEngine.gd")
const GameStateScript := preload("res://engine/save/GameState.gd")

const WORDS_PER_MINUTE := 180.0
const MINIMUM_PANEL_SECONDS := 4.0
const MAXIMUM_PANEL_SECONDS := 12.0
const FADE_DURATION_SECONDS := 0.6

# Where the caption sits when it is the whole panel. The authored strip is at the
# bottom of the frame because it normally has an image above it to caption; with
# nothing above it, text down there reads as a subtitle to a missing picture.
const IMAGELESS_CAPTION_ANCHOR_TOP := 0.38
const IMAGELESS_CAPTION_ANCHOR_BOTTOM := 0.62

@export var content_path: String = ""
@export var next_scene_path: String = ""
# Which chapter's save supplies the flags that gate this cutscene's panels. Empty for
# a cutscene that plays the same way every time, such as the prologue.
#
# It has to be named rather than passed. change_scene_to_file tears down the scene that
# launched this one, and the current-chapter pointer - the other obvious channel - is
# deleted precisely when a chapter ends with no successor, which is every case that
# reaches an outro. What does survive is the per-chapter save, written by
# ChapterView._save_and_finish just before it changes scene.
@export var flags_chapter_id: String = ""

@onready var panel_image: TextureRect = $PanelImage
@onready var caption_bar: ColorRect = $CaptionBar
@onready var caption_label: RichTextLabel = $CaptionBar/CaptionLabel
@onready var skip_button: Button = $SkipButton

var panels: Array = []
var flags: Dictionary = {}
var current_index := 0
var _advance_timer: Timer
var _authored_caption_anchor_top := 0.0
var _authored_caption_anchor_bottom := 1.0
var _authored_caption_color := Color(0, 0, 0, 0)

func _ready() -> void:
	_authored_caption_anchor_top = caption_bar.anchor_top
	_authored_caption_anchor_bottom = caption_bar.anchor_bottom
	_authored_caption_color = caption_bar.color
	flags = load_flags(flags_chapter_id)
	panels = visible_panels(_load_panels(), flags)
	skip_button.pressed.connect(_on_skip_pressed)
	_advance_timer = Timer.new()
	_advance_timer.one_shot = true
	_advance_timer.timeout.connect(_advance)
	add_child(_advance_timer)
	if panels.is_empty():
		# Skip is already connected, so the player can still leave. Loud because the
		# only way to get here is a content fault: either the file is missing, or every
		# panel is gated and none of the conditions held.
		push_error("Cutscene: no panels to show from '%s' (flags: %s)" % [content_path, flags])
		return
	_show_panel(0)

func _load_panels() -> Array:
	if not FileAccess.file_exists(content_path):
		return []
	var file := FileAccess.open(content_path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if not data is Array:
		return []
	return data

# Panels use the same requires_flag / forbids_flag vocabulary as dialogue choices and
# text variants, via the same implementation - see DialogueEngine.flag_conditions_met.
# Gating whole panels rather than swapping captions is deliberate: where a chapter ends
# in two differently-written terminal nodes, a swapped line only restates a difference
# the player has already read, while a divergent sequence is the only thing the ending
# can still say that the chapter did not.
static func visible_panels(all_panels: Array, flag_state: Dictionary) -> Array:
	var result: Array = []
	for panel in all_panels:
		if DialogueEngineScript.flag_conditions_met(panel, flag_state):
			result.append(panel)
	return result

# Reads the flags a finished chapter left on disk. Every failure returns {} rather than
# erroring: a cutscene whose save is missing should play its unconditional panels, not
# refuse to play.
static func load_flags(chapter_id: String) -> Dictionary:
	if chapter_id.is_empty():
		return {}
	var path := GameStateScript.save_path_for(chapter_id)
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if not data is Dictionary:
		return {}
	var stored = data.get("dialogue_flags", {})
	if not stored is Dictionary:
		return {}
	return stored

static func compute_panel_duration_seconds(caption: String) -> float:
	var word_count := caption.split(" ", false).size()
	var estimated := (word_count / WORDS_PER_MINUTE) * 60.0
	return clamp(estimated, MINIMUM_PANEL_SECONDS, MAXIMUM_PANEL_SECONDS)

func _show_panel(index: int) -> void:
	current_index = index
	_display_panel_data(panels[index])

func _display_panel_data(panel: Dictionary) -> void:
	# Whether the panel declares an image, not whether the image loaded. A declared
	# path that fails to load is a broken asset and should look broken; an absent key
	# is an authored caption-only panel and should look composed.
	var declares_image: bool = panel.has("image_path")
	if declares_image:
		panel_image.texture = TextureLoaderScript.load_texture(panel["image_path"])
	else:
		panel_image.texture = null
	_place_caption(declares_image)
	caption_label.text = "[center]%s[/center]" % panel["caption"]
	_advance_timer.start(compute_panel_duration_seconds(panel["caption"]))

func _place_caption(declares_image: bool) -> void:
	if declares_image:
		caption_bar.anchor_top = _authored_caption_anchor_top
		caption_bar.anchor_bottom = _authored_caption_anchor_bottom
		caption_bar.color = _authored_caption_color
		return
	caption_bar.anchor_top = IMAGELESS_CAPTION_ANCHOR_TOP
	caption_bar.anchor_bottom = IMAGELESS_CAPTION_ANCHOR_BOTTOM
	# The scrim exists to lift text off a picture. With no picture it is a darker
	# rectangle on black, which only draws a box around the words.
	caption_bar.color = Color(0, 0, 0, 0)

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
