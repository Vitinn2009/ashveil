class_name AttackButton
extends Control

## Botão grande de ataque manual, no canto da tela, com as habilidades em arco em volta. Segure para
## atacar. Usa os toques crus (como o joystick), para funcionar junto com o dedo que anda; o mouse
## do computador chega aqui como toque (emulate_touch_from_mouse). Até vencer o primeiro chefe
## é o único jeito de atacar; depois do ataque automático, serve para atacar na hora.

signal held_changed(held: bool)

const RADIUS := 82.0

var held := false
var auto_on := false
var auto_unlocked := false
var cooldown := 0.0:
	set(value):
		if absf(value - cooldown) > 0.01:
			cooldown = value
			queue_redraw()
var _touch := -1


func _init() -> void:
	custom_minimum_size = Vector2(RADIUS * 2.0, RADIUS * 2.0)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_auto(value: bool) -> void:
	if auto_on != value:
		auto_on = value
		queue_redraw()


func _center() -> Vector2:
	return global_position + size * 0.5


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		if event.pressed and _touch == -1 and event.position.distance_to(_center()) <= RADIUS + 6.0:
			_touch = event.index
			_set_held(true)
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == _touch:
			_touch = -1
			_set_held(false)


func _notification(what: int) -> void:
	# Se a janela de mochila abre ou o jogo pausa com o dedo no botão, solta o ataque.
	if what == NOTIFICATION_VISIBILITY_CHANGED and not visible and held:
		_touch = -1
		_set_held(false)


func release() -> void:
	_touch = -1
	_set_held(false)


func _set_held(value: bool) -> void:
	if held != value:
		held = value
		queue_redraw()
		held_changed.emit(held)


func _draw() -> void:
	var c := size * 0.5
	var ring := Brand.BRASS if not held else Color("ffe9a8")
	draw_circle(c, RADIUS + 3.0, Color("120a05"))
	draw_circle(c, RADIUS, Color(Brand.BRASS_DARK))
	draw_circle(c, RADIUS - 5.0, ring.darkened(0.15) if not held else ring)
	draw_circle(c, RADIUS - 11.0, Color("2b1a0e") if not held else Color("5a3a1a"))
	draw_circle(c + Vector2(-12, -14), RADIUS - 32.0, Color(1, 1, 1, 0.05))
	Icons.draw(self, "weapon", Rect2(c - Vector2(40, 46), Vector2(80, 80)), Color("e8e2d0") if not held else Color.WHITE)
	if cooldown > 0.0:
		draw_arc(c, RADIUS - 7.0, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - cooldown), 40, Color("9fe4ff"), 4.0)
	var font := get_theme_default_font()
	var text := ("AUTO" if auto_on else "MANUAL") if auto_unlocked else "Auto: 1º chefe"
	var tint := Color("7ee08a") if auto_on else (Color("ffb0a0") if auto_unlocked else Color("c9bfa8"))
	draw_string_outline(font, Vector2(0, c.y + 54), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, 17, 4, Color("120a05"))
	draw_string(font, Vector2(0, c.y + 54), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, 17, tint)


## O automático foi liberado (primeiro chefe derrotado) e está ligado ou desligado.
func set_auto_state(unlocked: bool, on: bool) -> void:
	auto_unlocked = unlocked
	set_auto(on)
	queue_redraw()
