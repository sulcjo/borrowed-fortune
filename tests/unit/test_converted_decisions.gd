extends GutTest

# Page-turns that became real decisions.
#
# The payoffs these create are checked with every other thread in
# test_thread_payoffs.gd. What is asserted here is the conversion itself, and above all
# the invariant that made it safe to do: choice index 0 keeps the next_id and the empty
# effects it was authored with, and the alternative is appended at index 1.
#
# That is not a style preference. Several chapters are covered by tests that walk them
# by pressing 0 repeatedly and assert on the nodes reached and the effects returned - a
# conversion that inserted its new option first, or moved a flag onto index 0, would
# shift those walks silently. Asserting it here means the next conversion cannot get it
# wrong without a failure pointing at the reason.

const CONVERTED := {
	# node id -> [chapter path, the next_id both choices lead to, the new flag]
	"n11_ostad_comfort": [
		"res://content/chapters/chapter_00_prologue/prologue.json",
		"n11a_nasuhs_farewell", "refused_the_ostads_comfort",
	],
	"n11b_the_provisioners_stake": [
		"res://content/chapters/chapter_01_teginabad/teginabad.json",
		"n11d_yusuf_at_teginabad", "overpaid_the_provisioner",
	],
	"n02_seeking_the_sarraf": [
		"res://content/chapters/chapter_02_bost/bost.json",
		"n02b_the_ordinary_business", "asked_mihran_about_his_books",
	],
}

func _node(path: String, node_id: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	var nodes = JSON.parse_string(file.get_as_text())
	file.close()
	for node in nodes:
		if node["id"] == node_id:
			return node
	return {}

func test_each_converted_node_now_offers_a_real_decision():
	for node_id in CONVERTED:
		var node := _node(CONVERTED[node_id][0], node_id)
		assert_eq((node.get("choices", []) as Array).size(), 2,
			"%s should offer two options" % node_id)

func test_the_original_option_stays_at_index_zero_with_no_effects():
	# The safety invariant. If this fails, an index-0 walk somewhere else has moved.
	for node_id in CONVERTED:
		var node := _node(CONVERTED[node_id][0], node_id)
		var first: Dictionary = node["choices"][0]
		assert_eq(first.get("next_id"), CONVERTED[node_id][1],
			"%s index 0 must still lead where it always led" % node_id)
		assert_eq(first.get("effects", {}).get("flags", []), [],
			"%s index 0 must not have gained flags - baseline walks assert on its effects" % node_id)

func test_the_new_option_is_the_one_that_records_the_choice():
	for node_id in CONVERTED:
		var node := _node(CONVERTED[node_id][0], node_id)
		var second: Dictionary = node["choices"][1]
		var flags: Array = second.get("effects", {}).get("flags", [])
		assert_true(flags.has(CONVERTED[node_id][2]),
			"%s index 1 should set %s" % [node_id, CONVERTED[node_id][2]])

func test_neither_option_changes_where_the_chapter_goes():
	# These are decisions about what kind of man makes them, not forks in the road.
	# Both options land on the same node, so no chapter needed restructuring.
	for node_id in CONVERTED:
		var node := _node(CONVERTED[node_id][0], node_id)
		var expected: String = CONVERTED[node_id][1]
		for choice in node["choices"]:
			assert_eq(choice.get("next_id"), expected,
				"%s should not branch the route" % node_id)

func test_no_converted_option_still_reads_as_a_page_turn():
	# The point was to replace "Continue." with two things a player can mean.
	for node_id in CONVERTED:
		var node := _node(CONVERTED[node_id][0], node_id)
		for choice in node["choices"]:
			assert_ne(choice["text"], "Continue.",
				"%s still offers a page-turn" % node_id)

func test_paying_the_provisioner_more_actually_costs_something():
	# Otherwise it is free virtue rather than a decision. The game models coin, so the
	# generous option spends it.
	var node := _node(CONVERTED["n11b_the_provisioners_stake"][0], "n11b_the_provisioners_stake")
	var effects: Dictionary = node["choices"][1]["effects"]
	assert_gt(float(effects.get("coin_spent_dirham_equivalent", 0.0)), 0.0,
		"overpaying her should spend real coin")

func test_both_options_remain_available_whatever_the_player_has_done():
	# None of the three is gated, so the decision is always actually offered.
	for node_id in CONVERTED:
		var engine := DialogueEngine.new()
		var file := FileAccess.open(CONVERTED[node_id][0], FileAccess.READ)
		var nodes = JSON.parse_string(file.get_as_text())
		file.close()
		engine.load_tree(nodes, node_id)
		assert_eq(engine.available_choices().size(), 2,
			"%s should offer both options with no flags set" % node_id)
