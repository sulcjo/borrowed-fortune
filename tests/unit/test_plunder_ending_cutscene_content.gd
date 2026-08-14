extends GutTest

func test_plunder_ending_outro_has_six_panels_each_with_a_caption_and_image_path():
	var file := FileAccess.open("res://content/cutscenes/plunder_ending_outro.json", FileAccess.READ)
	var panels = JSON.parse_string(file.get_as_text())
	file.close()
	assert_eq(panels.size(), 6)
	for i in range(panels.size()):
		var panel: Dictionary = panels[i]
		assert_true(panel.get("caption", "").length() > 0, "panel %d must have a non-empty caption" % i)
		assert_eq(panel.get("image_path", ""), "res://assets/cutscenes/plunder_ending_outro_%02d.png" % (i + 1))
