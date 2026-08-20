extends GutTest

func test_parse_to_bbcode_wraps_a_single_gloss_token():
	var result := GlossedTextParser.parse_to_bbcode("Hello {{khwaja|Khwaja}} sir.")
	assert_eq(result, "Hello [url=khwaja]Khwaja[/url] sir.")

func test_parse_to_bbcode_handles_multiple_tokens_in_one_string():
	var result := GlossedTextParser.parse_to_bbcode("{{ghusl|Ghusl}} then {{kafan|kafan}}.")
	assert_eq(result, "[url=ghusl]Ghusl[/url] then [url=kafan]kafan[/url].")

func test_parse_to_bbcode_leaves_plain_text_untouched():
	var result := GlossedTextParser.parse_to_bbcode("No glosses here.")
	assert_eq(result, "No glosses here.")

func test_extract_term_ids_returns_all_ids_in_order_without_duplicates():
	var ids := GlossedTextParser.extract_term_ids("{{khwaja|Khwaja Abu Farrukh}} ... {{ghusl|ghusl}}")
	assert_eq(ids, ["khwaja", "ghusl"])

func test_extract_term_ids_splits_multi_id_tokens():
	var ids := GlossedTextParser.extract_term_ids("{{khwaja,kunya|Khwaja Abu Farrukh}}")
	assert_eq(ids, ["khwaja", "kunya"])

func test_parse_to_marked_bbcode_colours_the_term_instead_of_linking_it():
	var marked := GlossedTextParser.parse_to_marked_bbcode(
		"He paid the {{dallal|dallal}} his cut.", Color("#7a1f14")
	)
	assert_false(marked.contains("[url"), "must not produce a link affordance")
	assert_eq(marked, "He paid the [color=#7a1f14]dallal[/color] his cut.")

func test_parse_to_marked_bbcode_handles_multi_term_tokens():
	var marked := GlossedTextParser.parse_to_marked_bbcode(
		"held as {{dallal,amana|a broker's trust}}", Color("#7a1f14")
	)
	assert_eq(marked, "held as [color=#7a1f14]a broker's trust[/color]")

func test_parse_to_marked_bbcode_leaves_unglossed_prose_untouched():
	assert_eq(GlossedTextParser.parse_to_marked_bbcode("Plain prose.", Color("#7a1f14")), "Plain prose.")

func test_parse_to_bbcode_still_produces_links_for_any_other_caller():
	# The original function is unchanged; only ChapterView switches away from it.
	assert_true(GlossedTextParser.parse_to_bbcode("a {{dallal|dallal}}").contains("[url=dallal]"))
