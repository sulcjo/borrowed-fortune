extends RefCounted
class_name MudarabaPartnership

var financier_name: String
var agent_name: String
var capital_dirham_equivalent: float
var agent_profit_share: float

func _init(p_financier_name: String, p_agent_name: String, p_capital_dirham_equivalent: float, p_agent_profit_share: float) -> void:
	financier_name = p_financier_name
	agent_name = p_agent_name
	capital_dirham_equivalent = p_capital_dirham_equivalent
	agent_profit_share = p_agent_profit_share

func settle(outcome_value_dirham_equivalent: float, agent_was_negligent: bool) -> Dictionary:
	var profit := outcome_value_dirham_equivalent - capital_dirham_equivalent
	if profit >= 0.0:
		var agent_share := profit * agent_profit_share
		return {
			"financier_result": capital_dirham_equivalent + (profit - agent_share),
			"agent_result": agent_share,
		}
	if agent_was_negligent:
		return {"financier_result": capital_dirham_equivalent, "agent_result": profit}
	return {"financier_result": outcome_value_dirham_equivalent, "agent_result": 0.0}
