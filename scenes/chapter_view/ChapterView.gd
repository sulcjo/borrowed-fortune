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

func _ready() -> void:
	narration_label.meta_clicked.connect(_on_narration_meta_clicked)

func load_chapter(dialogue_path: String, glossary_path: String) -> void:
	var dialogue_file := FileAccess.open(dialogue_path, FileAccess.READ)
	var nodes = JSON.parse_string(dialogue_file.get_as_text())
	dialogue_file.close()

	var glossary_file := FileAccess.open(glossary_path, FileAccess.READ)
	var entries = JSON.parse_string(glossary_file.get_as_text())
	glossary_file.close()

	margin_glossary.load_entries(entries)
	dialogue_engine.load_tree(nodes, nodes[0]["id"])
	_render_current_node()

func save_path() -> String:
	return "user://borrowed_fortune_%s.json" % chapter_id

func _render_current_node() -> void:
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
