class_name HealJar
extends Node2D

## Pote de cura espalhado pelo mapa: ao passar por cima, cura uma parte da vida do herói (20%) e some.
## Se o herói está com a vida cheia, o pote fica esperando.

const COLLECT_RADIUS := 30.0
const HEAL_FRACTION := 0.2

signal collected

var target: Player
var _clock := randf() * TAU
var _done := false


func _ready() -> void:
	add_to_group("jars")
	z_index = 1


func _physics_process(delta: float) -> void:
	_clock += delta
	queue_redraw()
	if _done or target == null or not is_instance_valid(target):
		return
	if target.health < target.max_health and global_position.distance_to(target.global_position) <= COLLECT_RADIUS + target.radius:
		_done = true
		target.heal(target.max_health * HEAL_FRACTION)
		collected.emit()
		queue_free()


func _draw() -> void:
	var bob := sin(_clock * 3.0) * 2.0
	draw_set_transform(Vector2(0, 12), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 13.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var body := PackedVector2Array([
		Vector2(-6, -12 + bob), Vector2(6, -12 + bob), Vector2(12, -2 + bob), Vector2(11, 9 + bob),
		Vector2(5, 13 + bob), Vector2(-5, 13 + bob), Vector2(-11, 9 + bob), Vector2(-12, -2 + bob)])
	var outline := PackedVector2Array()
	for point in body:
		outline.append(point * 1.12)
	draw_colored_polygon(outline, Color("1b0f08"))
	draw_colored_polygon(body, Color("b8643a"))
	draw_rect(Rect2(-8, -15 + bob, 16, 5), Color("8a4a26"))
	draw_rect(Rect2(-8, -15 + bob, 16, 5), Color("1b0f08"), false, 1.5)
	var glow := 0.55 + 0.35 * sin(_clock * 4.0)
	draw_rect(Rect2(-2.5, -4 + bob, 5, 14), Color("7ee08a", glow))
	draw_rect(Rect2(-7, 1 + bob, 14, 5), Color("7ee08a", glow))
