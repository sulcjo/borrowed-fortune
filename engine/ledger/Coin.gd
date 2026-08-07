extends RefCounted
class_name Coin

enum Metal { GOLD, SILVER }

const DINAR_NOMINAL_WEIGHT_GRAMS := 4.25
const DIRHAM_NOMINAL_WEIGHT_GRAMS := 2.97

var metal: int
var actual_weight_grams: float
var purity: float

func _init(p_metal: int, p_actual_weight_grams: float, p_purity: float) -> void:
	metal = p_metal
	actual_weight_grams = p_actual_weight_grams
	purity = p_purity

func pure_metal_grams() -> float:
	return actual_weight_grams * purity

func to_dict() -> Dictionary:
	return {
		"metal": metal,
		"actual_weight_grams": actual_weight_grams,
		"purity": purity,
	}

static func from_dict(data: Dictionary) -> Coin:
	return Coin.new(data["metal"], data["actual_weight_grams"], data["purity"])

static func minted_dinar(purity: float = 1.0) -> Coin:
	return Coin.new(Coin.Metal.GOLD, DINAR_NOMINAL_WEIGHT_GRAMS, purity)

static func minted_dirham(purity: float = 1.0) -> Coin:
	return Coin.new(Coin.Metal.SILVER, DIRHAM_NOMINAL_WEIGHT_GRAMS, purity)
