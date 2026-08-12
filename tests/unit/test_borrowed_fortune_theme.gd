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
