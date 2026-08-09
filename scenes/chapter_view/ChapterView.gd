extends Control

@onready var narration_label: RichTextLabel = $NarrationLabel
@onready var choices_container: VBoxContainer = $ChoicesContainer
@onready var margin_popup = $MarginPopup

var dialogue_engine: DialogueEngine = DialogueEngine.new()
var margin_glossary: MarginGlossary = MarginGlossary.new()
var ledger: Ledger = Ledger.new()
var reputation_tracker: ReputationTracker = ReputationTracker.new()
var save_manager: SaveManager = SaveManager.new()
var chapter_id: String = "chapter_00_prologue"
var next_chapter_id = null
var _manifest_path := "res://content/chapters/manifest.json"
# Chapter ids currently on the auto-transition call stack. _save_and_finish() ->
# load_chapter_by_id() -> load_chapter() -> _render_current_node() -> _save_and_finish()
# is re-entrant: a chapter that is already over the moment it loads (no choices at all, or
# every choice gated off by a flag the player lacks) transitions again from inside its own
# load, so a manifest cycle would otherwise recurse with no base case. Ids are recorded
# only for the duration of one chain and erased as it unwinds, so a chapter the player
# legitimately reaches again later in the session still loads normally.
var _auto_transition_chain_ids: Dictionary = {}

func _ready() -> void:
	narration_label.meta_clicked.connect(_on_narration_meta_clicked)

func load_chapter(dialogue_path: String, glossary_path: String) -> void:
	var dialogue_file := FileAccess.open(dialogue_path, FileAccess.READ)
	if dialogue_file == null:
		push_error("ChapterView: could not open dialogue file: %s" % dialogue_path)
		return
	var nodes = JSON.parse_string(dialogue_file.get_as_text())
	dialogue_file.close()
	if nodes == null or not (nodes is Array) or nodes.is_empty():
		push_error("ChapterView: dialogue file did not parse to a non-empty Array: %s" % dialogue_path)
		return

	var glossary_file := FileAccess.open(glossary_path, FileAccess.READ)
	if glossary_file == null:
		push_error("ChapterView: could not open glossary file: %s" % glossary_path)
		return
	var entries = JSON.parse_string(glossary_file.get_as_text())
	glossary_file.close()
	if entries == null:
		push_error("ChapterView: glossary file did not parse: %s" % glossary_path)
		return

	margin_glossary.load_entries(entries)
	dialogue_engine.load_tree(nodes, nodes[0]["id"])
	_render_current_node()

func load_chapter_by_id(id: String, manifest_path: String = "res://content/chapters/manifest.json") -> void:
	_manifest_path = manifest_path
	var manifest_file := FileAccess.open(manifest_path, FileAccess.READ)
	if manifest_file == null:
		push_error("ChapterView: could not open chapter manifest: %s" % manifest_path)
		return
	var manifest = JSON.parse_string(manifest_file.get_as_text())
	manifest_file.close()
	if manifest == null or not manifest.has(id):
		push_error("ChapterView: chapter id not found in manifest '%s': %s" % [manifest_path, id])
		return
	var entry: Dictionary = manifest[id]
	chapter_id = id
	next_chapter_id = entry.get("next_chapter_id", null)
	load_chapter(entry["dialogue_path"], entry["glossary_path"])

func save_path() -> String:
	return "user://borrowed_fortune_%s.json" % chapter_id

func _render_current_node() -> void:
	dialogue_engine.reputation = reputation_tracker.to_dict()
	var node := dialogue_engine.current_node()
	narration_label.text = GlossedTextParser.parse_to_bbcode(node.get("text", ""))

	for child in choices_container.get_children():
		child.queue_free()

	var choices := dialogue_engine.available_choices()
	for i in range(choices.size()):
		var button := Button.new()
		button.text = choices[i]["text"]
		button.pressed.connect(_on_choice_pressed.bind(i))
		choices_container.add_child(button)

	if dialogue_engine.is_chapter_end():
		_save_and_finish()

func _on_choice_pressed(choice_index: int) -> void:
	var effects := dialogue_engine.choose(choice_index)
	_apply_effects(effects)
	_render_current_node()

func _apply_effects(effects: Dictionary) -> void:
	for faction_id in effects.get("reputation", {}):
		# effects come from JSON, where all numbers parse as float - cast
		# explicitly since adjust_reputation's delta parameter is typed int.
		reputation_tracker.adjust_reputation(faction_id, int(effects["reputation"][faction_id]))
	for debt_data in effects.get("debts", []):
		ledger.guarantee_debt_via_kafala(debt_data["creditor_name"], debt_data["amount_dirham_equivalent"])
	if effects.has("coin_spent_dirham_equivalent"):
		ledger.spend_dirham_equivalent(effects["coin_spent_dirham_equivalent"])
	if effects.has("coin_gained_dirham_equivalent"):
		ledger.receive_dirham_equivalent(effects["coin_gained_dirham_equivalent"])

func _on_narration_meta_clicked(meta) -> void:
	var term_ids: Array = str(meta).split(",")
	var entries: Array = []
	for term_id in term_ids:
		margin_glossary.unlock(term_id)
		entries.append(margin_glossary.get_entry(term_id))
	margin_popup.show_entries(entries)

func _save_and_finish() -> void:
	var state := GameState.new()
	state.chapter_id = chapter_id
	state.dialogue_node_id = dialogue_engine.current_node_id
	state.dialogue_flags = dialogue_engine.flags
	state.reputation_data = reputation_tracker.to_dict()
	state.unlocked_glossary_terms = margin_glossary.unlocked_term_ids()
	state.ledger_data = ledger.to_dict()
	save_manager.save(state, save_path())
	# A terminal node may name its own next chapter (used when a chapter ends in more
	# than one place, e.g. a true story fork) - that wins over the chapter's manifest
	# default. Existing terminal nodes have no "next_chapter_id" key, so they fall
	# through to next_chapter_id unchanged. An explicit "next_chapter_id": null on the
	# node also wins over the fallback - it blocks the manifest's default entirely, even
	# a non-null one, so a node meant to defer to the manifest must omit the key, not set it to null.
	var resolved_next_chapter_id = dialogue_engine.current_node().get("next_chapter_id", next_chapter_id)
	if resolved_next_chapter_id == null:
		return
	if _auto_transition_chain_ids.has(resolved_next_chapter_id):
		push_error("ChapterView: chapter chain in '%s' loops back to '%s' (via the manifest or a terminal node's own next_chapter_id) without any player input in between; stopping the auto-transition chain" % [_manifest_path, resolved_next_chapter_id])
		return
	_auto_transition_chain_ids[resolved_next_chapter_id] = true
	load_chapter_by_id(resolved_next_chapter_id, _manifest_path)
	_auto_transition_chain_ids.erase(resolved_next_chapter_id)
