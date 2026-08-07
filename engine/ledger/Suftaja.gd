extends RefCounted
class_name Suftaja

var issuing_city: String
var redeeming_city: String
var face_value_dirham_equivalent: float
var is_redeemed: bool = false

func _init(p_issuing_city: String, p_redeeming_city: String, p_face_value_dirham_equivalent: float) -> void:
	issuing_city = p_issuing_city
	redeeming_city = p_redeeming_city
	face_value_dirham_equivalent = p_face_value_dirham_equivalent

func redeem() -> float:
	is_redeemed = true
	return face_value_dirham_equivalent
