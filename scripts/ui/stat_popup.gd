class_name StatPopup
extends PanelContainer

## Popup de atributos, aberto a cada 5 níveis. Exige gastar todos os pontos.

signal closed

const STATS := [
	{"id": "hp", "name": "HP", "desc": "+12 de vida máxima"},
	{"id": "defense", "name": "Defesa", "desc": "Reduz o dano recebido"},
	{"id": "attack", "name": "Ataque", "desc": "+8% de dano"},
	{"id": "speed", "name": "Rapidez", "desc": "+3% de movimento e de ataque"},
	{"id": "luck", "name": "Sorte", "desc": "+8% de XP e +10% de drops"},
]

var points_left := 0
var _player: Player
var _title: Label
var _points_label: Label
var _value_labels := {}
var _add_buttons: Array = []
var _confirm_button: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	process_mode = Node.PROCESS_MODE_ALWAYS
	var style := Brand.make_box(Color(Brand.NIGHT, 0.97), Brand.GOLD, 3, 14)
	style.set_content_margin_all(20)
	add_theme_stylebox_override("panel", style)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	add_child(column)
	_title = Brand.make_label("", 26, Brand.GOLD)
	column.add_child(_title)
	_points_label = Brand.make_label("", 20, Brand.PARCHMENT)
	column.add_child(_points_label)

	for stat in STATS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var name_box := VBoxContainer.new()
		name_box.custom_minimum_size = Vector2(300, 0)
		name_box.add_child(Brand.make_label(stat["name"], 20, Brand.PARCHMENT))
		name_box.add_child(Brand.make_label(stat["desc"], 13, Color("a8a2c8")))
		row.add_child(name_box)
		var value := Brand.make_label("0", 24, Brand.GOLD)
		value.custom_minimum_size = Vector2(50, 0)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_value_labels[stat["id"]] = value
		row.add_child(value)
		var add := Brand.make_button("+", Vector2(64, 48))
		add.pressed.connect(add_point.bind(stat["id"]))
		_add_buttons.append(add)
		row.add_child(add)
		column.add_child(row)

	_confirm_button = Brand.make_button("Confirmar", Vector2(0, 54))
	_confirm_button.pressed.connect(confirm)
	column.add_child(_confirm_button)
	hide()


func open(player: Player, points: int, level: int) -> void:
	_player = player
	points_left = points
	_title.text = "Nível %d! Distribua seus pontos" % level
	_refresh()
	show()


func add_point(stat: String) -> void:
	if points_left <= 0 or _player == null:
		return
	points_left -= 1
	_player.add_attribute(stat)
	_refresh()


func confirm() -> void:
	if points_left > 0:
		return
	hide()
	closed.emit()


func _refresh() -> void:
	_points_label.text = "Pontos disponíveis: %d" % points_left
	for stat in STATS:
		_value_labels[stat["id"]].text = str(_player.stat_points(stat["id"]))
	for button in _add_buttons:
		button.disabled = points_left <= 0
	_confirm_button.disabled = points_left > 0
