class_name DamageNumber
extends Node2D

## Número de dano que sobe e some sobre o inimigo atingido. Quanto maior o dano, maior e mais
## quente a cor. Também avisa o resultado do golpe: crítico (grande, dourado), bloqueio
## (cinza, com o dano que passou) e esquiva (azul, sem número).

const RISE := 38.0
const LIFETIME := 0.7

var text := ""
var _color := Color.WHITE
var _font_size := 16
var _lifetime := LIFETIME


func setup(value: int, at: Vector2, kind := "hit") -> void:
	global_position = at + Vector2(randf_range(-10.0, 10.0), -18.0)
	z_index = 20
	var strength := clampf(float(value) / 40.0, 0.0, 1.0)
	_color = Color.WHITE.lerp(Color("ffb02e"), strength)
	_font_size = int(lerpf(15.0, 26.0, strength))
	text = str(value)
	match kind:
		"crit":
			text = "%d" % value
			_color = Color("ff3b30")
			_font_size = maxi(_font_size + 10, 28)
			_lifetime = 0.95
		"block":
			text = "%d (bloqueio)" % value
			_color = Color("aeb6c4")
			_font_size = 15
		"miss":
			text = "Errou"
			_color = Color("d8d2c0")
			_font_size = 17
		"dodge":
			text = "Esquiva"
			_color = Color("8fd8ff")
			_font_size = 18
		"dot":
			_color = Color("ff9a4a")
			_font_size = 14


func _ready() -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", position.y - RISE, _lifetime).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, _lifetime * 0.45).set_delay(_lifetime * 0.55)
	scale = Vector2(1.5, 1.5)
	tween.tween_property(self, "scale", Vector2.ONE, 0.12)
	tween.chain().tween_callback(queue_free)


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, _font_size)
	var origin := Vector2(-size.x * 0.5, 0.0)
	draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, 5, Color("120a05"))
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, _color)
