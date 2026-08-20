extends GutTest

# Metrics for the 1280x720 reference at RichTextLabel normal_font_size = 22:
# roughly 10px average character width and a ~31px line box in EB Garamond.
const CHAR_W := 10.0
const LINE_H := 31.0
const GUTTER := 12.0

# Width left for the head block on the reference page once the fixed 160px margin
# column and the folio's own 28px side margins are taken out.
const REFERENCE_WIDTH := 1060.0
const REFERENCE_HEIGHT := 600.0

func test_narration_width_is_capped_so_prose_never_runs_to_a_punishing_measure():
	assert_eq(FolioMetrics.narration_width(2000.0), 720.0)

func test_narration_width_takes_what_is_available_when_under_the_cap():
	assert_eq(FolioMetrics.narration_width(440.0), 440.0)

func test_a_short_node_gets_a_larger_inset_than_a_long_one():
	var short_scale := FolioMetrics.choose_place_scale(120, REFERENCE_WIDTH, REFERENCE_HEIGHT, GUTTER, CHAR_W, LINE_H)
	var long_scale := FolioMetrics.choose_place_scale(1135, REFERENCE_WIDTH, REFERENCE_HEIGHT, GUTTER, CHAR_W, LINE_H)
	assert_gt(short_scale, long_scale)

func test_the_1135_character_prologue_node_drops_to_1x():
	# At 2x the inset is 640 wide, leaving ~408px of prose: ~29 lines at ~899px,
	# which does not fit 600px. At 1x the prose gets the full 720px cap: ~16 lines,
	# ~496px. Fits.
	var scale := FolioMetrics.choose_place_scale(1135, REFERENCE_WIDTH, REFERENCE_HEIGHT, GUTTER, CHAR_W, LINE_H)
	assert_eq(scale, 1)

func test_a_short_node_does_not_starve_the_prose_to_win_a_bigger_inset():
	# A 3x inset on the reference page would leave only ~88px of prose - about eight
	# characters a line. That "fits" by height while being unreadable, so the scale
	# must be rejected on width alone.
	var scale := FolioMetrics.choose_place_scale(120, REFERENCE_WIDTH, REFERENCE_HEIGHT, GUTTER, CHAR_W, LINE_H)
	var prose_width := REFERENCE_WIDTH - float(FolioMetrics.PLACE_BASE_WIDTH * scale) - GUTTER
	assert_gte(prose_width, float(FolioMetrics.MIN_NARRATION_WIDTH),
		"scale %d leaves only %d px of prose" % [scale, int(prose_width)])

func test_a_wide_window_can_afford_the_largest_inset():
	var scale := FolioMetrics.choose_place_scale(120, 2400.0, 900.0, GUTTER, CHAR_W, LINE_H)
	assert_eq(scale, FolioMetrics.MAX_PLACE_SCALE)

func test_scale_never_falls_below_one_even_when_nothing_fits():
	var scale := FolioMetrics.choose_place_scale(99999, REFERENCE_WIDTH, 100.0, GUTTER, CHAR_W, LINE_H)
	assert_eq(scale, 1, "1x is the floor - the inset is never dropped entirely")

func test_scale_is_bounded_by_the_width_actually_available():
	# 400px of width cannot host a 2x (640px) inset at any text length.
	var scale := FolioMetrics.choose_place_scale(10, 400.0, REFERENCE_HEIGHT, GUTTER, CHAR_W, LINE_H)
	assert_eq(scale, 1)

func test_scale_always_lands_within_the_allowed_range():
	for characters in [0, 10, 300, 800, 1135, 2400, 9000]:
		var scale := FolioMetrics.choose_place_scale(characters, REFERENCE_WIDTH, REFERENCE_HEIGHT, GUTTER, CHAR_W, LINE_H)
		assert_between(scale, 1, FolioMetrics.MAX_PLACE_SCALE,
			"scale %d out of range for %d characters" % [scale, characters])

func test_an_empty_node_is_handled_without_dividing_by_zero():
	var scale := FolioMetrics.choose_place_scale(0, REFERENCE_WIDTH, REFERENCE_HEIGHT, GUTTER, CHAR_W, LINE_H)
	assert_gte(scale, 1)
