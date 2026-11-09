class_name EnemyShot
extends Node2D

## Projétil de inimigo. "bone": osso do esqueleto, fere ao encostar.
## "web": teia da aranha, fere pouco mas deixa o herói lento por 2s.

var kind := "bone"
var velocity := Vector2.ZERO
var damage := 9.0
## Fração mínima da vida do herói que o tiro tira (ver Enemy.MIN_FRACTION).
var min_fraction := 0.01
var lifetime := 3.0
var target: Player


func _ready() -> void:
	z_index = 5


func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	rotation += delta * (12.0 if kind == "bone" else 3.0)
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	if target and global_position.distance_to(target.global_position) <= target.radius + 7.0:
		target.take_damage(damage, "hit", min_fraction)
		if kind == "web":
			target.apply_slow(0.5, 2.0)
		elif kind == "ice":
			target.apply_slow(0.3, 2.5)
		queue_free()


func _draw() -> void:
	if kind == "ice":
		draw_circle(Vector2.ZERO, 12.0, Color(0.6, 0.9, 1.0, 0.2))
		draw_colored_polygon(PackedVector2Array([Vector2(0, -9), Vector2(5, 0), Vector2(0, 9), Vector2(-5, 0)]), Color("bff0ff"))
		draw_polyline(PackedVector2Array([Vector2(0, -9), Vector2(5, 0), Vector2(0, 9), Vector2(-5, 0), Vector2(0, -9)]), Brand.NIGHT, 1.5)
		return
	if kind == "web":
		draw_circle(Vector2.ZERO, 11.0, Color(1, 1, 1, 0.18))
		for i in 4:
			var angle := PI * i / 4.0
			draw_line(Vector2.from_angle(angle) * -10.0, Vector2.from_angle(angle) * 10.0, Color(0.95, 0.95, 1.0, 0.9), 1.5)
		draw_arc(Vector2.ZERO, 6.5, 0.0, TAU, 14, Color(0.95, 0.95, 1.0, 0.9), 1.5)
		draw_arc(Vector2.ZERO, 10.5, 0.0, TAU, 18, Color(0.95, 0.95, 1.0, 0.7), 1.2)
		return
	draw_line(Vector2(-8, 0), Vector2(8, 0), Brand.NIGHT, 6.0)
	draw_line(Vector2(-8, 0), Vector2(8, 0), Brand.PARCHMENT, 3.0)
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(side * 8.0, -2.5), 3.5, Brand.NIGHT)
		draw_circle(Vector2(side * 8.0, 2.5), 3.5, Brand.NIGHT)
		draw_circle(Vector2(side * 8.0, -2.5), 2.4, Brand.PARCHMENT)
		draw_circle(Vector2(side * 8.0, 2.5), 2.4, Brand.PARCHMENT)
