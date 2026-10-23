class_name SkillButton
extends Button

## Botão de habilidade com nome, tecla de atalho e contagem de recarga.

signal cast_requested(skill_id: String)

var skill_id := ""
var cooldown_left := 0.0
var cooldown_total := 1.0
var _color := Color.WHITE
var _name := ""
var _glyph := ""
var _hotkey := ""


func setup(id: String, hotkey: String) -> void:
	skill_id = id
	var def := Skills.def(id)
	cooldown_total = def["cooldown"]
	_color = def["color"]
	_name = def["name"]
	_glyph = def["glyph"]
	_hotkey = hotkey
	custom_minimum_size = Vector2(104, 104)
	tooltip_text = "%s: %s" % [_name, def["desc"]]
	add_theme_stylebox_override("normal", Brand.make_box(Color(Brand.NIGHT, 0.88), _color, 3, 14))
	add_theme_stylebox_override("hover", Brand.make_box(Color("2a1a4d"), _color, 4, 14))
	add_theme_stylebox_override("pressed", Brand.make_box(Color("120a24"), Brand.PARCHMENT, 4, 14))
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	pressed.connect(func() -> void: cast_requested.emit(skill_id))


func set_cooldown(left: float, total: float) -> void:
	cooldown_left = left
	cooldown_total = max(total, 0.001)
	queue_redraw()


func _draw() -> void:
	var font := get_theme_default_font()
	draw_circle(Vector2(size.x * 0.5, 42), 25.0, Color(_color, 0.3))
	draw_arc(Vector2(size.x * 0.5, 42), 25.0, 0.0, TAU, 32, _color, 2.5)
	draw_string(font, Vector2(0, 52), _glyph, HORIZONTAL_ALIGNMENT_CENTER, size.x, 28, Brand.PARCHMENT)
	draw_string(font, Vector2(0, size.y - 12), _name, HORIZONTAL_ALIGNMENT_CENTER, size.x, 15, Brand.PARCHMENT)
	draw_string(font, Vector2(9, 20), _hotkey, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Brand.GOLD)
	if cooldown_left > 0.0:
		var ratio := clampf(cooldown_left / cooldown_total, 0.0, 1.0)
		draw_rect(Rect2(3, 3, size.x - 6, (size.y - 6) * ratio), Color(0, 0, 0, 0.62))
		draw_string(font, Vector2(0, size.y * 0.58), "%.1f" % cooldown_left, HORIZONTAL_ALIGNMENT_CENTER, size.x, 26, Color.WHITE)
