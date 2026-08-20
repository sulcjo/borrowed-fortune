extends GutTest

const ChapterViewScene := preload("res://scenes/chapter_view/ChapterView.tscn")
const NPC_FIXTURE_PATH := "res://assets/portraits/__test_fixture_npc__.png"
# Stage 98 is synthetic and out of npcs.json's real range (1-3) - using a real
# stage number here (e.g. farrukh_stage_1.png) would mean after_each() deletes
# the real, committed asset once the human has actually run the generator.
const FARRUKH_FIXTURE_STAGE := 98
const FARRUKH_FIXTURE_PATH := "res://assets/portraits/farrukh_stage_98.png"

func before_each():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/portraits"))
	var fixture_image := Image.create_empty(4, 4, false, Image.FORMAT_RGBA8)
	fixture_image.fill(Color.RED)
	fixture_image.save_png(NPC_FIXTURE_PATH)
	fixture_image.save_png(FARRUKH_FIXTURE_PATH)

func after_each():
	for path in [NPC_FIXTURE_PATH, FARRUKH_FIXTURE_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _view_with_node(node: Dictionary, farrukh_wear_stage: int = 1):
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.dialogue_engine.load_tree([node], node["id"])
	chapter_view.farrukh_wear_stage = farrukh_wear_stage
	return chapter_view

func test_npc_portrait_shows_when_the_current_node_names_one_that_exists_on_disk():
	var chapter_view = _view_with_node({"id": "n01", "text": "", "npc_portrait": "__test_fixture_npc__", "choices": []})
	chapter_view._update_portraits()
	var npc_portrait: TextureRect = chapter_view.get_node("Folio/FolioMargin/Page/MarginColumn/NpcRoundel/NpcPortrait")
	assert_not_null(npc_portrait.texture)

func test_npc_portrait_is_absent_when_the_current_node_names_none():
	var chapter_view = _view_with_node({"id": "n01", "text": "", "choices": []})
	chapter_view._update_portraits()
	var npc_portrait: TextureRect = chapter_view.get_node("Folio/FolioMargin/Page/MarginColumn/NpcRoundel/NpcPortrait")
	assert_null(npc_portrait.texture)

func test_npc_portrait_clears_when_moving_from_a_named_node_to_one_with_none():
	var chapter_view = _view_with_node({"id": "n01", "text": "", "npc_portrait": "__test_fixture_npc__", "choices": []})
	chapter_view._update_portraits()
	var npc_portrait: TextureRect = chapter_view.get_node("Folio/FolioMargin/Page/MarginColumn/NpcRoundel/NpcPortrait")
	assert_not_null(npc_portrait.texture, "sanity check: must actually be set first")

	chapter_view.dialogue_engine.load_tree([{"id": "n02", "text": "", "choices": []}], "n02")
	chapter_view._update_portraits()
	assert_null(npc_portrait.texture)

func test_farrukh_portrait_always_shows_using_the_loaded_wear_stage():
	var chapter_view = _view_with_node({"id": "n01", "text": "", "choices": []}, FARRUKH_FIXTURE_STAGE)
	chapter_view._update_portraits()
	var farrukh_portrait: TextureRect = chapter_view.get_node("Folio/FolioMargin/Page/MarginColumn/FarrukhRoundel/FarrukhPortrait")
	assert_not_null(farrukh_portrait.texture, "Farrukh's bust must show even on a node with zero NPCs")

func test_farrukh_portrait_missing_file_clears_without_erroring():
	# 99 is synthetic and deliberately has no fixture file at all (unlike 98, which
	# before_each() creates) - proves the missing-file fallback without touching
	# any real stage_1/2/3 art.
	var chapter_view = _view_with_node({"id": "n01", "text": "", "choices": []}, 99)
	chapter_view._update_portraits()
	var farrukh_portrait: TextureRect = chapter_view.get_node("Folio/FolioMargin/Page/MarginColumn/FarrukhRoundel/FarrukhPortrait")
	assert_null(farrukh_portrait.texture, "stage 99 has no fixture file on disk, so this must clear rather than error")

func test_npc_portrait_with_unknown_id_clears_without_erroring():
	var chapter_view = _view_with_node({"id": "n01", "text": "", "npc_portrait": "no_such_npc", "choices": []})
	chapter_view._update_portraits()
	var npc_portrait: TextureRect = chapter_view.get_node("Folio/FolioMargin/Page/MarginColumn/NpcRoundel/NpcPortrait")
	assert_null(npc_portrait.texture)

func test_npc_portrait_card_hides_when_no_npc_is_present():
	var chapter_view = _view_with_node({"id": "n01", "text": "", "choices": []})
	chapter_view._update_portraits()
	var npc_portrait_card: Panel = chapter_view.get_node("Folio/FolioMargin/Page/MarginColumn/NpcRoundel")
	assert_false(npc_portrait_card.visible, "an empty framed card reads as a rendering glitch, not 'no one else is here'")

func test_npc_portrait_card_shows_when_an_npc_is_present():
	var chapter_view = _view_with_node({"id": "n01", "text": "", "npc_portrait": "__test_fixture_npc__", "choices": []})
	chapter_view._update_portraits()
	var npc_portrait_card: Panel = chapter_view.get_node("Folio/FolioMargin/Page/MarginColumn/NpcRoundel")
	assert_true(npc_portrait_card.visible)

func test_farrukh_portrait_card_hides_when_the_wear_stage_file_is_missing():
	var chapter_view = _view_with_node({"id": "n01", "text": "", "choices": []}, 99)
	chapter_view._update_portraits()
	var farrukh_portrait_card: Panel = chapter_view.get_node("Folio/FolioMargin/Page/MarginColumn/FarrukhRoundel")
	assert_false(farrukh_portrait_card.visible)
