extends Node2D

## Temporary geometric fishing feedback; replace only if final effect art is supplied.
const FLIGHT_TIME := 0.35
const SPLASH_TIME := 0.8
var origin := Vector2.ZERO
var landing := Vector2.ZERO
var elapsed := 0.0
var biting := false
var bite_elapsed := 0.0

func _process(delta: float) -> void:
	elapsed += delta
	if biting:
		bite_elapsed += delta
	queue_redraw()

func show_bite() -> void:
	biting = true
	bite_elapsed = 0.0
	queue_redraw()

func _draw() -> void:
	var direction := (landing - origin).normalized()
	var rod_tip := origin + direction * 26.0 + Vector2(0, -16)
	draw_line(origin, rod_tip, Color("785639"), 3.0, true)
	var progress := clampf(elapsed / FLIGHT_TIME, 0.0, 1.0)
	var bobber := rod_tip.lerp(landing, progress)
	if elapsed < FLIGHT_TIME:
		bobber.y -= sin(progress * PI) * 48.0
	elif biting:
		bobber.y += 5.0 + absf(sin(bite_elapsed * 14.0)) * 7.0
	else:
		bobber.y += sin((elapsed - FLIGHT_TIME) * 5.0) * 1.5
	draw_line(rod_tip, bobber, Color("f6f1d3"), 1.5, true)
	if elapsed >= FLIGHT_TIME:
		_draw_splash(elapsed - FLIGHT_TIME)
	draw_circle(bobber, 4.0, Color("fff8e5"))
	draw_circle(bobber + Vector2(0, -2), 2.5, Color("e77963"))
	if biting:
		_draw_bite()

func _draw_bite() -> void:
	# Repeating rings keep the entire warning readable, not just its first frame.
	for index in 2:
		var progress := fmod(bite_elapsed * 2.5 + float(index) * 0.5, 1.0)
		draw_arc(landing, 9.0 + 28.0 * progress, 0, TAU, 32, Color(1, 0.96, 0.72, 1.0 - progress), 2.5, true)
	var mark := landing + Vector2(0, -25)
	draw_line(mark, mark + Vector2(0, -10), Color("fff8e5"), 4.0, true)
	draw_circle(mark + Vector2(0, 6), 2.5, Color("fff8e5"))

func _draw_splash(age: float) -> void:
	if age >= SPLASH_TIME:
		# A faint ring helps the waiting bobber stay readable against the water tile.
		draw_arc(landing, 9.0, 0, TAU, 24, Color(0.92, 1, 1, 0.35), 1.0, true)
		return
	var progress := age / SPLASH_TIME
	var water := Color(0.91, 1, 1, 1.0 - progress)
	draw_arc(landing, 7.0 + 35.0 * progress, 0, TAU, 32, water, 2.0, true)
	draw_arc(landing, 4.0 + 24.0 * progress, 0, TAU, 24, water, 1.5, true)
	for index in 6:
		var angle := TAU * float(index) / 6.0
		var offset := Vector2(cos(angle) * 32.0 * progress, sin(angle) * 16.0 * progress - sin(progress * PI) * 17.0)
		draw_circle(landing + offset, 2.0 * (1.0 - progress) + 0.5, water)
