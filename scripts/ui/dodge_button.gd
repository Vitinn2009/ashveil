class_name DodgeButton
extends Control

## Botão de esquiva da partida: círculo com setas de dash. Ao tocar, o herói dá um dash e fica com +40% de
## esquiva por um instante. Mostra a recarga como uma cortina escura que desce.

signal pressed

const SIZE := 82.0

## 0 (pronto) a 1 (acabou de usar).
var cooldown := 0.0:
	set(value):
		var clamped := clampf(value, 0.0, 1.0)
		if not is_equal_approx(clamped, cooldown):
			cooldown = clamped
			queue_redraw()
var _touch := -1


func _init() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE)
	size = Vector2(SIZE, SIZE)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()
		accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		pressed.emit()
		accept_event()


func _draw() -> void:
	var center := size * 0.5
	var ready := cooldown <= 0.0
	draw_circle(center, SIZE * 0.5, Color("120a05"))
	draw_circle(center, SIZE * 0.5 - 3.0, Color("2c3f5a") if ready else Color("2a2a32"))
	draw_arc(center, SIZE * 0.5 - 2.0, 0.0, TAU, 48, Brand.GOLD if ready else Color("6a5a3a"), 3.0)
	# Duas setas para a direita: o dash.
	var color := Color("cfe9ff") if ready else Color("7a8494")
	for shift in [-9.0, 7.0]:
		var tip := center + Vector2(shift + 12.0, -4.0)
		draw_line(center + Vector2(shift - 6.0, -16.0), tip, color, 4.0)
		draw_line(center + Vector2(shift - 6.0, 8.0), tip, color, 4.0)
	var font := ThemeDB.fallback_font
	var text := "Esquiva"
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 13).x
	draw_string(font, Vector2(center.x - width * 0.5, SIZE - 14.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Brand.PARCHMENT)
	if not ready:
		# Cortina de recarga: um setor escuro que diminui no sentido horário.
		var points := PackedVector2Array([center])
		var steps := 32
		var sweep := TAU * cooldown
		for i in steps + 1:
			points.append(center + Vector2.from_angle(-PI * 0.5 + sweep * float(i) / steps) * (SIZE * 0.5 - 3.0))
		draw_colored_polygon(points, Color(0, 0, 0, 0.5))
