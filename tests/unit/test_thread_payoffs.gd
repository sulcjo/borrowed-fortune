extends GutTest

# One test per delayed-consequence thread, in one file because the threads span six
# chapters and belong to none of them.
#
# Conditional text is invisible in the node graph: nothing in a chapter's structure
# shows that a decision three cities back changes how a beat reads. Without a test per
# thread an unrelated edit removes one and no failure follows. That makes this file the
# thing keeping the threads alive, not a formality.

# flag -> [chapter dialogue path, node id]
const THREADS := {
	"haggled_at_teginabad":
		["res://content/chapters/chapter_03_farah/farah.json", "n07_arrival_at_the_caravanserai"],
	"chose_tahirs_price":
		["res://content/chapters/chapter_04b_herat_favor/herat_favor.json", "n02_the_bundle_and_the_favor"],
	"chose_umm_kavus_channel":
		["res://content/chapters/chapter_04a_herat/herat.json", "n06_ardashir_introduced"],
	"asked_about_the_mints_delay":
		["res://content/chapters/chapter_07_sarakhs/sarakhs.json", "n04a_the_treasurys_long_reach"],
	"full_network_reveal":
		["res://content/chapters/chapter_08_nishapur/nishapur.json", "n05e_why_his_father"],
	"partial_network_reveal":
		["res://content/chapters/chapter_08_nishapur/nishapur.json", "n05e_why_his_father"],
	"hid_the_rayy_paper_more_carefully":
		["res://content/chapters/chapter_06_pushang/pushang.json", "n10c_refused"],
	"asked_about_the_khutba":
		["res://content/chapters/chapter_08_nishapur/nishapur.json", "n06_the_khaneqah_at_dusk"],
	"accepted_the_charge_for_payment":
		["res://content/chapters/chapter_08_nishapur/nishapur.json", "n05a_bahrams_family"],
	"learned_of_arranged_ghulam_marriages":
		["res://content/chapters/chapter_08_nishapur/nishapur.json", "n04x_the_unspent_favor"],
}

func _nodes(path: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	return data

func _text(path: String, node_id: String, flags: Dictionary) -> String:
	var engine := DialogueEngine.new()
	engine.flags = flags
	engine.load_tree(_nodes(path), node_id)
	return engine.current_text()

func test_every_thread_changes_the_text_at_its_payoff_site():
	for flag in THREADS:
		var path: String = THREADS[flag][0]
		var node_id: String = THREADS[flag][1]
		var neutral := _text(path, node_id, {})
		var carried := _text(path, node_id, {flag: true})
		assert_ne(carried, neutral, "%s must change %s" % [flag, node_id])

func test_every_payoff_keeps_the_base_reading_intact():
	# A variant extends the beat; it must not rewrite what was already there, or the
	# two readings drift apart as the prose is edited.
	for flag in THREADS:
		var path: String = THREADS[flag][0]
		var node_id: String = THREADS[flag][1]
		var neutral := _text(path, node_id, {})
		var carried := _text(path, node_id, {flag: true})
		assert_true(carried.begins_with(neutral),
			"%s should extend %s rather than replace its opening" % [flag, node_id])

func test_no_payoff_changes_what_is_on_offer():
	# A variant changes what a moment means, never what happens next.
	for flag in THREADS:
		var path: String = THREADS[flag][0]
		var node_id: String = THREADS[flag][1]
		var plain := DialogueEngine.new()
		plain.load_tree(_nodes(path), node_id)
		var baseline := plain.available_choices().size()

		var flagged := DialogueEngine.new()
		flagged.flags[flag] = true
		flagged.load_tree(_nodes(path), node_id)
		assert_eq(flagged.available_choices().size(), baseline,
			"%s must not alter the choices at %s" % [flag, node_id])

func test_the_two_network_reveals_are_distinguishable():
	# Both land on the same node, so first-match ordering decides which wins. They must
	# read differently or the distinction between knowing half and knowing all is lost.
	var path: String = THREADS["full_network_reveal"][0]
	var node_id: String = THREADS["full_network_reveal"][1]
	var full := _text(path, node_id, {"full_network_reveal": true})
	var partial := _text(path, node_id, {"partial_network_reveal": true})
	assert_ne(full, partial)

func test_no_payable_flag_is_left_unread():
	# The point of the batch: every flag that could be paid off, was. Flags with
	# nothing downstream, or set on every playthrough, are excluded - see
	# test_consequence_metrics.gd, which ratchets the same figure.
	var engine := DialogueEngine.new()
	assert_not_null(engine, "sanity")
	for flag in THREADS:
		var path: String = THREADS[flag][0]
		var found := false
		for node in _nodes(path):
			for variant in node.get("text_variants", []):
				if variant.get("requires_flag") == flag:
					found = true
		assert_true(found, "%s should be read by a variant in %s" % [flag, path])
