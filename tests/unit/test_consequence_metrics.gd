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
# Current, after three consequence threads and Merv's stay: 49 set, 23 read, 26 dead,
# 27 gated.
#
# Merv's hub added six flags - three that hide a taken opportunity, three recording
# what there was no time for - and `dead` did not move, because all six are read: the
# first three as forbids_flag, the other three by text_variants in Nishapur. That is
# what a hub should look like. A hub authored without payoffs will push `dead` up, and
# the fix is to write them, never to raise this ceiling.
# Four Teginabad and Bost threads were paid off in Farah, taking dead flags from 26
# to 22. That matters mechanically, not just cosmetically: the ceiling was 26 and the
# count was 26, so any new flag-setting content failed this test. Paying threads off
# is what buys room for the next hub or character arc.
const MAX_DEAD_FLAGS := 22
const MIN_GATED_CONDITIONS := 35

# Nodes offering no decision at all - zero or one choice. 172 of 230 today, and the
# number that actually separates this game from the one it wants to be.
#
# Ratcheted as a count rather than a share on purpose: a share can be improved by
# adding good nodes, but this count can only fall by making an existing node a real
# decision. Twenty new single-choice nodes would raise it, which is exactly the
# padding this is here to catch. Yusuf's three appearances came down from one choice
# to two each without adding a single node; that is the move this measures.
const MAX_NO_DECISION_NODES := 172

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
			# forbids_flag is a read too: it decides whether the choice is offered at
			# all. Counting only requires_* under-reported reads and would have called
			# a stay hub's opportunity flags dead while they were load-bearing.
			if choice.has("forbids_flag"):
				read_flags[choice["forbids_flag"]] = true
				gated += 1
			if choice.has("requires_reputation"):
				gated += 1
			for flag_name in choice.get("effects", {}).get("flags", []):
				set_flags[flag_name] = true
			# A forgone_flag is set by the engine when a stay is spent, not by
			# effects.flags, so scanning effects alone missed it entirely - a hub could
			# have been authored with no payoffs at all and this ratchet would have
			# reported nothing. Count it as set, which is what it is.
			if choice.has("forgone_flag"):
				set_flags[choice["forgone_flag"]] = true
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

func test_no_decision_nodes_do_not_increase():
	# The padding guard. A node with zero or one choice asks the player nothing, and
	# the cheapest way to grow this game has always been to add more of them.
	var no_decision := 0
	var total := 0
	for node in _all_chapter_nodes():
		total += 1
		if (node.get("choices", []) as Array).size() <= 1:
			no_decision += 1
	gut.p("no-decision nodes: %d of %d (%d%%)" % [no_decision, total, roundi(100.0 * no_decision / total)])
	assert_lte(no_decision, MAX_NO_DECISION_NODES,
		"%d nodes offer no decision; the ratchet allows at most %d. Turn one into a real choice rather than raising this." % [no_decision, MAX_NO_DECISION_NODES])
