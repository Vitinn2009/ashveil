class_name StatPopup
extends Control

## Popup de atributos. Abre em dois formatos:
## - "hero": atributos do herói, a cada 5 níveis (HP, Defesa, Ataque, Rapidez, Sorte)
## - "skill": atributos das habilidades, a cada 10 níveis (Alcance, x2, Recarga, Poder)
## Cada atributo tem um limite. Pontos que não cabem em nenhum atributo são perdidos.

signal closed

const HERO_STATS := [
	{"id": "hp", "name": "HP", "desc": "+12 de vida máxima"},
	{"id": "defense", "name": "Defesa", "desc": "Reduz o dano recebido"},
	{"id": "attack", "name": "Ataque", "desc": "+8% de dano"},
	{"id": "speed", "name": "Rapidez", "desc": "+3% de movimento e de ataque"},
	{"id": "luck", "name": "Sorte", "desc": "+8% de XP e +10% de drops"},
]
const SKILL_STATS := [
	{"id": "range", "name": "Alcance", "desc": "+10% de alcance e área das habilidades"},
	{"id": "echo", "name": "x2", "desc": "+10% de chance de usar a habilidade duas vezes"},
	{"id": "cooldown", "name": "Recarga", "desc": "-5% no tempo de recarga"},
	{"id": "power", "name": "Poder", "desc": "+12% de dano e efeito das habilidades"},
]

var points_left := 0
var group := "hero"
var _player: Player
var _title: Label
var _points_label: Label
var _rows: VBoxContainer
var _value_labels := {}
var _add_buttons := {}
var _confirm_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	# O CenterContainer mantém o painel no centro em qualquer tamanho de tela.
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := PanelContainer.new()
	var style := Brand.make_box(Color(Brand.NIGHT, 0.98), Brand.GOLD, 3, 14)
	style.set_content_margin_all(22)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	_title = Brand.make_label("", 26, Brand.GOLD)
	column.add_child(_title)
	_points_label = Brand.make_label("", 20, Brand.PARCHMENT)
	column.add_child(_points_label)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 8)
	column.add_child(_rows)
	_confirm_button = Brand.make_button("Confirmar", Vector2(0, 54))
	_confirm_button.pressed.connect(confirm)
	column.add_child(_confirm_button)
	hide()


func open(player: Player, points: int, level: int, popup_group := "hero") -> void:
	_player = player
	points_left = points
	group = popup_group
	if group == "skill":
		_title.text = "Nível %d! Atributos das habilidades" % level
	else:
		_title.text = "Nível %d! Distribua seus pontos" % level
	_build_rows()
	_refresh()
	show()


func stats() -> Array:
	return SKILL_STATS if group == "skill" else HERO_STATS


func add_point(stat: String) -> void:
	if points_left <= 0 or _player == null or not _player.can_add_point(group, stat):
		return
	points_left -= 1
	_player.add_point(group, stat)
	_refresh()


## Só fecha depois de gastar todos os pontos, ou quando nenhum atributo aceita mais.
func confirm() -> void:
	if points_left > 0 and _can_spend_any():
		return
	hide()
	closed.emit()


func _can_spend_any() -> bool:
	for stat in stats():
		if _player.can_add_point(group, stat["id"]):
			return true
	return false


func _build_rows() -> void:
	for child in _rows.get_children():
		child.queue_free()
	_value_labels.clear()
	_add_buttons.clear()
	for stat in stats():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var name_box := VBoxContainer.new()
		name_box.custom_minimum_size = Vector2(330, 0)
		name_box.add_child(Brand.make_label(stat["name"], 20, Brand.PARCHMENT))
		name_box.add_child(Brand.make_label(stat["desc"], 13, Color("a8a2c8")))
		row.add_child(name_box)
		var value := Brand.make_label("", 22, Brand.GOLD)
		value.custom_minimum_size = Vector2(90, 0)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_value_labels[stat["id"]] = value
		row.add_child(value)
		var add := Brand.make_button("+", Vector2(64, 48))
		add.pressed.connect(add_point.bind(stat["id"]))
		_add_buttons[stat["id"]] = add
		row.add_child(add)
		_rows.add_child(row)


func _refresh() -> void:
	var cap := Player.MAX_SKILL_POINTS if group == "skill" else Player.MAX_ATTRIBUTE_POINTS
	_points_label.text = "Pontos disponíveis: %d   (máx. %d por atributo)" % [points_left, cap]
	for stat in stats():
		var id: String = stat["id"]
		var spent: int = _player.get_points(group, id)
		var text := "%d/%d" % [spent, cap]
		if group == "hero" and _player.inventory.bonus(id) > 0:
			text += " +%d" % _player.inventory.bonus(id)
		_value_labels[id].text = text
		_add_buttons[id].disabled = points_left <= 0 or not _player.can_add_point(group, id)
	_confirm_button.disabled = points_left > 0 and _can_spend_any()
