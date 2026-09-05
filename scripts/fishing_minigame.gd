extends Control
## Swimming aim-and-click encounter. Fish parameters use design-space pixels.

signal caught(fish: Dictionary)
signal escaped
signal cancelled

const DESIGN_SIZE := Vector2(760, 540)
const POND := Rect2(38, 118, 684, 280)
const INK := Color("263f3b")
const PAPER := Color("f5e6bd")
const CORAL := Color("d66a56")
const DASH_DURATION := 0.18

var active := false
var current_fish: Dictionary = {}
var target_position := Vector2.ZERO
var target_radius := 32.0
var swim_speed := 125.0
var required_hits := 8
var danger_speed := 0.045
var behavior := "steady"
var hit_count := 0
var catch_progress := 0.0
var danger_progress := -0.12
var dashing := false
var _dash_start := Vector2.ZERO
var _dash_destination := Vector2.ZERO
var _dash_elapsed := 0.0
var _direction := Vector2.RIGHT
var _elapsed := 0.0
var _flash := 0.0
var _miss_flash := 0.0
var _burst_time := 0.0
var _turn_time := 0.9
var _feedback := "Click the swimming fish!"
var _fish_color := Color("efbd62")
var _texture: Texture2D


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)
	if not active:
		hide()
		set_process(false)
		set_process_input(false)


func start_fishing(fish: Dictionary, rod_level: int = 0) -> void:
	current_fish = fish.duplicate(true)
	# Keep upgrades modest: they help aim without changing species identity.
	target_radius = clampf(float(fish.get("radius", 32.0)) + maxi(rod_level, 0) * 2.0, 14.0, 64.0)
	swim_speed = clampf(float(fish.get("speed", 125.0)), 20.0, 600.0)
	required_hits = clampi(int(fish.get("required_hits", 8)), 3, 30)
	danger_speed = clampf(float(fish.get("danger_speed", 0.045)), 0.005, 0.5)
	behavior = str(fish.get("behavior", "steady"))
	_fish_color = Color(str(fish.get("color", "efbd62")))
	_texture = null
	var texture_path := str(fish.get("texture_path", ""))
	if not texture_path.is_empty() and ResourceLoader.exists(texture_path):
		_texture = load(texture_path) as Texture2D
	target_position = POND.get_center()
	_direction = Vector2.from_angle(randf_range(-PI, PI))
	_elapsed = 0.0
	hit_count = 0
	catch_progress = 0.0
	# A short lead gives players time to locate the target before the chase catches up.
	danger_progress = -0.12
	_flash = 0.0
	_miss_flash = 0.0
	_burst_time = 0.0
	_turn_time = 0.9
	dashing = false
	_dash_elapsed = 0.0
	_feedback = "Click the swimming fish!"
	active = true
	show()
	set_process(true)
	set_process_input(true)
	queue_redraw()


func _process(delta: float) -> void:
	if not active:
		return
	_flash = maxf(0.0, _flash - delta * 4.0)
	_miss_flash = maxf(0.0, _miss_flash - delta * 3.0)
	var swim_delta := _advance_dash(delta) if dashing else delta
	if swim_delta > 0.000001:
		_swim(swim_delta)
	danger_progress += danger_speed * delta
	if danger_progress >= catch_progress:
		_finish(false)
	queue_redraw()


func _start_dash() -> void:
	var bounds := POND.grow(-target_radius - 8.0)
	var minimum_distance := maxf(140.0, target_radius * 2.0 + 40.0)
	_dash_start = target_position
	# Rejection sampling keeps the destination unpredictable and well clear of the old ring.
	for attempt in range(20):
		_dash_destination = Vector2(randf_range(bounds.position.x, bounds.end.x), randf_range(bounds.position.y, bounds.end.y))
		if _dash_start.distance_to(_dash_destination) >= minimum_distance:
			break
	if _dash_start.distance_to(_dash_destination) < minimum_distance:
		# A bounded fallback guarantees separation even after unlucky random samples.
		for corner in [bounds.position, bounds.end, Vector2(bounds.position.x, bounds.end.y), Vector2(bounds.end.x, bounds.position.y)]:
			if _dash_start.distance_to(corner) > _dash_start.distance_to(_dash_destination):
				_dash_destination = corner
	_direction = _dash_start.direction_to(_dash_destination)
	_dash_elapsed = 0.0
	dashing = true
	_feedback = "Dashing — track it!"


func _advance_dash(delta: float) -> float:
	var used_delta := minf(delta, DASH_DURATION - _dash_elapsed)
	_dash_elapsed = minf(DASH_DURATION, _dash_elapsed + used_delta)
	target_position = _dash_start.lerp(_dash_destination, _dash_elapsed / DASH_DURATION)
	if _dash_elapsed >= DASH_DURATION - 0.000001:
		target_position = _dash_destination
		dashing = false
		_feedback = "Click again! Keep reeling."
	# Any time beyond the dash belongs to normal swimming, even after a slow frame.
	return maxf(0.0, delta - used_delta)


func _swim(delta: float) -> void:
	_elapsed += delta
	_burst_time = maxf(0.0, _burst_time - delta)
	_turn_time -= delta
	if _turn_time <= 0.0:
		_turn_time = 0.9 if behavior == "fast" else 1.5
		if behavior == "fast":
			_direction = _direction.rotated(randf_range(0.7, 1.5) * (-1 if randf() < 0.5 else 1))
		elif behavior == "rare":
			# A fake-out changes heading, never position, before the speed burst.
			_direction = -_direction.rotated(randf_range(-0.4, 0.4))
			_burst_time = 0.4
	var speed_multiplier := 1.0
	if behavior == "weave":
		_direction = _direction.rotated(sin(_elapsed * 3.2) * delta * 2.0)
	elif behavior == "dart":
		speed_multiplier = 0.55 + pow(maxf(0.0, sin(_elapsed * 3.0)), 4.0) * 1.6
	elif behavior == "restless":
		_direction = _direction.rotated(sin(_elapsed * 5.0) * delta * 3.0)
		speed_multiplier = 1.0 + sin(_elapsed * 2.0) * 0.3
	if _burst_time > 0.0:
		speed_multiplier *= 1.5
	target_position += _direction * swim_speed * speed_multiplier * delta
	var bounds := POND.grow(-target_radius - 8.0)
	# Reflect overshoot instead of discarding distance at an edge on slower frames.
	for axis in range(2):
		while target_position[axis] < bounds.position[axis] or target_position[axis] > bounds.end[axis]:
			if target_position[axis] < bounds.position[axis]:
				target_position[axis] = 2.0 * bounds.position[axis] - target_position[axis]
			else:
				target_position[axis] = 2.0 * bounds.end[axis] - target_position[axis]
			_direction[axis] *= -1.0


func _input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_stop()
		cancelled.emit()


func _gui_input(event: InputEvent) -> void:
	if not active or not event is InputEventMouseButton:
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	accept_event()
	# Immune only during the brief dash: repeated clicks cannot score or cause unfair misses.
	if dashing:
		return
	var point: Vector2 = (event.position - _design_origin()) / _design_scale()
	if not POND.has_point(point):
		return
	if point.distance_to(target_position) <= target_radius:
		hit_count += 1
		catch_progress = float(hit_count) / required_hits
		_flash = 1.0
		_feedback = "Nice! Keep reeling."
		if hit_count >= required_hits:
			_finish(true)
		else:
			_start_dash()
	else:
		danger_progress += 0.04
		_miss_flash = 1.0
		_feedback = "A little wide! Red is catching up."
		if danger_progress >= catch_progress:
			_finish(false)
	queue_redraw()


func _finish(success: bool) -> void:
	_stop()
	if success:
		caught.emit(current_fish.duplicate(true))
	else:
		escaped.emit()


func _stop() -> void:
	active = false
	dashing = false
	hide()
	set_process(false)
	set_process_input(false)


func _design_scale() -> float:
	return maxf(0.01, minf((size.x - 24.0) / DESIGN_SIZE.x, (size.y - 24.0) / DESIGN_SIZE.y))


func _design_origin() -> Vector2:
	return (size - DESIGN_SIZE * _design_scale()) * 0.5


func _draw() -> void:
	if not active:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.15, 0.14, 0.70))
	draw_set_transform(_design_origin(), 0.0, Vector2.ONE * _design_scale())
	draw_rect(Rect2(Vector2(5, 7), DESIGN_SIZE), Color("142e2c"))
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), PAPER)
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), INK, false, 5.0)
	_text(Vector2(32, 43), "FISH ON!", 28, INK)
	_text(Vector2(32, 78), "Keep clicking the fish. Stay ahead of the red!", 19, INK)
	_text(Vector2(626, 43), "ESC  leave", 16, INK)
	draw_rect(POND, Color("70b8bb").lerp(CORAL, _miss_flash * 0.22))
	draw_rect(POND, INK, false, 4.0)
	for index in range(9):
		var wave_y := POND.position.y + 24.0 + index * 29.0
		var wave_x := POND.position.x + 30.0 + fmod(index * 97.0 + _elapsed * 9.0, 540.0)
		draw_line(Vector2(wave_x, wave_y), Vector2(wave_x + 55, wave_y), Color("94ced0"), 3.0)
	if dashing:
		for segment in range(4):
			var angle := segment * PI * 0.5
			draw_arc(target_position, target_radius, angle, angle + PI * 0.32, 12, Color("f4d478"), 3.0, true)
		draw_line(target_position - _direction * target_radius, target_position - _direction * target_radius * 2.0, Color(0.96, 0.90, 0.73, 0.6), 5.0)
	else:
		draw_arc(target_position, target_radius, 0.0, TAU, 48, PAPER, 3.0, true)
	if _flash > 0.0:
		draw_arc(target_position, target_radius + (1.0 - _flash) * 20.0, 0.0, TAU, 48, Color(1, 0.97, 0.78, _flash), 4.0, true)
	_draw_fish()
	_text(Vector2(38, 430), _feedback, 19, INK)
	_draw_catch_bar()
	_text(Vector2(38, 518), "RED = ESCAPE", 15, CORAL.darkened(0.2))
	_text(Vector2(318, 518), "%d / %d hits" % [hit_count, required_hits], 17, INK)
	_text(Vector2(628, 518), "CAUGHT", 17, INK)
	draw_set_transform(Vector2.ZERO)


func _draw_catch_bar() -> void:
	var bar := Rect2(40, 451, 680, 30)
	draw_rect(bar, Color("d8c89c"))
	# The small inlet to the left of zero shows the fish's starting lead honestly.
	var danger_ratio := clampf((danger_progress + 0.14) / 1.14, 0.0, 1.0)
	var fish_ratio := (catch_progress + 0.14) / 1.14
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * danger_ratio, bar.size.y)), CORAL)
	draw_rect(bar, INK, false, 3.0)
	var marker := Vector2(bar.position.x + bar.size.x * fish_ratio, bar.get_center().y)
	draw_circle(marker, 13, INK)
	draw_circle(marker, 9, Color("f4d478"))
	draw_line(Vector2(bar.end.x, bar.position.y - 8), Vector2(bar.end.x, bar.end.y + 8), INK, 4)


func _draw_fish() -> void:
	var direction := 1.0 if _direction.x >= 0.0 else -1.0
	var fish_scale := target_radius * (1.0 + _flash * 0.12)
	if _texture != null:
		var dimensions := _texture.get_size()
		var draw_size := dimensions * (fish_scale * 1.75 / maxf(dimensions.x, dimensions.y))
		# Supplied Kenney fish face left in their original textures.
		draw_set_transform(_design_origin() + target_position * _design_scale(), 0.0, Vector2(-direction, 1.0) * _design_scale())
		draw_texture_rect(_texture, Rect2(-draw_size * 0.5, draw_size), false)
		draw_set_transform(_design_origin(), 0.0, Vector2.ONE * _design_scale())
		return
	var tail := PackedVector2Array([
		target_position + Vector2(-0.4 * direction, 0) * fish_scale,
		target_position + Vector2(-0.85 * direction, -0.5) * fish_scale,
		target_position + Vector2(-0.85 * direction, 0.5) * fish_scale,
	])
	draw_colored_polygon(tail, _fish_color.darkened(0.15))
	draw_circle(target_position, fish_scale * 0.63, _fish_color)
	var eye := target_position + Vector2(0.25 * direction, -0.17) * fish_scale
	draw_circle(eye, 5.0, PAPER)
	draw_circle(eye + Vector2(direction, 0), 2.5, INK)


func _text(position_at: Vector2, value: String, font_size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, position_at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
