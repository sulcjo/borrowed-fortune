extends GutTest

func _load_dialogue(path: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	var nodes = JSON.parse_string(file.get_as_text())
	file.close()
	return nodes

func _portrait_for(nodes: Array, node_id: String):
	for node in nodes:
		if node["id"] == node_id:
			return node.get("npc_portrait", null)
	fail_test("no node with id '%s' found" % node_id)
	return null

func test_prologue_portrait_keys_are_correct():
	var nodes := _load_dialogue("res://content/chapters/chapter_00_prologue/prologue.json")
	assert_eq(_portrait_for(nodes, "n08_nasuh_ledger"), "nasuh")
	assert_eq(_portrait_for(nodes, "n11_ostad_comfort"), "ostad")
	assert_null(_portrait_for(nodes, "n01_naming"), "the opening node has no NPC on-page yet")

func test_farah_switches_portrait_from_umm_kavus_to_tahir():
	var nodes := _load_dialogue("res://content/chapters/chapter_03_farah/farah.json")
	assert_eq(_portrait_for(nodes, "n08_umm_kavus_introduced"), "ummkavus")
	assert_eq(_portrait_for(nodes, "n15b_finding_tahir"), "tahir")
	assert_eq(_portrait_for(nodes, "n18b_the_favor_owed"), "tahir")

func test_pushang_has_three_distinct_unlabeled_npc_portraits():
	var nodes := _load_dialogue("res://content/chapters/chapter_06_pushang/pushang.json")
	assert_eq(_portrait_for(nodes, "n03_the_behdin_shopkeeper"), "behdinshopkeeper")
	assert_eq(_portrait_for(nodes, "n05_the_tarsa_merchant"), "tarsamerchant")
	assert_eq(_portrait_for(nodes, "n06b_the_merchants_reasoning"), "tarsamerchant")
	assert_eq(_portrait_for(nodes, "n09_the_officers_demand"), "pushanggateofficer")

func test_herat_4a_ardashir_portrait_covers_the_full_exchange_including_side_branches():
	var nodes := _load_dialogue("res://content/chapters/chapter_04a_herat/herat.json")
	assert_eq(_portrait_for(nodes, "n06_ardashir_introduced"), "ardashir")
	assert_eq(_portrait_for(nodes, "n08b_argued_the_discount"), "ardashir")
	assert_eq(_portrait_for(nodes, "n19b_the_full_truth"), "ardashir")
	assert_null(_portrait_for(nodes, "n03a_the_old_soldier"), "background-mention figure, not on the roster")
	assert_null(_portrait_for(nodes, "n21_departure_herat"), "Ardashir is no longer on-page by departure")

func test_herat_favors_reflective_aside_has_no_portrait():
	var nodes := _load_dialogue("res://content/chapters/chapter_04b_herat_favor/herat_favor.json")
	assert_null(_portrait_for(nodes, "n13_the_weight_of_knowing"))
	assert_eq(_portrait_for(nodes, "n09b_pushing_for_more"), "rostam")
	assert_eq(_portrait_for(nodes, "n12_rostams_boast"), "rostam")
	assert_null(_portrait_for(nodes, "n17a_departure_bound"))

func test_sarakhs_and_nishapur_portrait_keys_are_correct():
	var sarakhs_nodes := _load_dialogue("res://content/chapters/chapter_07_sarakhs/sarakhs.json")
	assert_eq(_portrait_for(sarakhs_nodes, "n05_bahram_the_gatekeeper"), "bahram")
	assert_eq(_portrait_for(sarakhs_nodes, "n08_the_commanders_charge"), "bahram")

	var nishapur_nodes := _load_dialogue("res://content/chapters/chapter_08_nishapur/nishapur.json")
	assert_eq(_portrait_for(nishapur_nodes, "n06_the_khaneqah_at_dusk"), "teacher")
	assert_eq(_portrait_for(nishapur_nodes, "n07_nobody_son_of_nobody"), "teacher")

func test_farrukh_wear_stage_is_set_on_every_manifest_chapter():
	var manifest_file := FileAccess.open("res://content/chapters/manifest.json", FileAccess.READ)
	var manifest = JSON.parse_string(manifest_file.get_as_text())
	manifest_file.close()

	var expected_stages := {
		"chapter_00_prologue": 1, "chapter_01_teginabad": 1, "chapter_02_bost": 1,
		"chapter_03_farah": 2, "chapter_04a_herat": 2, "chapter_04b_herat_favor": 2,
		"chapter_05_plunder_ending": 3, "chapter_06_pushang": 2, "chapter_07_sarakhs": 3,
		"chapter_07b_merv": 3, "chapter_08_nishapur": 3,
	}
	for chapter_id in expected_stages:
		assert_true(manifest.has(chapter_id), "manifest is missing expected chapter '%s'" % chapter_id)
		assert_eq(manifest[chapter_id].get("farrukh_wear_stage", null), expected_stages[chapter_id],
			"chapter '%s' has the wrong farrukh_wear_stage" % chapter_id)

func test_teginabad_provisioner_portrait_is_set_on_both_haggle_nodes():
	var nodes := _load_dialogue("res://content/chapters/chapter_01_teginabad/teginabad.json")
	assert_eq(_portrait_for(nodes, "n10_the_provisioner"), "teginabadprovisioner")
	assert_eq(_portrait_for(nodes, "n11_provisioner_pushback"), "teginabadprovisioner")
	assert_eq(_portrait_for(nodes, "n11b_the_provisioners_stake"), "teginabadprovisioner")
	assert_null(_portrait_for(nodes, "n12_departure_provisioned"), "Farrukh is alone again by departure")
