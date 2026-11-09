class_name LightningBolt
extends Node2D

## Raio que cai do alto sobre um ponto. Pisca e some depressa.

var radius := 70.0
var duration := 0.32
var _time := 0.0
var _points := PackedVector2Array()


func _ready() -> void:
	z_index = 7
	var segments := 9
	var height := 380.0
	var jitter := RandomNumberGenerator.new()
	jitter.randomize()
	for i in segments + 1:
		var along := float(i) / segments
		var sway := jitter.randf_range(-26.0, 26.0) * (1.0 - along)
		_points.append(Vector2(sway, -height * (1.0 - along)))


func _process(delta: float) -> void:
	_time += delta
	if _time >= duration:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var fade := 1.0 - clampf(_time / duration, 0.0, 1.0)
	var flicker := 1.0 if int(_time * 40.0) % 2 == 0 else 0.7
	draw_circle(Vector2.ZERO, radius, Color(1.0, 0.95, 0.5, 0.18 * fade))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(1.0, 0.92, 0.4, 0.8 * fade), 3.0)
	draw_polyline(_points, Color(0.5, 0.7, 1.0, 0.55 * fade * flicker), 14.0)
	draw_polyline(_points, Color(1.0, 0.95, 0.5, fade * flicker), 6.0)
	draw_polyline(_points, Color(1.0, 1.0, 1.0, fade), 2.5)
