class_name AttributePopup
extends Control

## Popup que abre a cada 5 níveis para gastar pontos de atributo PERMANENTES do herói: Ataque, Defesa,
## Destreza (acerto, esquiva e crítico), Crítico, Velocidade de movimento, Velocidade de ataque, Vida e
## Resistência (vitalidade). O jogo fica pausado enquanto ele está aberto.

signal point_added(stat: String)
signal closed


## Ordem na tela, nome e o que cada ponto dá.
const STATS := [
	{"id": "attack", "name": "Ataque", "desc": "+8% de dano"},
	{"id": "defense", "name": "Defesa", "desc": "+1 de defesa"},
	{"id": "dex", "name": "Destreza", "desc": "+2% de acerto, +1% de esquiva, +1,2% de crítico"},
	{"id": "crit", "name": "Chance de crítico", "desc": "+1,5% de chance de crítico"},
	{"id": "speed", "name": "Velocidade de movimento", "desc": "+3% de velocidade ao andar"},
	{"id": "aspd", "name": "Velocidade de ataque", "desc": "+4% de velocidade de ataque"},
	{"id": "hp", "name": "Vida", "desc": "+12 de vida máxima"},
	{"id": "stamina", "name": "Resistência", "desc": "+12 de vitalidade e cansa 4% menos"},
]

var points_left := 0

var _player: Player
var _title: Label
var _points_label: Label
var _rows := {}
var _confirm: Button


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dimmer := ColorRect.new()
	dimmer.color = Color(0, 0, 0, 0.62)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dimmer)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := Brand.make_wood_panel(16, Color(Brand.WOOD, 0.98))
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	column.custom_minimum_size = Vector2(640, 0)
	panel.add_child(column)
	column.add_child(Ribbon.new("NOVOS ATRIBUTOS", 40))
	_title = Brand.make_label("", 16, Color("b8c9a0"))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_title)
	_points_label = Brand.make_label("", 22, Brand.GOLD)
	_points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_points_label)
	for entry in STATS:
		column.add_child(_make_row(entry))
	_confirm = Brand.make_wood_button("Confirmar", Vector2(0, 48), 18)
	_confirm.pressed.connect(confirm)
	column.add_child(_confirm)
	hide()


func _make_row(entry: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override("separation", 0)
	var name_label := Brand.make_label(entry["name"], 17, Color("ffe9a8"))
	texts.add_child(name_label)
	texts.add_child(Brand.make_label(entry["desc"], 12, Color("b8c9a0")))
	row.add_child(texts)
	var value := Brand.make_label("", 18, Brand.PARCHMENT)
	value.custom_minimum_size = Vector2(70, 0)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(value)
	var plus := Brand.make_wood_button("+", Vector2(56, 40), 24)
	plus.pressed.connect(add_point.bind(entry["id"]))
	row.add_child(plus)
	_rows[entry["id"]] = {"value": value, "plus": plus}
	return row


func stats() -> Array:
	return STATS


func is_open() -> bool:
	return visible


## Abre com `points` para gastar; `player.attributes` guarda o valor atual de cada atributo.
func open(player: Player, points: int, level: int) -> void:
	_player = player
	points_left = points
	_title.text = "Nível %d! Os pontos ficam para sempre com o %s." % [level, player.hero["name"]]
	_refresh()
	show()


func add_point(stat: String) -> bool:
	if points_left <= 0 or _player == null or not _player.can_add_point("hero", stat):
		return false
	_player.add_point("hero", stat)
	points_left -= 1
	point_added.emit(stat)
	_refresh()
	return true


## Fecha quando os pontos acabam. Se todos os atributos estiverem no limite, o que sobra se perde.
func confirm() -> void:
	if points_left > 0 and _any_can_grow():
		return
	hide()
	closed.emit()


func _any_can_grow() -> bool:
	for entry in STATS:
		if _player.can_add_point("hero", entry["id"]):
			return true
	return false


func _refresh() -> void:
	_points_label.text = "Pontos para gastar: %d" % points_left
	for entry in STATS:
		var stat: String = entry["id"]
		var row: Dictionary = _rows[stat]
		var points := _player.get_points("hero", stat)
		row["value"].text = "%d / %d" % [points, Player.MAX_ATTRIBUTE_POINTS]
		row["plus"].disabled = points_left <= 0 or not _player.can_add_point("hero", stat)
	_confirm.disabled = points_left > 0 and _any_can_grow()
	_confirm.text = "Confirmar" if not _confirm.disabled else "Gaste todos os pontos"


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and visible:
		confirm()
