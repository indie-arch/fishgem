extends CanvasLayer
## Temporary interface: replace visuals without changing prototype rules.

signal journal_requested
signal pause_requested
signal close_requested
signal sell_requested
signal upgrade_requested(kind: String)
signal quit_requested
signal reset_requested
signal reset_confirmed
signal reset_cancelled

var stats: Label
var hint: Label
var notice: Label
var modal: PanelContainer
var modal_title: Label
var modal_body: VBoxContainer
var journal_button: Button
var pause_button: Button
var _screen: Control

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
	stats = _label("", row)
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	modal.custom_minimum_size = Vector2(590, 0)
	center.add_child(modal)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	modal.add_child(column)
	modal_title = _label("", column)
	modal_title.add_theme_font_size_override("font_size", 27)
	modal_body = VBoxContainer.new()
	modal_body.add_theme_constant_override("separation", 10)
	column.add_child(modal_body)
	modal.hide()

func update_stats(coins: int, bag_count: int) -> void:
	stats.text = "FISHGEM   •   %d coins   •   %d fish" % [coins, bag_count]

func set_modal(title: String) -> void:
	modal_title.text = title
	for child in modal_body.get_children():
		modal_body.remove_child(child)
		child.queue_free()
	modal.show()
	journal_button.disabled = true
	pause_button.disabled = true

func hide_modal() -> void:
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

func show_result(title: String, details: String, texture_path: String) -> void:
	set_modal(title)
	if not texture_path.is_empty():
		var icon := TextureRect.new()
		icon.texture = load(texture_path)
		icon.custom_minimum_size = Vector2(100, 76)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		modal_body.add_child(icon)
	_label(details, modal_body)
	_button("Keep fishing [Enter / Esc]", modal_body, func(): close_requested.emit()).grab_focus()

func show_shop(progress) -> void:
	set_modal("Bait & bits")
	_label("Fish value = species rate × weight.\nEach rod upgrade improves just one thing.", modal_body)
	if not progress.bag.is_empty():
		var scroll := ScrollContainer.new()
		scroll.custom_minimum_size.y = minf(110.0, progress.bag.size() * 27.0)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		modal_body.add_child(scroll)
		var catches := VBoxContainer.new()
		catches.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(catches)
		for caught_fish in progress.bag:
			var fish: Dictionary = progress.fish_by_id(caught_fish.id)
			_label("%s  •  %.2f kg  •  %d coins" % [fish.name, caught_fish.weight_kg, progress.sale_value(caught_fish)], catches)
	var sell := _button("Sell %d fish for %d coins" % [progress.bag.size(), progress.bag_value()], modal_body, func(): sell_requested.emit())
	sell.disabled = progress.bag.is_empty()
	var names := {"ease": "Steady grip — easier aiming", "weight": "Heavy lure — heavier catches", "speed": "Quick bite — shorter waits"}
	for kind in ["ease", "weight", "speed"]:
		var level := int(progress.upgrades[kind])
		var cost: int = progress.upgrade_cost(kind)
		var suffix := "MAX" if level >= 3 else "%d coins" % cost
		var upgrade := _button("%s  [%d/3]  •  %s" % [names[kind], level, suffix], modal_body, _request_upgrade.bind(kind))
		upgrade.disabled = level >= 3 or progress.coins < cost
	_button("Back to the bank [Esc]", modal_body, func(): close_requested.emit()).grab_focus()

func _request_upgrade(kind: String) -> void:
	upgrade_requested.emit(kind)

func show_journal(progress) -> void:
	set_modal("Fish journal   •   %d / 6 discovered" % progress.discovered.size())
	for fish in progress.fish_catalog():
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
		row.add_child(icon)
		_label("???   •   Keep fishing!" if count == 0 else "%s   •   caught %d   •   %d coins/kg" % [fish.name, count, fish.price], row)
	_label("Discoveries stay in your journal after selling.", modal_body)
	_button("Back [Esc]", modal_body, func(): close_requested.emit()).grab_focus()

func show_pause() -> void:
	set_modal("A moment on the bank")
	_label("WASD / arrows — walk\nE near water — cast\nE at the shop — sell / upgrade\nClick the moving target — reel in\nTab — journal    •    Esc — cancel / pause\n\nProgress saves after catches, sales and upgrades.", modal_body)
	_button("Keep fishing [Esc]", modal_body, func(): close_requested.emit()).grab_focus()
	_button("Reset save…", modal_body, func(): reset_requested.emit())
	_button("Save & quit", modal_body, func(): quit_requested.emit())

func show_reset_confirmation() -> void:
	set_modal("Reset your save?")
	_label("This clears your coins, all three rod upgrades,\ncaught fish and journal discoveries.\nYou will return to the starting bank.\n\nThis cannot be undone.", modal_body)
	_button("Cancel — keep my save [Esc]", modal_body, func(): reset_cancelled.emit()).grab_focus()
	_button("Yes, reset my save", modal_body, func(): reset_confirmed.emit())

func _label(value: String, parent: Node) -> Label:
	var label := Label.new()
	label.text = value
	parent.add_child(label)
	return label

func _button(value: String, parent: Node, action: Callable) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 42
	button.pressed.connect(action)
	parent.add_child(button)
	return button
