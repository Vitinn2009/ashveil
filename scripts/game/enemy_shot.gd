class_name EnemyShot
extends Node2D

## Osso lançado pelo Esqueleto Arqueiro. Fere o herói ao encostar nele.

var velocity := Vector2.ZERO
var damage := 9.0
var lifetime := 3.0
var target: Player


func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	rotation += delta * 12.0
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	if target and global_position.distance_to(target.global_position) <= target.radius + 7.0:
		target.take_damage(damage)
		queue_free()


func _draw() -> void:
	draw_line(Vector2(-8, 0), Vector2(8, 0), Brand.NIGHT, 6.0)
	draw_line(Vector2(-8, 0), Vector2(8, 0), Brand.PARCHMENT, 3.0)
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(side * 8.0, -2.5), 3.5, Brand.NIGHT)
		draw_circle(Vector2(side * 8.0, 2.5), 3.5, Brand.NIGHT)
		draw_circle(Vector2(side * 8.0, -2.5), 2.4, Brand.PARCHMENT)
		draw_circle(Vector2(side * 8.0, 2.5), 2.4, Brand.PARCHMENT)
