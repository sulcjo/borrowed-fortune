extends GutTest

# A ratchet, not a target. These bounds may only be tightened as threads are
# authored - never loosened to make a change pass.
#
# Measured on 6173b5f, before any delayed-consequences work: 43 flags set, 12 read,
# 31 dead, 15 gated conditions. Node count is deliberately not tracked: the cheapest
# way to grow it is more single-choice nodes, which is what this codebase already
# over-produces, so it makes a bad goal.
#
# Update these downward (dead) and upward (gated) in the same commit that earns it,
# so the numbers in git always describe the content in git.
# Current, after the first three threads: 43 set, 17 read, 26 dead, 20 gated.
#
# Stays are covered by this too, even though adding the machinery moved nothing: the
# fixture stay lives in tests/, and _all_chapter_nodes() reads only content/. The
# first *real* city to get a hub will push `dead` up, because every forgone_flag is a
# flag that is set. That is expected pressure, not a broken ratchet - the fix is to
# pay some of those flags off with text_variants, never to raise the ceiling.
const MAX_DEAD_FLAGS := 26
const MIN_GATED_CONDITIONS := 20

func _all_chapter_nodes() -> Array:
	var nodes: Array = []
	var chapters := DirAccess.open("res://content/chapters")
	assert_not_null(chapters, "cannot open res://content/chapters")
	for chapter in chapters.get_directories():
		var dir := DirAccess.open("res://content/chapters/%s" % chapter)
		for file_name in dir.get_files():
			if not file_name.ends_with(".json"):
				continue
			var file := FileAccess.open("res://content/chapters/%s/%s" % [chapter, file_name], FileAccess.READ)
			var parsed = JSON.parse_string(file.get_as_text())
			file.close()
			if parsed is Array:
				nodes.append_array(parsed)
	return nodes

func _measure() -> Dictionary:
	var set_flags := {}
	var read_flags := {}
	var gated := 0
	for node in _all_chapter_nodes():
		# Variants are readers too - that is the whole point of this work.
		for variant in node.get("text_variants", []):
			if variant.has("requires_flag"):
				read_flags[variant["requires_flag"]] = true
				gated += 1
			if variant.has("requires_reputation"):
				gated += 1
		for choice in node.get("choices", []):
			if choice.has("requires_flag"):
				read_flags[choice["requires_flag"]] = true
				gated += 1
			if choice.has("requires_reputation"):
				gated += 1
			for flag_name in choice.get("effects", {}).get("flags", []):
				set_flags[flag_name] = true
	var dead := 0
	for flag_name in set_flags:
		if not read_flags.has(flag_name):
			dead += 1
	return {"set": set_flags.size(), "read": read_flags.size(), "dead": dead, "gated": gated}

func test_dead_flags_do_not_increase():
	var m := _measure()
	assert_lte(m["dead"], MAX_DEAD_FLAGS,
		"%d flags are set and never read; the ratchet allows at most %d. Wire one up, or justify raising this." % [m["dead"], MAX_DEAD_FLAGS])

func test_gated_conditions_do_not_decrease():
	var m := _measure()
	assert_gte(m["gated"], MIN_GATED_CONDITIONS,
		"only %d gated conditions remain; the ratchet requires at least %d" % [m["gated"], MIN_GATED_CONDITIONS])

func test_measurement_reports_the_current_numbers():
	# Not a quality assertion - it prints the figures so any run shows progress.
	var m := _measure()
	gut.p("flags set=%d read=%d dead=%d | gated conditions=%d" % [m["set"], m["read"], m["dead"], m["gated"]])
	assert_gt(m["set"], 0, "no flags found at all - has the content layout moved?")
