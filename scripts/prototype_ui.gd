extends CanvasLayer
## Temporary interface: replace visuals without changing prototype rules.
const CatchList = preload("res://scripts/catch_list.gd")

signal retry_load_requested
signal fresh_start_requested
signal journal_requested
signal pause_requested
signal close_requested
signal recast_requested
signal sell_requested
signal upgrade_requested(kind: String)
signal quit_requested
signal reset_requested
signal reset_confirmed
signal reset_cancelled

var collection: Label
var stats: Label
var hint: Label
var notice: Label
var modal: PanelContainer
var modal_title: Label
var modal_body: VBoxContainer
var modal_actions: VBoxContainer
var modal_scroll: ScrollContainer
var journal_button: Button
var pause_button: Button
var _screen: Control
var _result_tween: Tween
var _shop_upgrade_buttons: Dictionary = {}
var _shop_upgrade_details: Dictionary = {}
var _shop_inventory: ScrollContainer
var _shop_back: Button

func _ready() -> void:
	_screen = Control.new()
	_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_screen)
	var theme := Theme.new()
	theme.default_font_size = 19
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("f4e8ce")
	panel.border_color = Color("38534c")
	panel.set_border_width_all(3)
	panel.content_margin_left = 18
	panel.content_margin_right = 18
	panel.content_margin_top = 12
	panel.content_margin_bottom = 12
	theme.set_stylebox("panel", "PanelContainer", panel)
	theme.set_color("font_color", "Label", Color("273f39"))
	_screen.theme = theme
	var top := PanelContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 16
	top.offset_top = 16
	top.offset_right = -16
	_screen.add_child(top)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	top.add_child(row)
	var summary := VBoxContainer.new()
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(summary)
	stats = _label("", summary)
	collection = _label("", summary)
	collection.add_theme_font_size_override("font_size", 16)
	journal_button = _button("Fish journal [Tab]", row, func(): journal_requested.emit())
	pause_button = _button("Pause [Esc]", row, func(): pause_requested.emit())
	var bottom := PanelContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 16
	bottom.offset_right = -16
	bottom.offset_top = -108
	bottom.offset_bottom = -16
	_screen.add_child(bottom)
	var bottom_rows := VBoxContainer.new()
	bottom.add_child(bottom_rows)
	hint = _label("", bottom_rows)
	notice = _label("", bottom_rows)
	notice.add_theme_font_size_override("font_size", 16)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen.add_child(center)
	modal = PanelContainer.new()
	modal.custom_minimum_size = Vector2(740, 0)
	center.add_child(modal)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	modal.add_child(column)
	modal_title = _label("", column)
	modal_title.add_theme_font_size_override("font_size", 27)
	modal_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_scroll = ScrollContainer.new()
	modal_scroll.custom_minimum_size.y = 330
	modal_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	modal_scroll.follow_focus = true
	column.add_child(modal_scroll)
	modal_body = VBoxContainer.new()
	modal_body.add_theme_constant_override("separation", 10)
	modal_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal_scroll.add_child(modal_body)
	modal_actions = VBoxContainer.new()
	modal_actions.add_theme_constant_override("separation", 10)
	column.add_child(modal_actions)
	modal.hide()

func update_stats(coins: int, bag_count: int) -> void:
	stats.text = "FISHGEM   •   %d coins   •   %d fish" % [coins, bag_count]

func update_collection(found: int, total: int) -> void:
	collection.text = "Collect every fish  •  %d/%d species — journal has hints!" % [found, total]
	if found == total:
		collection.text = "Collection complete!  •  %d/%d species found" % [found, total]

func show_save_recovery() -> void:
	set_modal("Your save could not be loaded")
	_wrapped_label("Your existing save has not been changed.
Retry loading, or start fresh and keep the old file for recovery.
Quitting here leaves your save untouched.", modal_body)
	_button("Retry loading", modal_actions, func(): retry_load_requested.emit()).grab_focus()
	_button("Start fresh & preserve old save", modal_actions, func(): fresh_start_requested.emit())
	_button("Quit without saving", modal_actions, func(): quit_requested.emit())

func set_modal(title: String) -> void:
	_stop_result_animation()
	_shop_upgrade_buttons.clear()
	_shop_upgrade_details.clear()
	_shop_inventory = null
	_shop_back = null
	modal_title.text = title
	for container in [modal_body, modal_actions]:
		for child in container.get_children():
			container.remove_child(child)
			child.queue_free()
	modal_scroll.scroll_vertical = 0
	modal.show()
	journal_button.disabled = true
	pause_button.disabled = true

func hide_modal() -> void:
	_stop_result_animation()
	modal.hide()
	journal_button.disabled = false
	pause_button.disabled = false

func show_waiting() -> void:
	# Leave the world unobstructed so the cast splash and bobber stay visible.
	hide_modal()
	journal_button.disabled = true
	pause_button.disabled = true
	hint.text = "Line cast! Watch the bobber…  [Esc] reel in"
	notice.text = "Waiting for a bite. Some fish take their time."

func show_result(title: String, details: String, texture_path: String, can_recast: bool = false, holographic: bool = false) -> void:
	set_modal(title)
	if not texture_path.is_empty():
		var icon := TextureRect.new()
		icon.texture = load(texture_path)
		if holographic:
			icon.material = _holographic_material()
		icon.custom_minimum_size = Vector2(100, 110)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		modal_body.add_child(icon)
		_animate_result_icon.call_deferred(icon)
	_wrapped_label(details, modal_body)
	var recast: Button
	if can_recast:
		recast = _button("Cast again [Enter]", modal_actions, func(): recast_requested.emit())
	var back := _button("Back to bank [Esc]", modal_actions, func(): close_requested.emit())
	if can_recast:
		recast.grab_focus()
	else:
		back.grab_focus()

func _animate_result_icon(icon: TextureRect) -> void:
	if not is_instance_valid(icon) or not icon.is_inside_tree() or not modal.visible:
		return
	icon.pivot_offset = icon.size * 0.5
	icon.scale = Vector2.ONE * 0.75
	_result_tween = create_tween()
	_result_tween.tween_property(icon, "scale", Vector2.ONE * 1.10, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_result_tween.tween_property(icon, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _stop_result_animation() -> void:
	if _result_tween != null:
		_result_tween.kill()
		_result_tween = null

func show_shop(progress) -> void:
	set_modal("Bait & bits")
	_wrapped_label("Fish value = species rate × weight.\nEach rod upgrade improves just one thing.", modal_body)
	var total_value := 0
	if not progress.bag.is_empty():
		var scroll := ScrollContainer.new()
		_shop_inventory = scroll
		scroll.custom_minimum_size.y = minf(110.0, progress.bag.size() * 27.0)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		modal_body.add_child(scroll)
		var catches := CatchList.new()
		catches.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var rows := PackedStringArray()
		for caught_fish in progress.bag:
			var value: int = progress.sale_value(caught_fish)
			total_value += value
			rows.append("%s  •  %.2f kg  •  %d coins" % [progress.fish_name(caught_fish.id), caught_fish.weight_kg, value])
		catches.rows = rows
		scroll.add_child(catches)
	var sell := _button("Sell %d fish for %d coins" % [progress.bag.size(), total_value], modal_body, func(): sell_requested.emit())
	sell.disabled = progress.bag.is_empty()
	for kind in ["ease", "weight", "speed"]:
		_shop_upgrade_buttons[kind] = _button("", modal_body, _request_upgrade.bind(kind))
		_shop_upgrade_details[kind] = _wrapped_label("", modal_body)
	_shop_back = _button("Back to the bank [Esc]", modal_actions, func(): close_requested.emit())
	refresh_shop_upgrades(progress)

func refresh_shop_upgrades(progress) -> void:
	# A purchase changes only coins and upgrade levels, never the bag or its rows.
	if not is_instance_valid(_shop_back):
		return
	var names := {"ease": "Steady grip", "weight": "Heavy lure", "speed": "Quick bite"}
	var effects := {"ease": "Target radius bonus", "weight": "Catch weight multiplier", "speed": "Average bite wait"}
	for kind in ["ease", "weight", "speed"]:
		var level := int(progress.upgrades[kind])
		var cost: int = progress.upgrade_cost(kind)
		var maxed: bool = level >= progress.MAX_UPGRADE_LEVEL
		var suffix := "MAX" if maxed else "%d coins" % cost
		var upgrade: Button = _shop_upgrade_buttons[kind]
		upgrade.text = "%s  [%d/%d]  •  %s" % [names[kind], level, progress.MAX_UPGRADE_LEVEL, suffix]
		upgrade.disabled = maxed or progress.coins < cost
		var current := _upgrade_value(kind, progress.upgrade_effect(kind, level))
		var effect_text := "%s: %s (maximum benefit)" % [effects[kind], current]
		if not maxed:
			var next := _upgrade_value(kind, progress.upgrade_effect(kind, level + 1))
			var affordability := "Ready to buy" if progress.coins >= cost else "Need %d more coins" % (cost - progress.coins)
			effect_text = "%s: %s → %s\n%s" % [effects[kind], current, next, affordability]
		_shop_upgrade_details[kind].text = effect_text
	# Preserve the old rebuild's scroll reset and keyboard focus.
	modal_scroll.scroll_vertical = 0
	if is_instance_valid(_shop_inventory):
		_shop_inventory.scroll_vertical = 0
	_shop_back.grab_focus()

func _upgrade_value(kind: String, value: float) -> String:
	match kind:
		"ease":
			return "+%s px" % String.num(value, 1)
		"weight":
			return "×%s" % String.num(value, 1)
		"speed":
			return "%s s" % String.num(value, 5)
	return ""

func _request_upgrade(kind: String) -> void:
	upgrade_requested.emit(kind)

func show_journal(progress) -> void:
	set_modal("Fish journal   •   %d / %d discovered" % [progress.discovered_species_count(), progress.FISH.size()])
	if progress.journal_complete():
		var celebration := _wrapped_label("JOURNAL COMPLETE! Every fish found. Nice fishing!", modal_body)
		celebration.add_theme_color_override("font_color", Color("397046"))
	var catalog: Array = progress.fish_catalog(true)
	for fish_index in catalog.size():
		var fish: Dictionary = catalog[fish_index]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		modal_body.add_child(row)
		var count := int(progress.discovered.get(fish.id, 0))
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(42, 36)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if count > 0:
			icon.texture = load(fish.texture_path)
			if fish.get("holographic", false):
				icon.material = _holographic_material()
		row.add_child(icon)
		var favourite := _preferred_spot(progress, fish_index % progress.FISH.size())
		var entry := "???   •   Undiscovered\nTry %s — this fish is more likely there." % favourite
		if count > 0:
			var record := "%.2f kg" % float(progress.best_weights[fish.id]) if progress.best_weights.has(fish.id) else "unknown — no saved weight for earlier catches"
			entry = "%s   •   caught %d   •   %d coins/kg\nPersonal best: %s\nFavourite spot: %s" % [fish.name, count, fish.price, record, favourite]
		if fish.get("holographic", false) and count == 0:
			entry = "Holographic ???   •   Undiscovered\nA very rare shimmer — try %s." % favourite
		_wrapped_label(entry, row)
	_wrapped_label("Every species can bite at every bank. Holographic variants appear in 1 in 200 bites, swim faster and take more hits. They are bonus discoveries. Favourite spots give better odds.\nDiscoveries and recorded personal bests stay after selling.", modal_body)
	_button("Back [Esc]", modal_actions, func(): close_requested.emit()).grab_focus()

func _preferred_spot(progress, fish_index: int) -> String:
	var favourite := ""
	var best_probability := -1.0
	for spot_id in progress.FISHING_SPOTS:
		var spot: Dictionary = progress.FISHING_SPOTS[spot_id]
		var total := 0.0
		for weight in spot.weights:
			total += float(weight)
		var probability := float(spot.weights[fish_index]) / total
		if probability > best_probability:
			best_probability = probability
			favourite = str(spot.name)
	return favourite

func show_pause() -> void:
	set_modal("A moment on the bank")
	_wrapped_label("WASD / arrows — walk\nE near water — cast\nE at the shop — sell / upgrade\nClick the moving target — reel in\nEnter / Space — start first-time guidance\nEnter on a result — cast again\nTab — journal    •    Esc — cancel / back\n\nProgress saves after catches, sales, upgrades\nand acknowledging fishing guidance.", modal_body)
	_button("Keep fishing [Esc]", modal_actions, func(): close_requested.emit()).grab_focus()
	_button("Reset save…", modal_actions, func(): reset_requested.emit())
	_button("Save & quit", modal_actions, func(): quit_requested.emit())

func show_reset_confirmation() -> void:
	set_modal("Reset your save?")
	_wrapped_label("This clears your coins, all three rod upgrades,\ncaught fish, journal discoveries and personal bests.\nFirst-time fishing guidance will appear again.\nYou will return to the starting bank.\n\nThis cannot be undone.", modal_body)
	_button("Cancel — keep my save [Esc]", modal_actions, func(): reset_cancelled.emit()).grab_focus()
	_button("Yes, reset my save", modal_actions, func(): reset_confirmed.emit())

func _label(value: String, parent: Node) -> Label:
	var label := Label.new()
	label.text = value
	parent.add_child(label)
	return label

func _wrapped_label(value: String, parent: Node) -> Label:
	var label := _label(value, parent)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label

func _button(value: String, parent: Node, action: Callable) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 42
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _holographic_material() -> ShaderMaterial:
	var shimmer := ShaderMaterial.new()
	shimmer.shader = preload("res://scripts/holographic.gdshader")
	return shimmer
