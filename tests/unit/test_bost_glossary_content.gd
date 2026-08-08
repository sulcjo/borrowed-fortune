extends GutTest

const REQUIRED_TERM_IDS := ["sarraf", "jizya"]

func _load_glossary() -> MarginGlossary:
	var file := FileAccess.open("res://content/glossary/bost_terms.json", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	var glossary := MarginGlossary.new()
	glossary.load_entries(data)
	return glossary

func test_every_required_term_is_present_with_headword_and_definition():
	var glossary := _load_glossary()
	for term_id in REQUIRED_TERM_IDS:
		assert_true(glossary.has_entry(term_id), "missing glossary entry: %s" % term_id)
		var entry := glossary.get_entry(term_id)
		assert_true(entry.get("headword", "").length() > 0, "%s has an empty headword" % term_id)
		assert_true(entry.get("definition", "").length() > 0, "%s has an empty definition" % term_id)
