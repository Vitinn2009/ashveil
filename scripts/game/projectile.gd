class_name Projectile
extends Node2D

var velocity := Vector2.ZERO
var damage := 10.0
var lifetime := 1.5
var radius := 6.0


func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy and global_position.distance_to(enemy.global_position) <= radius + enemy.radius:
			enemy.take_damage(damage)
			queue_free()
			return


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Brand.GOLD)
