extends SceneTree

const TEST_SAVE := "user://fishgem_loop_test.json"

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	var game = load("res://scenes/prototype.tscn").instantiate()
	game.save_path = TEST_SAVE
	root.add_child(game)
	assert(game.mode == "world" and game.world.input_enabled)
	assert(game.world.can_stand(game.world.player.position), "Spawn must be walkable")
	assert(not game.world.can_stand(Vector2(-1000, -1000)), "Water must block movement")
	game.world.player.position = game.world.ground.map_to_local(Vector2i(1, 5))
	game._cast()
	assert(game.mode == "waiting" and not game.world.input_enabled)
	assert(is_instance_valid(game.world.cast_effect), "Cast creates feedback at shoreline")
	assert(not game.world.is_land(game.world.ground.local_to_map(game.world.cast_position)))
	assert(game.bite_timer.wait_time >= 6.0 and game.bite_timer.wait_time <= 11.0)
	assert(not game.ui.modal.visible, "Waiting must leave cast feedback visible")
	game._return_to_world()
	assert(game.bite_timer.is_stopped() and game.world.input_enabled, "Cancel cast restores walking")
	assert(game.world.cast_effect == null, "Cancel removes bobber")
	game._cast()
	game.bite_timer.stop()
	game._on_bite()
	assert(game.mode == "fishing" and game.fishing.active)
	var fish: Dictionary = game.progress.fish_by_id("common")
	fish.weight_kg = 1.25
	game.fishing.start_fishing(fish)
	for hit in range(int(fish.required_hits)):
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = true
		event.position = game.fishing._design_origin() + game.fishing.target_position * game.fishing._design_scale()
		game.fishing._gui_input(event)
		game.fishing._process(game.fishing.DASH_DURATION)
	assert(game.mode == "result" and not game.world.input_enabled)
	assert(game.ui.modal.visible and game.ui.modal_title.text.contains(fish.name))
	assert(game.progress.bag[0].weight_kg == 1.25)
	game._return_to_world()
	assert(game.progress.bag.size() == 1 and game.progress.discovered.common == 1, "Catch flows into bag and journal")
	assert(FileAccess.file_exists(TEST_SAVE), "Catch autosaves")
	for i in range(3):
		game.progress.add_catch(fish)
	game._open_shop()
	game._sell()
	assert(game.progress.coins == 40 and game.progress.bag.is_empty())
	game._upgrade("ease")
	assert(game.progress.coins == 10 and game.progress.upgrades.ease == 1)
	assert(game.progress.discovered.common == 4, "Selling preserves discoveries")
	game._return_to_world()
	game._open_journal()
	assert(game.mode == "journal" and not game.world.input_enabled)
	game._return_to_world()
	game._open_pause()
	assert(game.mode == "pause" and not game.world.input_enabled)
	game._return_to_world()
	var loaded = load("res://scripts/prototype_progress.gd").new()
	assert(loaded.load_game(TEST_SAVE) == OK)
	assert(loaded.coins == 10 and loaded.upgrades.ease == 1 and loaded.discovered.common == 4)
	game._cast()
	game.bite_timer.stop()
	game._on_bite()
	var escaped_name: String = game.fishing.current_fish.name
	game.fishing._process(30.0)
	assert(game.mode == "result" and game.ui.modal_title.text == "The %s swam away." % escaped_name)
	assert(game.progress.bag.is_empty(), "Escapes never add catches")
	game.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	print("PASS: world, cast/cancel, bite/catch, inventory, sale, upgrade, journal, pause, autosave/reload")
	quit()
