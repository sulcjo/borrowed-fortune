extends GutTest

func test_pure_metal_grams_multiplies_weight_by_purity():
	var coin := Coin.new(Coin.Metal.SILVER, 3.0, 0.9)
	assert_almost_eq(coin.pure_metal_grams(), 2.7, 0.0001)

func test_minted_dinar_uses_standard_gold_weight_at_full_purity():
	var dinar := Coin.minted_dinar()
	assert_eq(dinar.metal, Coin.Metal.GOLD)
	assert_almost_eq(dinar.actual_weight_grams, 4.25, 0.0001)
	assert_almost_eq(dinar.purity, 1.0, 0.0001)

func test_minted_dirham_uses_standard_silver_weight():
	var dirham := Coin.minted_dirham(0.85)
	assert_eq(dirham.metal, Coin.Metal.SILVER)
	assert_almost_eq(dirham.actual_weight_grams, 2.97, 0.0001)
	assert_almost_eq(dirham.purity, 0.85, 0.0001)

func test_to_dict_and_from_dict_round_trip():
	var original := Coin.new(Coin.Metal.GOLD, 4.1, 0.92)
	var restored := Coin.from_dict(original.to_dict())
	assert_eq(restored.metal, original.metal)
	assert_almost_eq(restored.actual_weight_grams, original.actual_weight_grams, 0.0001)
	assert_almost_eq(restored.purity, original.purity, 0.0001)
