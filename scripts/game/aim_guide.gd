class_name AimGuide
extends Node2D

## Linha pontilhada e mira que aparecem no mundo enquanto o jogador arrasta uma habilidade com mira.

var direction := Vector2.ZERO
var distance := 0.0
var color := Color.WHITE


func _ready() -> void:
	z_index = 20
	visible = false


func aim(origin: Vector2, new_direction: Vector2, new_distance: float, new_color: Color) -> void:
	global_position = origin
	direction = new_direction
	distance = new_distance
	color = new_color
	visible = true
	queue_redraw()


func clear() -> void:
	visible = false


func _draw() -> void:
	var end := direction * distance
	draw_dashed_line(Vector2.ZERO, end, Color(color, 0.85), 4.0, 12.0)
	draw_arc(end, 20.0, 0.0, TAU, 28, Color(color, 0.95), 3.0)
	draw_circle(end, 5.0, Color(color, 0.95))
