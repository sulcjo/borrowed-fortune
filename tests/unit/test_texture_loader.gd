extends GutTest

# A committed asset, which the editor has imported.
const IMPORTED_ASSET := "res://assets/backgrounds/chapter_00_prologue.png"
# Written during the test, so never imported - the case Image.load_from_file exists for.
const RUNTIME_FIXTURE := "res://assets/backgrounds/__test_texture_loader__.png"

func after_each():
	if FileAccess.file_exists(RUNTIME_FIXTURE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RUNTIME_FIXTURE))

func _write_runtime_fixture() -> void:
	var image := Image.create_empty(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color.RED)
	image.save_png(RUNTIME_FIXTURE)

func test_a_missing_path_returns_null():
	assert_null(TextureLoader.load_texture("res://assets/backgrounds/does_not_exist_12345.png"))

func test_a_committed_asset_loads_as_an_imported_resource():
	# The point of the whole change: load() returns the imported resource, which is
	# what an exported build actually ships. Image.load_from_file() reads a raw file
	# off disk, and Godot warns "this will not work on export" for exactly that reason.
	var texture := TextureLoader.load_texture(IMPORTED_ASSET)
	assert_not_null(texture)
	assert_true(texture is Texture2D)
	assert_false(texture is ImageTexture,
		"an imported PNG should arrive as a CompressedTexture2D, not one built at runtime")

func test_loading_the_same_asset_twice_returns_the_same_instance():
	# ResourceLoader caches, so this is also what stops a PNG being re-decoded from
	# disk on every single node render.
	var first := TextureLoader.load_texture(IMPORTED_ASSET)
	var second := TextureLoader.load_texture(IMPORTED_ASSET)
	assert_true(first == second, "the second load must come from the resource cache")

func test_a_runtime_written_png_still_loads_through_the_fallback():
	# Tests write fixture images at runtime; those are never imported, so the raw-file
	# path has to remain available for them. It is a development-only fallback.
	_write_runtime_fixture()
	var texture := TextureLoader.load_texture(RUNTIME_FIXTURE)
	assert_not_null(texture)
	assert_true(texture is ImageTexture, "the fallback builds the texture at runtime")

func test_a_directory_path_returns_null_rather_than_erroring():
	assert_null(TextureLoader.load_texture("res://assets/backgrounds"))
