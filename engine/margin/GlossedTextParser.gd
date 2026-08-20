extends RefCounted
class_name GlossedTextParser

static func _token_regex() -> RegEx:
	var regex := RegEx.new()
	regex.compile("\\{\\{([\\w,]+)\\|([^}]+)\\}\\}")
	return regex

static func parse_to_bbcode(raw_text: String) -> String:
	var regex := _token_regex()
	var result := raw_text
	for match_result in regex.search_all(raw_text):
		var term_ids: String = match_result.get_string(1)
		var display_text: String = match_result.get_string(2)
		var token: String = match_result.get_string(0)
		result = result.replace(token, "[url=%s]%s[/url]" % [term_ids, display_text])
	return result

# Same tokens as parse_to_bbcode(), but marked with colour rather than wrapped in
# [url]. ChapterView shows glosses permanently in the folio margin, so a link there
# would be an affordance with nothing behind it.
static func parse_to_marked_bbcode(raw_text: String, mark_color: Color) -> String:
	var regex := _token_regex()
	var result := raw_text
	var mark_hex := "#" + mark_color.to_html(false)
	for match_result in regex.search_all(raw_text):
		var display_text: String = match_result.get_string(2)
		var token: String = match_result.get_string(0)
		result = result.replace(token, "[color=%s]%s[/color]" % [mark_hex, display_text])
	return result

static func extract_term_ids(raw_text: String) -> Array:
	var regex := _token_regex()
	var ids: Array = []
	for match_result in regex.search_all(raw_text):
		for term_id in match_result.get_string(1).split(","):
			if not ids.has(term_id):
				ids.append(term_id)
	return ids
