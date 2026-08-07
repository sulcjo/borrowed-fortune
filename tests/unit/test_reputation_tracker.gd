extends GutTest

func test_unknown_faction_starts_at_zero():
	var tracker := ReputationTracker.new()
	assert_eq(tracker.get_reputation("trading_families"), 0)

func test_adjust_reputation_accumulates():
	var tracker := ReputationTracker.new()
	tracker.adjust_reputation("trading_families", 2)
	tracker.adjust_reputation("trading_families", 1)
	assert_eq(tracker.get_reputation("trading_families"), 3)

func test_adjust_reputation_can_go_negative():
	var tracker := ReputationTracker.new()
	tracker.adjust_reputation("ghaznavid_officials", -3)
	assert_eq(tracker.get_reputation("ghaznavid_officials"), -3)

func test_meets_threshold_true_when_score_at_or_above():
	var tracker := ReputationTracker.new()
	tracker.adjust_reputation("townsfolk", 5)
	assert_true(tracker.meets_threshold("townsfolk", 5))
	assert_true(tracker.meets_threshold("townsfolk", 3))

func test_meets_threshold_false_when_score_below():
	var tracker := ReputationTracker.new()
	tracker.adjust_reputation("townsfolk", 2)
	assert_false(tracker.meets_threshold("townsfolk", 5))

func test_to_dict_and_load_from_dict_round_trip():
	var original := ReputationTracker.new()
	original.adjust_reputation("hidden_network", -1)
	var restored := ReputationTracker.new()
	restored.load_from_dict(original.to_dict())
	assert_eq(restored.get_reputation("hidden_network"), -1)
