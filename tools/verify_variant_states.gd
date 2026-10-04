extends SceneTree

# Rendered sweep: for each "chapter|node|flag" line in the file named by SWEEP_FILE,
# show that node with only that flag set and check the folio fits the window.
#
#     SWEEP_FILE=/abs/path/states.txt godot --path . -s tools/verify_variant_states.gd
#
# verify_folio_layout.gd only ever measures the first node with no flags set, so it
# cannot see a long variant, or a variant that a newly added button pushes off the
# page. Exits 1 if any listed state overflows the window. An empty flag field means
# the base text.

const WINDOW := Vector2i(1280, 720)
const SETTLE_FRAMES := 8

var _entries: Array = []
var _i := -1
var _frames := 0
var _fails := 0
var _view = null

func _init() -> void:
	root.size = WINDOW
	var f := FileAccess.open(OS.get_environment("SWEEP_FILE"), FileAccess.READ)
	for line in f.get_as_text().split("\n"):
		if line.strip_edges() != "":
			_entries.append(line.strip_edges().split("|"))
	root.add_child(load("res://scenes/main/Main.tscn").instantiate())
	process_frame.connect(_on_frame)

func _show(entry: Array) -> void:
	_view.load_chapter_by_id(entry[0])
	_view.dialogue_engine.flags = {}
	if entry.size() > 2 and entry[2] != "":
		_view.dialogue_engine.flags = {entry[2]: true}
	_view.dialogue_engine.current_node_id = entry[1]
	# A terminal node would make _render_current_node save and leave the chapter.
	# Give it one stand-in button instead: the page is then measured with slightly
	# less room than it really has, which errs the safe way.
	var node: Dictionary = _view.dialogue_engine.current_node()
	if (node.get("choices", []) as Array).is_empty():
		node["choices"] = [{"text": "Continue.", "next_id": entry[1], "effects": {}}]
	_view._render_current_node()

func _on_frame() -> void:
	_frames += 1
	if _view == null:
		if _frames < SETTLE_FRAMES:
			return
		_view = root.get_node_or_null("Main/ChapterView")
		if _view == null:
			print("FAIL: no ChapterView")
			quit(1)
			return
		_next()
		return
	if _frames < SETTLE_FRAMES:
		return
	var folio: Control = _view.get_node("Folio/FolioMargin")
	var e: Array = _entries[_i]
	var ok := folio.size.y <= float(WINDOW.y) + 1.0 and folio.size.x <= float(WINDOW.x) + 1.0
	if not ok:
		_fails += 1
	print("%s %-60s %-40s chars=%4d folio=%s" % ["OK  " if ok else "FAIL", e[0] + ":" + e[1], e[2] if e.size() > 2 else "", _view.dialogue_engine.current_text().length(), str(folio.size)])
	_next()

func _next() -> void:
	_i += 1
	_frames = 0
	if _i >= _entries.size():
		print("%d of %d states overflow" % [_fails, _entries.size()])
		quit(1 if _fails > 0 else 0)
		return
	_show(_entries[_i])
