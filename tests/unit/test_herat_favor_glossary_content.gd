extends GutTest

func test_herat_favor_glossary_has_the_two_expected_terms_with_headword_and_definition():
	var file := FileAccess.open("res://content/glossary/herat_favor_terms.json", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()

	var expected_ids := ["sikka", "muhtasib"]
	assert_eq(data.keys().size(), expected_ids.size())
	for term_id in expected_ids:
		assert_true(data.has(term_id), "missing glossary term '%s'" % term_id)
		assert_true(data[term_id].has("headword"))
		assert_true(data[term_id].has("definition"))
		assert_false(data[term_id]["headword"].is_empty())
		assert_false(data[term_id]["definition"].is_empty())
