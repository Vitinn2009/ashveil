class_name DeathBurst
extends Node2D

## Estouro de partículas quando um inimigo morre, na cor dele. Elites e chefes soltam mais, maiores
## e com um anel de choque.

const LIFETIME := 0.55

var _age := 0.0
var _bits: Array = []
var _color := Color.WHITE
var _big := false


func setup(at: Vector2, color: Color, radius: float, big: bool) -> void:
	global_position = at
	_color = color
	_big = big
	z_index = 12
	var count := 22 if big else 11
	for i in count:
		var angle := randf() * TAU
		var speed := randf_range(70.0, 190.0) * (1.4 if big else 1.0)
		_bits.append({
			"velocity": Vector2.from_angle(angle) * speed,
			"position": Vector2.from_angle(angle) * radius * 0.4,
			"size": randf_range(2.5, 5.5) * (1.5 if big else 1.0),
			"light": randf() < 0.35,
		})


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	for bit in _bits:
		bit["position"] += bit["velocity"] * delta
		bit["velocity"] = bit["velocity"] * (1.0 - 3.2 * delta) + Vector2(0, 90.0 * delta)
	queue_redraw()


func _draw() -> void:
	var t := _age / LIFETIME
	var fade := 1.0 - t * t
	for bit in _bits:
		var tint := _color.lightened(0.55) if bit["light"] else _color
		draw_circle(bit["position"], float(bit["size"]) * (1.0 - t * 0.6), Color(tint, fade))
	if _big:
		draw_arc(Vector2.ZERO, 12.0 + t * 90.0, 0.0, TAU, 32, Color(1, 1, 1, (1.0 - t) * 0.7), 4.0 * (1.0 - t) + 1.0)
