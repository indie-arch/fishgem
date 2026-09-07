extends SceneTree

const TEST_SAVE := "user://fishgem_reset_test_only.json"
var game

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	game = load("res://scenes/prototype.tscn").instantiate()
	game.save_path = TEST_SAVE
	root.add_child(game)
	game.progress.coins = 123
	game.progress.upgrades = {"ease": 1, "weight": 2, "speed": 3}
	game.progress.add_catch({"id": "common", "weight_kg": 1.4})
	game.progress.fishing_intro_seen = true
	assert(game.progress.save_game(TEST_SAVE) == OK)
	var original := FileAccess.get_file_as_string(TEST_SAVE)
	game._confirm_save_reset()
	assert(game.progress.coins == 123, "Reset requires confirmation mode")
	game._open_pause()
	press_button("Reset save…")
	assert(game.mode == "reset_confirm" and not game.world.input_enabled)
	assert(root.gui_get_focus_owner().text.begins_with("Cancel"), "Cancel is the default selection")
	assert(FileAccess.get_file_as_string(TEST_SAVE) == original, "Opening confirmation never resets")
	tap(KEY_ESCAPE)
	assert(game.mode == "pause" and FileAccess.get_file_as_string(TEST_SAVE) == original)
	press_button("Reset save…")
	tap(KEY_ENTER)
	assert(game.mode == "pause" and game.progress.coins == 123, "Default Enter cancels")
	press_button("Reset save…")
	game.save_path = "user://missing-reset-test-directory/save.json"
	press_button("Yes, reset my save")
	assert(game.mode == "reset_confirm" and game.progress.coins == 123, "Failed write preserves live progress")
	assert(FileAccess.get_file_as_string(TEST_SAVE) == original, "Failed reset preserves disk progress")
	game.save_path = TEST_SAVE
	press_button("Yes, reset my save")
	assert(game.mode == "pause")
	assert(game.progress.coins == 0 and game.progress.upgrades == {"ease": 0, "weight": 0, "speed": 0})
	assert(game.progress.bag.is_empty() and game.progress.discovered.is_empty())
	assert(game.progress.best_weights.is_empty() and not game.progress.fishing_intro_seen)
	assert(game.world.player.position == game.world.ground.map_to_local(game.world.SPAWN_CELL))
	var loaded = game.Progress.new()
	assert(loaded.load_game(TEST_SAVE) == OK and loaded.coins == 0 and loaded.bag.is_empty() and loaded.discovered.is_empty())
	assert(loaded.upgrades == game.progress.upgrades, "Reset survives restart")
	assert(loaded.best_weights.is_empty() and not loaded.fishing_intro_seen, "Reset clears records and restores first-time guidance after reload")
	game.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	print("PASS: reset confirmation, cancel/Escape/default focus, write failure, live reset and saved reset")
	quit()

func press_button(text_value: String) -> void:
	for child in game.ui.modal.find_children("*", "Button", true, false):
		if child is Button and child.text == text_value:
			child.pressed.emit()
			return
	assert(false, "Missing button: " + text_value)

func tap(key: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = key
		event.pressed = pressed
		root.push_input(event)
