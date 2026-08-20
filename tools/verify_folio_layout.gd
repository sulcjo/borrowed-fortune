extends SceneTree

# Rendered layout check for the folio. Run it with a real renderer, not --headless:
#
#     godot --path . -s tools/verify_folio_layout.gd
#
# Exits 0 when the page fits its window and the prose has room, 1 otherwise, and
# prints every region's rect either way.
#
# Why this exists rather than another GUT test: headless container layout does not
# reproduce the failure it guards. Under --headless the rects resolve early and
# cleanly, so a headless test passes even with the fix removed - that was verified,
# not assumed. Only a rendered first frame produces the small-but-nonzero rects that
# made measuring garbage, collapse the prose column to 1px, wrap a 325-character node
# into 9060px of height and push the whole page off screen behind bare parchment.
#
# Run this after touching ChapterView's tree, FolioMetrics, or anything that changes
# how the page is measured.

const WINDOW := Vector2i(1280, 720)
const MIN_PROSE_WIDTH := 200.0

const PATHS := [
	"Folio/FolioMargin",
	"Folio/FolioMargin/Page",
	"Folio/FolioMargin/Page/TextColumn",
	"Folio/FolioMargin/Page/TextColumn/HeadBlock",
	"Folio/FolioMargin/Page/TextColumn/HeadBlock/PlaceInset",
	"Folio/FolioMargin/Page/TextColumn/HeadBlock/NarrationLabel",
	"Folio/FolioMargin/Page/TextColumn/HeadBlock/HeadSpacer",
	"Folio/FolioMargin/Page/TextColumn/ChoicesContainer",
	"Folio/FolioMargin/Page/TextColumn/Colophon",
	"Folio/FolioMargin/Page/MarginColumn",
]

var _frames := 0

func _init() -> void:
	root.size = WINDOW
	root.add_child(load("res://scenes/main/Main.tscn").instantiate())
	process_frame.connect(_on_frame)

func _on_frame() -> void:
	_frames += 1
	if _frames < 8:
		return

	var view := root.get_node_or_null("Main/ChapterView")
	if view == null:
		print("FAIL: Main/ChapterView is missing - did ChapterView.gd fail to parse?")
		quit(1)
		return

	for p in PATHS:
		var n = view.get_node_or_null(p)
		if n == null:
			print("  %-62s MISSING" % p)
			continue
		print("  %-62s pos=%-16s size=%s" % [p, str(n.global_position), str(n.size)])

	var failures: Array[String] = []
	var folio_margin: Control = view.get_node("Folio/FolioMargin")
	if folio_margin.size.x > float(WINDOW.x) + 1.0:
		failures.append("folio is %d px wide in a %d px window" % [int(folio_margin.size.x), WINDOW.x])
	if folio_margin.size.y > float(WINDOW.y) + 1.0:
		failures.append("folio is %d px tall in a %d px window" % [int(folio_margin.size.y), WINDOW.y])

	var narration: RichTextLabel = view.get_node("Folio/FolioMargin/Page/TextColumn/HeadBlock/NarrationLabel")
	if narration.size.x < MIN_PROSE_WIDTH:
		failures.append("prose column is only %d px wide" % int(narration.size.x))
	if narration.text.is_empty():
		failures.append("the first node rendered no text")
	if narration.custom_minimum_size.x != 0.0:
		failures.append("prose has a minimum width of %d px - the page can ratchet wider on re-measure" % int(narration.custom_minimum_size.x))

	var inset: TextureRect = view.get_node("Folio/FolioMargin/Page/TextColumn/HeadBlock/PlaceInset")
	if inset.texture != null and int(inset.custom_minimum_size.x) % 320 != 0:
		failures.append("place inset is %d px wide, not a whole multiple of 320" % int(inset.custom_minimum_size.x))

	if failures.is_empty():
		print("OK: folio fits %s, prose %d px wide, inset %d px" % [
			str(WINDOW), int(narration.size.x), int(inset.custom_minimum_size.x)
		])
		quit(0)
		return

	for f in failures:
		print("FAIL: %s" % f)
	quit(1)
