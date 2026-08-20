extends GutTest

# The folio expands to fill the window, so the project must declare a reference
# viewport and a canvas_items stretch mode. Before this, project.godot had no
# [display] section at all, which is why ChapterView's 33 absolute offsets drifted:
# resizing the window changed the space available without scaling anything in it.

func test_reference_viewport_is_1280x720():
	assert_eq(int(ProjectSettings.get_setting("display/window/size/viewport_width")), 1280)
	assert_eq(int(ProjectSettings.get_setting("display/window/size/viewport_height")), 720)

func test_stretch_mode_scales_canvas_items():
	assert_eq(str(ProjectSettings.get_setting("display/window/stretch/mode")), "canvas_items")

func test_stretch_aspect_expands_so_a_wider_window_shows_more_page():
	assert_eq(str(ProjectSettings.get_setting("display/window/stretch/aspect")), "expand")

func test_canvas_texture_filter_is_nearest_so_pixel_art_is_not_blurred():
	# 0 == CANVAS_ITEM_TEXTURE_FILTER_NEAREST. The backgrounds are 320x180 and the
	# portraits 200x200 - deliberate pixel art. The default linear filter
	# interpolates them 4-6x on the way to the screen.
	assert_eq(int(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter")), 0)
