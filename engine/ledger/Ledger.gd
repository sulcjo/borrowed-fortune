extends RefCounted
class_name Ledger

const GOLD_TO_SILVER_VALUE_RATIO := 14.2
const ZAKAT_RATE := 0.025
const USHR_RATE_FOR_MUSLIM_TRADER := 0.05
const USHR_RATE_FOR_NON_MUSLIM_TRADER := 0.10

var purse: Array[Coin] = []
var debts: Array[Debt] = []

func add_coin(coin: Coin) -> void:
	purse.append(coin)

func total_wealth_dirham_equivalent() -> float:
	var total := 0.0
	for coin in purse:
		if coin.metal == Coin.Metal.GOLD:
			var dinar_equivalent := coin.pure_metal_grams() / Coin.DINAR_NOMINAL_WEIGHT_GRAMS
			total += dinar_equivalent * GOLD_TO_SILVER_VALUE_RATIO
		else:
			total += coin.pure_metal_grams() / Coin.DIRHAM_NOMINAL_WEIGHT_GRAMS
	return total

func guarantee_debt_via_kafala(creditor_name: String, amount_dirham_equivalent: float) -> Debt:
	var debt := Debt.new(creditor_name, amount_dirham_equivalent, true)
	debts.append(debt)
	return debt

func total_debt_owed() -> float:
	var total := 0.0
	for debt in debts:
		total += debt.amount_dirham_equivalent
	return total

func pay_debt(debt: Debt, amount_dirham_equivalent: float) -> void:
	debt.amount_dirham_equivalent -= amount_dirham_equivalent
	if debt.amount_dirham_equivalent <= 0.0:
		debts.erase(debt)

func calculate_zakat(threshold_dirham_equivalent: float) -> float:
	var wealth := total_wealth_dirham_equivalent()
	if wealth <= threshold_dirham_equivalent:
		return 0.0
	return wealth * ZAKAT_RATE

func calculate_ushr(goods_value_dirham_equivalent: float, is_muslim_trader: bool) -> float:
	var rate := USHR_RATE_FOR_MUSLIM_TRADER if is_muslim_trader else USHR_RATE_FOR_NON_MUSLIM_TRADER
	return goods_value_dirham_equivalent * rate

func to_dict() -> Dictionary:
	var purse_data: Array = []
	for coin in purse:
		purse_data.append(coin.to_dict())
	var debts_data: Array = []
	for debt in debts:
		debts_data.append(debt.to_dict())
	return {"purse": purse_data, "debts": debts_data}

func load_from_dict(data: Dictionary) -> void:
	purse.clear()
	for coin_data in data.get("purse", []):
		purse.append(Coin.from_dict(coin_data))
	debts.clear()
	for debt_data in data.get("debts", []):
		debts.append(Debt.from_dict(debt_data))
