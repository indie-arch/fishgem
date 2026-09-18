extends SceneTree

const Progress = preload("res://scripts/prototype_progress.gd")
const Fishing = preload("res://scripts/fishing_minigame.gd")
const TEST_SAVE := "user://fishgem_holographic_test_only.json"

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var progress = Progress.new()
	var game = Fishing.new()
	root.add_child(game)
	var caught: Array[Dictionary] = []
	game.caught.connect(func(fish): caught.append(fish))
	assert(progress.fish_catalog(true).size() == Progress.FISH.size() * 2)
	for base in progress.fish_catalog():
		var fish: Dictionary = progress.fish_by_id(base.id + "_holographic")
		fish.weight_kg = 1.25
		game.start_fishing(fish, Progress.MAX_UPGRADE_LEVEL)
		game.set_process(false)
		assert(game.swim_speed > base.speed and game.danger_speed > base.danger_speed)
		assert(game.required_hits > base.required_hits and game.behavior == base.behavior)
		assert(game._fish_canvas.material is ShaderMaterial)
		# Even the strongest variant can be landed by tracking each dash accurately.
		while game.active:
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			click.pressed = true
			click.position = game._design_origin() + game.target_position * game._design_scale()
			game._gui_input(click)
			if game.active:
				game._process(game.DASH_DURATION + 0.1)
		assert(caught.back().id == fish.id)
		progress.add_catch(caught.back())
		assert(progress.discovered[fish.id] == 1 and progress.discovered[base.id] == 1)
		assert(progress.best_weights[fish.id] == 1.25)
		assert(progress.fish_name(fish.id).begins_with("Holographic "))
		assert(progress.sale_value(progress.bag.back()) > 0)
	game.start_fishing(progress.fish_by_id("common"))
	assert(game._fish_canvas.material == null, "Shimmer must not leak into the next ordinary encounter")
	game._stop()
	assert(progress.journal_complete() and progress.discovered_species_count() == 6)
	assert(progress.save_game(TEST_SAVE) == OK)
	var restored = Progress.new()
	assert(restored.load_game(TEST_SAVE) == OK)
	assert(restored.bag == progress.bag)
	for species_id in progress.discovered:
		assert(restored.discovered[species_id] == progress.discovered[species_id])
	assert(restored.best_weights == progress.best_weights)
	restored.sell_all()
	assert(restored.save_game(TEST_SAVE) == OK)
	assert(restored.load_game(TEST_SAVE) == OK and restored.bag.is_empty())
	assert(restored.best_weights == progress.best_weights)
	for species_id in progress.discovered:
		assert(restored.discovered[species_id] == progress.discovered[species_id])
	# A seeded population checks both rarity and availability at every bank.
	seed(92618)
	for spot in Progress.FISHING_SPOTS:
		var variants := {}
		var holographic_count := 0
		for index in 50000:
			var fish: Dictionary = progress.roll_fish(spot)
			if fish.get("holographic", false):
				holographic_count += 1
				variants[fish.base_id] = true
		assert(variants.size() == Progress.FISH.size())
		assert(holographic_count > 170 and holographic_count < 330, "Holographic frequency should be close to 1 in 200")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	game.free()
	print("PASS: every holographic species, harder playable encounters, rarity at every bank, sale identity and persistent records")
	quit()
