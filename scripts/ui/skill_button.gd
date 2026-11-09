class_name SkillButton
extends Button

## Botão de habilidade: nome, tecla, custo de energia e recarga. A habilidade do
## nível 20 aparece com um cadeado até o herói chegar lá.

## Toque simples: dispara com a mira automática.
signal cast_requested(skill_id: String)
## Arrastando um botão de habilidade com mira: `offset` é o arrasto na tela (do centro do botão).
signal aim_changed(skill_id: String, offset: Vector2, active: bool)
## Soltou depois de arrastar: dispara na direção do arrasto.
signal aim_cast_requested(skill_id: String, offset: Vector2)

const SIZE := 104.0
## Arrasto (px) que equivale ao alcance máximo da habilidade, e arrasto mínimo para contar como mira.
const AIM_DRAG_MAX := 150.0
const AIM_DEADZONE := 24.0

var skill_id := ""
var cooldown_left := 0.0
var cooldown_total := 1.0
var unlock_level := 0
## Fase (a partir da 1) em que a habilidade é liberada; 0 quando só depende do nível.
var unlock_stage := 0
var locked := false
var energy_ok := true
var _color := Color.WHITE
var _name := ""
var _glyph := ""
var _hotkey := ""
var _cost := 0.0
var _touch := -1
var _shown_cooldown := -1
var _aiming := false
var _drag := Vector2.ZERO


func setup(id: String, hotkey: String, required_level := 0, required_stage := 0) -> void:
	skill_id = id
	var def := Skills.def(id)
	cooldown_total = def["cooldown"]
	_color = def["color"]
	_name = def["name"]
	_glyph = def["glyph"]
	_cost = def["cost"]
	_hotkey = hotkey
	unlock_level = required_level
	unlock_stage = required_stage
	locked = required_level > 0 or required_stage > 0
	custom_minimum_size = Vector2(SIZE, SIZE)
	focus_mode = Control.FOCUS_NONE
	# Os toques chegam crus (em _input), como no botão de ataque: assim dá para usar a habilidade
	# com um dedo enquanto o outro segura o joystick.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_refresh_tooltip()
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "focus"]:
		add_theme_stylebox_override(state, empty)


func _refresh_tooltip() -> void:
	var def := Skills.def(skill_id)
	var text := "%s (energia %d)\n%s" % [_name, int(_cost), def["desc"]]
	if locked:
		text = "%s\nLiberada: %s." % [text, _lock_text()]
	tooltip_text = text


func set_cooldown(left: float, total: float) -> void:
	# Só redesenha quando o número ou a fatia que aparecem mudam (décimos de segundo).
	var shown := int(ceil(left * 10.0))
	var changed := shown != _shown_cooldown or not is_equal_approx(total, cooldown_total)
	cooldown_left = left
	cooldown_total = maxf(total, 0.001)
	if changed:
		_shown_cooldown = shown
		queue_redraw()


func set_locked(value: bool) -> void:
	if locked != value:
		locked = value
		_refresh_tooltip()
		queue_redraw()


func set_energy_ok(value: bool) -> void:
	if energy_ok != value:
		energy_ok = value
		queue_redraw()


func _draw() -> void:
	var font := get_theme_default_font()
	var dim := locked or not energy_ok
	var tone := Color(0.55, 0.5, 0.45) if locked else (Color(0.75, 0.75, 0.85) if not energy_ok else Color.WHITE)
	var c := size * 0.5
	var r := size.x * 0.5 - 2.0
	draw_circle(c, r + 2.0, Color("120a05"))
	draw_circle(c, r, Brand.BRASS_DARK if not dim else Color("4a3a22"))
	draw_circle(c, r - 4.0, Color("24160d"))
	draw_circle(c, r - 7.0, Color(_color, 0.38 if not dim else 0.16))
	draw_arc(c, r - 2.0, 0.0, TAU, 40, _color * tone, 3.0 if not _aiming else 7.0)
	if locked:
		Icons.draw(self, "lock", Rect2(c - Vector2(15, 22), Vector2(30, 30)), Color("c9bfa8"))
		draw_string_outline(font, Vector2(0, c.y + 28), _lock_text(), HORIZONTAL_ALIGNMENT_CENTER, size.x, 18, 4, Color("120a05"))
		draw_string(font, Vector2(0, c.y + 28), _lock_text(), HORIZONTAL_ALIGNMENT_CENTER, size.x, 18, Color("ffe9a8"))
	else:
		draw_string(font, Vector2(0, c.y + 6), _glyph, HORIZONTAL_ALIGNMENT_CENTER, size.x, 40, Brand.PARCHMENT * tone)
		Icons.draw(self, "bolt", Rect2(c.x - 15, size.y - 24, 11, 13), Color("8ec6ff") * tone)
		draw_string(font, Vector2(c.x - 2, size.y - 13), str(int(_cost)), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("bfe0ff") * tone)
	draw_string_outline(font, Vector2(8, 18), _hotkey, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color("120a05"))
	draw_string(font, Vector2(8, 18), _hotkey, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Brand.BRASS)
	if cooldown_left > 0.0 and not locked:
		# Fatia escura que encolhe no sentido horário, com o tempo que falta no meio.
		var ratio := clampf(cooldown_left / cooldown_total, 0.0, 1.0)
		var points := PackedVector2Array([c])
		var steps := maxi(int(32.0 * ratio), 2)
		for i in steps + 1:
			var angle := -PI * 0.5 + TAU * (1.0 - ratio) + TAU * ratio * float(i) / float(steps)
			points.append(c + Vector2(cos(angle), sin(angle)) * (r - 3.0))
		draw_colored_polygon(points, Color(0, 0, 0, 0.62))
		draw_string_outline(font, Vector2(0, c.y + 9), "%.1f" % cooldown_left, HORIZONTAL_ALIGNMENT_CENTER, size.x, 24, 5, Color("120a05"))
		draw_string(font, Vector2(0, c.y + 9), "%.1f" % cooldown_left, HORIZONTAL_ALIGNMENT_CENTER, size.x, 24, Color.WHITE)


## "Nv 20" para a habilidade de nível; "Fase 2" para as que vêm com o avanço das fases.
func _lock_text() -> String:
	if unlock_level > 0:
		return "Nv %d" % unlock_level
	return "Fase %d" % (unlock_stage + 1)


func _center() -> Vector2:
	return global_position + size * 0.5


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		if event.pressed and _touch == -1 and not locked and event.position.distance_to(_center()) <= SIZE * 0.5 + 4.0:
			_touch = event.index
			_drag = Vector2.ZERO
			_aiming = false
			queue_redraw()
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == _touch:
			_finish_touch(event.position - _center())
	elif event is InputEventScreenDrag and event.index == _touch and Skills.is_aimed(skill_id):
		_drag = event.position - _center()
		var now_aiming := _drag.length() >= AIM_DEADZONE and cooldown_left <= 0.0
		if now_aiming != _aiming:
			_aiming = now_aiming
			queue_redraw()
		aim_changed.emit(skill_id, _drag, _aiming)
		get_viewport().set_input_as_handled()


func _finish_touch(offset: Vector2) -> void:
	var was_aiming := _aiming
	_touch = -1
	_aiming = false
	queue_redraw()
	if was_aiming and offset.length() >= AIM_DEADZONE:
		aim_cast_requested.emit(skill_id, offset)
	else:
		aim_changed.emit(skill_id, Vector2.ZERO, false)
		cast_requested.emit(skill_id)


func _notification(what: int) -> void:
	# Se o jogo pausa ou a janela some com o dedo no botão, cancela a mira.
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree() and _touch != -1:
		_touch = -1
		_aiming = false
		aim_changed.emit(skill_id, Vector2.ZERO, false)
