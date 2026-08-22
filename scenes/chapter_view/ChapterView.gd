extends Control

# Preloaded by path rather than reached through their global class_name. Class-name
# registration lives in .godot/global_script_class_cache.cfg, which is gitignored, so
# any checkout whose cache predates these two classes fails to parse this script -
# and because the script then fails to load, the scene falls back to a plain Control
# and Main.gd dies on a missing resume(). preload() resolves at parse time and needs
# no cache, so the game runs straight after a pull with no editor rescan.
const FolioMetricsScript := preload("res://engine/theme/FolioMetrics.gd")
const ThemeConstants := preload("res://engine/theme/BorrowedFortuneTheme.gd")
const TextureLoaderScript := preload("res://engine/assets/TextureLoader.gd")

const _PAGE := "Folio/FolioMargin/Page"

@onready var narration_label: RichTextLabel = get_node("%s/TextColumn/HeadBlock/NarrationLabel" % _PAGE)
@onready var choices_container: VBoxContainer = get_node("%s/TextColumn/ChoicesContainer" % _PAGE)
@onready var colophon: Label = get_node("%s/TextColumn/Colophon" % _PAGE)
@onready var place_inset: TextureRect = get_node("%s/TextColumn/HeadBlock/PlaceInset" % _PAGE)
@onready var npc_roundel: Panel = get_node("%s/MarginColumn/NpcRoundel" % _PAGE)
@onready var npc_portrait: TextureRect = get_node("%s/MarginColumn/NpcRoundel/NpcPortrait" % _PAGE)
@onready var farrukh_roundel: Panel = get_node("%s/MarginColumn/FarrukhRoundel" % _PAGE)
@onready var farrukh_portrait: TextureRect = get_node("%s/MarginColumn/FarrukhRoundel/FarrukhPortrait" % _PAGE)
@onready var head_spacer: Control = get_node("%s/TextColumn/HeadBlock/HeadSpacer" % _PAGE)
@onready var gloss_notes: VBoxContainer = get_node("%s/MarginColumn/GlossNotes" % _PAGE)

var dialogue_engine: DialogueEngine = DialogueEngine.new()
var margin_glossary: MarginGlossary = MarginGlossary.new()
var ledger: Ledger = Ledger.new()
var reputation_tracker: ReputationTracker = ReputationTracker.new()
var save_manager: SaveManager = SaveManager.new()
var chapter_id: String = "chapter_00_prologue"
# The city this chapter is set in, shown at the head of the colophon. Empty when
# the manifest entry names none, in which case the colophon starts at the coin.
var place_name: String = ""
var next_chapter_id = null
var post_ending_cutscene_path = null
var farrukh_wear_stage: int = 1
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
	# Sizing depends on container rects, which do not exist yet when the first render
	# runs out of Main._ready(): the containers report small-but-nonzero sizes at that
	# point, so measuring then produces garbage. Recompute once at the end of this
	# frame, before anything is drawn, and again whenever the window changes.
	#
	# Safe against feedback: this Control is anchored to the window, so changing a
	# descendant's minimum size cannot change our own size and cannot re-fire resized.
	resized.connect(_resize_place_inset)
	call_deferred("_resize_place_inset")

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
	post_ending_cutscene_path = entry.get("post_ending_cutscene_path", null)
	# JSON.parse_string() parses all numbers as float, same reason _apply_effects()
	# already casts reputation deltas explicitly - farrukh_wear_stage must be int
	# for the "farrukh_stage_%d" format string in _update_portraits() below.
	farrukh_wear_stage = int(entry.get("farrukh_wear_stage", 1))
	place_name = str(entry.get("place_name", ""))
	# Slots are content, read from the manifest rather than saved, so renaming a
	# chapter's slots does not invalidate an existing save. resume() restores the
	# index after this call, because this resets it.
	var stay: Dictionary = entry.get("stay", {})
	dialogue_engine.slots = stay.get("slots", [])
	dialogue_engine.slot_index = 0
	load_chapter(entry["dialogue_path"], entry["glossary_path"])

func save_path() -> String:
	return "user://borrowed_fortune_%s.json" % chapter_id

func _render_current_node() -> void:
	dialogue_engine.reputation = reputation_tracker.to_dict()
	_update_colophon()
	_update_place_inset()
	_update_portraits()
	# current_text() applies any matching text_variant, so a decision taken cities
	# earlier can change how this beat reads.
	narration_label.text = GlossedTextParser.parse_to_marked_bbcode(
		dialogue_engine.current_text(), ThemeConstants.RUBRIC_RED
	)
	_update_gloss_notes()

	# Detach before freeing, for the same reason as the gloss notes below: a queued
	# free is not applied until the end of the frame, so re-rendering twice within one
	# frame would otherwise leave the previous node's choices still counted here.
	for child in choices_container.get_children():
		choices_container.remove_child(child)
		child.queue_free()

	var choices := dialogue_engine.available_choices()
	for i in range(choices.size()):
		var button := Button.new()
		button.text = choices[i]["text"]
		# Rubricated lines written down the page rather than filled boxes on it.
		button.theme_type_variation = &"Rubric"
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_on_choice_pressed.bind(i))
		choices_container.add_child(button)

	if dialogue_engine.is_chapter_end():
		_save_and_finish()

func _update_colophon() -> void:
	# total_wealth_dirham_equivalent() is -spent_dirham_equivalent, which is exactly
	# 0.0 (i.e. IEEE754 negative zero) before any spend/gain - normalize it so the
	# readout shows "0.0" rather than the technically-correct but confusing "-0.0".
	var wealth := ledger.total_wealth_dirham_equivalent()
	if wealth == 0.0:
		wealth = 0.0
	var parts: Array[String] = []
	if place_name != "":
		# "Nishapur, the next morning" while a stay is in progress; just the place
		# otherwise, and once the stay is spent.
		var slot_name := dialogue_engine.current_slot_name()
		parts.append(place_name if slot_name == "" else "%s, %s" % [place_name, slot_name])
	parts.append("Coin: %.1f dirham" % wealth)
	var debt := ledger.total_debt_owed()
	if debt > 0.0:
		parts.append("Debt owed: %.1f dirham" % debt)
	for faction_id in reputation_tracker.to_dict():
		parts.append("%s: %+d" % [String(faction_id).capitalize(), reputation_tracker.get_reputation(faction_id)])
	colophon.text = " · ".join(parts)

# Average character width and line height for the narration font, derived from the
# theme's RichTextLabel normal_font_size of 22 in EB Garamond. Passed into
# FolioMetrics as plain numbers so engine/ stays free of scene-tree types.
const _NARRATION_CHAR_WIDTH := 10.0
const _NARRATION_LINE_HEIGHT := 31.0
const _HEAD_BLOCK_GUTTER := 12.0

func _update_place_inset() -> void:
	place_inset.texture = _load_place_texture()
	_resize_place_inset()

func _load_place_texture() -> Texture2D:
	return TextureLoaderScript.load_texture("res://assets/backgrounds/%s.png" % chapter_id)

# Dimensions are parameters rather than measurements so this is testable without a
# rendered frame: in a headless run container layout never happens and every
# measured rect is zero. The live scene passes nothing and gets the measured values.
func _resize_place_inset(available_width: float = -1.0, available_height: float = -1.0) -> void:
	if available_width < 0.0:
		available_width = _measured_available_width()
	if available_height < 0.0:
		available_height = _measured_available_height()

	# Width the inset claims, gutter included. Zero when the chapter has no art.
	var inset_claim := 0.0
	if place_inset.texture == null:
		place_inset.custom_minimum_size = Vector2.ZERO
	else:
		var character_count: int = str(dialogue_engine.current_node().get("text", "")).length()
		var scale := FolioMetricsScript.choose_place_scale(
			character_count,
			available_width,
			available_height,
			_HEAD_BLOCK_GUTTER,
			_NARRATION_CHAR_WIDTH,
			_NARRATION_LINE_HEIGHT
		)
		place_inset.custom_minimum_size = Vector2(
			FolioMetricsScript.PLACE_BASE_WIDTH * scale,
			FolioMetricsScript.PLACE_BASE_HEIGHT * scale
		)
		inset_claim = place_inset.custom_minimum_size.x + _HEAD_BLOCK_GUTTER

	# The prose expands into whatever the inset and this spacer leave, so its own
	# minimum width stays zero and it can never inflate the page's minimum. On a wide
	# page the spacer holds back the surplus and the measure stops at the cap.
	#
	# Assign whole Vector2s, never custom_minimum_size.x on its own: writing to one
	# component of a value-type property goes to a temporary copy and is silently
	# discarded.
	narration_label.custom_minimum_size = Vector2.ZERO
	head_spacer.custom_minimum_size = Vector2(
		FolioMetricsScript.spacer_reserve(available_width, inset_claim), 0.0
	)

func _measured_available_width() -> float:
	# Measure HeadBlock itself rather than deriving its width from the page. Deriving
	# it as page-minus-margin-column silently dropped the Page container's own
	# separation, handing the prose 20px more than existed - enough to push the folio's
	# minimum width past the window and make each pass drift wider than the last.
	# HeadBlock's rect is exactly the space the inset, gutter and prose must share.
	var head_block: Control = get_node("%s/TextColumn/HeadBlock" % _PAGE)
	var width := head_block.size.x
	# Before layout has run this is meaningless; the deferred pass in _ready() and the
	# resized handler recompute once real rects exist.
	return width if width > 0.0 else float(FolioMetricsScript.NARRATION_MAX_WIDTH)

func _measured_available_height() -> float:
	var head_block: Control = get_node("%s/TextColumn/HeadBlock" % _PAGE)
	return head_block.size.y if head_block.size.y > 0.0 else float(FolioMetricsScript.PLACE_BASE_HEIGHT)

func _update_portraits() -> void:
	var npc_id = dialogue_engine.current_node().get("npc_portrait", null)
	npc_portrait.texture = _load_portrait_texture(npc_id)
	npc_roundel.visible = npc_portrait.texture != null
	farrukh_portrait.texture = _load_portrait_texture("farrukh_stage_%d" % farrukh_wear_stage)
	farrukh_roundel.visible = farrukh_portrait.texture != null

func _load_portrait_texture(portrait_id) -> Texture2D:
	if portrait_id == null:
		return null
	return TextureLoaderScript.load_texture("res://assets/portraits/%s.png" % portrait_id)

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
	if effects.has("debt_repaid"):
		var repayment: Dictionary = effects["debt_repaid"]
		var matched_debt: Debt = null
		for debt in ledger.debts:
			if debt.creditor_name == repayment["creditor_name"]:
				matched_debt = debt
				break
		assert(matched_debt != null, "debt_repaid effect references unknown creditor '%s'" % repayment["creditor_name"])
		ledger.pay_debt(matched_debt, repayment["amount_dirham_equivalent"])
		ledger.spend_dirham_equivalent(repayment["amount_dirham_equivalent"])
	if effects.has("coin_spent_dirham_equivalent"):
		ledger.spend_dirham_equivalent(effects["coin_spent_dirham_equivalent"])
	if effects.has("coin_gained_dirham_equivalent"):
		ledger.receive_dirham_equivalent(effects["coin_gained_dirham_equivalent"])
	if effects.has("mudaraba_settlement"):
		var venture: Dictionary = effects["mudaraba_settlement"]
		assert(venture.has("financier_name"), "mudaraba_settlement effect is missing required key 'financier_name'")
		assert(venture.has("agent_name"), "mudaraba_settlement effect is missing required key 'agent_name'")
		assert(venture.has("capital_dirham_equivalent"), "mudaraba_settlement effect is missing required key 'capital_dirham_equivalent'")
		assert(venture.has("agent_profit_share"), "mudaraba_settlement effect is missing required key 'agent_profit_share'")
		assert(venture.has("outcome_value_dirham_equivalent"), "mudaraba_settlement effect is missing required key 'outcome_value_dirham_equivalent'")
		assert(venture.has("agent_was_negligent"), "mudaraba_settlement effect is missing required key 'agent_was_negligent'")
		var partnership := MudarabaPartnership.new(
			venture["financier_name"],
			venture["agent_name"],
			venture["capital_dirham_equivalent"],
			venture["agent_profit_share"]
		)
		var result := partnership.settle(venture["outcome_value_dirham_equivalent"], venture["agent_was_negligent"])
		var agent_result: float = result["agent_result"]
		if agent_result > 0.0:
			ledger.receive_dirham_equivalent(agent_result)
		elif agent_result < 0.0:
			ledger.spend_dirham_equivalent(-agent_result)

func _update_gloss_notes() -> void:
	# queue_free() alone defers removal to the end of the frame, so the old notes would
	# still be counted by anything that re-reads the container in the same frame.
	# Detaching first makes the clear immediate; the queued free still reclaims it.
	for child in gloss_notes.get_children():
		gloss_notes.remove_child(child)
		child.queue_free()
	# Must be the resolved text, not the node's base text: a term glossed only inside
	# an active variant still needs its margin note.
	var raw_text: String = dialogue_engine.current_text()
	for term_id in GlossedTextParser.extract_term_ids(raw_text):
		if not margin_glossary.has_entry(term_id):
			continue
		# Unlocking is kept for save-format compatibility: unlocked_term_ids() is still
		# written into GameState by _save_and_finish().
		margin_glossary.unlock(term_id)
		var entry: Dictionary = margin_glossary.get_entry(term_id)
		var note := Label.new()
		note.theme_type_variation = &"GlossNote"
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.text = "%s — %s" % [entry.get("headword", term_id), entry.get("definition", "")]
		gloss_notes.add_child(note)

func _save_and_finish() -> void:
	var state := GameState.new()
	state.chapter_id = chapter_id
	state.dialogue_node_id = dialogue_engine.current_node_id
	state.dialogue_flags = dialogue_engine.flags
	state.reputation_data = reputation_tracker.to_dict()
	state.unlocked_glossary_terms = margin_glossary.unlocked_term_ids()
	state.ledger_data = ledger.to_dict()
	state.slot_index = dialogue_engine.slot_index
	save_manager.save(state, save_path())
	# A terminal node may name its own next chapter (used when a chapter ends in more
	# than one place, e.g. a true story fork) - that wins over the chapter's manifest
	# default. Existing terminal nodes have no "next_chapter_id" key, so they fall
	# through to next_chapter_id unchanged. An explicit "next_chapter_id": null on the
	# node also wins over the fallback - it blocks the manifest's default entirely, even
	# a non-null one, so a node meant to defer to the manifest must omit the key, not set it to null.
	var resolved_next_chapter_id = dialogue_engine.current_node().get("next_chapter_id", next_chapter_id)
	_write_current_chapter_pointer(resolved_next_chapter_id, state)
	if resolved_next_chapter_id == null:
		if post_ending_cutscene_path != null:
			get_tree().change_scene_to_file(post_ending_cutscene_path)
		return
	if _auto_transition_chain_ids.has(resolved_next_chapter_id):
		push_error("ChapterView: chapter chain in '%s' loops back to '%s' (via the manifest or a terminal node's own next_chapter_id) without any player input in between; stopping the auto-transition chain" % [_manifest_path, resolved_next_chapter_id])
		return
	_auto_transition_chain_ids[resolved_next_chapter_id] = true
	load_chapter_by_id(resolved_next_chapter_id, _manifest_path)
	_auto_transition_chain_ids.erase(resolved_next_chapter_id)

func _write_current_chapter_pointer(next_id, state: GameState) -> void:
	var pointer_path := "user://borrowed_fortune_current_chapter.json"
	if next_id == null:
		if FileAccess.file_exists(pointer_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(pointer_path))
		return
	var pointer_data := state.to_dict()
	pointer_data["chapter_id"] = next_id
	# The pointer means "start here next", so it must carry no in-chapter progress:
	# it is written with the finishing chapter's state and only chapter_id is
	# retargeted. Left alone, the next chapter's stay would begin already spent.
	pointer_data["slot_index"] = 0
	var file := FileAccess.open(pointer_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(pointer_data))
	file.close()

func resume(id: String, state_data: Dictionary) -> void:
	if state_data.has("reputation_data"):
		reputation_tracker.load_from_dict(state_data["reputation_data"])
	if state_data.has("ledger_data"):
		ledger.load_from_dict(state_data["ledger_data"])
	if state_data.has("dialogue_flags"):
		dialogue_engine.flags = state_data["dialogue_flags"]
	load_chapter_by_id(id)
	# slot_index is deliberately not restored. Resuming is chapter-granular - it always
	# starts at the chapter's first node - so honouring an in-chapter index would put
	# the player in the opening scene of a city with its days already spent. The field
	# is still saved, for a future mid-chapter resume that would restore the node too.
