extends SceneTree
## Exercise routed events, including GUI focus, rather than calling game handlers.

const TEST_SAVE := "user://fishgem_input_test_only.json"
var game
var failures := 0
var bite_count := 0
var cancellation_count := 0


func _initialize() -> void:
	call_deferred("run_checks")


func run_checks() -> void:
	_cleanup_save()
	game = load("res://scripts/prototype_game.gd").new()
	game.save_path = TEST_SAVE
	root.add_child(game)
	await process_frame
	game.bite_timer.timeout.connect(func(): bite_count += 1)
	game.fishing.cancelled.connect(func(): cancellation_count += 1)

	var shore_found := false
	for cell in game.world.ground.get_used_cells():
		var point: Vector2 = game.world.ground.map_to_local(cell)
		if not game.world.can_stand(point):
			continue
		game.world.player.position = point
		if game.world.is_near_water() and not game.world.is_near_shop():
			shore_found = true
			break
	_check(shore_found, "Map must contain an accessible fishing shore")
	var shore: Vector2 = game.world.player.position
	_tap(KEY_E)
	_check(game.mode == "waiting" and not game.ui.modal.visible, "Routed E at shore starts waiting")
	await _check_movement_locked("waiting")
	# A short pending timer makes the cancellation race quick and deterministic.
	game.bite_timer.start(0.04)
	_tap(KEY_ESCAPE)
	_check(game.mode == "world" and game.bite_timer.is_stopped(), "Escape cancels pending cast")
	await create_timer(0.08).timeout
	_check(bite_count == 0 and game.mode == "world" and not game.fishing.active, "Cancelled timer never starts fishing")

	game.ui.journal_button.grab_focus()
	_check(root.gui_get_focus_owner() == game.ui.journal_button, "HUD owns focus before shortcut")
	_tap(KEY_TAB)
	_check(game.mode == "journal" and game.ui.modal.visible, "Tab opens journal despite GUI focus traversal")
	await _check_movement_locked("journal")
	_tap(KEY_ESCAPE)
	_check(game.mode == "world" and not game.ui.modal.visible, "Escape closes journal")

	_tap(KEY_ESCAPE)
	_check(game.mode == "pause", "Escape in world opens pause")
	await _check_movement_locked("pause")
	_tap(KEY_ESCAPE)
	game.world.player.position = game.world.shop_position
	_tap(KEY_E)
	_check(game.mode == "shop", "Routed E at shop opens shop")
	await _check_movement_locked("shop")
	game.progress.coins = 200
	game.ui.show_shop(game.progress)
	for choice in [["Heavy lure", "weight"], ["Quick bite", "speed"], ["Steady grip", "ease"]]:
		for child in game.ui.modal_body.get_children():
			if child is Button and child.text.begins_with(choice[0]):
				child.pressed.emit()
				break
		_check(game.progress.upgrades[choice[1]] == 1, "Each shop button purchases its own upgrade")
	_check(game.progress.coins == 110, "Each independent level-one upgrade costs 30")
	_tap(KEY_ESCAPE)

	game.world.player.position = shore
	_tap(KEY_E)
	game.bite_timer.start(0.02)
	await create_timer(0.06).timeout
	_check(bite_count == 1 and game.mode == "fishing" and game.fishing.active, "Live timer starts encounter")
	_check(not game.ui.modal.visible and game.ui.journal_button.disabled, "Fishing replaces modal and disables HUD")
	await _check_movement_locked("fishing")
	_tap(KEY_ESCAPE)
	_check(cancellation_count == 1 and game.mode == "world", "Fishing Escape returns to world exactly once without opening pause")
	_check(not game.fishing.active and not game.ui.journal_button.disabled, "Cancellation restores HUD and hides fishing")

	var catch_data: Dictionary = game.progress.fish_by_id("common")
	catch_data.weight_kg = 1.42
	game._on_caught(catch_data)
	_check(game.mode == "result" and game.ui.modal_title.text.contains("Pond pal"), "Catch produces named result")
	await _check_movement_locked("result")
	_tap(KEY_ENTER)
	_check(game.mode == "world" and not game.ui.modal.visible, "Enter dismisses the focused result button")

	# Verify synthetic held-key input actually moves the player when unlocked.
	game.world.player.position = game.world.ground.map_to_local(game.world.SPAWN_CELL)
	var start: Vector2 = game.world.player.position
	var movement_key := KEY_D
	for candidate in [[KEY_D, Vector2.RIGHT], [KEY_A, Vector2.LEFT], [KEY_W, Vector2.UP], [KEY_S, Vector2.DOWN]]:
		if game.world.can_stand(start + candidate[1] * 20.0):
			movement_key = candidate[0]
			break
	_set_held_key(movement_key, true)
	await create_timer(0.06).timeout
	_set_held_key(movement_key, false)
	_check(game.world.player.position.distance_to(start) > 0.0, "Held-key test input moves player after modal closes")
	game.free()
	_cleanup_save()
	if failures == 0:
		print("PASS: routed cast, cancelled timer, focused journal shortcut, modal movement locks, fishing cancellation and movement restoration")
	quit(1 if failures > 0 else 0)


func _tap(key: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = key
		event.physical_keycode = key
		event.pressed = pressed
		root.push_input(event)


func _set_held_key(key: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = pressed
	# push_input routes through the viewport but does not update Input's key state.
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _check_movement_locked(context: String) -> void:
	var before: Vector2 = game.world.player.position
	_check(not game.world.input_enabled, "%s disables world input" % context)
	_set_held_key(KEY_D, true)
	_check(Input.is_physical_key_pressed(KEY_D), "Movement test must hold physical D")
	await create_timer(0.06).timeout
	_set_held_key(KEY_D, false)
	_check(game.world.player.position == before, "%s blocks held-key movement" % context)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _cleanup_save() -> void:
	for suffix in ["", ".tmp"]:
		var path := ProjectSettings.globalize_path(TEST_SAVE + suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
