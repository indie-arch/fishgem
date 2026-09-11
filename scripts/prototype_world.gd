extends Node2D

signal fish_requested
signal shop_requested
signal interaction_hint(text: String)

const PlayerScript = preload("res://scripts/prototype_player.gd")
const CastEffectScript = preload("res://scripts/cast_effect.gd")
const Progress = preload("res://scripts/prototype_progress.gd")
const PAINTED_WORLD = preload("res://node_2d.tscn")
const SHOP_CELL := Vector2i(3, 0)
const SPAWN_CELL := Vector2i(1, 3)
const SPOT_IDS := ["west_bank", "home_bank", "east_bank"]
const NEIGHBORS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
const FOOT_OFFSETS := [Vector2(-9, -9), Vector2(9, -9), Vector2(-9, 9), Vector2(9, 9)]
var input_enabled := true
var hint := ""
var player: Node2D
var ground: TileMapLayer
var shop_position := Vector2.ZERO
var cast_position := Vector2.ZERO
var cast_effect: Node2D
var shore_min_x := 0.0
var shore_max_x := 0.0
var shop_sign: Label
var shop_sign_phase := 0.0
var shop_attention := 0.0
var _hint_context := ""

func _ready() -> void:
	var painted_world := PAINTED_WORLD.instantiate()
	add_child(painted_world)
	ground = painted_world.get_node("Ground")
	shop_position = ground.map_to_local(SHOP_CELL)
	_add_shop_marker()
	_add_fishing_markers()
	player = Node2D.new()
	player.set_script(PlayerScript)
	player.name = "Player"
	player.position = ground.map_to_local(SPAWN_CELL)
	player.z_index = 3
	add_child(player)
	var camera := Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	player.add_child(camera)
	_update_hint()

func _physics_process(delta: float) -> void:
	if input_enabled:
		player.walk(delta, can_stand)
	else:
		player.rest()
	_update_hint()

func _process(delta: float) -> void:
	var previous_attention := shop_attention
	shop_attention = move_toward(shop_attention, 1.0 if input_enabled and is_near_shop() else 0.0, delta * 4.0)
	shop_sign_phase = fmod(shop_sign_phase + delta * 3.5, TAU)
	# Keep the phase advancing so approaching the shop has identical animation.
	if shop_attention == 0.0 and previous_attention == 0.0:
		return
	shop_sign.position = shop_position + Vector2(-34, -63 - absf(sin(shop_sign_phase)) * 3.0 * shop_attention)
	shop_sign.rotation = sin(shop_sign_phase) * 0.035 * shop_attention

func _unhandled_key_input(event: InputEvent) -> void:
	if not input_enabled or not event is InputEventKey:
		return
	if not event.pressed or event.echo or (event.keycode != KEY_E and event.physical_keycode != KEY_E):
		return
	if is_near_shop():
		get_viewport().set_input_as_handled()
		shop_requested.emit()
	elif is_near_water():
		get_viewport().set_input_as_handled()
		fish_requested.emit()

func is_land(cell: Vector2i) -> bool:
	if ground.get_cell_source_id(cell) < 0:
		return false
	var atlas := ground.get_cell_atlas_coords(cell)
	# This supplied sheet places grass/dirt in columns 0–9 and water in 10–14.
	# Water shoreline tiles remain blocked: they contain water inside the cell.
	return atlas.y >= 0 and atlas.y <= 2 and atlas.x >= 0 and atlas.x < 10

func can_stand(point: Vector2) -> bool:
	for offset in FOOT_OFFSETS:
		if not is_land(ground.local_to_map(point + offset)):
			return false
	return true

func is_near_water() -> bool:
	return _is_shore(ground.local_to_map(player.position))

func _is_water(cell: Vector2i) -> bool:
	if ground.get_cell_source_id(cell) < 0:
		return false
	var atlas := ground.get_cell_atlas_coords(cell)
	return atlas.x >= 10 and atlas.x <= 14 and atlas.y >= 0 and atlas.y <= 2

func _is_shore(cell: Vector2i) -> bool:
	for offset in NEIGHBORS:
		if _is_water(cell + offset):
			return true
	return false

func is_near_shop() -> bool:
	return player.position.distance_to(shop_position) <= 95.0

func get_fishing_spot() -> String:
	return _spot_at_x(player.position.x)

func _spot_at_x(point_x: float) -> String:
	var fraction := (point_x - shore_min_x) / maxf(shore_max_x - shore_min_x, 1.0)
	return SPOT_IDS[clampi(int(floor(fraction * 3.0)), 0, 2)]

func _add_fishing_markers() -> void:
	# Only the spawn-connected island counts, not the painted ocean or isolated land.
	var reachable: Array[Vector2i] = [SPAWN_CELL]
	var visited := {SPAWN_CELL: true}
	var shore: Array[Vector2] = []
	var cursor := 0
	shore_min_x = INF
	shore_max_x = -INF
	var half_tile := float(ground.tile_set.tile_size.x) * 0.5
	while cursor < reachable.size():
		var cell := reachable[cursor]
		cursor += 1
		var point := ground.map_to_local(cell)
		if _is_shore(cell):
			shore.append(point)
			shore_min_x = minf(shore_min_x, point.x - half_tile + PlayerScript.FOOT_RADIUS)
			shore_max_x = maxf(shore_max_x, point.x + half_tile - PlayerScript.FOOT_RADIUS)
		for offset in NEIGHBORS:
			var neighbor: Vector2i = cell + offset
			if not visited.has(neighbor) and can_stand(ground.map_to_local(neighbor)):
				visited[neighbor] = true
				reachable.append(neighbor)
	for index in SPOT_IDS.size():
		var spot_id: String = SPOT_IDS[index]
		var target := Vector2(lerpf(shore_min_x, shore_max_x, (float(index) + 0.5) / 3.0), ground.map_to_local(SPAWN_CELL).y + 128.0)
		var nearest := Vector2.ZERO
		var distance := INF
		for point in shore:
			if _spot_at_x(point.x) == spot_id and point.distance_squared_to(target) < distance:
				nearest = point
				distance = point.distance_squared_to(target)
		var label := _add_label(str(Progress.FISHING_SPOTS[spot_id]["name"]), nearest + Vector2(-70, -64))
		label.name = spot_id
		label.custom_minimum_size.x = 140.0
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.modulate.a = 0.8

func begin_cast() -> void:
	end_cast()
	var cell := ground.local_to_map(player.position)
	var closest_distance := INF
	var found_water := false
	for offset in NEIGHBORS:
		var neighbor: Vector2i = cell + offset
		if not _is_water(neighbor):
			continue
		var landing := ground.map_to_local(neighbor)
		var distance := player.position.distance_squared_to(landing)
		if distance < closest_distance:
			closest_distance = distance
			cast_position = landing
			found_water = true
	if not found_water:
		return
	player.begin_cast(cast_position)
	cast_effect = Node2D.new()
	cast_effect.set_script(CastEffectScript)
	cast_effect.origin = player.position + Vector2(7, -15)
	cast_effect.landing = cast_position
	cast_effect.z_index = 4
	add_child(cast_effect)

func show_bite() -> void:
	if is_instance_valid(cast_effect):
		cast_effect.show_bite()
		player.show_bite()

func end_cast() -> void:
	if is_instance_valid(cast_effect):
		cast_effect.hide()
		cast_effect.queue_free()
	cast_effect = null
	cast_position = Vector2.ZERO
	if is_instance_valid(player):
		player.end_cast()

func _update_hint() -> void:
	# Keep live tile checks for map edits, but format text only when the interaction changes.
	var context := "disabled"
	if input_enabled:
		context = "world"
		if is_near_shop():
			context = "shop"
		elif is_near_water():
			context = get_fishing_spot()
	if context == _hint_context:
		return
	_hint_context = context
	var next := "WASD / arrows: walk · E: interact · Tab: journal"
	if context == "disabled":
		next = ""
	elif context == "shop":
		next = "E: shop — sell fish and buy upgrades"
	elif context != "world":
		var spot: Dictionary = Progress.FISHING_SPOTS[context]
		next = "E: cast at %s — %s" % [spot["name"], spot["hint"]]
	if next != hint:
		hint = next
		interaction_hint.emit(hint)

func _add_shop_marker() -> void:
	var marker := ColorRect.new()
	marker.position = shop_position - Vector2(26, 22)
	marker.size = Vector2(52, 44)
	marker.color = Color("bd996a")
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.z_index = 2
	add_child(marker)
	shop_sign = _add_label("SHOP\nE to trade", shop_position + Vector2(-34, -63))
	shop_sign.pivot_offset = Vector2(34, 28)

func _add_label(text: String, point: Vector2) -> Label:
	var label := Label.new()
	label.text = text
	label.position = point
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color("243645"))
	label.z_index = 2
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label
