extends SceneTree

const SAVE := "user://fishgem_recovery_test_only.json"

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	for suffix in ["", ".unreadable", ".unreadable.1"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE + suffix))
	var file := FileAccess.open(SAVE, FileAccess.WRITE)
	file.store_string("broken original bytes")
	file.close()
	file = FileAccess.open(SAVE + ".unreadable", FileAccess.WRITE)
	file.store_string("older preserved save")
	file.close()
	var game = load("res://scenes/prototype.tscn").instantiate()
	game.save_path = SAVE
	root.add_child(game)
	assert(game.mode == "save_recovery" and not game.world.input_enabled)
	assert(not game._save_progress())
	game._return_to_world()
	game._load_progress()
	assert(game.mode == "save_recovery")
	assert(FileAccess.get_file_as_string(SAVE) == "broken original bytes")
	# A blocked archive destination must leave the original untouched and recovery open.
	assert(DirAccess.make_dir_absolute(ProjectSettings.globalize_path(SAVE + ".unreadable.1")) == OK)
	game._start_fresh_after_load_failure()
	assert(game.mode == "save_recovery" and not game._save_progress())
	assert(FileAccess.get_file_as_string(SAVE) == "broken original bytes")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE + ".unreadable.1"))
	game._start_fresh_after_load_failure()
	assert(game.mode == "world" and game.world.input_enabled)
	assert(FileAccess.get_file_as_string(SAVE + ".unreadable.1") == "broken original bytes")
	assert(FileAccess.get_file_as_string(SAVE + ".unreadable") == "older preserved save")
	assert(game.ui.collection.text.contains("0/6"))
	for fish in game.progress.fish_catalog():
		game.progress.add_catch({"id": fish.id, "weight_kg": 1.0})
	game.progress.sell_all()
	game._update_stats()
	assert(game.ui.collection.text.contains("Collection complete!"))
	assert(game._save_progress())
	game.free()
	game = load("res://scenes/prototype.tscn").instantiate()
	game.save_path = SAVE
	root.add_child(game)
	assert(game.ui.collection.text.contains("6/6"), "Collection survives sale and reload")
	game._open_pause()
	game._request_save_reset()
	game._confirm_save_reset()
	assert(game.ui.collection.text.contains("0/6"))
	# Retry loads a repaired save without replacing it with the fresh session.
	game._save_load_failed = true
	game._set_mode("save_recovery")
	var repaired = game.Progress.new()
	repaired.coins = 123
	assert(repaired.save_game(SAVE) == OK)
	game._load_progress()
	assert(game.mode == "world" and game.progress.coins == 123)
	game.free()
	for suffix in ["", ".unreadable", ".unreadable.1"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE + suffix))
	print("PASS: recovery blocks autosave, preserves originals, retries repaired saves; collection survives sale/reload/reset")
	quit()
