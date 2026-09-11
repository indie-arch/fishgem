extends Control
## Keep the original wrapped labels and spacing, but allocate only visible rows.
var rows := PackedStringArray()
var _offsets := PackedFloat32Array()
var _labels: Array[Label] = []
var _measure: Label
var _scroll: ScrollContainer
var _measured_width := -1.0
var _layout_pending := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_scroll = get_parent() as ScrollContainer
	_measure = _new_label()
	_measure.hide()
	resized.connect(_schedule_layout)
	_scroll.resized.connect(_show_visible_rows)
	_scroll.get_v_scroll_bar().value_changed.connect(func(_value): _show_visible_rows())
	_schedule_layout()

func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_instance_valid(_measure):
		_measured_width = -1.0
		_schedule_layout()

func _schedule_layout() -> void:
	if not _layout_pending:
		_layout_pending = true
		_layout_rows.call_deferred()

func _layout_rows() -> void:
	_layout_pending = false
	if size.x <= 0.0 or size.x == _measured_width:
		return
	_measured_width = size.x
	_measure.size.x = size.x
	var separation := get_theme_constant("separation", "VBoxContainer")
	_offsets.resize(rows.size() + 1)
	_offsets[0] = 0.0
	var measured_heights := {}
	for index in rows.size():
		# Label measures wrapping with the same font and width as the visible row.
		# Equal species/weights often produce identical rows in a large bag.
		if not measured_heights.has(rows[index]):
			_measure.text = rows[index]
			measured_heights[rows[index]] = _measure.get_minimum_size().y
		_offsets[index + 1] = _offsets[index] + float(measured_heights[rows[index]]) + separation
	custom_minimum_size.y = maxf(0.0, _offsets[rows.size()] - separation)
	_show_visible_rows()

func _show_visible_rows() -> void:
	if _offsets.is_empty():
		return
	var top := float(_scroll.scroll_vertical)
	var bottom := top + _scroll.size.y
	var index := maxi(0, _offsets.bsearch(top) - 1)
	var used := 0
	var separation := get_theme_constant("separation", "VBoxContainer")
	while index < rows.size() and _offsets[index] <= bottom:
		if used == _labels.size():
			_labels.append(_new_label())
		var label := _labels[used]
		# Establish width before text: a new zero-width Label otherwise clamps its
		# height to a character-per-line minimum until a later container layout.
		label.size.x = size.x
		label.text = rows[index]
		label.position = Vector2(0.0, _offsets[index])
		label.size = Vector2(size.x, _offsets[index + 1] - _offsets[index] - separation)
		label.show()
		index += 1
		used += 1
	for unused in range(used, _labels.size()):
		_labels[unused].hide()

func _new_label() -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(label)
	return label
