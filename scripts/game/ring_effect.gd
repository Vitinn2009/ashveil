class_name RingEffect
extends Node2D

## Anel que se expande e some. Usado em golpes, vento e ativação de habilidades.

var radius := 100.0
var color := Color.WHITE
var duration := 0.35
var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	if _time >= duration:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var progress := clampf(_time / duration, 0.0, 1.0)
	var current := radius * (0.35 + 0.65 * progress)
	draw_circle(Vector2.ZERO, current, Color(color, 0.12 * (1.0 - progress)))
	draw_arc(Vector2.ZERO, current, 0.0, TAU, 56, Color(color, 1.0 - progress), 4.0)
