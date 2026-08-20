extends GutTest

const ChapterViewScene := preload("res://scenes/chapter_view/ChapterView.tscn")
const FIXTURE_PATH := "res://assets/backgrounds/__test_fixture_chapter__.png"

func before_each():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/backgrounds"))
	var fixture_image := Image.create_empty(4, 4, false, Image.FORMAT_RGB8)
	fixture_image.fill(Color.RED)
	fixture_image.save_png(FIXTURE_PATH)

func after_each():
	if FileAccess.file_exists(FIXTURE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(FIXTURE_PATH))

func test_update_place_inset_sets_a_texture_when_a_background_png_exists_for_the_chapter_id():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.chapter_id = "__test_fixture_chapter__"
	chapter_view._update_place_inset()
	var background: TextureRect = chapter_view.get_node("Folio/FolioMargin/Page/TextColumn/HeadBlock/PlaceInset")
	assert_not_null(background.texture)

func test_update_place_inset_clears_an_existing_texture_when_no_background_png_exists_for_the_chapter_id():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.chapter_id = "__test_fixture_chapter__"
	chapter_view._update_place_inset()
	var background: TextureRect = chapter_view.get_node("Folio/FolioMargin/Page/TextColumn/HeadBlock/PlaceInset")
	assert_not_null(background.texture, "sanity check: fixture must actually set a texture first")

	chapter_view.chapter_id = "chapter_id_with_no_art_yet"
	chapter_view._update_place_inset()
	assert_null(background.texture)

# The tests below pass dimensions in explicitly. In a headless run no frame is
# drawn, so container layout never happens and every measured rect is (0, 0) - a
# test that let the code measure would exercise the fallback branch and prove
# nothing. FolioMetrics' own tests cover the arithmetic; these cover the wiring.

func _view_with_text(text: String):
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.dialogue_engine.load_tree([{"id": "n01", "text": text, "choices": []}], "n01")
	var image := Image.create_empty(
		FolioMetrics.PLACE_BASE_WIDTH, FolioMetrics.PLACE_BASE_HEIGHT, false, Image.FORMAT_RGBA8
	)
	image.fill(Color.RED)
	chapter_view.place_inset.texture = ImageTexture.create_from_image(image)
	return chapter_view

func test_place_inset_is_sized_to_an_integer_multiple_of_the_source_art():
	var chapter_view = _view_with_text("Short.")
	chapter_view._resize_place_inset(1060.0, 600.0)
	var width: float = chapter_view.place_inset.custom_minimum_size.x
	assert_gt(width, 0.0, "the inset must be given an explicit size")
	assert_eq(int(width) % FolioMetrics.PLACE_BASE_WIDTH, 0,
		"inset width %d must be a whole multiple of %d" % [int(width), FolioMetrics.PLACE_BASE_WIDTH])

func test_place_inset_keeps_the_source_aspect_ratio():
	var chapter_view = _view_with_text("Short.")
	chapter_view._resize_place_inset(1060.0, 600.0)
	var scale: float = chapter_view.place_inset.custom_minimum_size.x / float(FolioMetrics.PLACE_BASE_WIDTH)
	assert_eq(chapter_view.place_inset.custom_minimum_size.y, FolioMetrics.PLACE_BASE_HEIGHT * scale)

func test_a_short_node_gets_a_larger_inset_than_the_1135_character_prologue_node():
	var short_view = _view_with_text("Short.")
	short_view._resize_place_inset(1060.0, 600.0)

	# The real prologue n12_departure length, built as a string of the right size so
	# the test does not break if that prose is edited.
	var long_view = _view_with_text("x".repeat(1135))
	long_view._resize_place_inset(1060.0, 600.0)

	assert_gt(short_view.place_inset.custom_minimum_size.x, long_view.place_inset.custom_minimum_size.x,
		"long prose must claw width back from the inset")
	assert_eq(long_view.place_inset.custom_minimum_size.x, float(FolioMetrics.PLACE_BASE_WIDTH),
		"the 1135-character node should land on 1x")

func test_inset_collapses_when_the_chapter_has_no_place_art():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.dialogue_engine.load_tree([{"id": "n01", "text": "Short.", "choices": []}], "n01")
	chapter_view.place_inset.texture = null
	chapter_view._resize_place_inset(1060.0, 600.0)
	assert_eq(chapter_view.place_inset.custom_minimum_size, Vector2.ZERO)
