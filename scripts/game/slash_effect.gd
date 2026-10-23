class_name SlashEffect
extends Node2D

## Golpe de espada em leque: o arco varre a frente do herói e some.

var radius := 100.0
var half_arc := 0.96
var color := Color.WHITE
var duration := 0.22
var facing_angle := 0.0
var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	if _time >= duration:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var progress := clampf(_time / duration, 0.0, 1.0)
	var sweep := clampf(progress * 2.2, 0.0, 1.0)
	var start := facing_angle - half_arc
	var end := start + half_arc * 2.0 * sweep
	var fade := 1.0 - progress
	draw_arc(Vector2.ZERO, radius * 0.9, start, end, 28, Color(color, 0.35 * fade), radius * 0.35)
	draw_arc(Vector2.ZERO, radius * 1.02, start, end, 28, Color(color, fade), 6.0)
