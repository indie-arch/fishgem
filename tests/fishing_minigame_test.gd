extends SceneTree

var catches := 0
var escapes := 0
var cancellations := 0

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var game = load("res://scripts/fishing_minigame.gd").new()
	root.add_child(game)
	game.caught.connect(func(_fish): catches += 1)
	game.escaped.connect(func(): escapes += 1)
	game.cancelled.connect(func(): cancellations += 1)
	var species := {"name": "Test fish", "required_hits": 8, "speed": 100.0}
	game.start_fishing(species)
	game.set_process(false)
	var start: Vector2 = game.target_position
	game._process(0.1)
	assert(game.target_position.distance_to(start) > 0.0, "Fish must swim between clicks")
	for i in range(8):
		click(game, game.target_position)
		if game.active:
			game._process(game.DASH_DURATION)
	assert(catches == 1 and not game.active, "Eight hits should catch exactly once")
	click(game, game.target_position)
	assert(catches == 1, "Inactive encounter must ignore clicks")
	game.start_fishing(species)
	game.set_process(false)
	var danger_before: float = game.danger_progress
	click(game, Vector2(60, 140))
	assert(is_equal_approx(game.danger_progress - danger_before, 0.04), "Miss should advance danger by 4 percent")
	game._process(3.0)
	assert(escapes == 1 and not game.active, "Idle fish must escape")
	game.start_fishing(species)
	game.set_process(false)
	game.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	game.size = Vector2(480, 360)
	click(game, game.target_position)
	assert(game.hit_count == 1, "Scaled click coordinates must hit the fish")
	var escape_key := InputEventKey.new()
	escape_key.keycode = KEY_ESCAPE
	escape_key.pressed = true
	game._input(escape_key)
	assert(cancellations == 1 and not game.active, "Escape must cancel")
	check_dash(game)
	check_dash_frame_timing(game)
	game.free()
	print("PASS: movement, catch, inactive input, miss penalty, escape, scaling, cancellation, continuous random dash, spam guard, reacquisition and dash frame timing")
	quit()


func check_dash(game: Control) -> void:
	var destinations := {}
	for movement in ["steady", "fast", "weave", "dart", "restless", "rare"]:
		game.start_fishing({"behavior": movement, "radius": 64, "required_hits": 16})
		game.set_process(false)
		var start: Vector2 = game.target_position
		click(game, start)
		assert(game.dashing and game.target_position == start, "Hit starts a dash without teleporting")
		var destination: Vector2 = game._dash_destination
		destinations[destination] = true
		var bounds: Rect2 = game.POND.grow(-game.target_radius - 8.0)
		assert(destination == destination.clamp(bounds.position, bounds.end), "Dash destination respects target radius and pond edges")
		assert(start.distance_to(destination) >= game.target_radius * 2.0 + 40.0, "Dash clears the previous clickable circle")
		var danger_before: float = game.danger_progress
		for spam_click in range(20):
			click(game, start)
		assert(game.hit_count == 1 and game.danger_progress == danger_before, "Clicks during dash give neither hits nor penalties")
		game._process(game.DASH_DURATION * 0.5)
		assert(game.target_position.is_equal_approx(start.lerp(destination, 0.5)), "Dash moves continuously through its midpoint")
		click(game, game.target_position)
		assert(game.hit_count == 1, "Even tracking clicks wait for dash to finish")
		game._process(game.DASH_DURATION * 0.5)
		assert(not game.dashing and game.target_position.is_equal_approx(destination), "Dash finishes exactly at destination")
		click(game, start)
		assert(game.hit_count == 1, "Old stationary aim cannot score after dash")
		click(game, game.target_position)
		assert(game.hit_count == 2 and game.dashing, "Reacquiring the fish scores and starts the next dash")
	assert(destinations.size() > 1, "Successive dash destinations vary")


func check_dash_frame_timing(game: Control) -> void:
	var comparison = load("res://scripts/fishing_minigame.gd").new()
	root.add_child(comparison)
	for node in [game, comparison]:
		seed(482)
		node.start_fishing({"behavior": "steady", "speed": 100, "required_hits": 8})
		node.set_process(false)
		click(node, node.target_position)
	game._process(game.DASH_DURATION)
	for frame in range(18):
		comparison._process(0.01)
	assert(not game.dashing and not comparison.dashing, "Large and small frames finish dash at the same time")
	assert(game.target_position.is_equal_approx(comparison.target_position), "Dash endpoint is frame independent")
	assert(is_equal_approx(game.danger_progress, comparison.danger_progress), "Danger continues equally during dash")
	# A slow frame spanning the dash boundary must keep its leftover swimming time.
	for node in [game, comparison]:
		seed(482)
		node.start_fishing({"behavior": "steady", "speed": 100, "required_hits": 8})
		node.set_process(false)
		click(node, node.target_position)
	game._process(game.DASH_DURATION + 0.06)
	for frame in range(24):
		comparison._process(0.01)
	assert(game.target_position.is_equal_approx(comparison.target_position), "Overshoot time resumes normal swimming without frame-dependent delay")
	comparison.free()

func click(game: Control, design_position: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = game._design_origin() + design_position * game._design_scale()
	game._gui_input(event)
