class_name XpGem
extends Node2D

## Gema de XP: é atraída para o herói quando ele chega perto e some ao ser coletada.

const MAGNET_SPEED := 420.0
const COLLECT_DISTANCE := 14.0

var value := 1
var target: Player
var _collected := false


func _physics_process(delta: float) -> void:
	if _collected or target == null:
		return
	var offset := target.global_position - global_position
	var distance := offset.length()
	if distance <= target.pickup_radius:
		global_position += offset / max(distance, 0.001) * MAGNET_SPEED * delta
	if distance <= COLLECT_DISTANCE:
		_collected = true
		EventBus.xp_collected.emit(value)
		queue_free()


func _draw() -> void:
	var diamond := PackedVector2Array([Vector2(0, -6), Vector2(5, 0), Vector2(0, 6), Vector2(-5, 0)])
	draw_colored_polygon(diamond, Color("7bd389"))
