extends SceneTree

const Progress = preload("res://scripts/prototype_progress.gd")
const Interface = preload("res://scripts/prototype_ui.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var progress = Progress.new()
	var ui = Interface.new()
	root.add_child(ui)
	for populated in [false, true]:
		if populated:
			for fish in progress.fish_catalog(true):
				progress.add_catch({"id": fish.id, "weight_kg": 1.25})
		ui.show_journal(progress)
		await _settle()
		_check(_image_count(ui.modal_body) == 12, "Every normal and holographic entry has a fish image")
		var original_text := _text(ui.modal_body)
		for fish in progress.fish_catalog(true):
			_check(original_text.contains(fish.name), "Every species has a readable name")
		if populated:
			_check(original_text.contains("Personal best: 1.25 kg"), "Caught fish show their saved best weight")
		else:
			_check(original_text.count("Not caught yet") == 12, "Uncaught status is explicit for all entries")
		_check(not original_text.contains("???"), "Unknown entries use readable, distinct names")
		_check(original_text.contains("Bonus holographic fish"), "Bonus discoveries have their own section")
		for position in [0, 120, 360, 100000, 240, 0]:
			ui.modal_scroll.scroll_vertical = position
			await _settle()
			_check(_text(ui.modal_body) == original_text, "Scrolling preserves every journal entry")
			_check_layout(ui.modal_body)
			_check(ui.modal_scroll.get_global_rect().end.y <= ui.modal_actions.get_global_rect().position.y, "Scrolling stays above Back button")
		var wheel := InputEventMouseButton.new()
		wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
		wheel.pressed = true
		wheel.position = ui.modal_scroll.global_position + Vector2(120, 100)
		root.push_input(wheel, true)
		await _settle()
		_check(ui.modal_scroll.scroll_vertical > 0, "Wheel over journal text scrolls the list")
		ui.hide_modal()
		ui.show_journal(progress)
		await _settle()
		_check(ui.modal_scroll.scroll_vertical == 0, "Reopening starts at the beginning")
	ui.free()
	if failures == 0:
		print("PASS: readable journal entries, bonus section, row layout, wheel scrolling and reopening")
	quit(1 if failures else 0)

func _image_count(node: Node) -> int:
	var count := 1 if node is TextureRect and node.texture != null else 0
	for child in node.get_children():
		count += _image_count(child)
	return count

func _text(node: Node) -> String:
	var text: String = node.text + "\n" if node is Label else ""
	for child in node.get_children():
		text += _text(child)
	return text

func _check_layout(node: Node) -> void:
	if node is VBoxContainer:
		var previous_bottom := 0.0
		for child in node.get_children():
			_check(child.position.y >= previous_bottom, "Journal rows do not overlap")
			previous_bottom = child.position.y + child.size.y
	if node is Label:
		_check(node.size.y >= node.get_minimum_size().y, "Wrapped journal text fits its row")
	for child in node.get_children():
		_check_layout(child)

func _settle() -> void:
	for frame in 8:
		await process_frame

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
