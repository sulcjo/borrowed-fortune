extends RefCounted
class_name FolioMetrics

# Sizing arithmetic for the folio page. Pure logic with no scene-tree types, so it
# can be unit-tested without instantiating anything - font metrics arrive as
# parameters rather than being read off a live Font.

# The place art is pixel art at a fixed source size, so it may only be drawn at
# integer multiples. A fractional upscale makes the pixel grid shimmer unevenly.
const PLACE_BASE_WIDTH := 320
const PLACE_BASE_HEIGHT := 180

# Roughly 72 characters per line at normal_font_size = 22. Past this, a line of
# prose is tiring to track back from on a wide display.
const NARRATION_MAX_WIDTH := 720

# Roughly 36 characters per line - the narrowest column that still reads as prose
# rather than as a ragged strip. A scale that would leave less than this is
# rejected however well it fits by height.
const MIN_NARRATION_WIDTH := 360

# Beyond 3x the art starts dominating a page whose point is the prose.
const MAX_PLACE_SCALE := 3

static func narration_width(available_width: float) -> float:
	return clampf(available_width, 0.0, float(NARRATION_MAX_WIDTH))

# Picks the largest integer scale that leaves the prose both a readable measure and
# enough height for the whole node. Falls back to 1x, which is always drawn even if
# the text then has to scroll - dropping the art would leave a hole in the page.
static func choose_place_scale(
	character_count: int,
	available_width: float,
	available_height: float,
	gutter: float,
	char_width: float,
	line_height: float
) -> int:
	for scale in range(MAX_PLACE_SCALE, 1, -1):
		var inset_width := float(PLACE_BASE_WIDTH * scale)
		var prose_width := narration_width(available_width - inset_width - gutter)
		if prose_width < float(MIN_NARRATION_WIDTH):
			continue
		if _text_height(character_count, prose_width, char_width, line_height) <= available_height:
			return scale
	return 1

static func _text_height(
	character_count: int,
	prose_width: float,
	char_width: float,
	line_height: float
) -> float:
	var characters_per_line := maxf(1.0, floorf(prose_width / maxf(1.0, char_width)))
	var lines := ceilf(float(character_count) / characters_per_line)
	return lines * line_height
