extends SceneTree

# Runs INSIDE an exported pack to answer the one question the test suite cannot:
# does the game actually find its art when res:// is served from a .pck rather than
# from the filesystem?
#
#   godot --headless --path . --export-pack "Linux" /tmp/game.pck
#   godot --headless --main-pack /tmp/game.pck -s tools/verify_export_textures.gd
#
# Exits 0 if every checked asset resolves to an imported texture, 1 otherwise. Also
# proves the negative: Image.load_from_file(), which every scene used before the
# export fix, cannot see these files at all once packed.

const TextureLoaderScript := preload("res://engine/assets/TextureLoader.gd")

const CHECKS := [
	"res://assets/backgrounds/chapter_00_prologue.png",
	"res://assets/backgrounds/chapter_07b_merv.png",
	"res://assets/portraits/mihran.png",
	"res://assets/portraits/farrukh_stage_1.png",
	"res://assets/ui/menu_banner_tall.png",
	"res://assets/cutscenes/prologue_intro_01.png",
]

func _init() -> void:
	var failures: Array[String] = []

	for path in CHECKS:
		var texture = TextureLoaderScript.load_texture(path)
		if texture == null:
			failures.append("%s -> null" % path)
			continue
		print("OK  %-52s %s %dx%d" % [
			path, texture.get_class(), texture.get_width(), texture.get_height()
		])

	# The old code path, for contrast: the raw PNG is not in the pack, so this is what
	# every scene would have got before the loader change.
	var raw := Image.load_from_file(CHECKS[0])
	print("\nImage.load_from_file(%s) -> %s" % [CHECKS[0], "an Image" if raw != null else "null"])
	if raw != null:
		print("  note: raw file readable here, so this pack still carries loose PNGs")

	if failures.is_empty():
		print("\nPASS: all %d assets resolved from the pack" % CHECKS.size())
		quit(0)
		return
	for f in failures:
		print("FAIL: %s" % f)
	quit(1)
