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
