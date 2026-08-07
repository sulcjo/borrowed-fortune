extends GutTest

func test_settle_splits_profit_by_agreed_share():
	var partnership := MudarabaPartnership.new("financier", "agent", 100.0, 0.3)
	var result := partnership.settle(150.0, false)
	# profit = 50; agent gets 30% of profit = 15; financier gets capital + rest = 135
	assert_almost_eq(result["agent_result"], 15.0, 0.0001)
	assert_almost_eq(result["financier_result"], 135.0, 0.0001)

func test_settle_on_loss_without_negligence_puts_loss_on_financier_alone():
	var partnership := MudarabaPartnership.new("financier", "agent", 100.0, 0.3)
	var result := partnership.settle(60.0, false)
	assert_almost_eq(result["financier_result"], 60.0, 0.0001)
	assert_almost_eq(result["agent_result"], 0.0, 0.0001)

func test_settle_on_loss_with_negligence_shifts_loss_to_agent():
	var partnership := MudarabaPartnership.new("financier", "agent", 100.0, 0.3)
	var result := partnership.settle(60.0, true)
	assert_almost_eq(result["financier_result"], 100.0, 0.0001)
	assert_almost_eq(result["agent_result"], -40.0, 0.0001)

func test_suftaja_starts_unredeemed():
	var suftaja := Suftaja.new("Ghazni", "Rayy", 340.0)
	assert_false(suftaja.is_redeemed)

func test_redeem_returns_face_value_and_marks_redeemed():
	var suftaja := Suftaja.new("Ghazni", "Rayy", 340.0)
	var paid_out := suftaja.redeem()
	assert_almost_eq(paid_out, 340.0, 0.0001)
	assert_true(suftaja.is_redeemed)
