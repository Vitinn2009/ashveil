class_name TouchJoystick
extends Control

## Joystick virtual: aparece onde o dedo toca na metade esquerda da tela.
## `output` vai de -1 a 1 em cada eixo. Zero quando nenhum dedo está nele.

const MAX_DISTANCE := 90.0

var output := Vector2.ZERO
var _touch_index := -1
var _origin := Vector2.ZERO
var _thumb := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Continua recebendo toques durante a pausa do level-up, para não perder o soltar do dedo.
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1 and _is_in_zone(event.position):
			_touch_index = event.index
			_origin = event.position
			_thumb = event.position
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
			output = Vector2.ZERO
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_thumb = event.position
		output = (_thumb - _origin).limit_length(MAX_DISTANCE) / MAX_DISTANCE
	queue_redraw()


func _is_in_zone(point: Vector2) -> bool:
	return point.x < get_viewport_rect().size.x * 0.5


func _draw() -> void:
	if _touch_index == -1:
		return
	var origin := get_global_transform_with_canvas().affine_inverse() * _origin
	draw_circle(origin, MAX_DISTANCE, Color(1, 1, 1, 0.12))
	draw_circle(origin + (_thumb - _origin).limit_length(MAX_DISTANCE), 34.0, Color(1, 1, 1, 0.35))
