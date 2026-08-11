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

static func build() -> Theme:
	var theme := Theme.new()
	theme.default_font = _load_font(REGULAR_FONT_PATH)

	_apply_global_button_style(theme)
	_apply_banner_button_variation(theme)
	_apply_banner_title_variation(theme)

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
