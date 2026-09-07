extends Node2D

## Plain temporary marker. Replace with the player's supplied character art later.
const WALK_SPEED := 210.0
const FOOT_RADIUS := 9.0

var body := Node2D.new()
var stride := 0.0
var casting := false
var cast_offset := Vector2.ZERO
var pose_tween: Tween

func _ready() -> void:
	add_child(body)
	var marker := ColorRect.new()
	marker.position = Vector2(-10, -26)
	marker.size = Vector2(20, 28)
	marker.color = Color("f9f4db")
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(marker)
	var label := Label.new()
	label.text = "YOU"
	label.position = Vector2(-20, -48)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color("243645"))
	add_child(label)

func walk(delta: float, can_stand: Callable) -> void:
	var direction := Vector2(
		float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
		float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
	).normalized()
	var previous_position := position
	var motion := direction * WALK_SPEED * delta
	# Substeps keep the foot marker on land even after a long frame.
	var steps := maxi(1, ceili(motion.length() / FOOT_RADIUS))
	motion /= steps
	for step in steps:
		var next := position + Vector2(motion.x, 0)
		if can_stand.call(next):
			position = next
		next = position + Vector2(0, motion.y)
		if can_stand.call(next):
			position = next
	var distance := position.distance_to(previous_position)
	if distance < 0.01:
		rest()
		return
	stride = fmod(stride + distance * 0.09, TAU)
	var bounce := absf(sin(stride))
	body.position = Vector2(0, -bounce * 2.5)
	body.scale = Vector2(1.0 + bounce * 0.035, 1.0 - bounce * 0.035)
	body.rotation = sin(stride) * 0.035

func rest() -> void:
	if casting:
		return
	body.position = Vector2.ZERO
	body.scale = Vector2.ONE
	body.rotation = 0.0

func begin_cast(target: Vector2) -> void:
	end_cast()
	casting = true
	cast_offset = (target - position).normalized() * 3.0
	pose_tween = create_tween().set_parallel(true)
	pose_tween.tween_property(body, "rotation", cast_offset.x * 0.055, 0.2)
	pose_tween.tween_property(body, "position", cast_offset, 0.2)
	pose_tween.tween_property(body, "scale", Vector2(1.04, 0.96), 0.2)

func show_bite() -> void:
	if not casting:
		return
	if pose_tween:
		pose_tween.kill()
	pose_tween = create_tween()
	pose_tween.tween_property(body, "position", cast_offset + Vector2(0, -4), 0.12)
	pose_tween.tween_property(body, "position", cast_offset, 0.4).set_trans(Tween.TRANS_SINE)

func end_cast() -> void:
	if pose_tween:
		pose_tween.kill()
	casting = false
	rest()
