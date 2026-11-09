class_name CrackEffect
extends Node2D

## Rachaduras no chão que se espalham a partir do ponto da pancada.

var radius := 230.0
var duration := 0.6
var _time := 0.0
var _angles: Array = []
var _bends: Array = []


func _ready() -> void:
	z_index = -15
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in 10:
		_angles.append(TAU * i / 10.0 + rng.randf_range(-0.2, 0.2))
		_bends.append(rng.randf_range(-0.35, 0.35))


func _process(delta: float) -> void:
	_time += delta
	if _time >= duration:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var progress := clampf(_time / duration, 0.0, 1.0)
	var spread := radius * clampf(progress * 2.5, 0.0, 1.0)
	var fade := 1.0 - maxf(0.0, progress - 0.4) / 0.6
	draw_circle(Vector2.ZERO, spread, Color(0.45, 0.3, 0.15, 0.25 * fade))
	draw_arc(Vector2.ZERO, spread, 0.0, TAU, 48, Color(0.85, 0.65, 0.35, 0.9 * fade), 4.0)
	for i in _angles.size():
		var direction := Vector2.from_angle(_angles[i])
		var middle := direction.rotated(_bends[i]) * spread * 0.55
		var tip := direction * spread * 0.95
		var path := PackedVector2Array([Vector2.ZERO, middle, tip])
		draw_polyline(path, Color(0.12, 0.07, 0.03, 0.9 * fade), 6.0)
		draw_polyline(path, Color(0.85, 0.65, 0.35, 0.7 * fade), 2.0)
