extends Node2D

## Plain temporary marker. Replace with the player's supplied character art later.
const WALK_SPEED := 210.0
const FOOT_RADIUS := 9.0

func _ready() -> void:
	var marker := ColorRect.new()
	marker.position = Vector2(-10, -26)
	marker.size = Vector2(20, 28)
	marker.color = Color("f9f4db")
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(marker)
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
