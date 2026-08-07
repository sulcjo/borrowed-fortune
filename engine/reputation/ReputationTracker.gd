extends RefCounted
class_name ReputationTracker

var _scores: Dictionary = {}

func get_reputation(faction_id: String) -> int:
	return _scores.get(faction_id, 0)

func adjust_reputation(faction_id: String, delta: int) -> void:
	_scores[faction_id] = get_reputation(faction_id) + delta

func meets_threshold(faction_id: String, threshold: int) -> bool:
	return get_reputation(faction_id) >= threshold

func to_dict() -> Dictionary:
	return _scores.duplicate()

func load_from_dict(data: Dictionary) -> void:
	_scores = data.duplicate()
