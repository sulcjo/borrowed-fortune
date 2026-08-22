extends SceneTree

# Rendered check for the ending outro's caption placement. Run it with a real renderer,
# not --headless:
#
#     godot --path . -s tools/verify_outro_captions.gd
#
# Exits 0 when both kinds of panel place their caption sensibly, 1 otherwise, and prints
# the measured rects either way.
#
# Why this exists rather than only a GUT test: the unit tests assert anchor values, which
# is geometry, not appearance. An anchor pair can be correct and still put the text
# somewhere useless once the window and the font are real. The specific thing being
# checked is that a caption-only panel - the outro is mostly those - lands near the
# middle of the frame rather than in the bottom strip the bar was authored for, where it
# would read as a subtitle to a picture that isn't there.

const WINDOW := Vector2i(1280, 720)
const SCENE := "res://scenes/nishapur_ending_cutscene/NishapurEndingCutscene.tscn"

# How far the caption's centre may sit from the frame's centre before it stops reading
# as centred. A fifth of the height is generous and still excludes the authored strip,
# whose centre sits at 0.91 of the height.
const CENTRE_TOLERANCE := 0.20

var _frames := 0

func _init() -> void:
	root.size = WINDOW
	root.add_child(load(SCENE).instantiate())
	process_frame.connect(_on_frame)

func _on_frame() -> void:
	_frames += 1
	if _frames < 8:
		return

	var cutscene := root.get_node_or_null("NishapurEndingCutscene")
	if cutscene == null:
		print("FAIL: scene did not instantiate - did Cutscene.gd fail to parse?")
		quit(1)
		return

	# The awaits below yield back to the frame loop, which would re-enter this callback
	# and run the whole check a second time.
	process_frame.disconnect(_on_frame)

	var bar: ColorRect = cutscene.get_node("CaptionBar")
	var failures: Array[String] = []

	cutscene._display_panel_data({"caption": "The debt was settled. He had not planned for the morning after it."})
	await process_frame
	var imageless_centre := (bar.global_position.y + bar.size.y * 0.5) / float(WINDOW.y)
	print("  caption-only   bar pos=%-16s size=%-16s centre=%.2f alpha=%.2f" % [
		str(bar.global_position), str(bar.size), imageless_centre, bar.color.a])
	if absf(imageless_centre - 0.5) > CENTRE_TOLERANCE:
		failures.append("caption-only text centres at %.2f of the frame, not near the middle" % imageless_centre)
	if bar.color.a > 0.01:
		failures.append("caption-only panel still draws a scrim (alpha %.2f) with nothing to lift text off" % bar.color.a)
	if cutscene.panel_image.texture != null:
		failures.append("caption-only panel is still showing a texture")

	cutscene._display_panel_data({
		"image_path": "res://assets/backgrounds/chapter_08_nishapur.png",
		"caption": "Past the walls, the road went on being a road.",
	})
	await process_frame
	var imaged_centre := (bar.global_position.y + bar.size.y * 0.5) / float(WINDOW.y)
	print("  with an image  bar pos=%-16s size=%-16s centre=%.2f alpha=%.2f" % [
		str(bar.global_position), str(bar.size), imaged_centre, bar.color.a])
	if imaged_centre < 0.75:
		failures.append("an imaged panel's caption drifted to %.2f instead of the authored strip" % imaged_centre)
	if bar.color.a < 0.5:
		failures.append("an imaged panel lost its scrim (alpha %.2f), so text sits straight on the art" % bar.color.a)
	if cutscene.panel_image.texture == null:
		failures.append("an imaged panel rendered no texture - is the art missing?")

	if failures.is_empty():
		print("OK: caption-only centres at %.2f, imaged stays at %.2f, in a %s window" % [
			imageless_centre, imaged_centre, str(WINDOW)])
		quit(0)
		return

	for f in failures:
		print("FAIL: %s" % f)
	quit(1)
