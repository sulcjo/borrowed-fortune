extends GutTest

# A ratchet, not a target. These bounds may only be tightened as content earns it,
# never loosened to make a change pass. Update them in the same commit that earns
# them, so the numbers in git always describe the content in git.
#
# Baseline for reference, measured before any of this work: 43 flags set, 12 read,
# 31 dead, 15 gated conditions.
#
# Now: 96 set, 87 read, 9 dead, 96 gated. The 9 that remain fall into two groups:
#
#   - 5 are set by a node offering no alternative, so they fire on every playthrough.
#     A variant conditioned on one is the base text with extra ceremony. Excluded from
#     the ceiling below, because nothing useful can be done about them.
#   - 4 are the plunder ending's final self-knowledge flags, and they are the ceiling.
#
# Those 4 are dead by measurement but not by design, which is why this is the floor and
# not a task. Each is set on a choice that also routes to its own differently-written
# terminal node, so the player has already read the consequence in prose. A conditional
# outro caption keyed on one would restate a difference already delivered - extra prose,
# not extra possibility, which is the exact trade this file exists to refuse. Moving
# this below 4 means finding something the plunder outro can say that its four terminal
# nodes do not already say; until someone has that, the number stays.
#
# Nishapur's three were the opposite case and are now paid off: its terminal nodes have
# nothing after them at all, so the outro was the only place those flags could ever be
# read. See content/cutscenes/nishapur_outro.json.
const MAX_DEAD_PAYABLE_FLAGS := 4
const MIN_GATED_CONDITIONS := 96

# Nodes offering no decision at all - zero or one choice. 166 of 266 today, and the
# number that actually separates this game from the one it wants to be.
#
# Ratcheted as a count rather than a share on purpose: a share can be improved by
# adding good nodes, but this count can only fall by making an existing node a real
# decision. Twenty new single-choice nodes would raise it, which is exactly the
# padding this is here to catch. Yusuf's three appearances came down from one choice
# to two each without adding a single node; that is the move this measures.
#
# The count staying put while the total moves is the other shape of progress and the
# only one that adds material. The nine roads are the whole demonstration: 36 nodes
# added across the game, every one of them a decision, so this held at 166 while the
# total went 230 -> 266 and the share fell 72% -> 62%. A subsystem that cannot raise
# this number is a subsystem that cannot pad, which is why roads were built as four
# decisions each rather than as the scenery they could easily have been.
#
# The literal-"Continue." count is the cross-check, and it did not move either: 142
# before the roads and 142 after. Thirty-six new nodes, no new page-turns.
#
# What the number does not say, and should: 18 of these are terminal nodes, with zero
# choices because they end a chapter. Those can never be converted, so 18 is the real
# floor and the live pool is 148 - of which 142 offer a single choice whose text is
# literally "Continue.". The count is deliberately left inclusive of terminals anyway,
# because excluding them would drop it 166 -> 148 for no content work at all, which
# would read as progress in git history beside four PRs measured the old way.
#
# Not every one of the 148 should become a decision. Three kinds are false targets,
# and all three were found by trying:
#
#   - Nodes whose prose refuses one. n06_vow states outright that Farrukh "said the
#     words before he had decided to say them", and the timing choice already exists
#     upstream at n04_grave_question. A button there would contradict the sentence.
#   - Nodes whose immediate successor already offers the same beat as a choice. This
#     is the n06_vow trap one node forward rather than one node back, and Pushang is
#     full of it: n03_the_behdin_shopkeeper leads straight into n04_closing_early's
#     "Tell her you're sorry" / "Say nothing", and n06_two_names_one_people leads into
#     the identical pair at n06b_the_merchants_reasoning. herat_favor n12_rostams_boast
#     is the same shape - n12b_rostams_own_road already branches on whether to let
#     Rostam be seen as a person. Converting any of them buys the count a point and
#     asks the player the same question twice in a row. Check the successor's choices
#     before writing, not after.
#   - Nodes that set a flag currently counted as unconditional. Converting one makes
#     that flag conditional and therefore payable, so it breaks MAX_DEAD_PAYABLE_FLAGS
#     unless paid off in the same change - and since every choice on the node would
#     still set it, a variant keyed on it fires every playthrough, which is the
#     ceremony this file exists to refuse. n11a_nasuhs_farewell is the example.
#
# The targets worth having are the ones whose prose already names the road not taken:
# "the account-books that Farrukh noticed but did not ask about", "before he could
# offer any". Those had an alternative already written; they just had no button.
const MAX_NO_DECISION_NODES := 166

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

# Cutscene panels are gated with the same requires_flag / forbids_flag vocabulary as
# dialogue, so they read flags too. They have to be counted: an ending outro is the only
# place some flags can ever be read, because the chapter that sets them is terminal and
# has nothing after it. Scanning chapters alone reported those flags dead while they
# were the entire point of the outro.
func _all_cutscene_panels() -> Array:
	var panels: Array = []
	var dir := DirAccess.open("res://content/cutscenes")
	if dir == null:
		return panels
	for file_name in dir.get_files():
		if not file_name.ends_with(".json"):
			continue
		var file := FileAccess.open("res://content/cutscenes/%s" % file_name, FileAccess.READ)
		var parsed = JSON.parse_string(file.get_as_text())
		file.close()
		if parsed is Array:
			panels.append_array(parsed)
	return panels

func _measure() -> Dictionary:
	var set_flags := {}
	var read_flags := {}
	# A flag set by a node whose only choice sets it fires on every playthrough, so it
	# can never usefully gate anything: a variant conditioned on it is just the base
	# text with extra ceremony. Those are tracked apart from flags that some
	# playthroughs genuinely do not set.
	var unconditional := {}
	var gated := 0
	for node in _all_chapter_nodes():
		var alternatives: int = (node.get("choices", []) as Array).size()
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
				if alternatives <= 1:
					unconditional[flag_name] = true
			# A forgone_flag is set by the engine when a stay is spent, not by
			# effects.flags, so scanning effects alone missed it entirely - a hub could
			# have been authored with no payoffs at all and this ratchet would have
			# reported nothing. Count it as set, which is what it is.
			if choice.has("forgone_flag"):
				set_flags[choice["forgone_flag"]] = true
	for panel in _all_cutscene_panels():
		if panel.has("requires_flag"):
			read_flags[panel["requires_flag"]] = true
			gated += 1
		if panel.has("forbids_flag"):
			read_flags[panel["forbids_flag"]] = true
			gated += 1
	var dead := 0
	var dead_conditional := 0
	for flag_name in set_flags:
		if read_flags.has(flag_name):
			continue
		dead += 1
		if not unconditional.has(flag_name):
			dead_conditional += 1
	return {
		"set": set_flags.size(),
		"read": read_flags.size(),
		"dead": dead,
		"dead_conditional": dead_conditional,
		"gated": gated,
	}

func test_dead_flags_do_not_increase():
	# Bounds the flags that could actually be paid off. Unconditional ones are counted
	# and reported, but not ratcheted: nothing useful can be done about them, and
	# holding them against the ceiling would only invite pointless variants.
	var m := _measure()
	assert_lte(m["dead_conditional"], MAX_DEAD_PAYABLE_FLAGS,
		"%d payable flags are set and never read; the ratchet allows at most %d. Wire one up, or justify raising this." % [m["dead_conditional"], MAX_DEAD_PAYABLE_FLAGS])

func test_gated_conditions_do_not_decrease():
	var m := _measure()
	assert_gte(m["gated"], MIN_GATED_CONDITIONS,
		"only %d gated conditions remain; the ratchet requires at least %d" % [m["gated"], MIN_GATED_CONDITIONS])

func test_measurement_reports_the_current_numbers():
	# Not a quality assertion - it prints the figures so any run shows progress.
	var m := _measure()
	gut.p("flags set=%d read=%d dead=%d (payable %d) | gated conditions=%d" % [
		m["set"], m["read"], m["dead"], m["dead_conditional"], m["gated"]])
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
