extends RefCounted

# Walking a chapter in a test, without hardcoding how long the chapter is.
#
# Every navigation test in this suite used to say "press 0 nine times, now assert you
# are at n10". That reads as precision and is actually a liability: the 9 is not a fact
# about the route, it is a fact about how many nodes happened to sit in front of it on
# the day the test was written. Insert one beat of prose - which this project does
# constantly, and should - and the test lands one node short and fails, having found
# nothing wrong. Twenty-two of them were red at once for exactly this reason, and the
# cost was not the red: it was that a route genuinely breaking would have looked
# identical, so the suite had stopped being able to report one.
#
# advance_to presses 0 until the node it is looking for arrives, or until a generous
# budget runs out. Adding prose to a chapter no longer breaks it. A route that actually
# stops reaching its destination still fails, and fails with the path it walked instead,
# which is the information you want at that moment.
#
# It presses 0 and nothing else, deliberately: the default path is what these tests are
# about. A test that needs a specific option still calls engine.choose(index) itself,
# and uses this only to cover the prose in between.

const DEFAULT_MAX_STEPS := 60

# Presses choice 0 until `target_id` is current. Returns the ids walked through,
# including where it started and where it stopped, so an assertion that fails can show
# the route rather than just the disappointment.
static func advance_to(engine, target_id: String, max_steps: int = DEFAULT_MAX_STEPS) -> Array:
	var path: Array = [engine.current_node()["id"]]
	var steps := 0
	while engine.current_node()["id"] != target_id:
		if steps >= max_steps:
			path.append("<gave up after %d steps>" % max_steps)
			break
		if engine.available_choices().is_empty():
			path.append("<terminal, target never reached>")
			break
		engine.choose(0)
		path.append(engine.current_node()["id"])
		steps += 1
	return path

# The common shape: walk there and assert you arrived, reporting the route if not.
# Returns the full path so a caller can print or inspect it.
static func expect_reaches(test, engine, target_id: String, max_steps: int = DEFAULT_MAX_STEPS) -> Array:
	var path := advance_to(engine, target_id, max_steps)
	test.assert_eq(engine.current_node()["id"], target_id,
		"pressing 0 from %s never reached %s; %s" % [path[0], target_id, summarise(path)])
	return path

# A route that fails usually fails by looping, and a loop over a 60-step budget prints
# the same dozen ids five times. Verified while checking that these tests still catch a
# real break: the assertion fired correctly and the message was unreadable. Ends are
# what matter - where it started and where it gave up - so the middle is elided.
static func summarise(path: Array, head: int = 6, tail: int = 3) -> String:
	if path.size() <= head + tail + 1:
		return "walked %d: %s" % [path.size(), " -> ".join(path)]
	var shown: Array = []
	for i in range(head):
		shown.append(str(path[i]))
	shown.append("... %d more ..." % (path.size() - head - tail))
	for i in range(path.size() - tail, path.size()):
		shown.append(str(path[i]))
	return "walked %d: %s" % [path.size(), " -> ".join(shown)]
