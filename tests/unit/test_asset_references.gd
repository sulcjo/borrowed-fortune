extends GutTest

# Every image the content asks for must be one an exported build can actually serve.
#
# This is the guard the export fix could not get from a real build: no export
# templates were installed, so the change rested on Godot's diagnostic and on load()
# returning the imported resource. What that left uncovered is the case where an asset
# is added later and never imported - it would work from source, because the raw PNG
# is on disk, and come back null in a shipped build. ResourceLoader.exists() is the
# discriminator: it is true only for assets the import pipeline knows about, which is
# exactly what gets packed.
#
# Art that has not been drawn yet is listed below rather than silently tolerated, and
# the list is checked for staleness in both directions.

# Portraits referenced by content but not yet drawn. Both are blocked on the pixellab
# pipeline, which needs credentials this repo does not carry. Delete an entry the
# moment its art lands - a test below fails if one of these turns up on disk, so the
# list cannot quietly rot.
const KNOWN_MISSING := [
	"res://assets/portraits/yusuf.png",
	"res://assets/portraits/parviz.png",
]

func _read_json(path: String):
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed

func _json_paths_in(dir_path: String) -> Array:
	var out: Array = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	for name in dir.get_files():
		if name.ends_with(".json"):
			out.append("%s/%s" % [dir_path, name])
	for sub in dir.get_directories():
		out.append_array(_json_paths_in("%s/%s" % [dir_path, sub]))
	return out

# Every asset path the content asks for, gathered the same way the game asks for it.
func _referenced_assets() -> Array:
	var refs := {}

	for path in _json_paths_in("res://content/chapters"):
		if path.ends_with("manifest.json"):
			continue
		var nodes = _read_json(path)
		if not (nodes is Array):
			continue
		for node in nodes:
			var npc = node.get("npc_portrait", null)
			if npc != null:
				refs["res://assets/portraits/%s.png" % npc] = true

	var manifest = _read_json("res://content/chapters/manifest.json")
	if manifest is Dictionary:
		for chapter_id in manifest:
			refs["res://assets/backgrounds/%s.png" % chapter_id] = true
			var stage := int(manifest[chapter_id].get("farrukh_wear_stage", 1))
			refs["res://assets/portraits/farrukh_stage_%d.png" % stage] = true

	for path in _json_paths_in("res://content/cutscenes"):
		var panels = _read_json(path)
		if not (panels is Array):
			continue
		for panel in panels:
			var image_path = panel.get("image_path", null)
			if image_path != null:
				refs[str(image_path)] = true

	return refs.keys()

func test_the_scan_finds_the_assets_at_all():
	# Guards against the whole file passing vacuously if the content layout moves.
	var refs := _referenced_assets()
	assert_gt(refs.size(), 30, "expected the content to reference dozens of images, found %d" % refs.size())

func test_every_referenced_asset_is_importable_or_known_missing():
	var unimported: Array[String] = []
	var absent: Array[String] = []
	for path in _referenced_assets():
		if ResourceLoader.exists(path):
			continue
		if FileAccess.file_exists(path):
			# The export hazard: the raw file is there, so it works from source, but
			# the import pipeline has never seen it and a shipped build would not
			# contain it.
			unimported.append(path)
		elif not KNOWN_MISSING.has(path):
			absent.append(path)

	assert_eq(unimported, [] as Array[String],
		"present on disk but never imported, so these would be missing from an exported build: %s" % str(unimported))
	assert_eq(absent, [] as Array[String],
		"referenced by content but absent, and not on the known-missing list: %s" % str(absent))

func test_the_known_missing_list_has_no_stale_entries():
	# If the art has landed, the entry must go, or the list stops meaning anything.
	var arrived: Array[String] = []
	for path in KNOWN_MISSING:
		if ResourceLoader.exists(path) or FileAccess.file_exists(path):
			arrived.append(path)
	assert_eq(arrived, [] as Array[String],
		"art has arrived for these; remove them from KNOWN_MISSING: %s" % str(arrived))

func test_the_known_missing_list_is_actually_referenced():
	# The other direction: an entry for something content no longer asks for is dead
	# weight that would hide a future real absence.
	var refs := _referenced_assets()
	for path in KNOWN_MISSING:
		assert_true(refs.has(path),
			"%s is on KNOWN_MISSING but no content references it any more" % path)
