extends GutTest

# The acceptance cases for the folio redesign cannot be checked by driving the GUI -
# this suite runs headless. Container layout is computed on the CPU though, so
# resizing the root viewport and awaiting frames yields real rectangles.

const ChapterViewScene := preload("res://scenes/chapter_view/ChapterView.tscn")
const SIZES := [Vector2i(800, 600), Vector2i(1280, 720), Vector2i(2560, 1080)]

var _original_size: Vector2i

func before_all():
	_original_size = get_tree().root.size

func after_all():
	get_tree().root.size = _original_size

func _laid_out_view(text: String, choice_count: int, size: Vector2i):
	get_tree().root.size = size
	var choices := []
	for i in range(choice_count):
		choices.append({"text": "Choice number %d." % i, "next_id": "n01", "effects": {}})
	var chapter_view: Control = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chapter_view.size = Vector2(size)
	chapter_view.dialogue_engine.load_tree([{"id": "n01", "text": text, "choices": choices}], "n01")
	chapter_view._render_current_node()
	# Two frames: one for the size change, one for the containers to re-sort children.
	await get_tree().process_frame
	await get_tree().process_frame
	return chapter_view

func _node(view, path: String) -> Control:
	return view.get_node("Folio/FolioMargin/Page/%s" % path)

func test_four_choices_stay_inside_the_text_column_at_every_size():
	for size in SIZES:
		var view = await _laid_out_view("An officer at the gate named a sum.", 4, size)
		var choices := _node(view, "TextColumn/ChoicesContainer")
		var column := _node(view, "TextColumn")
		assert_eq(choices.get_child_count(), 4, "at %s" % size)
		assert_lte(choices.global_position.y + choices.size.y,
			column.global_position.y + column.size.y + 1.0,
			"choices overflow the text column at %s" % size)

func test_the_longest_node_is_not_clipped_at_every_size():
	var long_text := "x ".repeat(568)  # ~1135 chars, the prologue n12_departure length
	for size in SIZES:
		var view = await _laid_out_view(long_text, 1, size)
		var narration: RichTextLabel = _node(view, "TextColumn/HeadBlock/NarrationLabel")
		assert_gt(narration.size.y, 0.0, "narration has no height at %s" % size)
		assert_lte(narration.get_content_height(), narration.size.y + 1.0,
			"narration is clipped at %s" % size)

func test_prose_column_never_exceeds_the_readability_cap():
	for size in SIZES:
		var view = await _laid_out_view("Short prose.", 2, size)
		var narration := _node(view, "TextColumn/HeadBlock/NarrationLabel")
		assert_lte(narration.size.x, float(FolioMetrics.NARRATION_MAX_WIDTH) + 1.0,
			"prose ran to %d px at %s, past the %d px cap" % [
				int(narration.size.x), size, FolioMetrics.NARRATION_MAX_WIDTH])

func test_the_page_actually_widens_with_the_window():
	# Guards the cap test above from passing trivially because nothing ever got wide.
	var narrow = await _laid_out_view("Short prose.", 2, SIZES[0])
	var narrow_page: float = _node(narrow, "TextColumn").size.x
	var wide = await _laid_out_view("Short prose.", 2, SIZES[2])
	var wide_page: float = _node(wide, "TextColumn").size.x
	assert_gt(wide_page, narrow_page,
		"text column did not grow between %s and %s - the layout is not tracking the window" % [SIZES[0], SIZES[2]])

func test_margin_column_never_overlaps_the_text_column():
	for size in SIZES:
		var view = await _laid_out_view("Short prose.", 2, size)
		var column := _node(view, "TextColumn")
		var margin := _node(view, "MarginColumn")
		assert_lte(column.global_position.x + column.size.x, margin.global_position.x + 1.0,
			"text column runs into the margin at %s" % size)

func test_the_folio_never_overflows_the_window():
	# The failure this guards: prose width collapsed to 1px, so a 325-character node
	# wrapped into 9060px of height and the whole page was pushed off screen, leaving
	# nothing but bare parchment. Nothing previously asserted the page fits its window.
	for size in SIZES:
		var view = await _laid_out_view("An officer at the gate named a sum.", 4, size)
		var folio_margin: Control = view.get_node("Folio/FolioMargin")
		assert_lte(folio_margin.size.x, float(size.x) + 1.0,
			"folio is %d px wide in a %d px window" % [int(folio_margin.size.x), size.x])
		assert_lte(folio_margin.size.y, float(size.y) + 1.0,
			"folio is %d px tall in a %d px window" % [int(folio_margin.size.y), size.y])

func test_prose_is_actually_given_room_not_merely_capped():
	# The cap test below bounds prose from above. Without a lower bound a 1px column
	# satisfies it, which is exactly how the collapse shipped.
	for size in SIZES:
		var view = await _laid_out_view("An officer at the gate named a sum.", 4, size)
		var narration: RichTextLabel = _node(view, "TextColumn/HeadBlock/NarrationLabel")
		assert_gt(narration.size.x, 200.0,
			"prose column is only %d px wide at %s" % [int(narration.size.x), size])

func test_prose_minimum_width_stays_zero_so_the_page_cannot_ratchet():
	# Enforcing the cap through the label's own minimum made HeadBlock's minimum equal
	# its width, which locked in overflow and made each re-measure drift wider. The cap
	# is held by the spacer instead, so the label must contribute no minimum.
	var view = await _laid_out_view("An officer at the gate named a sum.", 4, SIZES[2])
	var narration: RichTextLabel = _node(view, "TextColumn/HeadBlock/NarrationLabel")
	assert_eq(narration.custom_minimum_size.x, 0.0)

func test_the_real_main_scene_lays_out_inside_its_window():
	# Goes through Main.tscn and Main._ready() -> resume(), the path that actually
	# broke. Every earlier check drove ChapterView directly and so could not see it.
	get_tree().root.size = Vector2i(1280, 720)
	var main: Control = add_child_autofree(load("res://scenes/main/Main.tscn").instantiate())
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main.size = Vector2(1280, 720)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	var view: Control = main.get_node("ChapterView")
	var folio_margin: Control = view.get_node("Folio/FolioMargin")
	assert_lte(folio_margin.size.y, 721.0,
		"folio is %d px tall in a 720 px window" % int(folio_margin.size.y))
	assert_lte(folio_margin.size.x, 1281.0,
		"folio is %d px wide in a 1280 px window" % int(folio_margin.size.x))

	var narration: RichTextLabel = view.get_node("Folio/FolioMargin/Page/TextColumn/HeadBlock/NarrationLabel")
	assert_gt(narration.size.x, 200.0,
		"prose column is only %d px wide through the real Main path" % int(narration.size.x))
	assert_gt(narration.text.length(), 0, "the first node rendered no text")

func test_every_scene_still_instantiates_under_the_new_content_scale():
	# The [display] settings are project-wide, so they re-render all seven scenes.
	# These six are verified rather than redesigned; PrologueCutscene, EndingCutscene
	# and Main have no tests of their own, so this is the only thing standing between
	# a content-scale change and a scene that silently stopped loading.
	var scene_paths := [
		"res://scenes/main/Main.tscn",
		"res://scenes/main_menu/MainMenu.tscn",
		"res://scenes/journey_map/JourneyMapScreen.tscn",
		"res://scenes/prologue_cutscene/PrologueCutscene.tscn",
		"res://scenes/ending_cutscene/EndingCutscene.tscn",
		"res://scenes/nishapur_ending_cutscene/NishapurEndingCutscene.tscn",
	]
	for path in scene_paths:
		var packed: PackedScene = load(path)
		assert_not_null(packed, "could not load %s" % path)
		var instance = add_child_autofree(packed.instantiate())
		assert_not_null(instance, "could not instantiate %s" % path)
		await get_tree().process_frame

func test_place_inset_stays_on_integer_scales_at_every_size():
	for size in SIZES:
		var view = await _laid_out_view("Short prose.", 2, size)
		var inset: TextureRect = _node(view, "TextColumn/HeadBlock/PlaceInset")
		if inset.texture == null:
			continue  # no place art loaded for a bare node; nothing to scale
		assert_eq(int(inset.custom_minimum_size.x) % FolioMetrics.PLACE_BASE_WIDTH, 0,
			"inset off integer scale at %s" % size)
