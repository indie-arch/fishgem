extends Node
## Connects the prototype loop; each system keeps its own small responsibility.

const Progress = preload("res://scripts/prototype_progress.gd")
const World = preload("res://scenes/prototype_world.tscn")
const Fishing = preload("res://scenes/fishing_minigame.tscn")
const Interface = preload("res://scripts/prototype_ui.gd")

var progress = Progress.new()
var world
var ui
var fishing
var mode := "world"
var bite_timer: Timer
var save_path := "user://fishgem_prototype.json"
var _shore_hint := "WASD / arrows: walk. Find the water and press E."

func _ready() -> void:
	world = World.instantiate()
	add_child(world)
	ui = Interface.new()
	add_child(ui)
	var fishing_layer := CanvasLayer.new()
	fishing_layer.layer = 2
	add_child(fishing_layer)
	fishing = Fishing.instantiate()
	fishing_layer.add_child(fishing)
	bite_timer = Timer.new()
	bite_timer.one_shot = true
	bite_timer.timeout.connect(_on_bite)
	add_child(bite_timer)
	world.fish_requested.connect(_cast)
	world.shop_requested.connect(_open_shop)
	world.interaction_hint.connect(_on_hint)
	ui.journal_requested.connect(_open_journal)
	ui.pause_requested.connect(_open_pause)
	ui.close_requested.connect(_return_to_world)
	ui.sell_requested.connect(_sell)
	ui.upgrade_requested.connect(_upgrade)
	ui.quit_requested.connect(_quit_game)
	ui.reset_requested.connect(_request_save_reset)
	ui.reset_confirmed.connect(_confirm_save_reset)
	ui.reset_cancelled.connect(_cancel_save_reset)
	fishing.caught.connect(_on_caught)
	fishing.escaped.connect(_on_escaped)
	fishing.cancelled.connect(func(): _end_encounter("Line reeled in. Nothing lost."))
	get_tree().auto_accept_quit = false
	var result: Error = progress.load_game(save_path)
	ui.notice.text = "Progress loaded. Welcome back!" if result == OK else "Walk to the shore and catch your first fish."
	if result != OK and result != ERR_FILE_NOT_FOUND:
		ui.notice.text = "Save could not be loaded; using a fresh session."
	_update_stats()
	_on_hint(world.hint)

func _input(event: InputEvent) -> void:
	# Handle Tab before GUI focus traversal consumes the journal shortcut.
	if not event is InputEventKey or not event.is_pressed() or event.is_echo():
		return
	if event.keycode == KEY_ESCAPE and mode != "fishing":
		if mode == "world":
			_open_pause()
		elif mode == "reset_confirm":
			_cancel_save_reset()
		else:
			_return_to_world()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_TAB and mode == "world":
		_open_journal()
		get_viewport().set_input_as_handled()

func _set_mode(next_mode: String) -> void:
	mode = next_mode
	world.input_enabled = mode == "world"
	ui.hint.text = _shore_hint if mode == "world" else "Esc: cancel / back"

func _cast() -> void:
	if mode != "world":
		return
	_set_mode("waiting")
	world.begin_cast()
	ui.show_waiting()
	bite_timer.start(progress.roll_wait_time())

func _on_bite() -> void:
	if mode != "waiting":
		return
	world.end_cast()
	ui.hide_modal()
	_set_mode("fishing")
	ui.journal_button.disabled = true
	ui.pause_button.disabled = true
	fishing.start_fishing(progress.roll_fish(), int(progress.upgrades.ease))

func _on_caught(fish: Dictionary) -> void:
	var was_complete: bool = progress.journal_complete()
	progress.add_catch(fish)
	var title := "You caught a %s!" % fish.name
	var details := "It weighs %.2f kg!\nWorth %d coins at the shop." % [fish.weight_kg, progress.sale_value(fish)]
	if not was_complete and progress.journal_complete():
		details = title + "\n" + details + "\n\nAll %d fish discovered. Nice fishing!" % progress.FISH.size()
		title = "Journal complete!"
	_show_result(title, details, fish.texture_path)
	_save_progress()

func _on_escaped() -> void:
	var fish: Dictionary = fishing.current_fish
	_show_result("The %s swam away." % fish.get("name", "fish"),
		"It slipped off the line. Cast again when you're ready.", str(fish.get("texture_path", "")))

func _show_result(title: String, details: String, texture_path: String) -> void:
	bite_timer.stop()
	world.end_cast()
	_set_mode("result")
	ui.show_result(title, details, texture_path)
	ui.notice.text = title
	_update_stats()

func _end_encounter(message: String) -> void:
	_return_to_world()
	ui.notice.text = message
	_update_stats()

func _return_to_world() -> void:
	if mode == "waiting":
		ui.notice.text = "Line reeled in. Cast again whenever you like."
	bite_timer.stop()
	world.end_cast()
	ui.hide_modal()
	_set_mode("world")

func _open_shop() -> void:
	if mode != "world":
		return
	_set_mode("shop")
	ui.show_shop(progress)

func _open_journal() -> void:
	if mode != "world":
		return
	_set_mode("journal")
	ui.show_journal(progress)

func _open_pause() -> void:
	if mode != "world":
		return
	_set_mode("pause")
	ui.show_pause()

func _request_save_reset() -> void:
	if mode != "pause":
		return
	_set_mode("reset_confirm")
	ui.show_reset_confirmation()

func _cancel_save_reset() -> void:
	if mode != "reset_confirm":
		return
	_set_mode("pause")
	ui.show_pause()

func _confirm_save_reset() -> void:
	if mode != "reset_confirm":
		return
	var fresh_progress = Progress.new()
	# Commit the fresh save before changing the live session, so failures keep progress intact.
	if fresh_progress.save_game(save_path) != OK:
		ui.notice.text = "Could not reset the save. Your progress is unchanged."
		return
	progress = fresh_progress
	world.player.position = world.ground.map_to_local(world.SPAWN_CELL)
	get_viewport().get_camera_2d().reset_smoothing()
	_update_stats()
	_cancel_save_reset()
	ui.notice.text = "Save reset. A fresh start awaits!"

func _sell() -> void:
	if mode != "shop":
		return
	var earned: int = progress.sell_all()
	ui.notice.text = "Sold your catch for %d coins." % earned
	_update_stats()
	ui.show_shop(progress)
	_save_progress()

func _upgrade(kind: String) -> void:
	if mode != "shop" or not progress.buy_upgrade(kind):
		return
	ui.notice.text = {"ease": "Steady grip upgraded — easier aiming!", "weight": "Heavy lure upgraded — heavier fish on average!", "speed": "Quick bite upgraded — shorter waits!"}.get(kind, "Rod upgraded!")
	_update_stats()
	ui.show_shop(progress)
	_save_progress()

func _on_hint(message: String) -> void:
	_shore_hint = message
	if mode == "world":
		ui.hint.text = message

func _update_stats() -> void:
	ui.update_stats(progress.coins, progress.bag.size())

func _save_progress() -> bool:
	if progress.save_game(save_path) != OK:
		ui.notice.text = "Could not save progress. Keep this session open and try again."
		return false
	return true

func _quit_game() -> void:
	if _save_progress():
		get_tree().quit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_instance_valid(ui):
		_quit_game()
