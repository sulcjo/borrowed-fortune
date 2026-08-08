extends PanelContainer

signal close_requested

@onready var margin_rich_text_label: RichTextLabel = $MarginRichTextLabel

func show_entries(entries: Array) -> void:
	var lines: Array = []
	for entry in entries:
		lines.append("[b]%s[/b]\n%s" % [entry.get("headword", ""), entry.get("definition", "")])
	margin_rich_text_label.text = "\n\n".join(lines)
	visible = true

func _on_close_button_pressed() -> void:
	visible = false
	close_requested.emit()
