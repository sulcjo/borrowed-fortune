extends GutTest

func test_button_disabled_text_is_visible_not_washed_out():
	var theme := BorrowedFortuneTheme.build()
	var disabled_color: Color = theme.get_color("font_disabled_color", "Button")
	assert_almost_eq(disabled_color.a, 0.35, 0.001)
	assert_true(disabled_color.a > 0.3)

func test_button_font_size_is_bumped_up_from_default():
	var theme := BorrowedFortuneTheme.build()
	assert_eq(theme.get_font_size("font_size", "Button"), 18)

func test_banner_button_variation_has_no_visible_box():
	var theme := BorrowedFortuneTheme.build()
	var normal_style: StyleBox = theme.get_stylebox("normal", "BannerButton")
	assert_true(normal_style is StyleBoxEmpty)

func test_banner_button_font_size_is_larger_than_global_default():
	var theme := BorrowedFortuneTheme.build()
	assert_eq(theme.get_font_size("font_size", "BannerButton"), 20)

func test_banner_title_uses_the_bold_font_at_36px():
	var theme := BorrowedFortuneTheme.build()
	assert_eq(theme.get_font_size("font_size", "BannerTitle"), 36)
	assert_not_null(theme.get_font("font", "BannerTitle"))

func test_focus_ring_color_matches_the_confirmed_slate_blue():
	var theme := BorrowedFortuneTheme.build()
	var focus_style: StyleBoxFlat = theme.get_stylebox("focus", "Button")
	assert_eq(focus_style.border_color, Color("#6b7f8a"))

func test_default_panel_style_is_parchment_with_gold_border():
	var theme := BorrowedFortuneTheme.build()
	var panel_style: StyleBoxFlat = theme.get_stylebox("panel", "Panel")
	assert_eq(panel_style.bg_color, Color("#e3d5aa"))
	assert_eq(panel_style.border_color, Color("#c9a24b"))

func test_superseded_chapter_view_variations_are_gone():
	# Both were referenced by ChapterView and nothing else. Roundel replaces
	# PortraitCard and Folio replaces DialogueParchment, so they do not sit alongside
	# them - keeping them would leave two dead entries in every generated theme.
	var theme := BorrowedFortuneTheme.build()
	assert_false(theme.has_stylebox("panel", "PortraitCard"), "PortraitCard was replaced by Roundel")
	assert_false(theme.has_stylebox("panel", "DialogueParchment"), "DialogueParchment was replaced by Folio")

func test_richtextlabel_default_color_is_ink_black():
	var theme := BorrowedFortuneTheme.build()
	assert_eq(theme.get_color("default_color", "RichTextLabel"), Color("#241a10"))

func test_richtextlabel_font_size_uses_the_correct_property_name():
	var theme := BorrowedFortuneTheme.build()
	assert_eq(theme.get_font_size("normal_font_size", "RichTextLabel"), 22)

func test_scrollbar_grabber_is_gold():
	var theme := BorrowedFortuneTheme.build()
	var grabber_style: StyleBoxFlat = theme.get_stylebox("grabber", "VScrollBar")
	assert_eq(grabber_style.bg_color, Color("#c9a24b"))

func test_folio_variation_is_a_parchment_panel():
	var theme := BorrowedFortuneTheme.build()
	assert_eq(theme.get_type_variation_base("Folio"), &"Panel")
	var panel_style: StyleBoxFlat = theme.get_stylebox("panel", "Folio")
	assert_eq(panel_style.bg_color, Color("#e3d5aa"))

func test_roundel_variation_reads_as_a_circle_not_a_box():
	var theme := BorrowedFortuneTheme.build()
	assert_eq(theme.get_type_variation_base("Roundel"), &"Panel")
	var panel_style: StyleBoxFlat = theme.get_stylebox("panel", "Roundel")
	assert_gt(panel_style.corner_radius_top_left, 8)

func test_colophon_variation_uses_muted_ink():
	var theme := BorrowedFortuneTheme.build()
	assert_eq(theme.get_type_variation_base("Colophon"), &"Label")
	assert_eq(theme.get_color("font_color", "Colophon"), Color("#6b5a44"))

func test_gloss_note_variation_uses_muted_ink_at_a_smaller_size():
	var theme := BorrowedFortuneTheme.build()
	assert_eq(theme.get_type_variation_base("GlossNote"), &"Label")
	assert_eq(theme.get_color("font_color", "GlossNote"), Color("#6b5a44"))
	assert_lt(theme.get_font_size("font_size", "GlossNote"), theme.get_font_size("font_size", "Button"))

func test_rubric_choice_variation_is_written_on_the_page_not_boxed_on_it():
	var theme := BorrowedFortuneTheme.build()
	assert_eq(theme.get_type_variation_base("Rubric"), &"Button")
	assert_eq(theme.get_color("font_color", "Rubric"), Color("#7a1f14"))
	var normal_style: StyleBoxFlat = theme.get_stylebox("normal", "Rubric")
	assert_false(normal_style.draw_center)
	assert_eq(normal_style.border_width_left, 2, "the gold rule down the left margin")

func test_rubric_keeps_the_existing_focus_ring_for_the_later_controls_work():
	var theme := BorrowedFortuneTheme.build()
	var focus_style: StyleBoxFlat = theme.get_stylebox("focus", "Rubric")
	assert_eq(focus_style.border_color, Color("#6b7f8a"))
