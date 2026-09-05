extends Node2D

signal fish_requested
signal shop_requested
signal interaction_hint(text: String)

const PlayerScript = preload("res://scripts/prototype_player.gd")
const CastEffectScript = preload("res://scripts/cast_effect.gd")
const PAINTED_WORLD = preload("res://node_2d.tscn")
const SHOP_CELL := Vector2i(3, 0)
const SPAWN_CELL := Vector2i(1, 3)
var input_enabled := true
var hint := ""
var player: Node2D
var ground: TileMapLayer
var shop_position := Vector2.ZERO
var cast_position := Vector2.ZERO
var cast_effect: Node2D

func _ready() -> void:
	var painted_world := PAINTED_WORLD.instantiate()
	add_child(painted_world)
	ground = painted_world.get_node("Ground")
	shop_position = ground.map_to_local(SHOP_CELL)
	_add_shop_marker()
	_add_label("FISHING SHORE\nE near water", ground.map_to_local(Vector2i(1, 5)) + Vector2(-62, -30))
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
	_update_hint()

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
	for offset in [Vector2(-9, -9), Vector2(9, -9), Vector2(-9, 9), Vector2(9, 9)]:
		if not is_land(ground.local_to_map(point + offset)):
			return false
	return true

func is_near_water() -> bool:
	var cell := ground.local_to_map(player.position)
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var neighbor: Vector2i = cell + offset
		if ground.get_cell_source_id(neighbor) >= 0 and not is_land(neighbor):
			return true
	return false

func is_near_shop() -> bool:
	return player.position.distance_to(shop_position) <= 95.0

func begin_cast() -> void:
	end_cast()
	var cell := ground.local_to_map(player.position)
	var closest_distance := INF
	var found_water := false
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var neighbor: Vector2i = cell + offset
		var atlas := ground.get_cell_atlas_coords(neighbor)
		if ground.get_cell_source_id(neighbor) < 0 or atlas.x < 10 or atlas.x > 14 or atlas.y < 0 or atlas.y > 2:
			continue
		var landing := ground.map_to_local(neighbor)
		var distance := player.position.distance_squared_to(landing)
		if distance < closest_distance:
			closest_distance = distance
			cast_position = landing
			found_water = true
	if not found_water:
		return
	cast_effect = Node2D.new()
	cast_effect.set_script(CastEffectScript)
	cast_effect.origin = player.position + Vector2(7, -15)
	cast_effect.landing = cast_position
	cast_effect.z_index = 4
	add_child(cast_effect)

func end_cast() -> void:
	if is_instance_valid(cast_effect):
		cast_effect.hide()
		cast_effect.queue_free()
	cast_effect = null
	cast_position = Vector2.ZERO

func _update_hint() -> void:
	var next := "WASD / arrows: walk · E: interact · Tab: journal"
	if not input_enabled:
		next = ""
	elif is_near_shop():
		next = "E: shop — sell fish and buy upgrades"
	elif is_near_water():
		next = "E: cast a line"
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
	_add_label("SHOP\nE to trade", shop_position + Vector2(-34, -63))

func _add_label(text: String, point: Vector2) -> void:
	var label := Label.new()
	label.text = text
	label.position = point
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color("243645"))
	label.z_index = 2
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
