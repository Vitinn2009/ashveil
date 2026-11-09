class_name CloudEffect
extends Node2D

## Nuvem de gás que se espalha e some, como a da Poção Paralisante.

var radius := 140.0
var duration := 1.8
var color := Color("7bd389")
var _time := 0.0


func _ready() -> void:
	z_index = 4


func _process(delta: float) -> void:
	_time += delta
	if _time >= duration:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var progress := clampf(_time / duration, 0.0, 1.0)
	var grow := 0.6 + 0.4 * minf(progress * 3.0, 1.0)
	var fade := 1.0 - maxf(0.0, progress - 0.5) / 0.5
	draw_circle(Vector2.ZERO, radius * grow, Color(color, 0.14 * fade))
	for i in 8:
		var angle := TAU * i / 8.0 + _time * 0.8
		var center := Vector2.from_angle(angle) * radius * 0.5 * grow
		draw_circle(center, radius * 0.38 * grow, Color(color, 0.2 * fade))
	draw_arc(Vector2.ZERO, radius * grow, 0.0, TAU, 48, Color(color, 0.7 * fade), 3.0)
