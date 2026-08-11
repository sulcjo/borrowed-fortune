extends SceneTree

func _init() -> void:
	var theme := BorrowedFortuneTheme.build()
	var err := ResourceSaver.save(theme, "res://theme/borrowed_fortune_theme.tres")
	if err != OK:
		printerr("Failed to save theme: %s" % error_string(err))
		quit(1)
		return
	print("Theme saved to res://theme/borrowed_fortune_theme.tres")
	quit(0)
