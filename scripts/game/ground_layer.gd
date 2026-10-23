class_name GroundLayer
extends Node2D

## Chão de grama infinito: uma textura seamless repetida em volta do alvo.
## O nó anda em múltiplos exatos do tamanho do ladrilho, então a grama parece
## parada no mundo enquanto o herói se move.

const TILE := 256.0
const HALF_TILES_X := 7
const HALF_TILES_Y := 6

var follow: Node2D
var _texture: Texture2D


func _ready() -> void:
	_texture = load("res://assets/world/grass.png")
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	z_index = -100
	queue_redraw()


func _process(_delta: float) -> void:
	if follow:
		position = (follow.global_position / TILE).round() * TILE


func _draw() -> void:
	var rect := Rect2(-HALF_TILES_X * TILE, -HALF_TILES_Y * TILE, HALF_TILES_X * 2 * TILE, HALF_TILES_Y * 2 * TILE)
	draw_texture_rect(_texture, rect, true)
