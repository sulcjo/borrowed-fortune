extends GutTest

func test_total_wealth_sums_silver_coins_directly():
	var ledger := Ledger.new()
	ledger.add_coin(Coin.new(Coin.Metal.SILVER, 8.91, 1.0))
	ledger.add_coin(Coin.new(Coin.Metal.SILVER, 5.94, 0.5))
	assert_almost_eq(ledger.total_wealth_dirham_equivalent(), 4.0, 0.0001)

func test_total_wealth_converts_gold_via_exchange_rate():
	var ledger := Ledger.new()
	ledger.add_coin(Coin.new(Coin.Metal.GOLD, 4.25, 1.0))
	assert_almost_eq(ledger.total_wealth_dirham_equivalent(), Ledger.GOLD_TO_SILVER_VALUE_RATIO, 0.0001)

func test_empty_purse_has_zero_wealth():
	var ledger := Ledger.new()
	assert_almost_eq(ledger.total_wealth_dirham_equivalent(), 0.0, 0.0001)

func test_guarantee_debt_via_kafala_creates_a_flagged_debt():
	var ledger := Ledger.new()
	var debt := ledger.guarantee_debt_via_kafala("Ibrahim al-Sarraf", 340.0)
	assert_true(debt.is_guaranteed_by_kafala)
	assert_eq(ledger.debts.size(), 1)
	assert_eq(ledger.debts[0], debt)

func test_total_debt_owed_sums_all_debts():
	var ledger := Ledger.new()
	ledger.guarantee_debt_via_kafala("Ibrahim al-Sarraf", 340.0)
	ledger.guarantee_debt_via_kafala("Rukn ibn Faramarz", 210.0)
	assert_almost_eq(ledger.total_debt_owed(), 550.0, 0.0001)

func test_pay_debt_reduces_remaining_amount():
	var ledger := Ledger.new()
	var debt := ledger.guarantee_debt_via_kafala("Nasuh", 60.0)
	ledger.pay_debt(debt, 20.0)
	assert_almost_eq(debt.amount_dirham_equivalent, 40.0, 0.0001)
	assert_eq(ledger.debts.size(), 1)

func test_pay_debt_in_full_removes_it_from_the_ledger():
	var ledger := Ledger.new()
	var debt := ledger.guarantee_debt_via_kafala("Nasuh", 60.0)
	ledger.pay_debt(debt, 60.0)
	assert_eq(ledger.debts.size(), 0)

func test_zakat_is_zero_below_threshold():
	var ledger := Ledger.new()
	ledger.add_coin(Coin.new(Coin.Metal.SILVER, 10.0, 1.0))
	assert_almost_eq(ledger.calculate_zakat(50.0), 0.0, 0.0001)

func test_zakat_is_two_and_a_half_percent_above_threshold():
	var ledger := Ledger.new()
	ledger.add_coin(Coin.new(Coin.Metal.SILVER, 297.0, 1.0))
	assert_almost_eq(ledger.calculate_zakat(50.0), 2.5, 0.0001)

func test_ushr_for_muslim_trader_is_five_percent():
	var ledger := Ledger.new()
	assert_almost_eq(ledger.calculate_ushr(200.0, true), 10.0, 0.0001)

func test_ushr_for_non_muslim_trader_is_ten_percent():
	var ledger := Ledger.new()
	assert_almost_eq(ledger.calculate_ushr(200.0, false), 20.0, 0.0001)

func test_to_dict_and_from_dict_round_trip_purse_and_debts():
	var original := Ledger.new()
	original.add_coin(Coin.new(Coin.Metal.SILVER, 3.0, 0.9))
	original.guarantee_debt_via_kafala("Ibrahim al-Sarraf", 340.0)

	var restored := Ledger.new()
	restored.load_from_dict(original.to_dict())

	assert_eq(restored.purse.size(), 1)
	assert_almost_eq(restored.purse[0].actual_weight_grams, 3.0, 0.0001)
	assert_eq(restored.debts.size(), 1)
	assert_eq(restored.debts[0].creditor_name, "Ibrahim al-Sarraf")
	assert_almost_eq(restored.debts[0].amount_dirham_equivalent, 340.0, 0.0001)

func test_total_wealth_uses_dirham_count_not_gram_weight():
	var ledger := Ledger.new()
	ledger.add_coin(Coin.minted_dirham(1.0))
	assert_almost_eq(ledger.total_wealth_dirham_equivalent(), 1.0, 0.0001)

func test_spend_dirham_equivalent_reduces_total_wealth():
	var ledger := Ledger.new()
	ledger.add_coin(Coin.minted_dirham(1.0))
	ledger.spend_dirham_equivalent(0.4)
	assert_almost_eq(ledger.total_wealth_dirham_equivalent(), 0.6, 0.0001)

func test_spend_dirham_equivalent_accumulates_across_multiple_calls():
	var ledger := Ledger.new()
	ledger.spend_dirham_equivalent(15.0)
	ledger.spend_dirham_equivalent(6.0)
	assert_almost_eq(ledger.total_wealth_dirham_equivalent(), -21.0, 0.0001)

func test_to_dict_and_from_dict_round_trip_spent_dirham_equivalent():
	var original := Ledger.new()
	original.spend_dirham_equivalent(9.0)

	var restored := Ledger.new()
	restored.load_from_dict(original.to_dict())

	assert_almost_eq(restored.spent_dirham_equivalent, 9.0, 0.0001)
	assert_almost_eq(restored.total_wealth_dirham_equivalent(), -9.0, 0.0001)
