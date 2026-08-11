extends GutTest

func _route_data() -> Dictionary:
	return {
		"display_names": {
			"chapter_00_prologue": "Ghazni",
			"chapter_01_teginabad": "Teginabad",
			"chapter_02_bost": "Bost",
			"chapter_03_farah": "Farah",
			"chapter_04a_herat": "Herat",
			"chapter_04b_herat_favor": "Herat",
			"chapter_06_pushang": "Pushang",
			"chapter_07_sarakhs": "Sarakhs",
			"chapter_07b_merv": "Merv",
			"chapter_08_nishapur": "Nishapur",
			"chapter_05_plunder_ending": "Plunder",
		},
		"shared_prefix": [
			"chapter_00_prologue",
			"chapter_01_teginabad",
			"chapter_02_bost",
			"chapter_03_farah",
		],
		"fork": {
			"main": "chapter_04a_herat",
			"favor": "chapter_04b_herat_favor",
		},
		"main_suffix": [
			"chapter_06_pushang",
			"chapter_07_sarakhs",
			{"chapter_id": "chapter_07b_merv", "optional": true},
			"chapter_08_nishapur",
		],
		"favor_suffix": [
			"chapter_05_plunder_ending",
		],
	}

func _chapter_ids(waypoints: Array) -> Array:
	var ids: Array = []
	for waypoint in waypoints:
		ids.append(waypoint["chapter_id"])
	return ids

func test_prefix_only_preview_before_fork_resolves():
	var builder := JourneyMapBuilder.new()
	var visited := {"chapter_00_prologue": true, "chapter_01_teginabad": true}
	var waypoints := builder.build_waypoints(_route_data(), visited, "chapter_02_bost")

	assert_eq(waypoints.size(), 4)
	assert_eq(_chapter_ids(waypoints), ["chapter_00_prologue", "chapter_01_teginabad", "chapter_02_bost", "chapter_03_farah"])
	assert_eq(waypoints[0]["status"], "visited")
	assert_eq(waypoints[2]["status"], "current")
	assert_eq(waypoints[3]["status"], "unvisited")

func test_main_route_resolution_walks_main_suffix_and_flags_nishapur_as_ending():
	var builder := JourneyMapBuilder.new()
	var visited := {
		"chapter_00_prologue": true, "chapter_01_teginabad": true, "chapter_02_bost": true, "chapter_03_farah": true,
		"chapter_04a_herat": true, "chapter_06_pushang": true,
	}
	var waypoints := builder.build_waypoints(_route_data(), visited, "chapter_07_sarakhs")

	assert_eq(_chapter_ids(waypoints), [
		"chapter_00_prologue", "chapter_01_teginabad", "chapter_02_bost", "chapter_03_farah",
		"chapter_04a_herat", "chapter_06_pushang", "chapter_07_sarakhs", "chapter_08_nishapur",
	])
	assert_eq(waypoints[6]["status"], "current")
	var nishapur = waypoints[7]
	assert_eq(nishapur["status"], "unvisited")
	assert_true(nishapur["is_ending"])

func test_favor_route_resolution_never_shows_main_suffix_and_flags_plunder_as_ending():
	var builder := JourneyMapBuilder.new()
	var visited := {
		"chapter_00_prologue": true, "chapter_01_teginabad": true, "chapter_02_bost": true, "chapter_03_farah": true,
		"chapter_04b_herat_favor": true, "chapter_05_plunder_ending": true,
	}
	var waypoints := builder.build_waypoints(_route_data(), visited, "")

	assert_eq(_chapter_ids(waypoints), [
		"chapter_00_prologue", "chapter_01_teginabad", "chapter_02_bost", "chapter_03_farah",
		"chapter_04b_herat_favor", "chapter_05_plunder_ending",
	])
	var ids := _chapter_ids(waypoints)
	for chapter_id in ["chapter_04a_herat", "chapter_06_pushang", "chapter_07_sarakhs", "chapter_07b_merv", "chapter_08_nishapur"]:
		assert_false(ids.has(chapter_id))
	var plunder = waypoints[5]
	assert_eq(plunder["status"], "visited")
	assert_true(plunder["is_ending"])

func test_merv_appears_when_visited():
	var builder := JourneyMapBuilder.new()
	var visited := {
		"chapter_00_prologue": true, "chapter_01_teginabad": true, "chapter_02_bost": true, "chapter_03_farah": true,
		"chapter_04a_herat": true, "chapter_06_pushang": true, "chapter_07_sarakhs": true, "chapter_07b_merv": true,
	}
	var waypoints := builder.build_waypoints(_route_data(), visited, "chapter_08_nishapur")

	assert_eq(_chapter_ids(waypoints), [
		"chapter_00_prologue", "chapter_01_teginabad", "chapter_02_bost", "chapter_03_farah",
		"chapter_04a_herat", "chapter_06_pushang", "chapter_07_sarakhs", "chapter_07b_merv", "chapter_08_nishapur",
	])
	assert_eq(waypoints[7]["status"], "visited")
	assert_eq(waypoints[8]["status"], "current")

func test_merv_skipped_silently_without_stopping_the_walk():
	var builder := JourneyMapBuilder.new()
	var visited := {
		"chapter_00_prologue": true, "chapter_01_teginabad": true, "chapter_02_bost": true, "chapter_03_farah": true,
		"chapter_04a_herat": true, "chapter_06_pushang": true, "chapter_07_sarakhs": true,
	}
	var waypoints := builder.build_waypoints(_route_data(), visited, "chapter_08_nishapur")

	assert_eq(_chapter_ids(waypoints), [
		"chapter_00_prologue", "chapter_01_teginabad", "chapter_02_bost", "chapter_03_farah",
		"chapter_04a_herat", "chapter_06_pushang", "chapter_07_sarakhs", "chapter_08_nishapur",
	])
	assert_false(_chapter_ids(waypoints).has("chapter_07b_merv"))
	assert_eq(waypoints[7]["status"], "current")

func test_finished_game_with_no_current_chapter_marks_nothing_as_current():
	var builder := JourneyMapBuilder.new()
	var visited := {
		"chapter_00_prologue": true, "chapter_01_teginabad": true, "chapter_02_bost": true, "chapter_03_farah": true,
		"chapter_04a_herat": true, "chapter_06_pushang": true, "chapter_07_sarakhs": true, "chapter_08_nishapur": true,
	}
	var waypoints := builder.build_waypoints(_route_data(), visited, "")

	for waypoint in waypoints:
		assert_ne(waypoint["status"], "current")
	assert_eq(waypoints[7]["chapter_id"], "chapter_08_nishapur")
	assert_eq(waypoints[7]["status"], "visited")
	assert_true(waypoints[7]["is_ending"])

func test_all_chapter_ids_returns_every_id_across_both_routes():
	var builder := JourneyMapBuilder.new()
	var ids := builder.all_chapter_ids(_route_data())
	assert_eq(ids.size(), 11)
	for expected_id in [
		"chapter_00_prologue", "chapter_01_teginabad", "chapter_02_bost", "chapter_03_farah",
		"chapter_04a_herat", "chapter_04b_herat_favor",
		"chapter_06_pushang", "chapter_07_sarakhs", "chapter_07b_merv", "chapter_08_nishapur",
		"chapter_05_plunder_ending",
	]:
		assert_true(ids.has(expected_id), "missing %s" % expected_id)
