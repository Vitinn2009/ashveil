class_name Projectile
extends Node2D

var style := "magic"
var color := Color.WHITE
var velocity := Vector2.ZERO
var damage := 10.0
var lifetime := 1.5
var radius := 6.0
var pierce := 0
var burn_ticks := 0
var burn_damage := 0.0
var _already_hit: Array = []


func _ready() -> void:
	rotation = velocity.angle()


func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null or _already_hit.has(enemy):
			continue
		if global_position.distance_to(enemy.global_position) <= radius + enemy.radius:
			enemy.take_damage(damage)
			if burn_ticks > 0 and not enemy.is_queued_for_deletion():
				enemy.apply_burn(burn_ticks, burn_damage)
			_already_hit.append(enemy)
			if pierce <= 0:
				queue_free()
				return
			pierce -= 1


func _draw() -> void:
	match style:
		"arrow":
			draw_line(Vector2(-16, 0), Vector2(6, 0), Brand.NIGHT, 5.0)
			draw_line(Vector2(-16, 0), Vector2(6, 0), Color("c9a06a"), 2.5)
			draw_colored_polygon(PackedVector2Array([Vector2(5, -5), Vector2(15, 0), Vector2(5, 5)]), color)
			draw_line(Vector2(-16, 0), Vector2(-20, -4), color, 2.0)
			draw_line(Vector2(-16, 0), Vector2(-20, 4), color, 2.0)
		"fire":
			draw_circle(Vector2.ZERO, radius * 1.9, Color(color, 0.25))
			draw_circle(Vector2.ZERO, radius * 1.2, color)
			draw_circle(Vector2.ZERO, radius * 0.6, Color("fff2a0"))
			draw_circle(Vector2(-radius * 1.4, 0), radius * 0.7, Color(color, 0.6))
		_:
			draw_circle(Vector2.ZERO, radius * 1.8, Color(color, 0.25))
			draw_circle(Vector2.ZERO, radius, color)
			draw_circle(Vector2.ZERO, radius * 0.5, Color.WHITE)
