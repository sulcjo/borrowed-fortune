extends RefCounted
class_name BorrowedFortuneTheme

const REGULAR_FONT_PATH := "res://assets/fonts/EBGaramond-Regular.ttf"
const BOLD_FONT_PATH := "res://assets/fonts/EBGaramond-Bold.ttf"

const BUTTON_FILL_NORMAL := Color("#3d2a15")
const BUTTON_FILL_HOVER := Color("#4a3520")
const BUTTON_FILL_PRESSED := Color("#2e2013")
const BUTTON_FILL_DISABLED := Color(60.0 / 255.0, 48.0 / 255.0, 32.0 / 255.0, 0.5)
const BUTTON_BORDER := Color("#7a5a32")
const BUTTON_BORDER_DISABLED := Color(122.0 / 255.0, 90.0 / 255.0, 50.0 / 255.0, 0.25)
const BUTTON_TEXT := Color("#f0e6cc")
const BUTTON_TEXT_DISABLED := Color(240.0 / 255.0, 230.0 / 255.0, 204.0 / 255.0, 0.35)
const FOCUS_RING := Color("#6b7f8a")

const BANNER_TEXT := Color("#f2e2c0")
const BANNER_TEXT_DISABLED := Color(0.949, 0.886, 0.753, 0.32)

const GOLD := Color("#c9a24b")
const PARCHMENT_FILL := Color("#e3d5aa")
const INK_TEXT := Color("#241a10")
const SCROLLBAR_TRACK := Color(0.353, 0.255, 0.118, 0.15)
const SCROLLBAR_GRABBER_HIGHLIGHT := Color("#d9b25e")
const SCROLLBAR_GRABBER_PRESSED := Color("#a8823a")

# Rubrication - the red a scribe reserved for headings and marked passages. Used
# for the choice lines and for marking glossed terms in the narration.
const RUBRIC_RED := Color("#7a1f14")
# The lighter hand of a later annotator, for the colophon and the margin notes.
const MUTED_INK := Color("#6b5a44")

static func build() -> Theme:
	var theme := Theme.new()
	theme.default_font = _load_font(REGULAR_FONT_PATH)

	_apply_global_button_style(theme)
	_apply_banner_button_variation(theme)
	_apply_banner_title_variation(theme)
	_apply_panel_style(theme)
	_apply_folio_variation(theme)
	_apply_roundel_variation(theme)
	_apply_marginalia_variations(theme)
	_apply_rubric_variation(theme)
	_apply_richtextlabel_defaults(theme)
	_apply_scrollbar_style(theme)

	return theme

static func _apply_global_button_style(theme: Theme) -> void:
	theme.set_stylebox("normal", "Button", _boxed_stylebox(BUTTON_FILL_NORMAL, BUTTON_BORDER))
	theme.set_stylebox("hover", "Button", _boxed_stylebox(BUTTON_FILL_HOVER, BUTTON_BORDER))
	theme.set_stylebox("pressed", "Button", _boxed_stylebox(BUTTON_FILL_PRESSED, BUTTON_BORDER))
	theme.set_stylebox("disabled", "Button", _boxed_stylebox(BUTTON_FILL_DISABLED, BUTTON_BORDER_DISABLED))
	theme.set_stylebox("focus", "Button", _focus_stylebox())

	theme.set_color("font_color", "Button", BUTTON_TEXT)
	theme.set_color("font_hover_color", "Button", BUTTON_TEXT)
	theme.set_color("font_pressed_color", "Button", BUTTON_TEXT)
	theme.set_color("font_focus_color", "Button", BUTTON_TEXT)
	theme.set_color("font_disabled_color", "Button", BUTTON_TEXT_DISABLED)
	theme.set_font_size("font_size", "Button", 18)

static func _apply_banner_button_variation(theme: Theme) -> void:
	theme.set_type_variation("BannerButton", "Button")
	theme.set_stylebox("normal", "BannerButton", StyleBoxEmpty.new())
	theme.set_stylebox("hover", "BannerButton", StyleBoxEmpty.new())
	theme.set_stylebox("pressed", "BannerButton", StyleBoxEmpty.new())
	theme.set_stylebox("disabled", "BannerButton", StyleBoxEmpty.new())
	theme.set_stylebox("focus", "BannerButton", _focus_stylebox())

	theme.set_color("font_color", "BannerButton", BANNER_TEXT)
	theme.set_color("font_hover_color", "BannerButton", BANNER_TEXT)
	theme.set_color("font_pressed_color", "BannerButton", BANNER_TEXT)
	theme.set_color("font_focus_color", "BannerButton", BANNER_TEXT)
	theme.set_color("font_disabled_color", "BannerButton", BANNER_TEXT_DISABLED)
	theme.set_font_size("font_size", "BannerButton", 20)

static func _apply_banner_title_variation(theme: Theme) -> void:
	theme.set_type_variation("BannerTitle", "Label")
	theme.set_font("font", "BannerTitle", _load_font(BOLD_FONT_PATH))
	theme.set_font_size("font_size", "BannerTitle", 36)
	theme.set_color("font_color", "BannerTitle", BANNER_TEXT)
	theme.set_color("font_shadow_color", "BannerTitle", Color(0, 0, 0, 0.4))
	theme.set_constant("shadow_offset_x", "BannerTitle", 2)
	theme.set_constant("shadow_offset_y", "BannerTitle", 2)

static func _apply_panel_style(theme: Theme) -> void:
	theme.set_stylebox("panel", "Panel", _framed_panel_stylebox(4))

	theme.set_type_variation("DialogueParchment", "Panel")
	theme.set_stylebox("panel", "DialogueParchment", _dialogue_parchment_stylebox())

	theme.set_type_variation("PortraitCard", "Panel")
	theme.set_stylebox("panel", "PortraitCard", _boxed_stylebox(BUTTON_FILL_NORMAL, GOLD))

static func _apply_folio_variation(theme: Theme) -> void:
	theme.set_type_variation("Folio", "Panel")
	var box := StyleBoxFlat.new()
	box.bg_color = PARCHMENT_FILL
	box.border_color = GOLD
	box.set_border_width_all(1)
	theme.set_stylebox("panel", "Folio", box)

static func _apply_roundel_variation(theme: Theme) -> void:
	theme.set_type_variation("Roundel", "Panel")
	var box := StyleBoxFlat.new()
	box.bg_color = BUTTON_FILL_NORMAL
	box.border_color = GOLD
	box.set_border_width_all(1)
	# Godot clamps the radius to half the shorter side, so an oversized value makes
	# any roundel we draw read as a circle regardless of its size.
	box.set_corner_radius_all(256)
	theme.set_stylebox("panel", "Roundel", box)

static func _apply_marginalia_variations(theme: Theme) -> void:
	theme.set_type_variation("Colophon", "Label")
	theme.set_color("font_color", "Colophon", MUTED_INK)
	theme.set_font_size("font_size", "Colophon", 14)

	theme.set_type_variation("GlossNote", "Label")
	theme.set_color("font_color", "GlossNote", MUTED_INK)
	theme.set_font_size("font_size", "GlossNote", 13)

static func _apply_rubric_variation(theme: Theme) -> void:
	theme.set_type_variation("Rubric", "Button")

	var written := StyleBoxFlat.new()
	written.draw_center = false
	written.border_color = GOLD
	written.border_width_left = 2
	written.content_margin_left = 8
	written.content_margin_top = 2
	written.content_margin_bottom = 2

	var marked := written.duplicate()
	marked.draw_center = true
	marked.bg_color = Color(GOLD.r, GOLD.g, GOLD.b, 0.12)

	theme.set_stylebox("normal", "Rubric", written)
	theme.set_stylebox("hover", "Rubric", marked)
	theme.set_stylebox("pressed", "Rubric", marked)
	theme.set_stylebox("disabled", "Rubric", written)
	theme.set_stylebox("focus", "Rubric", _focus_stylebox())

	theme.set_color("font_color", "Rubric", RUBRIC_RED)
	theme.set_color("font_hover_color", "Rubric", RUBRIC_RED)
	theme.set_color("font_pressed_color", "Rubric", RUBRIC_RED)
	theme.set_color("font_focus_color", "Rubric", RUBRIC_RED)
	theme.set_font_size("font_size", "Rubric", 20)

static func _framed_panel_stylebox(corner_radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = PARCHMENT_FILL
	box.border_color = GOLD
	box.set_border_width_all(3)
	box.set_corner_radius_all(corner_radius)
	return box

static func _dialogue_parchment_stylebox() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = PARCHMENT_FILL
	box.border_color = GOLD
	box.border_width_top = 3
	return box

static func _apply_richtextlabel_defaults(theme: Theme) -> void:
	theme.set_color("default_color", "RichTextLabel", INK_TEXT)
	theme.set_font_size("normal_font_size", "RichTextLabel", 22)

static func _apply_scrollbar_style(theme: Theme) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = SCROLLBAR_TRACK
	track.set_corner_radius_all(2)

	var grabber := StyleBoxFlat.new()
	grabber.bg_color = GOLD
	grabber.set_corner_radius_all(2)

	var grabber_highlight := StyleBoxFlat.new()
	grabber_highlight.bg_color = SCROLLBAR_GRABBER_HIGHLIGHT
	grabber_highlight.set_corner_radius_all(2)

	var grabber_pressed := StyleBoxFlat.new()
	grabber_pressed.bg_color = SCROLLBAR_GRABBER_PRESSED
	grabber_pressed.set_corner_radius_all(2)

	theme.set_stylebox("scroll", "VScrollBar", track)
	theme.set_stylebox("scroll_focus", "VScrollBar", track)
	theme.set_stylebox("grabber", "VScrollBar", grabber)
	theme.set_stylebox("grabber_highlight", "VScrollBar", grabber_highlight)
	theme.set_stylebox("grabber_pressed", "VScrollBar", grabber_pressed)

static func _load_font(path: String) -> FontFile:
	var font := FontFile.new()
	font.load_dynamic_font(path)
	return font

static func _boxed_stylebox(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(2)
	return box

static func _focus_stylebox() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.draw_center = false
	box.border_color = FOCUS_RING
	box.set_border_width_all(2)
	box.set_corner_radius_all(2)
	return box
