extends RefCounted
class_name Debt

var creditor_name: String
var amount_dirham_equivalent: float
var is_guaranteed_by_kafala: bool

func _init(p_creditor_name: String, p_amount_dirham_equivalent: float, p_is_guaranteed_by_kafala: bool = false) -> void:
	creditor_name = p_creditor_name
	amount_dirham_equivalent = p_amount_dirham_equivalent
	is_guaranteed_by_kafala = p_is_guaranteed_by_kafala

func to_dict() -> Dictionary:
	return {
		"creditor_name": creditor_name,
		"amount_dirham_equivalent": amount_dirham_equivalent,
		"is_guaranteed_by_kafala": is_guaranteed_by_kafala,
	}

static func from_dict(data: Dictionary) -> Debt:
	return Debt.new(data["creditor_name"], data["amount_dirham_equivalent"], data["is_guaranteed_by_kafala"])
