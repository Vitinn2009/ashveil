class_name MapBorder
extends Node2D

## A borda do mapa: um anel vermelho translúcido a MAP_RADIUS do centro. O herói não passa dela, e os
## monstros e potes nascem dentro (menos coisas distantes para a partida processar).

func _ready() -> void:
	z_index = -1


func _draw() -> void:
	draw_arc(Vector2.ZERO, Player.MAP_RADIUS, 0.0, TAU, 160, Color(1.0, 0.25, 0.2, 0.22), 28.0)
	draw_arc(Vector2.ZERO, Player.MAP_RADIUS, 0.0, TAU, 160, Color(1.0, 0.4, 0.3, 0.7), 4.0)
