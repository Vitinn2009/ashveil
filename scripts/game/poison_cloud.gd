class_name PoisonCloud
extends Node2D

## Nuvem venenosa deixada pelo Cogumelo Tóxico. Fere o herói que ficar dentro
## dela, de meio em meio segundo.

const TICK := 0.5

var target: Player
var radius := 52.0
var duration := 5.0
var damage_per_second := 5.0
## Cor da nuvem: verde para veneno, laranja para as brasas do Diabrete.
var tint := Color(0.55, 0.95, 0.35)
var _time := 0.0
var _tick := TICK


func _ready() -> void:
	z_index = -10


func _physics_process(delta: float) -> void:
	_time += delta
	if _time >= duration:
		queue_free()
		return
	_tick -= delta
	if _tick <= 0.0:
		_tick = TICK
		if target and global_position.distance_to(target.global_position) <= radius + target.radius:
			target.take_damage(damage_per_second * TICK, "dot")
	queue_redraw()


func _draw() -> void:
	var fade := clampf(duration - _time, 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius, Color(tint, 0.2 * fade))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(tint, 0.55 * fade), 2.0)
	for i in 5:
		var angle := TAU * i / 5.0 + _time * 0.7
		var bubble := Vector2.from_angle(angle) * radius * 0.55
		draw_circle(bubble, radius * 0.22, Color(0.6, 0.95, 0.4, 0.28 * fade))
