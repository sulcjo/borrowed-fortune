extends RefCounted
class_name DialogueEngine

var current_node_id: String = ""
var flags: Dictionary = {}
var reputation: Dictionary = {}
# Named slots of time for this chapter's stay, supplied by ChapterView from the
# manifest entry. Empty for a chapter that declares no stay, which must behave
# exactly as it did before stays existed.
var slots: Array = []
var slot_index: int = 0
var _nodes_by_id: Dictionary = {}
# The last stay hub the player stood on. Needed because taking an opportunity moves
# current_node_id into that opportunity's branch, so by the time the final slot is
# spent the hub is no longer current and its untaken choices could not be found.
var _hub_node_id: String = ""

func load_tree(nodes: Array, start_id: String) -> void:
	var errors := validate_tree(nodes)
	assert(errors.is_empty(), "DialogueEngine: invalid node graph — " + ", ".join(errors))
	_nodes_by_id.clear()
	for node in nodes:
		_nodes_by_id[node["id"]] = node
	current_node_id = start_id

func validate_tree(nodes: Array) -> Array:
	var errors: Array = []
	var seen_ids: Dictionary = {}
	var known_ids: Dictionary = {}
	var hub_count := 0
	for node in nodes:
		known_ids[node["id"]] = true
	for node in nodes:
		var node_id: String = node["id"]
		if seen_ids.has(node_id):
			errors.append("duplicate node id '%s'" % node_id)
		seen_ids[node_id] = true
		var is_hub: bool = node.get("stay_hub", false)
		if is_hub:
			hub_count += 1
		var residual_bbcode := GlossedTextParser.parse_to_bbcode(node.get("text", ""))
		if residual_bbcode.contains("{{"):
			errors.append("node '%s' has an unparsed gloss token (check for a space after a comma in a multi-id token, or a malformed {{...}})" % node_id)
		for variant in node.get("text_variants", []):
			var variant_text = variant.get("text", null)
			if not (variant_text is String) or str(variant_text).strip_edges().is_empty():
				errors.append("node '%s' has a text_variant with no text" % node_id)
				continue
			if GlossedTextParser.parse_to_bbcode(variant_text).contains("{{"):
				errors.append("node '%s' has a text_variant with an unparsed gloss token" % node_id)
			var variant_reputation = variant.get("requires_reputation", null)
			if variant_reputation != null and not (variant_reputation is Dictionary and variant_reputation.get("faction_id") is String and (variant_reputation.get("min_score") is float or variant_reputation.get("min_score") is int)):
				errors.append("node '%s' has a text_variant with a malformed requires_reputation (needs a String faction_id and a numeric min_score)" % node_id)
		for choice in node.get("choices", []):
			var next_id = choice.get("next_id")
			if next_id != null and not known_ids.has(next_id):
				errors.append("node '%s' has a choice with dangling next_id '%s'" % [node_id, next_id])
			var requires_reputation = choice.get("requires_reputation", null)
			if requires_reputation != null and not (requires_reputation is Dictionary and requires_reputation.get("faction_id") is String and (requires_reputation.get("min_score") is float or requires_reputation.get("min_score") is int)):
				errors.append("node '%s' has a choice with a malformed requires_reputation (needs a String faction_id and a numeric min_score)" % node_id)
			if choice.get("forgone_flag", null) != null and choice.get("forbids_flag", null) == null:
				errors.append("node '%s' has a choice with a forgone_flag but no forbids_flag, so taking it could not be told from declining it" % node_id)
			if choice.get("spends_slot", false) and not is_hub:
				errors.append("node '%s' has a choice with spends_slot but the node is not a stay_hub" % node_id)
	if hub_count > 1:
		errors.append("chapter declares %d nodes with stay_hub; exactly one is allowed" % hub_count)
	return errors

func current_node() -> Dictionary:
	return _nodes_by_id.get(current_node_id, {})

# The current node's prose, with the first matching variant applied. Variants let a
# decision taken cities earlier change how a beat reads without duplicating the node.
# Array order is priority: the first variant whose conditions hold wins, and the
# node's own text is the unconditional fallback.
func current_text() -> String:
	var node := current_node()
	for variant in node.get("text_variants", []):
		if _conditions_met(variant):
			return str(variant.get("text", ""))
	return str(node.get("text", ""))

# The slot the stay is currently in, for display. Empty when the chapter declares no
# stay, and empty once the stay is spent.
func current_slot_name() -> String:
	if slot_index < 0 or slot_index >= slots.size():
		return ""
	return str(slots[slot_index])

# True once every slot has been spent. Always false where no stay is declared: a
# chapter without slots has no time to run out of.
func slots_spent() -> bool:
	return not slots.is_empty() and slot_index >= slots.size()

func available_choices() -> Array:
	var result: Array = []
	for choice in current_node().get("choices", []):
		if _choice_is_available(choice):
			result.append(choice)
	return result

func choose(choice_index: int) -> Dictionary:
	var choices := available_choices()
	if choice_index < 0 or choice_index >= choices.size():
		return {}
	var choice: Dictionary = choices[choice_index]
	var effects: Dictionary = choice.get("effects", {})
	for flag_name in effects.get("flags", []):
		flags[flag_name] = true
	if current_node().get("stay_hub", false):
		_hub_node_id = current_node_id
	var was_spent := slots_spent()
	if choice.get("spends_slot", false):
		slot_index += 1
	# Runs after the effects flags above, so the opportunity just taken already has
	# its forbids_flag set and is correctly excluded from the forgone sweep.
	if slots_spent() and not was_spent:
		_record_forgone_opportunities()
	# A stay can also run out of things to do while time remains - every opportunity
	# taken, with slots left over. Left alone the hub would offer nothing at all: the
	# opportunities hidden by their forbids_flag, the exit still hidden behind
	# requires_slots_spent. available_choices() would empty, is_chapter_end() would
	# fire, and the chapter would transition out of an unspent stay with the forgone
	# flags never written. Treat it as spent instead.
	if not slots_spent() and _hub_node_id != "" and not _hub_has_spendable_opportunity():
		slot_index = slots.size()
		_record_forgone_opportunities()
	current_node_id = choice["next_id"]
	return effects

# Whether the hub still offers anything that costs time. Uses _conditions_met rather
# than _choice_is_available because the latter vetoes every spends_slot choice once
# the stay is spent, which would make this trivially false at the wrong moment.
func _hub_has_spendable_opportunity() -> bool:
	var hub: Dictionary = _nodes_by_id.get(_hub_node_id, {})
	for choice in hub.get("choices", []):
		if choice.get("spends_slot", false) and _conditions_met(choice):
			return true
	return false

# Called once, on the transition that exhausts the stay. An opportunity counts as
# taken if the flag its forbids_flag watches is set - the same flag that hides it from
# the hub - so taken and forgone can never both be recorded for one opportunity.
func _record_forgone_opportunities() -> void:
	var hub: Dictionary = _nodes_by_id.get(_hub_node_id, {})
	for choice in hub.get("choices", []):
		var forgone_flag = choice.get("forgone_flag", null)
		if forgone_flag == null:
			continue
		var taken_flag = choice.get("forbids_flag", null)
		if taken_flag != null and flags.get(taken_flag, false):
			continue
		flags[forgone_flag] = true

func is_chapter_end() -> bool:
	return available_choices().is_empty()

func _choice_is_available(choice: Dictionary) -> bool:
	# You cannot spend time you no longer have. Without this an opportunity stays on
	# offer after the stay is exhausted - forbids_flag only hides one that was taken -
	# and taking it would push the slot index past the end of the stay.
	if choice.get("spends_slot", false) and slots_spent():
		return false
	return _conditions_met(choice)

# The flag half of the rule set, static so a scene that has flags but no engine can
# apply the same vocabulary. An ending cutscene is exactly that: it reads a finished
# save off disk and has no dialogue tree, no reputation, and no stay - but it must
# read requires_flag and forbids_flag identically, or content authored for one would
# quietly mean something else in the other.
static func flag_conditions_met(condition_holder: Dictionary, flag_state: Dictionary) -> bool:
	var requires_flag = condition_holder.get("requires_flag", null)
	if requires_flag != null and not flag_state.get(requires_flag, false):
		return false
	var forbids_flag = condition_holder.get("forbids_flag", null)
	if forbids_flag != null and flag_state.get(forbids_flag, false):
		return false
	return true

# Shared by choices and text variants so both apply exactly one rule set rather than
# two implementations that drift apart.
func _conditions_met(condition_holder: Dictionary) -> bool:
	if not flag_conditions_met(condition_holder, flags):
		return false
	var requires_reputation = condition_holder.get("requires_reputation", null)
	if requires_reputation != null:
		var faction_id: String = requires_reputation["faction_id"]
		var min_score: int = int(requires_reputation["min_score"])
		if reputation.get(faction_id, 0) < min_score:
			return false
	if condition_holder.get("requires_slots_spent", false) and not slots_spent():
		return false
	return true
