extends GutTest

func test_constructor_defaults_kafala_flag_to_false():
	var debt := Debt.new("Ibrahim al-Sarraf", 100.0)
	assert_eq(debt.creditor_name, "Ibrahim al-Sarraf")
	assert_almost_eq(debt.amount_dirham_equivalent, 100.0, 0.0001)
	assert_false(debt.is_guaranteed_by_kafala)

func test_constructor_accepts_explicit_kafala_flag():
	var debt := Debt.new("Rukn ibn Faramarz", 50.0, true)
	assert_true(debt.is_guaranteed_by_kafala)

func test_to_dict_and_from_dict_round_trip():
	var original := Debt.new("Nasuh", 60.0, true)
	var restored := Debt.from_dict(original.to_dict())
	assert_eq(restored.creditor_name, original.creditor_name)
	assert_almost_eq(restored.amount_dirham_equivalent, original.amount_dirham_equivalent, 0.0001)
	assert_eq(restored.is_guaranteed_by_kafala, original.is_guaranteed_by_kafala)
