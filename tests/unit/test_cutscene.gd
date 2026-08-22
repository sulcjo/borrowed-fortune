extends GutTest

const CutsceneScript := preload("res://scenes/cutscene/Cutscene.gd")
const PrologueCutsceneScene := preload("res://scenes/prologue_cutscene/PrologueCutscene.tscn")
const NishapurEndingCutsceneScene := preload("res://scenes/nishapur_ending_cutscene/NishapurEndingCutscene.tscn")
const FIXTURE_CHAPTER := "fixture_chapter_for_cutscene_flags"

func after_each():
	var path := GameState.save_path_for(FIXTURE_CHAPTER)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func test_compute_panel_duration_seconds_clamps_short_captions_to_the_minimum():
	var short_caption := "Word word word."
	assert_almost_eq(CutsceneScript.compute_panel_duration_seconds(short_caption), 4.0, 0.0001)

func test_compute_panel_duration_seconds_clamps_long_captions_to_the_maximum():
	var words: Array[String] = []
	for i in range(50):
		words.append("word")
	var long_caption := " ".join(words)
	assert_almost_eq(CutsceneScript.compute_panel_duration_seconds(long_caption), 12.0, 0.0001)

func test_compute_panel_duration_seconds_scales_with_word_count_in_between():
	var words: Array[String] = []
	for i in range(24):
		words.append("word")
	var mid_caption := " ".join(words)
	assert_almost_eq(CutsceneScript.compute_panel_duration_seconds(mid_caption), 8.0, 0.0001)

func test_displaying_panel_data_sets_the_caption_and_starts_the_advance_timer():
	var cutscene = add_child_autofree(PrologueCutsceneScene.instantiate())
	var words: Array[String] = []
	for i in range(12):
		words.append("word")
	var caption := " ".join(words)
	cutscene._display_panel_data({"image_path": "res://this_fixture_path_does_not_need_to_exist.png", "caption": caption})
	assert_eq(cutscene.caption_label.get_parsed_text(), caption)
	assert_almost_eq(cutscene._advance_timer.wait_time, 4.0, 0.0001)

# --- flag-gated panels -------------------------------------------------------------
#
# An ending cutscene is the only screen that can respond to a choice made at a terminal
# node, because nothing in the chapter follows it. That makes panel gating load-bearing
# rather than decorative, so it is tested at the seam: visible_panels is static and pure
# precisely so this needs no scene, no save, and no running tree.

func test_visible_panels_keeps_ungated_panels_whatever_the_flags():
	var panels := [{"caption": "always"}]
	assert_eq(CutsceneScript.visible_panels(panels, {}).size(), 1)
	assert_eq(CutsceneScript.visible_panels(panels, {"anything": true}).size(), 1)

func test_visible_panels_honours_requires_flag():
	var panels := [{"requires_flag": "carried", "caption": "gated"}]
	assert_eq(CutsceneScript.visible_panels(panels, {}).size(), 0)
	assert_eq(CutsceneScript.visible_panels(panels, {"carried": true}).size(), 1)

func test_visible_panels_honours_forbids_flag():
	var panels := [{"forbids_flag": "carried", "caption": "gated"}]
	assert_eq(CutsceneScript.visible_panels(panels, {}).size(), 1)
	assert_eq(CutsceneScript.visible_panels(panels, {"carried": true}).size(), 0)

func test_visible_panels_preserves_authored_order():
	# Filtering decides which panels play; the file decides the order they play in.
	var panels := [
		{"caption": "first"},
		{"requires_flag": "carried", "caption": "second"},
		{"caption": "third"},
	]
	var shown := CutsceneScript.visible_panels(panels, {"carried": true})
	assert_eq(shown[0]["caption"], "first")
	assert_eq(shown[1]["caption"], "second")
	assert_eq(shown[2]["caption"], "third")

func test_load_flags_returns_nothing_when_no_chapter_is_named():
	# The prologue names no chapter, and must not start reading arbitrary saves.
	assert_eq(CutsceneScript.load_flags(""), {})

func test_load_flags_returns_nothing_when_the_save_is_absent():
	assert_eq(CutsceneScript.load_flags(FIXTURE_CHAPTER), {})

func test_load_flags_reads_what_the_chapter_actually_saved():
	# The whole channel end to end: a cutscene can only see a choice if the format
	# ChapterView writes is the format load_flags reads. Both now go through
	# GameState.save_path_for so they cannot disagree about where the file is.
	var state := GameState.new()
	state.chapter_id = FIXTURE_CHAPTER
	state.dialogue_flags = {"chose_something": true}
	var manager := SaveManager.new()
	manager.save(state, GameState.save_path_for(FIXTURE_CHAPTER))
	var loaded := CutsceneScript.load_flags(FIXTURE_CHAPTER)
	assert_true(loaded.get("chose_something", false),
		"a flag saved by the chapter must be visible to its outro")

func test_a_caption_only_panel_clears_the_image_and_centres_the_text():
	var cutscene = add_child_autofree(NishapurEndingCutsceneScene.instantiate())
	cutscene._display_panel_data({"caption": "no picture here"})
	assert_null(cutscene.panel_image.texture,
		"a panel with no image_path must not keep the previous panel's picture")
	assert_almost_eq(cutscene.caption_bar.anchor_top, CutsceneScript.IMAGELESS_CAPTION_ANCHOR_TOP, 0.0001)
	assert_almost_eq(cutscene.caption_bar.color.a, 0.0, 0.0001,
		"the scrim has nothing to lift the text off, so it should not draw a box")

func test_an_imaged_panel_restores_the_authored_caption_placement():
	# The centring is per-panel, so a sequence that alternates must put the bar back.
	var cutscene = add_child_autofree(NishapurEndingCutsceneScene.instantiate())
	var authored_top: float = cutscene._authored_caption_anchor_top
	cutscene._display_panel_data({"caption": "no picture"})
	cutscene._display_panel_data({"image_path": "res://assets/backgrounds/chapter_08_nishapur.png", "caption": "picture"})
	assert_almost_eq(cutscene.caption_bar.anchor_top, authored_top, 0.0001)
	assert_almost_eq(cutscene.caption_bar.color.a, 0.72, 0.0001)

func test_the_nishapur_outro_scene_names_the_chapter_whose_flags_it_reads():
	# Without this the cutscene loads, plays its ungated panels, and silently drops
	# every branch - which looks like working software.
	var cutscene = add_child_autofree(NishapurEndingCutsceneScene.instantiate())
	assert_eq(cutscene.flags_chapter_id, "chapter_08_nishapur")
