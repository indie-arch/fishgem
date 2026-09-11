extends SceneTree
## Informational timings, not pass/fail limits: run headless on the same machine.
const Progress = preload("res://scripts/prototype_progress.gd")
const Interface = preload("res://scripts/prototype_ui.gd")
const TEST_SAVE := "user://fishgem_benchmark_only.json"

func _initialize() -> void:
	call_deferred("run_benchmark")

func run_benchmark() -> void:
	# An optional directory of pre-change scripts allows an identical comparison.
	var arguments := OS.get_cmdline_user_args()
	var progress_script = Progress if arguments.is_empty() else load(arguments[0].path_join("prototype_progress.gd"))
	var interface_script = Interface if arguments.is_empty() else load(arguments[0].path_join("prototype_ui.gd"))
	var ui = interface_script.new()
	root.add_child(ui)
	for count in [100, 1000, 10000]:
		var progress = progress_script.new()
		progress.coins = 1000
		seed(54)
		for index in count:
			progress.add_catch(progress.roll_fish())
		var started := Time.get_ticks_usec()
		for repeat in 10:
			progress.bag_value()
		var valuation_ms := (Time.get_ticks_usec() - started) / 10000.0
		started = Time.get_ticks_usec()
		ui.show_shop(progress)
		var build_ms := (Time.get_ticks_usec() - started) / 1000.0
		await process_frame
		await process_frame
		await process_frame
		var ready_ms := (Time.get_ticks_usec() - started) / 1000.0
		progress.buy_upgrade("ease")
		started = Time.get_ticks_usec()
		if ui.has_method("refresh_shop_upgrades"):
			ui.refresh_shop_upgrades(progress)
		else:
			ui.show_shop(progress)
		var upgrade_ms := (Time.get_ticks_usec() - started) / 1000.0
		started = Time.get_ticks_usec()
		var save_error: Error = progress.save_game(TEST_SAVE)
		var save_ms := (Time.get_ticks_usec() - started) / 1000.0
		if save_error != OK:
			push_error("Benchmark save failed")
			quit(1)
			return
		var restored = progress_script.new()
		started = Time.get_ticks_usec()
		var load_error: Error = restored.load_game(TEST_SAVE)
		var load_ms := (Time.get_ticks_usec() - started) / 1000.0
		var matches: bool = load_error == OK and restored.bag.size() == progress.bag.size()
		if matches:
			for index in progress.bag.size():
				matches = matches and restored.bag[index].id == progress.bag[index].id and is_equal_approx(restored.bag[index].weight_kg, progress.bag[index].weight_kg)
		if not matches:
			push_error("Benchmark round trip failed")
			quit(1)
			return
		print("fish=%d valuation=%.3fms shop_call=%.3fms shop_ready=%.3fms upgrade_refresh=%.3fms save=%.3fms load=%.3fms" % [count, valuation_ms, build_ms, ready_ms, upgrade_ms, save_ms, load_ms])
		ui.show_pause()
		await process_frame
	ui.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	quit()
