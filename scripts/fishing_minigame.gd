extends Control
## Swimming aim-and-click encounter. Fish parameters use design-space pixels.

signal caught(fish: Dictionary)
signal escaped
signal cancelled
signal introduction_completed

const Progress = preload("res://scripts/prototype_progress.gd")
const DESIGN_SIZE := Vector2(760, 540)
const POND := Rect2(38, 118, 684, 280)
const INTRO_START := Rect2(218, 322, 324, 46)
const INK := Color("263f3b")
const PAPER := Color("f5e6bd")
const CORAL := Color("d66a56")
const DASH_DURATION := 0.18

var active := false
var introducing := false
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
var _hit_position := Vector2.ZERO
var _miss_position := Vector2.ZERO
var _burst_time := 0.0
var _turn_time := 0.9
var _feedback := "Click the swimming fish!"
var _fish_color := Color("efbd62")
var _texture: Texture2D
var _background: Node2D
var _fish_canvas: Node2D


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_background = Node2D.new()
	_background.show_behind_parent = true
	add_child(_background)
	_background.draw.connect(_draw_background)
	_fish_canvas = Node2D.new()
	_fish_canvas.show_behind_parent = true
	add_child(_fish_canvas)
	_fish_canvas.draw.connect(_draw_fish)
	resized.connect(_redraw_all)
	if not active:
		hide()
		set_process(false)
		set_process_input(false)


func start_fishing(fish: Dictionary, rod_level: int = 0, show_intro: bool = false) -> void:
	current_fish = fish.duplicate(true)
	_fish_canvas.material = null
	if fish.get("holographic", false):
		var shimmer := ShaderMaterial.new()
		shimmer.shader = preload("res://scripts/holographic.gdshader")
		_fish_canvas.material = shimmer
	# Keep upgrades modest: they help aim without changing species identity.
	target_radius = clampf(float(fish.get("radius", 32.0)) + Progress.upgrade_effect("ease", rod_level), 14.0, 64.0)
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
	introducing = show_intro
	show()
	set_process(not introducing)
	set_process_input(true)
	_redraw_all()


func dismiss_introduction() -> void:
	if not active or not introducing:
		return
	introducing = false
	set_process(true)
	introduction_completed.emit()
	queue_redraw()


func _process(delta: float) -> void:
	if not active or introducing:
		return
	_flash = maxf(0.0, _flash - delta * 2.5)
	_miss_flash = maxf(0.0, _miss_flash - delta * 2.5)
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
	_feedback = "Dashing — track it! Clicks are paused."


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
	elif introducing and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			get_viewport().set_input_as_handled()
			dismiss_introduction()


func _gui_input(event: InputEvent) -> void:
	if not active or not event is InputEventMouseButton:
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	accept_event()
	var point: Vector2 = (event.position - _design_origin()) / _design_scale()
	if introducing:
		if INTRO_START.has_point(point):
			dismiss_introduction()
		# The acknowledgement click must never also reach the fish.
		return
	# Immune only during the brief dash: repeated clicks cannot score or cause unfair misses.
	if dashing:
		return
	if not POND.has_point(point):
		return
	if point.distance_to(target_position) <= target_radius:
		hit_count += 1
		catch_progress = float(hit_count) / required_hits
		_flash = 1.0
		_hit_position = target_position
		_feedback = "Nice! Keep reeling."
		if hit_count >= required_hits:
			_finish(true)
		else:
			_start_dash()
	else:
		danger_progress += 0.04
		_miss_flash = 1.0
		_miss_position = point
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
	introducing = false
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
	draw_set_transform(_design_origin(), 0.0, Vector2.ONE * _design_scale())
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
	_draw_click_feedback()
	_fish_canvas.queue_redraw()
	_text(Vector2(38, 430), "Take your time — fishing is paused." if introducing else _feedback, 19, INK)
	_draw_catch_bar()
	var danger_label := "RED IS CLOSE!" if catch_progress - danger_progress <= 0.06 else "RED = ESCAPE"
	_text(Vector2(38, 518), danger_label, 15, CORAL.darkened(0.2))
	_text(Vector2(318, 518), "%d / %d hits" % [hit_count, required_hits], 17, INK)
	_text(Vector2(628, 518), "CAUGHT", 17, INK)
	if introducing:
		_draw_introduction()
	draw_set_transform(Vector2.ZERO)


func _redraw_all() -> void:
	queue_redraw()
	if is_instance_valid(_background):
		_background.queue_redraw()


func _draw_background() -> void:
	# Static commands stay cached while the fish, waves and catch bar animate.
	if not active:
		return
	_background.draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.15, 0.14, 0.70))
	_background.draw_set_transform(_design_origin(), 0.0, Vector2.ONE * _design_scale())
	_background.draw_rect(Rect2(Vector2(5, 7), DESIGN_SIZE), Color("142e2c"))
	_background.draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), PAPER)
	_background.draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), INK, false, 5.0)
	_text(Vector2(32, 43), "HOLOGRAPHIC FISH ON!" if current_fish.get("holographic", false) else "FISH ON!", 28, INK, _background)
	_text(Vector2(32, 78), "Click inside the ring. Keep the gold marker ahead of red!", 19, INK, _background)
	_text(Vector2(626, 43), "ESC  leave", 16, INK, _background)
	_background.draw_rect(POND, Color("70b8bb"))
	_background.draw_rect(POND, INK, false, 4.0)
	_background.draw_set_transform(Vector2.ZERO)


func _draw_introduction() -> void:
	var panel := Rect2(56, 136, 648, 248)
	draw_rect(Rect2(panel.position + Vector2(4, 5), panel.size), INK)
	draw_rect(panel, PAPER)
	draw_rect(panel, INK, false, 4.0)
	_text(Vector2(78, 174), "Your first fish — here's the trick!", 23, INK)
	_text(Vector2(78, 211), "AIM: Click anywhere inside the fish's white ring.", 18, INK)
	_text(Vector2(78, 242), "REEL: Each hit moves gold ahead. Red catching it = escape.", 18, INK)
	_text(Vector2(78, 273), "DASH: After a hit, track it. Clicks pause until the ring returns.", 18, INK)
	_text(Vector2(78, 304), "A miss moves red closer. Escape leaves without starting.", 17, INK)
	draw_rect(Rect2(INTRO_START.position + Vector2(3, 4), INTRO_START.size), INK)
	draw_rect(INTRO_START, Color("f4d478"))
	draw_rect(INTRO_START, INK, false, 3.0)
	_text(INTRO_START.position + Vector2(24, 30), "Start fishing  [Enter / Space]", 20, INK)


func _draw_click_feedback() -> void:
	if _flash > 0.0:
		var ripple_radius := target_radius + (1.0 - _flash) * 26.0
		var hit_color := Color(1.0, 0.97, 0.78, _flash)
		draw_arc(_hit_position, ripple_radius, 0.0, TAU, 48, hit_color, 4.0, true)
		for index in range(6):
			var ray := Vector2.from_angle(index * TAU / 6.0)
			draw_line(_hit_position + ray * (ripple_radius + 5.0), _hit_position + ray * (ripple_radius + 14.0), hit_color, 3.0, true)
		var label_position := _hit_position + Vector2(-12, -target_radius - 8.0 - (1.0 - _flash) * 12.0)
		label_position.y = maxf(POND.position.y + 24.0, label_position.y)
		_text(label_position + Vector2(2, 2), "+1", 24, Color(INK, _flash))
		_text(label_position, "+1", 24, hit_color)
	if _miss_flash > 0.0:
		var miss_color := Color(CORAL.darkened(0.2), _miss_flash)
		var radius := 10.0 + (1.0 - _miss_flash) * 12.0
		draw_arc(_miss_position, radius + 8.0, 0.0, TAU, 32, miss_color, 3.0, true)
		draw_line(_miss_position + Vector2(-radius, -radius), _miss_position + Vector2(radius, radius), miss_color, 4.0, true)
		draw_line(_miss_position + Vector2(-radius, radius), _miss_position + Vector2(radius, -radius), miss_color, 4.0, true)
		var label_position := Vector2(clampf(_miss_position.x - 22.0, POND.position.x + 6.0, POND.end.x - 54.0), maxf(POND.position.y + 22.0, _miss_position.y - radius - 10.0))
		_text(label_position, "MISS", 17, miss_color)


func _draw_catch_bar() -> void:
	var bar := Rect2(40, 451, 680, 30)
	draw_rect(bar, Color("d8c89c"))
	# The small inlet to the left of zero shows the fish's starting lead honestly.
	var danger_ratio := clampf((danger_progress + 0.14) / 1.14, 0.0, 1.0)
	var fish_ratio := (catch_progress + 0.14) / 1.14
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * danger_ratio, bar.size.y)), CORAL)
	draw_rect(bar, INK, false, 3.0)
	var danger_x := bar.position.x + bar.size.x * danger_ratio
	draw_line(Vector2(danger_x, bar.position.y), Vector2(danger_x, bar.end.y), INK, 3.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(danger_x - 6.0, bar.end.y + 9.0),
		Vector2(danger_x + 6.0, bar.end.y + 9.0),
		Vector2(danger_x, bar.end.y + 1.0),
	]), CORAL.darkened(0.2))
	if catch_progress - danger_progress <= 0.06 or _miss_flash > 0.0:
		draw_rect(bar.grow(3.0), CORAL.darkened(0.2), false, 3.0)
	var marker := Vector2(bar.position.x + bar.size.x * fish_ratio, bar.get_center().y)
	draw_circle(marker, 13, INK)
	draw_circle(marker, 9, Color("f4d478"))
	draw_line(Vector2(bar.end.x, bar.position.y - 8), Vector2(bar.end.x, bar.end.y + 8), INK, 4)


func _draw_fish() -> void:
	if not active:
		return
	_fish_canvas.draw_set_transform(_design_origin(), 0.0, Vector2.ONE * _design_scale())
	var direction := 1.0 if _direction.x >= 0.0 else -1.0
	var fish_scale := target_radius * (1.0 + _flash * 0.12)
	if _texture != null:
		var dimensions := _texture.get_size()
		var draw_size := dimensions * (fish_scale * 1.75 / maxf(dimensions.x, dimensions.y))
		# Supplied Kenney fish face left in their original textures.
		_fish_canvas.draw_set_transform(_design_origin() + target_position * _design_scale(), 0.0, Vector2(-direction, 1.0) * _design_scale())
		_fish_canvas.draw_texture_rect(_texture, Rect2(-draw_size * 0.5, draw_size), false)
		_fish_canvas.draw_set_transform(_design_origin(), 0.0, Vector2.ONE * _design_scale())
		return
	var tail := PackedVector2Array([
		target_position + Vector2(-0.4 * direction, 0) * fish_scale,
		target_position + Vector2(-0.85 * direction, -0.5) * fish_scale,
		target_position + Vector2(-0.85 * direction, 0.5) * fish_scale,
	])
	_fish_canvas.draw_colored_polygon(tail, _fish_color.darkened(0.15))
	_fish_canvas.draw_circle(target_position, fish_scale * 0.63, _fish_color)
	var eye := target_position + Vector2(0.25 * direction, -0.17) * fish_scale
	_fish_canvas.draw_circle(eye, 5.0, PAPER)
	_fish_canvas.draw_circle(eye + Vector2(direction, 0), 2.5, INK)


func _text(position_at: Vector2, value: String, font_size: int, color: Color, canvas: CanvasItem = self) -> void:
	canvas.draw_string(ThemeDB.fallback_font, position_at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
