extends GutTest

# The contract a recurring character has to meet, checked against every character
# declared in content/characters/recurring.json.
#
# Before this, "recurring character" meant "Yusuf", and the only definition was his
# three nodes. PR #11 is the reason there is a contract at all: the obvious way to add
# more recurring people is to drop a single-choice cameo into each chapter, and that
# was tried in principle and rejected, because it is exactly the page-turn padding
# test_consequence_metrics.gd exists to stop. What made Yusuf worth having was not
# that he came back. It was that every time he came back he asked something, and
# remembered what you said the last time. These tests hold every other character to
# that, so the next one is a declaration rather than a rediscovery.
#
# What is checked, per character:
#   - at least two appearances, in at least two different chapters
#   - every appearance is a decision - two or more choices, never a cameo
#   - every appearance after the first remembers an earlier one: at least one of its
#     text_variants is keyed on a flag that an earlier appearance's choices set
#   - one face throughout: every appearance carries the declared portrait, or, while a
#     portrait is still pending, none of them does - never a character drawn in one
#     chapter and faceless in the next
#
# And across the game: anyone whose portrait turns up in two or more chapters must be
# declared here, so recurrence cannot be added around the contract instead of through it.

const DECLARATION := "res://content/characters/recurring.json"
const MANIFEST := "res://content/chapters/manifest.json"

func _read_json(path: String):
	var file := FileAccess.open(path, FileAccess.READ)
	assert_not_null(file, "cannot open %s" % path)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed

func _characters() -> Dictionary:
	return _read_json(DECLARATION)

# chapter_id -> {node_id: node}
func _nodes_by_chapter() -> Dictionary:
	var manifest: Dictionary = _read_json(MANIFEST)
	var out := {}
	for chapter_id in manifest:
		var nodes = _read_json(str(manifest[chapter_id]["dialogue_path"]))
		var by_id := {}
		for node in nodes:
			by_id[node["id"]] = node
		out[chapter_id] = by_id
	return out

func _appearance_nodes(character: Dictionary, chapters: Dictionary) -> Array:
	var nodes: Array = []
	for appearance in character["appearances"]:
		var chapter: Dictionary = chapters.get(appearance["chapter"], {})
		nodes.append(chapter.get(appearance["node"], {}))
	return nodes

func _flags_set_by(node: Dictionary) -> Dictionary:
	var flags := {}
	for choice in node.get("choices", []):
		for flag_name in choice.get("effects", {}).get("flags", []):
			flags[flag_name] = true
	return flags

func test_the_declaration_names_at_least_the_characters_already_built():
	var characters := _characters()
	for who in ["yusuf", "said", "parviz", "hamza"]:
		assert_true(characters.has(who), "%s is missing from the declaration" % who)

func test_every_appearance_exists_where_it_is_declared():
	var chapters := _nodes_by_chapter()
	var characters := _characters()
	for who in characters:
		for appearance in characters[who]["appearances"]:
			assert_true(chapters.has(appearance["chapter"]),
				"%s: chapter %s is not in the manifest" % [who, appearance["chapter"]])
			assert_true(chapters.get(appearance["chapter"], {}).has(appearance["node"]),
				"%s: %s is not a node of %s" % [who, appearance["node"], appearance["chapter"]])

func test_every_character_recurs_across_chapters():
	var characters := _characters()
	for who in characters:
		var appearances: Array = characters[who]["appearances"]
		var distinct := {}
		for appearance in appearances:
			distinct[appearance["chapter"]] = true
		assert_gte(appearances.size(), 2, "%s appears once; that is a character, not a recurring one" % who)
		assert_gte(distinct.size(), 2, "%s never leaves one chapter" % who)

func test_every_appearance_is_a_decision_not_a_cameo():
	var chapters := _nodes_by_chapter()
	var characters := _characters()
	for who in characters:
		for node in _appearance_nodes(characters[who], chapters):
			assert_gte((node.get("choices", []) as Array).size(), 2,
				"%s at %s offers no decision - a cameo is the padding this contract exists to refuse"
				% [who, node.get("id", "?")])

func test_every_later_appearance_remembers_an_earlier_one():
	var chapters := _nodes_by_chapter()
	var characters := _characters()
	for who in characters:
		var nodes := _appearance_nodes(characters[who], chapters)
		var remembered := {}
		for i in range(nodes.size()):
			var node: Dictionary = nodes[i]
			if i > 0:
				var recalls := false
				for variant in node.get("text_variants", []):
					if remembered.has(variant.get("requires_flag", "")):
						recalls = true
				assert_true(recalls,
					"%s at %s reads nothing an earlier appearance set - the player cannot tell they have met before"
					% [who, node.get("id", "?")])
			remembered.merge(_flags_set_by(node))

func test_every_character_keeps_one_face():
	var chapters := _nodes_by_chapter()
	var characters := _characters()
	for who in characters:
		var portrait = characters[who].get("portrait", null)
		for node in _appearance_nodes(characters[who], chapters):
			if portrait == null:
				assert_false(node.has("npc_portrait"),
					"%s has no portrait yet, so %s must not show one - a face in one chapter and none in the next reads as two people"
					% [who, node.get("id", "?")])
			else:
				assert_eq(str(node.get("npc_portrait", "")), str(portrait),
					"%s at %s shows the wrong face" % [who, node.get("id", "?")])

func test_nobody_recurs_without_being_declared():
	var chapters := _nodes_by_chapter()
	var seen_in := {}
	for chapter_id in chapters:
		for node_id in chapters[chapter_id]:
			var portrait = chapters[chapter_id][node_id].get("npc_portrait", null)
			if portrait == null:
				continue
			if not seen_in.has(portrait):
				seen_in[portrait] = {}
			seen_in[portrait][chapter_id] = true
	var declared := {}
	var characters := _characters()
	for who in characters:
		var portrait = characters[who].get("portrait", null)
		if portrait != null:
			declared[str(portrait)] = true
	for portrait in seen_in:
		if seen_in[portrait].size() >= 2:
			assert_true(declared.has(portrait),
				"%s appears in %d chapters but is not declared in recurring.json, so none of the rules above are being checked"
				% [portrait, seen_in[portrait].size()])
