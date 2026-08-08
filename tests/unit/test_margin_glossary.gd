extends GutTest

func test_has_entry_false_before_loading():
	var glossary := MarginGlossary.new()
	assert_false(glossary.has_entry("khwaja"))

func test_load_entries_then_has_and_get_entry():
	var glossary := MarginGlossary.new()
	glossary.load_entries({"khwaja": {"headword": "Khwaja", "definition": "A respectful address."}})
	assert_true(glossary.has_entry("khwaja"))
	assert_eq(glossary.get_entry("khwaja")["headword"], "Khwaja")

func test_get_entry_for_unknown_term_returns_empty_dict():
	var glossary := MarginGlossary.new()
	assert_eq(glossary.get_entry("nonexistent"), {})

func test_unlock_only_takes_effect_for_known_terms():
	var glossary := MarginGlossary.new()
	glossary.load_entries({"khwaja": {"headword": "Khwaja", "definition": "..."}})
	glossary.unlock("khwaja")
	glossary.unlock("nonexistent")
	assert_true(glossary.is_unlocked("khwaja"))
	assert_false(glossary.is_unlocked("nonexistent"))

func test_unlocked_term_ids_lists_only_unlocked_terms():
	var glossary := MarginGlossary.new()
	glossary.load_entries({
		"khwaja": {"headword": "Khwaja", "definition": "..."},
		"kunya": {"headword": "Kunya", "definition": "..."},
	})
	glossary.unlock("khwaja")
	assert_eq(glossary.unlocked_term_ids(), ["khwaja"])

func test_load_entries_merges_rather_than_replaces():
	var glossary := MarginGlossary.new()
	glossary.load_entries({"khwaja": {"headword": "Khwaja", "definition": "A respectful address."}})
	glossary.load_entries({"amid": {"headword": "Amid", "definition": "A Ghaznavid administrative title."}})
	assert_true(glossary.has_entry("khwaja"), "first load's entries must survive a second load")
	assert_true(glossary.has_entry("amid"), "second load's entries must also be present")
