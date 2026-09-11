extends SceneTree
## Also run with a display to exercise the real Forward+ canvas renderer.
const Fishing = preload("res://scripts/fishing_minigame.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var fishing = Fishing.new()
	root.add_child(fishing)
	var background_draws := [0]
	var animated_draws := [0]
	fishing._background.draw.connect(func(): background_draws[0] += 1)
	fishing.draw.connect(func(): animated_draws[0] += 1)
	fishing.start_fishing({"danger_speed": 0.005}, 0, true)
	_check(not fishing.is_processing() and fishing.is_processing_input(), "Guidance waits for input without frame processing")
	await _frames(3)
	if DisplayServer.get_name() != "headless":
		_check(background_draws[0] > 0 and animated_draws[0] > 0, "Both canvas layers draw when an encounter opens")
	var backgrounds_before: int = background_draws[0]
	var animated_before: int = animated_draws[0]
	await _frames(5)
	_check(background_draws[0] == backgrounds_before and animated_draws[0] == animated_before, "Unchanging introduction does not redraw")
	fishing.dismiss_introduction()
	_check(fishing.is_processing(), "Acknowledging guidance enables swimming immediately")
	await _frames(5)
	_check(background_draws[0] == backgrounds_before, "Swimming retains cached static drawing commands")
	if DisplayServer.get_name() != "headless":
		_check(animated_draws[0] > animated_before, "Fish and feedback keep drawing while swimming")
	fishing.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	fishing.size = Vector2(960, 640)
	await _frames(3)
	if DisplayServer.get_name() != "headless":
		_check(background_draws[0] > backgrounds_before, "Resizing invalidates the static background")
	fishing._stop()
	_check(not fishing.is_processing() and not fishing.is_processing_input() and not fishing.visible, "Ending an encounter stops processing and hides both layers")
	await _frames(3)
	backgrounds_before = background_draws[0]
	animated_before = animated_draws[0]
	await _frames(3)
	_check(background_draws[0] == backgrounds_before and animated_draws[0] == animated_before, "Closed encounters do not keep drawing")
	fishing.start_fishing({"danger_speed": 0.005})
	await _frames(3)
	if DisplayServer.get_name() != "headless":
		_check(background_draws[0] > backgrounds_before, "Recasting restores the background")
	fishing.free()
	if failures == 0:
		print("PASS: introduction processing, animated/static drawing lifecycle, resize and recast (%s)" % DisplayServer.get_name())
	quit(1 if failures else 0)

func _frames(count: int) -> void:
	for frame in count:
		await process_frame

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
