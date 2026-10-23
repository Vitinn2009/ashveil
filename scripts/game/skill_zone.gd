class_name SkillZone
extends Node2D

## Chão congelado: enquanto está na área, o inimigo anda mais devagar.

var radius := 170.0
var duration := 5.0
var slow_factor := 0.4
var color := Color("6ec6ff")
var _time := 0.0


func _physics_process(delta: float) -> void:
	_time += delta
	if _time >= duration:
		queue_free()
		return
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy and global_position.distance_to(enemy.global_position) <= radius + enemy.radius:
			enemy.apply_slow(slow_factor, 0.3)
	queue_redraw()


func _draw() -> void:
	var fade := clampf(duration - _time, 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius, Color(color, 0.2 * fade))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(color, 0.8 * fade), 3.0)
	for i in 9:
		var angle := TAU * i / 9.0 + 0.4
		var distance := radius * (0.35 + 0.5 * fmod(i * 0.37, 1.0))
		var center := Vector2.from_angle(angle) * distance
		var crystal := PackedVector2Array([
			center + Vector2(0, -9), center + Vector2(5, 0), center + Vector2(0, 9), center + Vector2(-5, 0)])
		draw_colored_polygon(crystal, Color(Color("d8f3ff"), 0.85 * fade))
