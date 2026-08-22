extends RefCounted
class_name TextureLoader

# One place to turn an asset path into a Texture2D, in a way an exported build can
# actually do.
#
# Every scene used to call Image.load_from_file() followed by
# ImageTexture.create_from_image(). That reads a raw file off the filesystem, and
# Godot warns about it in as many words: "Loaded resource as image file, this will not
# work on export." An exported build serves res:// out of the .pck, which contains
# imported resources rather than the original PNGs, so those calls would come back
# null and the game would ship with no art at all.
#
# load() asks for the imported resource instead, which is what actually gets packed.
# It is also cached by ResourceLoader, so the same texture is not re-decoded from disk
# on every node render - the old code paid that cost on every single click.

static func load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var resource = load(path)
		if resource is Texture2D:
			return resource
		# A path that exists but is not a texture: treat as absent rather than
		# handing a caller something it cannot draw.
		return null
	# Development-only fallback. Tests write fixture PNGs at runtime, and a file
	# created after import time is not in the resource database, so load() cannot see
	# it. Shipped assets never take this branch.
	if not FileAccess.file_exists(path):
		return null
	var image := Image.load_from_file(path)
	if image == null:
		return null
	return ImageTexture.create_from_image(image)
