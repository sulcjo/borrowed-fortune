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
