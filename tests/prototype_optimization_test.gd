extends SceneTree

const Progress = preload("res://scripts/prototype_progress.gd")
const Interface = preload("res://scripts/prototype_ui.gd")
const Player = preload("res://scripts/prototype_player.gd")
const TEST_SAVE := "user://fishgem_optimization_test_only.json"
var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	_check_catalog_and_save()
	await _check_shop()
	await _check_virtual_inventory()
	_check_idle_player()
	await _check_hints()
	if failures == 0:
		print("PASS: catalog isolation, large inventory round trip, shop reuse, virtual rows/scrolling/wrapping/theme changes, idle collision work and hint invalidation")
	quit(1 if failures else 0)

func _check_catalog_and_save() -> void:
	var progress = Progress.new()
	var copy: Dictionary = progress.fish_by_id("common")
	copy.price = 999
	copy.name = "Changed"
	var catalog: Array = progress.fish_catalog()
	catalog[0].price = 888
	_check(progress.fish_by_id("common").price == 8, "Public catalog copies must not mutate species definitions")
	_check(progress.fish_by_id("absent").is_empty(), "Unknown species stays empty")
	var expected := 0
	for index in 1000:
		var species: Dictionary = Progress.FISH[index % Progress.FISH.size()]
		var weight := float(index % 200 + 1) / 100.0
		progress.add_catch({"id": species.id, "weight_kg": weight})
		expected += maxi(1, roundi(species.price * weight))
	_check(progress.bag_value() == expected, "Large mixed bag retains per-fish rounding")
	for invalid in [{"id": "unknown", "weight_kg": 1}, {"id": 2, "weight_kg": 1}, {"id": "common", "weight_kg": NAN}, {"id": "common", "weight_kg": 1001}]:
		_check(progress.sale_value(invalid) == 0, "Invalid catches remain worthless")
	_check(progress.save_game(TEST_SAVE) == OK, "Large inventory saves synchronously")
	var restored = Progress.new()
	_check(restored.load_game(TEST_SAVE) == OK, "Large inventory reloads")
	_check(restored.bag == progress.bag and restored.bag_value() == expected, "Save preserves catch order, individual weights and sale value")
	_check(restored.sell_all() == expected and restored.bag.is_empty(), "Sale remains exact and clears inventory")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))

func _check_shop() -> void:
	var progress = Progress.new()
	progress.coins = 1000
	for index in 1000:
		progress.add_catch({"id": Progress.FISH[index % 6].id, "weight_kg": 1.25})
	var ui = Interface.new()
	root.add_child(ui)
	ui.show_shop(progress)
	await process_frame
	await process_frame
	var inventory := _inventory_scroll(ui)
	_check(inventory != null, "Nonempty bag has a scrolling inventory")
	var inventory_id := inventory.get_instance_id()
	_check(inventory.get_child(0).get_child_count() < 20, "A thousand fish must not allocate a thousand labels")
	var sell := _find_button(ui.modal_body, "Sell ")
	_check(sell.text == "Sell 1000 fish for %d coins" % progress.bag_value(), "Shop total agrees with actual sale")
	progress.buy_upgrade("ease")
	if ui.has_method("refresh_shop_upgrades"):
		ui.refresh_shop_upgrades(progress)
	else:
		ui.show_shop(progress)
	_check(_inventory_scroll(ui).get_instance_id() == inventory_id, "Upgrades must reuse the inventory controls")
	_check(_find_button(ui.modal_body, "Steady grip").text.contains("[1/5]"), "Upgrade level refreshes")
	_check(_find_button(ui.modal_body, "Heavy lure").text.contains("[0/5]"), "Other upgrade levels remain unchanged")
	_check(root.gui_get_focus_owner() == ui.modal_actions.get_child(0), "Upgrade retains the existing back-button focus behavior")
	progress.sell_all()
	ui.show_shop(progress)
	_check(_inventory_scroll(ui) == null and _find_button(ui.modal_body, "Sell ").disabled, "Selling removes inventory rows and disables selling again")
	ui.show_journal(progress)
	ui.show_shop(progress)
	_check(_find_button(ui.modal_body, "Steady grip").text.contains("[1/5]"), "Reopening after another modal retains correct upgrades")
	ui.free()
	await process_frame

func _check_virtual_inventory() -> void:
	# Compare against the original VBox/Label layout, including multi-line rows.
	var original := VBoxContainer.new()
	var optimized = load("res://scripts/catch_list.gd").new()
	var reference_scroll := ScrollContainer.new()
	var optimized_scroll := ScrollContainer.new()
	var theme := Theme.new()
	theme.default_font_size = 19
	for scroll in [reference_scroll, optimized_scroll]:
		scroll.theme = theme
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.size = Vector2(680, 110)
		root.add_child(scroll)
	var rows := PackedStringArray()
	for index in 200:
		var value := "%d. Stubborn chum  •  12.34 kg  •  222 coins" % index
		if index % 5 == 0:
			value += "\nA second line with a much longer description that wraps in a narrow inventory."
		rows.append(value)
		var label := Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = value
		original.add_child(label)
	original.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	optimized.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	optimized.rows = rows
	reference_scroll.add_child(original)
	optimized_scroll.add_child(optimized)
	for width in [680, 240, 480]:
		for scroll in [reference_scroll, optimized_scroll]:
			scroll.size.x = width
		await _settle_layout()
		_check(is_equal_approx(original.size.y, optimized.size.y), "Virtual content height matches wrapped VBox rows at width %d" % width)
		for scroll_position in [0, 143, 1400, 100000]:
			reference_scroll.scroll_vertical = scroll_position
			optimized_scroll.scroll_vertical = scroll_position
			await _settle_layout()
			_check(reference_scroll.scroll_vertical == optimized_scroll.scroll_vertical, "Scroll clamping matches the complete inventory")
			_compare_visible_rows(original, optimized, optimized_scroll)
	# Font/spacing changes must remeasure both wrapping and the scroll extent.
	theme.default_font_size = 25
	theme.set_constant("separation", "VBoxContainer", 9)
	await _settle_layout()
	_check(is_equal_approx(original.size.y, optimized.size.y), "Theme changes preserve row and scroll heights")
	_compare_visible_rows(original, optimized, optimized_scroll)
	_check(optimized.get_child_count() < 20, "Scrolling and resizing reuse a bounded label pool")
	# Route a wheel event over the row: the inner inventory must still scroll.
	optimized_scroll.scroll_vertical = 0
	await _settle_layout()
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	wheel.position = optimized_scroll.global_position + Vector2(40, 40)
	root.push_input(wheel, true)
	await _settle_layout()
	_check(optimized_scroll.scroll_vertical > 0, "Mouse wheel still scrolls over a pooled label")
	reference_scroll.free()
	optimized_scroll.free()

func _compare_visible_rows(original: VBoxContainer, optimized: Control, scroll: ScrollContainer) -> void:
	var visible_text: Dictionary = {}
	for label in optimized.get_children():
		if label.visible:
			visible_text[label.text] = label
	for reference in original.get_children():
		if reference.position.y + reference.size.y < scroll.scroll_vertical or reference.position.y > scroll.scroll_vertical + scroll.size.y:
			continue
		_check(visible_text.has(reference.text), "Every visible catch remains accessible after scrolling")
		if visible_text.has(reference.text):
			var actual: Label = visible_text[reference.text]
			_check(actual.get_rect().is_equal_approx(reference.get_rect()), "Pooled row '%s': expected %s, got %s" % [reference.text, reference.get_rect(), actual.get_rect()])

func _settle_layout() -> void:
	for frame in 6:
		await process_frame

func _check_idle_player() -> void:
	var player = Player.new()
	root.add_child(player)
	var probes := [0]
	var start: Vector2 = player.position
	player.walk(1.0 / 60.0, func(_point): probes[0] += 1; return true)
	_check(probes[0] == 0 and player.position == start, "Idle movement must skip collision probes")
	player.body.position = Vector2(0, -2)
	player.walk(1.0 / 60.0, func(_point): return true)
	_check(player.body.position == Vector2.ZERO, "Stopping movement still restores the resting pose")
	var direction_key := InputEventKey.new()
	direction_key.physical_keycode = KEY_D
	direction_key.pressed = true
	Input.parse_input_event(direction_key)
	Input.flush_buffered_events()
	probes[0] = 0
	player.walk(1.0 / 60.0, func(_point): probes[0] += 1; return true)
	_check(probes[0] == 1 and is_equal_approx(player.position.x - start.x, Player.WALK_SPEED / 60.0), "Straight movement retains speed and skips stationary-axis probes")
	direction_key = direction_key.duplicate()
	direction_key.pressed = false
	Input.parse_input_event(direction_key)
	Input.flush_buffered_events()
	player.free()

func _check_hints() -> void:
	var world = load("res://scenes/prototype_world.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.set_process(false)
	world.player.position = world.shop_position
	world._physics_process(0.0)
	_check(world.hint.begins_with("E: shop"), "Teleporting to the shop updates the hint")
	world.input_enabled = false
	world._physics_process(0.0)
	_check(world.hint.is_empty(), "Opening a modal clears interaction hints")
	world.input_enabled = true
	world._physics_process(0.0)
	_check(world.hint.begins_with("E: shop"), "Closing a modal restores hints without movement")
	world.player.position = world.ground.map_to_local(Vector2i(1, 5))
	world._physics_process(0.0)
	_check(world.hint.begins_with("E: cast"), "Shoreline hint updates after position changes")
	var emissions := [0]
	world.interaction_hint.connect(func(_message): emissions[0] += 1)
	for tick in 120:
		world._physics_process(1.0 / 60.0)
	_check(emissions[0] == 0, "Idle hints emit no duplicate messages")
	# Removing neighboring water must refresh a cached hint without movement.
	var cell: Vector2i = world.ground.local_to_map(world.player.position)
	for offset in world.NEIGHBORS:
		if world._is_water(cell + offset):
			world.ground.erase_cell(cell + offset)
	world._physics_process(0.0)
	_check(not world.hint.begins_with("E: cast"), "Tile changes invalidate a stationary shoreline hint")
	world.player.position = world.shop_position
	for frame in 20:
		world._process(0.05)
	_check(world.shop_attention == 1.0, "Shop sign still animates when approached")
	world.player.position = Vector2(-1000, -1000)
	for frame in 20:
		world._process(0.05)
	_check(world.shop_attention == 0.0 and world.shop_sign.rotation == 0.0, "Shop sign settles after leaving")
	var resting_sign: Vector2 = world.shop_sign.position
	var previous_phase: float = world.shop_sign_phase
	world._process(0.1)
	_check(world.shop_sign.position == resting_sign and world.shop_sign_phase != previous_phase, "Idle sign skips transforms but preserves animation phase")
	world.free()
	await process_frame

func _inventory_scroll(ui) -> ScrollContainer:
	for child in ui.modal_body.get_children():
		if child is ScrollContainer:
			return child
	return null

func _find_button(parent: Node, prefix: String) -> Button:
	for child in parent.get_children():
		if child is Button and child.text.begins_with(prefix):
			return child
	return null

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
